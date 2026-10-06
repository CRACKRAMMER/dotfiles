"""Regression checks; never attach to or terminate a user's tmux server."""

import importlib.util
import json
import os
from pathlib import Path
import shlex
import shutil
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


@unittest.skipUnless(
    sys.platform.startswith("linux") and shutil.which("tmux") and shutil.which("zsh"),
    "Linux, tmux and Zsh are required for isolated PTY integration tests",
)
class TmuxIntegrationTests(unittest.TestCase):
    def test_prompt_jobs_layout_and_last_client_exit(self):
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
            (home / ".zshrc").write_text("source " + shlex.quote(str(hook)) + "\n")
            command = ["tmux", "-S", str(Path(directory) / "socket")]
            env = dict(os.environ, HOME=str(home), ZDOTDIR=str(home),
                       XDG_CONFIG_HOME=str(home / ".config"), TERM="xterm-256color",
                       DOTFILES_KITTY_TMUX_DEBUG="0")
            env.pop("TMUX", None)
            env.pop("TMUX_PANE", None)
            master = None
            client_pid = None
            second_master = None
            second_pid = None

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
                               "new-session", "-s", "test", "zsh -d -i"], env)
                os.set_blocking(master, False)

                def cmdline(pid):
                    return (Path("/proc") / str(pid) / "cmdline").read_bytes().rstrip(b"\0").decode().split("\0")

                child = SimpleNamespace(child_fd=master, cmdline_of_pid=cmdline)
                window = SimpleNamespace(child=child)
                boss = make_boss(window)
                idle = lambda: WATCHER._idle_tmux_window(boss, 1)
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

                enter("sleep 60 &")
                wait_for(lambda: run("capture-pane", "-p", "-t", "test").stdout.count("sleep 60 &") > 0)
                time.sleep(0.15)
                self.assertFalse(idle(), "background job at prompt")
                enter("kill %1; wait")
                wait_for(idle)

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
