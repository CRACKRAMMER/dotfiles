"""Skip Kitty's OS-window confirmation only for a single idle tmux pane."""

from datetime import datetime
from functools import wraps
import json
import os
from pathlib import Path
import subprocess
import sys


def _trace(event, **details):
    if os.environ.get("DOTFILES_KITTY_TMUX_DEBUG") != "1":
        return
    try:
        with Path(__file__).with_suffix(".log").open("a") as log:
            record = {
                "time": datetime.now().isoformat(),
                "kitty_pid": os.getpid(),
                "event": event,
                **details,
            }
            log.write(json.dumps(record) + "\n")
    except OSError:
        pass


def _reject(reason, **details):
    _trace("confirmation-required", reason=reason, **details)
    return False


def _linux_processes():
    """Read one process snapshot; unreadable state must not authorize closing."""
    processes = {}
    for entry in Path("/proc").iterdir():
        if not entry.name.isdecimal():
            continue
        try:
            fields = (entry / "stat").read_text().rsplit(")", 1)[1].split()
        except (FileNotFoundError, ProcessLookupError):
            # Processes routinely exit between listing /proc and reading stat.
            continue
        pid = int(entry.name)
        processes[pid] = {
            "state": fields[0],
            "parent": int(fields[1]),
            "group": int(fields[2]),
            "session": int(fields[3]),
            "foreground_group": int(fields[5]),
        }
    return processes


def _window_processes(child):
    if not sys.platform.startswith("linux"):
        return child.foreground_processes, child.background_processes
    # Kitty's Linux process-group parser splits /proc/PID/stat on spaces,
    # which loses processes whose name contains spaces (e.g. "tmux: client").
    group = os.tcgetpgrp(child.child_fd)
    session = os.getsid(group)
    foreground, background = [], []
    for pid, process in _linux_processes().items():
        if process["state"] == "Z" or process["session"] != session:
            continue
        if process["group"] == group:
            foreground.append({"pid": pid, "cmdline": child.cmdline_of_pid(pid)})
        else:
            background.append(pid)
    return foreground, background


def _pane_has_only_prompt_helpers(pane_pid, helper_state):
    # Kitty knows the outer tmux client's processes, not those inside its pane.
    # jobs -p also misses disowned jobs, so inspect the actual pane session.
    if not sys.platform.startswith("linux"):
        return _reject("pane-process-inspection-unavailable")
    pane_pid = int(pane_pid)
    fields = helper_state.split()
    helpers = set()
    if fields:
        if fields[0] != str(pane_pid):
            return _reject("stale-prompt-helper-owner")
        helpers = {int(value) for value in fields[1:]}
        if any(group <= 0 or group == pane_pid for group in helpers):
            return _reject("invalid-prompt-helper-group")

    processes = _linux_processes()
    pane = processes.get(pane_pid)
    if pane is None or pane["state"] == "Z":
        return _reject("missing-pane-shell")
    if pane["session"] != pane_pid or pane["foreground_group"] != pane_pid:
        return _reject("pane-shell-is-not-foreground")

    # Follow descendants too, so a directly spawned setsid job cannot evade the
    # session check. Fully daemonized services no longer belong to the pane.
    descendants = {pane_pid}
    pending = set(processes) - descendants
    while True:
        children = {pid for pid in pending if processes[pid]["parent"] in descendants}
        if not children:
            break
        descendants.update(children)
        pending.difference_update(children)

    for pid, process in processes.items():
        if pid == pane_pid or process["state"] == "Z":
            continue
        in_session = process["session"] == pane_pid
        if not in_session and pid not in descendants:
            continue
        # P10k and OMZ report their own worker groups, qualified by shell PID.
        # Unknown helpers remain protected by the normal confirmation dialog.
        if in_session and process["group"] in helpers:
            continue
        return _reject("pane-has-background-process", pid=pid)
    return True


def _tmux_output(command, *args):
    result = subprocess.run(
        command + list(args), capture_output=True, text=True, timeout=0.5
    )
    if result.returncode:
        raise ValueError("Cannot inspect tmux")
    return result.stdout.splitlines()


def _idle_tmux_window(boss, os_window_id):
    manager = boss.os_window_map.get(os_window_id)
    if manager is None:
        return _reject("missing-tab-manager")
    tabs = list(manager)
    if len(tabs) != 1:
        return _reject("kitty-tab-count", count=len(tabs))
    windows = list(tabs[0])
    if len(windows) != 1:
        return _reject("kitty-window-count", count=len(windows))
    child = windows[0].child
    foreground, background = _window_processes(child)
    if len(foreground) != 1 or background:
        return _reject("terminal-processes", foreground=len(foreground), background=len(background))
    process = foreground[0]
    argv = process["cmdline"]
    if not argv or Path(argv[0]).name != "tmux":
        return _reject("foreground-is-not-tmux", command=Path(argv[0]).name if argv else "unknown")
    command = [argv[0]]
    # Match custom tmux sockets as well as the default server.
    for index, arg in enumerate(argv[1:], 1):
        if arg in ("-S", "-L"):
            command += [arg, argv[index + 1]]
            break
        if arg.startswith(("-S", "-L")):
            command.append(arg)
            break
    try:
        clients = _tmux_output(command, "list-clients", "-F", "#{client_pid}")
        if clients != [str(process["pid"])]:
            return _reject("tmux-client-count-or-pid", expected=process["pid"], actual=clients)
        # All panes matter: exit-unattached also ends detached sessions.
        panes = _tmux_output(
            command, "list-panes", "-a", "-F",
            "#{pane_pid}\t#{pane_current_command}\t#{@kitty_idle_shell_pid}\t#{pane_in_mode}\t#{@kitty_prompt_helper_pgroups}",
        )
        if len(panes) != 1:
            return _reject("tmux-pane-count", count=len(panes))
        pid, shell, idle_pid, in_mode, helper_state = panes[0].split("\t")
        idle = shell == "zsh" and pid == idle_pid and in_mode == "0"
        if idle:
            idle = _pane_has_only_prompt_helpers(pid, helper_state)
        _trace("tmux-pane-state", shell=shell, pid=pid, idle_pid=idle_pid, in_mode=in_mode, idle=idle)
        return idle
    except (OSError, ValueError, IndexError, subprocess.TimeoutExpired) as error:
        return _reject("tmux-inspection-failed", error=type(error).__name__)


def on_load(boss, data):
    # Watchers expose Kitty internals; keep the original handler as the fallback.
    cls = type(boss)
    original = getattr(cls, "confirm_os_window_close", None)
    if not callable(original):
        _trace("close-handler-unavailable")
        return
    if getattr(original, "_dotfiles_tmux_close", False):
        _trace("watcher-already-loaded")
        return

    @wraps(original)
    def confirm_os_window_close(self, os_window_id):
        _trace("close-request", os_window_id=os_window_id)
        try:
            idle = _idle_tmux_window(self, os_window_id)
        except Exception as error:
            _trace("close-check-error", error=type(error).__name__)
            idle = False
        if idle:
            try:
                self.mark_os_window_for_close(os_window_id)
                return
            except Exception as error:
                _trace("close-handler-error", error=type(error).__name__)
        original(self, os_window_id)

    confirm_os_window_close._dotfiles_tmux_close = True
    cls.confirm_os_window_close = confirm_os_window_close
    _trace("watcher-loaded", version=4)
