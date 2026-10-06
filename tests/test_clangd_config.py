"""Run with: python -B -m unittest discover -s tests -p test_clangd_config.py."""

import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]


@unittest.skipUnless(shutil.which("clangd"), "clangd is required")
class ClangdConfigTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory(prefix="dotfiles-clangd-")
        self.root = Path(self.directory.name)
        config = self.root / "config" / "clangd"
        config.mkdir(parents=True)
        shutil.copyfile(ROOT / "nvim/.config/clangd/config.yaml", config / "config.yaml")
        self.environment = {**os.environ, "XDG_CONFIG_HOME": str(self.root / "config")}

    def tearDown(self):
        self.directory.cleanup()

    def check(self, name, text, standard=None):
        source = self.root / name
        source.write_text(text)
        if standard:
            database = [{
                "directory": str(self.root),
                "arguments": ["clang++", f"-std={standard}", "-c", str(source)],
                "file": str(source),
            }]
            (self.root / "compile_commands.json").write_text(json.dumps(database))
        return subprocess.run(
            ["clangd", f"--check={source}", "--enable-config", "--log=info"],
            env=self.environment,
            cwd=self.root,
            capture_output=True,
            text=True,
            timeout=30,
        )

    def test_valid_c_has_no_cpp_standard_flag(self):
        result = self.check("sample.c", "int main(void) { return 0; }\n")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn("-std=c++20", result.stderr)

    def test_project_cpp17_rejects_cpp20_syntax(self):
        result = self.check("sample.cpp", "template <typename T> concept Any = true;\n", "c++17")
        self.assertNotEqual(result.returncode, 0, result.stderr)
        self.assertIn("-std=c++17", result.stderr)
        self.assertNotIn("-std=c++20", result.stderr)

    def test_project_cpp20_accepts_cpp20_syntax(self):
        result = self.check("sample.cpp", "template <typename T> concept Any = true;\n", "c++20")
        self.assertEqual(result.returncode, 0, result.stderr)


if __name__ == "__main__":
    unittest.main()
