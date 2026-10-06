"""Regression checks; never attach to or terminate a user's tmux server."""

import importlib.util
import json
import os
from pathlib import Path
import shlex
import shutil
import signal
import subprocess
import sys
import tempfile
import time
from types import SimpleNamespace
import unittest
from unittest.mock import patch


ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location(
    "tmux_close", ROOT / "kitty/.config/kitty/tmux_close.py"
)
WATCHER = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(WATCHER)


def make_boss(window=None):
    # Each fixture owns its class so wrappers cannot leak between tests.
    class Boss:
        def __init__(self):
            self.os_window_map = {1: [[window]]}
            self.result = None

        def confirm_os_window_close(self, window_id):
            self.result = "confirm"

        def mark_os_window_for_close(self, window_id):
            self.result = "close"

    boss = Boss()
    WATCHER.on_load(boss, {})
    return boss


class CloseHandlerTests(unittest.TestCase):
    def test_logging_is_disabled_by_default(self):
        with patch.dict(os.environ, {"DOTFILES_KITTY_TMUX_DEBUG": "0"}), \
                patch.object(WATCHER.Path, "open") as opened:
            WATCHER._trace("test")
            opened.assert_not_called()

    def test_debug_logging_is_opt_in(self):
        with tempfile.TemporaryDirectory() as directory, \
                patch.dict(os.environ, {"DOTFILES_KITTY_TMUX_DEBUG": "1"}), \
                patch.object(WATCHER, "__file__", str(Path(directory) / "watcher.py")):
            WATCHER._trace("test")
            record = json.loads((Path(directory) / "watcher.log").read_text())
            self.assertEqual(record["event"], "test")

    def test_idle_closes_and_busy_confirms(self):
        boss = make_boss()
        with patch.object(WATCHER, "_idle_tmux_window", return_value=True):
            boss.confirm_os_window_close(1)
            self.assertEqual(boss.result, "close")
        with patch.object(WATCHER, "_idle_tmux_window", return_value=False):
            boss.confirm_os_window_close(1)
            self.assertEqual(boss.result, "confirm")

    def test_check_failure_preserves_confirmation(self):
        boss = make_boss()
        with patch.object(WATCHER, "_idle_tmux_window", side_effect=OSError("gone")):
            boss.confirm_os_window_close(1)
        self.assertEqual(boss.result, "confirm")

    def test_missing_close_api_preserves_confirmation(self):
        boss = make_boss()
        del type(boss).mark_os_window_for_close
        with patch.object(WATCHER, "_idle_tmux_window", return_value=True):
            boss.confirm_os_window_close(1)
        self.assertEqual(boss.result, "confirm")

    def test_missing_confirmation_api_does_not_break_loading(self):
        WATCHER.on_load(SimpleNamespace(), {})

    def test_repeated_loading_keeps_one_wrapper(self):
        boss = make_boss()
        original = type(boss).confirm_os_window_close
        WATCHER.on_load(boss, {})
        self.assertIs(type(boss).confirm_os_window_close, original)


class PaneProcessTests(unittest.TestCase):
    def setUp(self):
        self.platform = patch.object(WATCHER.sys, "platform", "linux")
        self.platform.start()
        self.addCleanup(self.platform.stop)
        self.shell = dict(state="S", parent=99, group=100, session=100,
                          foreground_group=100)

    def check(self, extra, helpers="100"):
        with patch.object(WATCHER, "_linux_processes", return_value={100: self.shell, **extra}):
            return WATCHER._pane_has_only_prompt_helpers("100", helpers)

    def test_only_current_shells_reported_helper_groups_are_exempt(self):
        worker = dict(state="S", parent=1, group=200, session=100,
                      foreground_group=100)
        self.assertTrue(self.check({201: worker}, "100 200"))
        self.assertFalse(self.check({201: worker}))
        self.assertFalse(self.check({201: worker}, "999 200"))
        self.assertFalse(self.check({201: worker}, "100 100"))

    def test_background_process_and_new_session_descendant_require_confirmation(self):
        job = dict(state="S", parent=100, group=300, session=100,
                   foreground_group=100)
        self.assertFalse(self.check({300: job}))
        job = dict(job, session=300, foreground_group=-1)
        self.assertFalse(self.check({300: job}, "100 300"))

    def test_exited_processes_and_unrelated_sessions_do_not_block_closing(self):
        process = dict(state="Z", parent=100, group=300, session=100,
                       foreground_group=100)
        self.assertTrue(self.check({300: process}))
        process = dict(process, state="S", parent=1, session=300)
        self.assertTrue(self.check({300: process}))

    def test_unknown_process_state_preserves_confirmation(self):
        child = SimpleNamespace(child_fd=-1)
        boss = make_boss(SimpleNamespace(child=child))
        with patch.object(WATCHER, "_window_processes", side_effect=PermissionError("unreadable")):
            boss.confirm_os_window_close(1)
        self.assertEqual(boss.result, "confirm")

    def test_non_linux_pane_state_keeps_confirmation(self):
        with patch.object(WATCHER.sys, "platform", "darwin"):
            self.assertFalse(WATCHER._pane_has_only_prompt_helpers("100", "100"))


