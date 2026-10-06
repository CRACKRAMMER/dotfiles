"""Desktop script regressions using temporary homes and mocked desktop processes."""

import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
SCRIPTS = ROOT / "scripts/.local/scripts"
LINKS = (
    ".steam/bin32", ".steam/bin64", ".steam/root", ".steam/steam",
    ".steam/sdk32", ".steam/sdk64", ".local/share/Steam",
    ".steam/registry.vdf", ".steam/steam.token",
)
MOCK = r'''
import json, os, pathlib, sys
name = pathlib.Path(sys.argv[0]).name
with open(os.environ["MOCK_LOG"], "a") as f:
    f.write(json.dumps([name, *sys.argv[1:]]) + "\n")
if name == "pgrep":
    sys.exit(int(os.environ.get("PGREP_STATUS", "1")))
if name in ("wofi", "rofi"):
    sys.stdout.write(os.environ.get("MENU_SELECTION", ""))
    sys.exit(int(os.environ.get("MENU_STATUS", "0")))
if name in ("mv", "ln"):
    counter = pathlib.Path(os.environ["MOCK_LOG"] + "." + name)
    count = int(counter.read_text()) + 1 if counter.exists() else 1
    counter.write_text(str(count))
    if count == int(os.environ.get("FAIL_" + name.upper() + "_AT", "0")):
        sys.exit(73)
    os.execv("/usr/bin/" + name, [name, *sys.argv[1:]])
if name == "flock":
    sys.exit(int(os.environ.get("LOCK_BUSY", "0")))
if name == "ps":
    print(os.environ.get("MOCK_PROCESS", "unrelated-player"))
    sys.exit(0)
if name == "setsid":
    os.execvp(sys.argv[1], sys.argv[1:])
if name == "sleep":
    sys.exit(43)
if name == "swww" and sys.argv[1:] == ["query"]:
    counter = pathlib.Path(os.environ["MOCK_LOG"] + ".query")
    count = int(counter.read_text()) + 1 if counter.exists() else 1
    counter.write_text(str(count))
    sys.exit(1 if count <= int(os.environ.get("QUERY_FAILURES", "0")) else 0)
if name == "swww-daemon":
    sys.exit(0)
sys.exit(int(os.environ.get("PLAYER_STATUS", "42")))
'''


