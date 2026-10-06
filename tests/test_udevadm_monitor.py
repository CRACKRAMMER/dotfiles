"""Exercise hotplug handling without mounting real devices."""

import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
MOCK = r'''
import json, os, pathlib, sys
if pathlib.Path(sys.argv[0]).name == "udevadm":
    if sys.argv[1] == "monitor":
        print(os.environ["EVENTS"])
    else:
        path = next(arg.removeprefix("--path=") for arg in sys.argv if arg.startswith("--path="))
        properties = json.loads(os.environ["PROPERTIES"]).get(path)
        if properties is None:
            sys.exit(1)
        print(properties)
else:
    with open(os.environ["MOUNT_LOG"], "a") as log:
        log.write(json.dumps(sys.argv[1:]) + "\n")
    sys.exit(int(os.environ.get("MOUNT_STATUS", "0")))
'''


class UdevMonitorTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        self.log = self.root / "mounts.jsonl"
        for name in ("udevadm", "udisksctl"):
            command = self.root / name
            command.write_text("#!" + sys.executable + "\n" + MOCK)
            command.chmod(0o755)

    def run_monitor(self, events, properties, status="0"):
        return subprocess.run(
            ["sh", str(ROOT / "scripts/.local/scripts/udevadm-monitor.sh")],
            env=os.environ | {
                "PATH": str(self.root) + ":/usr/bin:/bin",
                "EVENTS": events, "PROPERTIES": json.dumps(properties),
                "MOUNT_LOG": str(self.log), "MOUNT_STATUS": status,
            },
            capture_output=True, text=True, timeout=5,
        )

    def mounts(self):
        return [json.loads(line) for line in self.log.read_text().splitlines()] if self.log.exists() else []

    def test_mounts_only_added_filesystems(self):
        result = self.run_monitor(
            "monitor heading\n"
            "UDEV [1.0] add /devices/disk (block)\n"
            "UDEV [1.1] add /devices/partition (block)\n"
            "UDEV [1.2] remove /devices/partition (block)\n"
            "UDEV [1.3] change /devices/partition (block)\n"
            "UDEV [1.4] add /unexpected/path (block)",
            {
                "/sys/devices/disk": "DEVNAME=/dev/sdz\nID_FS_USAGE=raid",
                "/sys/devices/partition": "DEVNAME=/dev/sdz1\nID_FS_USAGE=filesystem",
            },
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.mounts(), [["mount", "--block-device", "/dev/sdz1", "--no-user-interaction"]])

    def test_failed_queries_and_incomplete_properties_do_not_mount(self):
        result = self.run_monitor(
            "UDEV [1] add /devices/gone (block)\n"
            "UDEV [2] add /devices/no-name (block)\n"
            "UDEV [3] add /devices/no-filesystem (block)",
            {
                "/sys/devices/no-name": "ID_FS_USAGE=filesystem",
                "/sys/devices/no-filesystem": "DEVNAME=/dev/sdz1",
            },
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.mounts(), [])

    def test_mount_failure_does_not_stop_monitoring(self):
        result = self.run_monitor(
            "UDEV [1] add /devices/one (block)\nUDEV [2] add /devices/two (block)",
            {
                "/sys/devices/one": "DEVNAME=/dev/sdz1\nID_FS_USAGE=filesystem",
                "/sys/devices/two": "DEVNAME=/dev/sdy1\nID_FS_USAGE=filesystem",
            },
            status="1",
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual([call[2] for call in self.mounts()], ["/dev/sdz1", "/dev/sdy1"])


if __name__ == "__main__":
    unittest.main()