@unittest.skipUnless(
    sys.platform.startswith("linux") and shutil.which("tmux") and shutil.which("zsh"),
    "Linux, tmux and Zsh are required for isolated PTY integration tests",
)
class TmuxIntegrationTests(unittest.TestCase):
    def test_prompt_jobs_layout_and_last_client_exit(self):
        self.check_prompt_jobs_layout_and_last_client_exit()

    @unittest.skipUnless(
        Path("/usr/share/oh-my-zsh/oh-my-zsh.sh").is_file()
        and Path("/usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme").is_file()
        and Path("/usr/share/zsh-theme-powerlevel10k/gitstatus/usrbin/gitstatusd").is_file(),
        "The system OMZ/P10k packages are required for the full configuration test",
    )
    def test_full_zsh_configuration_with_prompt_helpers(self):
        self.check_prompt_jobs_layout_and_last_client_exit(full_config=True)

    def check_prompt_jobs_layout_and_last_client_exit(self, full_config=False):
        import fcntl
        import pty
        import select
        import struct
        import termios

        with tempfile.TemporaryDirectory(prefix="dotfiles-tmux-test-") as directory:
            home = Path(directory) / "home"
            home.mkdir()
            tmux_dir = home / ".config/tmux"
            tmux_dir.mkdir(parents=True)
            for filename in ("fzf_panes.tmux", "clipboard.sh", "tmux.conf"):
                shutil.copy2(ROOT / "tmux/.config/tmux" / filename, tmux_dir / filename)
            hook = ROOT / "zsh/.config/zsh/tmux-kitty-idle.zsh"
            if full_config:
                zsh_dir = home / ".config/zsh"
                zsh_dir.mkdir(parents=True)
                shutil.copy2(hook, zsh_dir / hook.name)
                shutil.copy2(ROOT / "zsh/.config/zsh/boot-windows.zsh", zsh_dir / "boot-windows.zsh")
                shutil.copytree(ROOT / "zsh/.config/zsh/fzf-tab", zsh_dir / "fzf-tab")
                (home / ".zshenv").write_text("source " + shlex.quote(str(ROOT / "zsh/.zshenv")) + "\n")
                (home / ".zshrc").write_text("source " + shlex.quote(str(ROOT / "zsh/.zshrc")) + "\n")
                p10k = Path.home() / ".p10k.zsh"
                if p10k.is_file():
                    shutil.copy2(p10k, home / ".p10k.zsh")
                else:
                    (home / ".p10k.zsh").write_text(
                        "typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(dir vcs)\n"
                        "typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status command_execution_time)\n"
                        "typeset -g POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true\n"
                    )
            else:
                (home / ".zshrc").write_text("source " + shlex.quote(str(hook)) + "\n")
            command = ["tmux", "-S", str(Path(directory) / "socket")]
            env = dict(os.environ, HOME=str(home), ZDOTDIR=str(home),
                       XDG_CONFIG_HOME=str(home / ".config"), TERM="xterm-256color",
                       XDG_CACHE_HOME=str(home / ".cache"),
                       ZSH_COMPDUMP=str(home / ".zcompdump"), HISTFILE=str(home / ".zsh_history"),
                       TMPDIR=str(directory), DOTFILES_NO_TMUX="1", DOTFILES_KITTY_TMUX_DEBUG="0")
            if full_config:
                env["ZSH"] = "/usr/share/oh-my-zsh"
            env.pop("TMUX", None)
            env.pop("TMUX_PANE", None)
            master = None
            client_pid = None
            second_master = None
            second_pid = None
            disowned_jobs = set()

            def run(*args):
                return subprocess.run(command + list(args), env=env, capture_output=True,
                                      text=True, timeout=2)

            def wait_for(predicate):
                deadline = time.monotonic() + 5
                while time.monotonic() < deadline:
                    if master is not None:
                        try:
                            while select.select([master], [], [], 0)[0]:
                                os.read(master, 65536)
                        except OSError:
                            pass
                    if predicate():
                        return
                    time.sleep(0.05)
                panes = run("list-panes", "-a", "-F", "#{pane_pid}:#{pane_current_command}:#{@kitty_idle_shell_pid}")
                with patch.object(WATCHER, "_trace", lambda event, **details: print(event, details)):
                    idle()
                screen = run("capture-pane", "-p", "-M", "-t", "test")
                self.fail("timed out waiting for the isolated tmux fixture: " + panes.stdout + panes.stderr + screen.stdout)

            def enter(text):
                self.assertEqual(run("send-keys", "-t", "test", "-l", text).returncode, 0)
                # Avoid observing the previous prompt while Enter is still queued.
                run("set-option", "-p", "-t", "test", "@kitty_idle_shell_pid", "0")
                self.assertEqual(run("send-keys", "-t", "test", "Enter").returncode, 0)

            try:
                client_pid, master = pty.fork()
                if client_pid == 0:
                    fcntl.ioctl(0, termios.TIOCSWINSZ, struct.pack("HHHH", 24, 80, 0, 0))
                    os.execvpe("tmux", command + ["-f", str(ROOT / "tmux/.config/tmux/tmux.conf"),
                               "new-session", "-s", "test", "-c", str(ROOT), "zsh -d -i"], env)
                os.set_blocking(master, False)

                def cmdline(pid):
                    return (Path("/proc") / str(pid) / "cmdline").read_bytes().rstrip(b"\0").decode().split("\0")

                child = SimpleNamespace(child_fd=master, cmdline_of_pid=cmdline)
                window = SimpleNamespace(child=child)
                boss = make_boss(window)
                idle = lambda: WATCHER._idle_tmux_window(boss, 1)
                wait_for(idle)
                if full_config:
                    helpers = run("show-options", "-pv", "-t", "test", "@kitty_prompt_helper_pgroups")
                    self.assertGreaterEqual(len(helpers.stdout.split()), 3, "P10k worker and gitstatus groups")
                    self.assertTrue(idle(), "real Zsh startup with persistent prompt workers")
                    # Exercise an active OMZ async prompt request as well as
                    # P10k's persistent workers; neither is a user background job.
                    enter("function _dotfiles_test_async { sleep 60; }; _omz_register_handler _dotfiles_test_async")
                    wait_for(lambda: len(run("show-options", "-pv", "-t", "test", "@kitty_prompt_helper_pgroups").stdout.split()) >= 4)
                    wait_for(idle)
                    self.assertTrue(idle(), "active OMZ async prompt worker")
                    enter("_omz_async_functions=(${_omz_async_functions:#_dotfiles_test_async}); "
                          "kill -TERM -- -${_OMZ_ASYNC_PIDS[_dotfiles_test_async]} 2>/dev/null")
                    wait_for(idle)
                boss.confirm_os_window_close(1)
                self.assertEqual(boss.result, "close", "fresh Zsh prompt")
                enter("source " + shlex.quote(str(hook)))
                wait_for(idle)
                self.assertTrue(idle(), "re-sourcing the hook")

                for layout in ([[window], [window]], [[window, window]]):
                    boss.os_window_map[1] = layout
                    self.assertFalse(idle(), "multiple Kitty tabs/windows")
                boss.os_window_map[1] = [[window]]

                enter("sleep 60")
                wait_for(lambda: run("display-message", "-p", "-t", "test", "#{pane_current_command}").stdout.strip() == "sleep")
                boss.confirm_os_window_close(1)
                self.assertEqual(boss.result, "confirm", "running foreground command")
                run("send-keys", "-t", "test", "C-c")
                wait_for(idle)

                enter("read value")
                wait_for(lambda: run("show-options", "-pv", "-t", "test", "@kitty_idle_shell_pid").stdout.strip() == "0")
                self.assertFalse(idle(), "running shell builtin")
                run("send-keys", "-t", "test", "C-c")
                wait_for(idle)

                enter("test_value=; vared test_value")
                wait_for(lambda: run("show-options", "-pv", "-t", "test", "@kitty_idle_shell_pid").stdout.strip() == "0")
                self.assertFalse(idle(), "ZLE line-init inside vared must not mark a command idle")
                run("send-keys", "-t", "test", "C-c")
                wait_for(idle)

                enter("sleep 60 &")
                wait_for(lambda: run("capture-pane", "-p", "-t", "test").stdout.count("sleep 60 &") > 0)
                time.sleep(0.15)
                self.assertFalse(idle(), "background job at prompt")
                enter("kill %1; wait")
                wait_for(idle)

                # &! and disown remove jobs from the Zsh table without stopping
                # their processes. Inspect the real pane, not just jobs -p.
                for launch in ("sleep 60 &!", "sleep 60 & disown"):
                    pid_file = home / "disowned-pid"
                    enter(launch + "; print -r -- $! > " + shlex.quote(str(pid_file)))
                    wait_for(lambda: pid_file.is_file() and bool(pid_file.read_text().strip()))
                    job_pid = int(pid_file.read_text())
                    disowned_jobs.add(job_pid)
                    wait_for(lambda: run("display-message", "-p", "-t", "test", "#{pane_pid}:#{@kitty_idle_shell_pid}").stdout.strip().split(":")
                             == [run("display-message", "-p", "-t", "test", "#{pane_pid}").stdout.strip()] * 2)
                    self.assertTrue((Path("/proc") / str(job_pid)).exists(), "disowned job still runs")
                    self.assertFalse(idle(), launch)
                    boss.confirm_os_window_close(1)
                    self.assertEqual(boss.result, "confirm", launch)
                    enter("kill " + str(job_pid))
                    wait_for(idle)
                    pid_file.unlink()

                run("copy-mode", "-t", "test")
                self.assertFalse(idle(), "copy mode")
                run("send-keys", "-t", "test", "-X", "cancel")
                wait_for(idle)

                pane = run("split-window", "-t", "test", "-P", "-F", "#{pane_id}", "sleep 60").stdout.strip()
                self.assertFalse(idle(), "extra pane")
                run("kill-pane", "-t", pane)
                wait_for(idle)
                hidden = run("new-window", "-d", "-t", "test", "-P", "-F", "#{window_id}", "sleep 60").stdout.strip()
                self.assertFalse(idle(), "hidden tmux window")
                run("kill-window", "-t", hidden)
                wait_for(idle)

                run("set-option", "-p", "-t", "test", "@kitty_idle_shell_pid", "999999999")
                self.assertFalse(idle(), "stale shell PID")
                enter(":")
                wait_for(idle)

                second_pid, second_master = pty.fork()
                if second_pid == 0:
                    fcntl.ioctl(0, termios.TIOCSWINSZ, struct.pack("HHHH", 24, 80, 0, 0))
                    os.execvpe("tmux", command + ["attach-session", "-t", "test"], env)
                wait_for(lambda: len(run("list-clients", "-F", "#{client_pid}").stdout.splitlines()) == 2)
                self.assertFalse(idle(), "another attached client")
                os.close(second_master)
                second_master = None
                os.waitpid(second_pid, 0)
                second_pid = None
                wait_for(idle)

                os.close(master)
                master = None
                wait_for(lambda: run("list-clients").returncode != 0)
            finally:
                for job_pid in disowned_jobs:
                    try:
                        os.kill(job_pid, signal.SIGTERM)
                    except ProcessLookupError:
                        pass
                run("kill-server")
                if master is not None:
                    os.close(master)
                if second_master is not None:
                    os.close(second_master)
                if second_pid is not None and second_pid > 0:
                    os.waitpid(second_pid, 0)
                if client_pid is not None and client_pid > 0:
                    os.waitpid(client_pid, 0)


if __name__ == "__main__":
    unittest.main(verbosity=2)