class ScriptFixture(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.home = Path(self.directory.name)
        self.bin = self.home / "bin"
        self.bin.mkdir()
        self.log = self.home / "calls.jsonl"
        self.kills = self.home / "kills.log"
        for name in ("pgrep", "wofi", "rofi", "mv", "ln", "flock", "ps", "setsid",
                     "sleep", "swww", "swww-daemon", "feh", "mpvpaper", "xwinwrap"):
            path = self.bin / name
            path.write_text("#!" + sys.executable + "\n" + MOCK)
            path.chmod(0o755)
        # Intercept even Bash's builtin kill: tests never signal host processes.
        startup = self.home / "bash-env"
        startup.write_text('kill() { printf "%s\\n" "$*" >> "$MOCK_KILLS"; return 0; }\n')
        self.env = os.environ | {
            "HOME": str(self.home), "PATH": str(self.bin) + ":/usr/bin:/bin",
            "XDG_RUNTIME_DIR": str(self.home / "run"), "XDG_SESSION_TYPE": "wayland",
            "MOCK_LOG": str(self.log), "MOCK_KILLS": str(self.kills),
            "BASH_ENV": str(startup),
        }

    def run_script(self, name, *args, **overrides):
        return subprocess.run(
            ["/usr/bin/bash", str(SCRIPTS / name), *args], cwd=self.home,
            env=self.env | overrides, capture_output=True, text=True, timeout=8,
        )

    def calls(self):
        return [json.loads(line) for line in self.log.read_text().splitlines()] if self.log.exists() else []

    def reset_calls(self):
        for path in self.home.glob("calls.jsonl*"):
            path.unlink()


class SteamSwitchTests(ScriptFixture):
    def setUp(self):
        super().setUp()
        self.account = self.create_account("Valid Account")
        self.old = {}
        for relative in LINKS:
            path = self.home / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            target = str(self.home / "previous account" / relative)
            path.symlink_to(target)
            self.old[relative] = target

    def create_account(self, name):
        account = self.home / "Games/SteamUser" / name
        for subdir in ("ubuntu12_32", "ubuntu12_64", "linux32", "linux64"):
            (account / "Steam" / subdir).mkdir(parents=True)
        (account / "registry.vdf").write_text("fixture registry")
        (account / "steam.token").write_text("fixture token")
        return account

    def assert_old_links(self):
        for relative, target in self.old.items():
            self.assertTrue((self.home / relative).is_symlink(), relative)
            self.assertEqual(os.readlink(self.home / relative), target)

    def assert_no_transaction(self):
        self.assertFalse((self.home / ".steam/.dotfiles-switch.lock").exists())
        self.assertFalse(any(call[0] in ("ln", "mv") for call in self.calls()))

    def test_empty_invalid_and_traversal_accounts_do_not_touch_links(self):
        for name in ("", ".", "..", "../Valid Account", "Valid Account/Steam", "missing"):
            with self.subTest(name=name):
                result = self.run_script("steam-switch.sh", name)
                if name:
                    self.assertNotEqual(result.returncode, 0)
                self.assert_old_links()
                self.assert_no_transaction()

    def test_cancelled_and_empty_menu_do_not_touch_links(self):
        for status in ("0", "1"):
            with self.subTest(status=status):
                result = self.run_script("steam-switch.sh", MENU_SELECTION="", MENU_STATUS=status)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assert_old_links()
                self.assert_no_transaction()

    def test_missing_target_and_running_steam_prevent_changes(self):
        for status in ("0", "2"):
            with self.subTest(status=status):
                result = self.run_script("steam-switch.sh", "Valid Account", PGREP_STATUS=status)
                self.assertNotEqual(result.returncode, 0)
                self.assert_old_links()
                self.assert_no_transaction()
        (self.account / "steam.token").unlink()
        result = self.run_script("steam-switch.sh", "Valid Account")
        self.assertNotEqual(result.returncode, 0)
        self.assert_old_links()
        self.assert_no_transaction()

    def test_regular_file_and_directory_are_never_replaced(self):
        for is_directory in (False, True):
            with self.subTest(directory=is_directory):
                path = self.home / LINKS[4]
                path.unlink()
                if is_directory:
                    path.mkdir()
                else:
                    path.write_text("keep this file")
                result = self.run_script("steam-switch.sh", "Valid Account")
                self.assertNotEqual(result.returncode, 0)
                if is_directory:
                    self.assertTrue(path.is_dir())
                    path.rmdir()
                else:
                    self.assertEqual(path.read_text(), "keep this file")
                    path.unlink()
                path.symlink_to(self.old[LINKS[4]])
                self.assert_old_links()
                self.assert_no_transaction()

    def test_spaces_and_shell_metacharacters_are_literal_account_names(self):
        for name in ("Valid Account", "account; touch INJECTED"):
            with self.subTest(name=name):
                account = self.account if name == "Valid Account" else self.create_account(name)
                result = self.run_script("steam-switch.sh", name)
                self.assertEqual(result.returncode, 0, result.stderr)
                for relative in LINKS:
                    self.assertTrue((self.home / relative).is_symlink())
                    self.assertTrue(os.readlink(self.home / relative).startswith(str(account) + "/"))
                self.assertFalse((self.home / "INJECTED").exists())
                self.assertFalse(list(self.home.rglob(".dotfiles-switch.*??????")))
                self.reset_calls()

    def test_preparation_failure_leaves_all_existing_links_unchanged(self):
        result = self.run_script("steam-switch.sh", "Valid Account", FAIL_LN_AT="3")
        self.assertNotEqual(result.returncode, 0)
        self.assert_old_links()
        self.assertFalse(any(call[0] == "mv" for call in self.calls()))

    def test_mid_commit_failure_restores_links_and_absent_destination(self):
        missing = LINKS[1]
        (self.home / missing).unlink()
        del self.old[missing]
        result = self.run_script("steam-switch.sh", "Valid Account", FAIL_MV_AT="5")
        self.assertNotEqual(result.returncode, 0)
        self.assert_old_links()
        self.assertFalse((self.home / missing).is_symlink())
        self.assertFalse((self.home / missing).exists())
        self.assertFalse(list(self.home.rglob(".dotfiles-switch.*??????")))


class WallpaperTests(ScriptFixture):
    def wallpaper(self, kind, filename):
        path = self.home / "Pictures/Wallpaper" / kind / filename
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text("fixture media")
        return path

    def state(self, mode, pid="424242"):
        state = Path(self.env["XDG_RUNTIME_DIR"]) / "dotfiles-wallpaper"
        state.mkdir(parents=True, exist_ok=True)
        (state / (mode + ".pid")).write_text(pid + "\n")
        return state

    def test_images_and_videos_preserve_filename_as_one_argument(self):
        filename = 'wall $(touch INJECTED); " blue\nline'
        for session, script, kind, backend, suffix in (
            ("wayland", "randomWallpaper.sh", "Images", "swww", ".jpg"),
            ("x11", "randomWallpaper.sh", "Images", "feh", ".jpg"),
            ("wayland", "randomVideoWallpaper.sh", "Videos", "mpvpaper", ".MP4"),
            ("x11", "randomVideoWallpaper.sh", "Videos", "xwinwrap", ".MP4"),
        ):
            with self.subTest(session=session, script=script):
                self.reset_calls()
                path = self.wallpaper(kind, filename + suffix)
                result = self.run_script(script, XDG_SESSION_TYPE=session)
                self.assertEqual(result.returncode, 42, result.stderr)
                playback = [c for c in self.calls() if c[0] == backend and c[1:] != ["query"]]
                self.assertEqual(len(playback), 1)
                self.assertEqual(playback[0][-1], str(path))
                self.assertEqual(playback[0].count(str(path)), 1)
                self.assertFalse((self.home / "INJECTED").exists())
                self.assertFalse((Path(self.env["XDG_RUNTIME_DIR"]) / "dotfiles-wallpaper" /
                                  ("images.pid" if kind == "Images" else "videos.pid")).exists())
                path.unlink()

    def test_video_filter_ignores_non_media_and_directories(self):
        self.wallpaper("Videos", "notes.txt")
        (self.home / "Pictures/Wallpaper/Videos/not-a-file.mp4").mkdir()
        result = self.run_script("randomVideoWallpaper.sh")
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(any(c[0] == "mpvpaper" for c in self.calls()))

    def test_current_swww_daemon_startup_is_supported(self):
        self.wallpaper("Images", "one.jpg")
        result = self.run_script("randomWallpaper.sh", QUERY_FAILURES="1")
        self.assertEqual(result.returncode, 42, result.stderr)
        self.assertEqual(len([c for c in self.calls() if c[0] == "swww-daemon"]), 1)
        self.assertFalse(any(c == ["swww", "init"] for c in self.calls()))

    def test_repeat_invocation_stops_only_matching_controller(self):
        for mode, script in (("images", "randomWallpaper.sh"), ("videos", "randomVideoWallpaper.sh")):
            with self.subTest(mode=mode):
                self.reset_calls()
                self.state(mode)
                result = self.run_script(script, LOCK_BUSY="1", MOCK_PROCESS="bash " + str(SCRIPTS / script))
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertIn("-TERM 424242", self.kills.read_text().splitlines())
                self.assertFalse(any(c[0] in ("mpvpaper", "swww", "feh", "xwinwrap") for c in self.calls()))
                self.kills.unlink()
                (Path(self.env["XDG_RUNTIME_DIR"]) / "dotfiles-wallpaper" / (mode + ".pid")).unlink()

    def test_image_mode_can_stop_video_and_rejects_unrelated_pid(self):
        self.state("videos")
        result = self.run_script("randomWallpaper.sh", MOCK_PROCESS="bash " + str(SCRIPTS / "randomVideoWallpaper.sh"))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("-TERM 424242", self.kills.read_text().splitlines())
        self.kills.unlink()
        self.reset_calls()
        self.wallpaper("Images", "one.jpg")
        result = self.run_script("randomWallpaper.sh", MOCK_PROCESS="/usr/bin/mpv unrelated.mp4")
        self.assertEqual(result.returncode, 42, result.stderr)
        self.assertFalse(any(line.startswith("-TERM") for line in self.kills.read_text().splitlines()))
        self.assertFalse(any(c[0] in ("killall", "pkill") for c in self.calls()))

    def test_image_loop_stops_if_its_wait_fails(self):
        self.wallpaper("Images", "one.jpg")
        result = self.run_script("randomWallpaper.sh", PLAYER_STATUS="0")
        self.assertEqual(result.returncode, 43, result.stderr)
        self.assertEqual(len([c for c in self.calls() if c[0] == "swww" and c[1] == "img"]), 1)


if __name__ == "__main__":
    unittest.main(verbosity=2)
