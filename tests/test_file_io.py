"""Offline tests for the file reads and writes in the three Python scripts.

Every path is a temporary file in a throwaway directory; the module path
constants are patched to point there, so the real OpenMW config is never read
or written. download_mods has its network client replaced by a stub, and
urlopen is made to fail loudly if anything reaches for it.

Run:  python3 -m unittest discover -s tests -v
"""
import contextlib
import importlib
import io
import json
import os
import struct
import sys
import tempfile
import unittest
from unittest import mock

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

apply_config = importlib.import_module("apply_config")
check_masters = importlib.import_module("check_masters")
download_mods = importlib.import_module("download_mods")

E_ACUTE = chr(0xE9)


def write(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="") as f:
        f.write(text)


def read_bytes(path):
    with open(path, "rb") as f:
        return f.read()


class Sandbox(unittest.TestCase):
    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self._tmp.cleanup)
        self.root = self._tmp.name


class ApplyConfigTests(Sandbox):
    def setUp(self):
        super().setUp()
        r = self.root
        self.paths = {
            "OPENMW_CFG": f"{r}/cfg/openmw.cfg",
            "SETTINGS_CFG": f"{r}/cfg/settings.cfg",
            "MODS": f"{r}/mods",
            "TUNING": f"{r}/repo/settings-tuning.cfg",
            "SKIES_FALLBACKS": f"{r}/repo/skies.cfg",
            "BACKUP_DIR": f"{r}/backup",
        }
        for name, value in self.paths.items():
            p = mock.patch.object(apply_config, name, value)
            p.start()
            self.addCleanup(p.stop)

    def run_quiet(self, fn, *args):
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            fn(*args)
        return buf.getvalue()

    def test_openmw_cfg_adds_data_content_and_skies_fallbacks(self):
        mods = self.paths["MODS"]
        os.makedirs(f"{mods}/407_normal_maps_for_morrowind")
        write(f"{mods}/407_normal_maps_for_morrowind/k_weather.esp", "x")
        os.makedirs(f"{mods}/405_skies_iv")
        write(f"{mods}/405_skies_iv/placeholder.txt", "x")
        write(self.paths["SKIES_FALLBACKS"], "# c\nfallback=Sky_A,1\nfallback=Sky_B,2\nother=1\n")
        original = (
            'data="/game/Data Files"\n'
            "content=Morrowind.esm\n"
            "content=Waterfalls Tweaks.esp\n"
            "fallback=Old,0\n"
            f"caf{E_ACUTE}=ok\n"
        )
        write(self.paths["OPENMW_CFG"], original)

        out = self.run_quiet(apply_config.apply_openmw_cfg, False)

        self.assertIn("written.", out)
        expected = "\n".join([
            'data="/game/Data Files"',
            f'data="{mods}/407_normal_maps_for_morrowind"',
            f'data="{mods}/405_skies_iv"',
            "content=Morrowind.esm",
            "content=k_weather.esp",
            "fallback=Old,0",
            "fallback=Sky_A,1",
            "fallback=Sky_B,2",
            f"caf{E_ACUTE}=ok",
            "",
        ])
        self.assertEqual(read_bytes(self.paths["OPENMW_CFG"]), expected.encode("utf-8"))
        backups = os.listdir(self.paths["BACKUP_DIR"])
        self.assertEqual(len(backups), 1)
        self.assertEqual(read_bytes(f"{self.paths['BACKUP_DIR']}/{backups[0]}"), original.encode("utf-8"))

    def test_openmw_cfg_dry_run_writes_nothing(self):
        mods = self.paths["MODS"]
        os.makedirs(f"{mods}/407_normal_maps_for_morrowind")
        write(f"{mods}/407_normal_maps_for_morrowind/k_weather.esp", "x")
        original = 'data="/game/Data Files"\ncontent=Morrowind.esm\n'
        write(self.paths["OPENMW_CFG"], original)
        out = self.run_quiet(apply_config.apply_openmw_cfg, True)
        self.assertIn("+ data: 407_normal_maps_for_morrowind", out)
        self.assertEqual(read_bytes(self.paths["OPENMW_CFG"]), original.encode())
        self.assertFalse(os.path.exists(self.paths["BACKUP_DIR"]))

    def test_openmw_cfg_crlf_input_is_normalized_like_text_mode(self):
        mods = self.paths["MODS"]
        os.makedirs(f"{mods}/407_normal_maps_for_morrowind")
        write(f"{mods}/407_normal_maps_for_morrowind/a.txt", "x")
        write(self.paths["OPENMW_CFG"], 'data="/g"\r\ncontent=Morrowind.esm\r\n')
        self.run_quiet(apply_config.apply_openmw_cfg, False)
        data = read_bytes(self.paths["OPENMW_CFG"])
        self.assertNotIn(b"\r", data)
        self.assertIn(b"407_normal_maps_for_morrowind", data)

    def test_settings_merges_tuning_and_keeps_header(self):
        write(self.paths["TUNING"], "[Video]\nframerate limit = 60 # c\n[Camera]\nfov = 90\n")
        live = "# header line\n\n[Video]\nfullscreen = true\nframerate limit = 30\n\n[GUI]\nscaling = 1\n"
        write(self.paths["SETTINGS_CFG"], live)

        out = self.run_quiet(apply_config.apply_settings, False, 144)

        self.assertIn("(was 30)", out)
        self.assertIn("written.", out)
        expected = (
            "# header line\n\n"
            "[Video]\nfullscreen = true\nframerate limit = 144\n\n"
            "[GUI]\nscaling = 1\n\n"
            "[Camera]\nfov = 90\n\n"
        )
        self.assertEqual(read_bytes(self.paths["SETTINGS_CFG"]), expected.encode("utf-8"))
        self.assertEqual(len(os.listdir(self.paths["BACKUP_DIR"])), 1)

    def test_settings_dry_run_and_no_change_leave_file_alone(self):
        write(self.paths["TUNING"], "[Camera]\nfov = 90\n")
        live = "[Camera]\nfov = 70\n"
        write(self.paths["SETTINGS_CFG"], live)
        self.run_quiet(apply_config.apply_settings, True, None)
        self.assertEqual(read_bytes(self.paths["SETTINGS_CFG"]), live.encode())
        write(self.paths["SETTINGS_CFG"], "[Camera]\nfov = 90\n")
        out = self.run_quiet(apply_config.apply_settings, False, None)
        self.assertIn("(no changes)", out)
        self.assertFalse(os.path.exists(self.paths["BACKUP_DIR"]))


class CheckMastersTests(Sandbox):
    @staticmethod
    def plugin(masters):
        body = b"HEDR" + struct.pack("<I", 4) + bytes(4)
        for m in masters:
            raw = m.encode("cp1252") + bytes(1)
            body += b"MAST" + struct.pack("<I", len(raw)) + raw
            body += b"DATA" + struct.pack("<I", 8) + bytes(8)
        return b"TES3" + struct.pack("<I", len(body)) + bytes(8) + body

    def test_masters_of_reads_header(self):
        p = f"{self.root}/a.esp"
        with open(p, "wb") as f:
            f.write(self.plugin(["Morrowind.esm", "Other.esm"]))
        self.assertEqual(check_masters.masters_of(p), ["Morrowind.esm", "Other.esm"])

    def run_main(self, cfg):
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf), mock.patch.object(sys, "argv", ["check_masters.py", cfg]):
            rc = check_masters.main()
        return rc, buf.getvalue()

    def test_main_ok_and_order_problem(self):
        d = f"{self.root}/data"
        os.makedirs(d)
        with open(f"{d}/Base.esm", "wb") as f:
            f.write(self.plugin(["Morrowind.esm"]))
        with open(f"{d}/Dep.esp", "wb") as f:
            f.write(self.plugin(["Base.esm"]))
        good = f"{self.root}/good.cfg"
        write(good, f'data="{d}"\ncontent=Morrowind.esm\ncontent=Base.esm\ncontent=Dep.esp\n')
        rc, out = self.run_main(good)
        self.assertEqual(rc, 0)
        self.assertIn("3 plugins checked, 0 master-order problem(s).", out)
        bad = f"{self.root}/bad.cfg"
        write(bad, f'data="{d}"\ncontent=Morrowind.esm\ncontent=Dep.esp\ncontent=Base.esm\n')
        rc, out = self.run_main(bad)
        self.assertEqual(rc, 1)
        self.assertIn("loads LATER", out)


class DownloadModsTests(Sandbox):
    def test_load_key_reads_key_file(self):
        keyfile = f"{self.root}/apikey"
        write(keyfile, "  abc123\n")
        with mock.patch.object(download_mods, "KEY_FILE", keyfile), \
                mock.patch.dict(os.environ, {}, clear=False):
            os.environ.pop("NEXUS_API_KEY", None)
            self.assertEqual(download_mods.load_key(), "abc123")

    def test_load_key_missing_exits(self):
        with mock.patch.object(download_mods, "KEY_FILE", f"{self.root}/none"), \
                mock.patch.dict(os.environ, {}, clear=False):
            os.environ.pop("NEXUS_API_KEY", None)
            with self.assertRaises(SystemExit):
                download_mods.load_key()

    def test_main_list_reads_manifest_without_network(self):
        manifest = f"{self.root}/manifest.json"
        write(manifest, json.dumps({
            "game": "morrowind", "mods": [],
            "urls": [{"name": "U", "folder": "u", "file_name": "u.zip", "url": "http://localhost/u"}],
        }))

        class FakeNexus:
            def __init__(self, key, game):
                pass

            def validate(self):
                return {"name": "tester", "is_premium": True}

        def no_network(*a, **k):
            raise AssertionError("network access attempted")

        buf = io.StringIO()
        argv = ["download_mods.py", "--list", "--manifest", manifest, "--dest", f"{self.root}/dest"]
        with contextlib.redirect_stdout(buf), \
                mock.patch.object(sys, "argv", argv), \
                mock.patch.object(download_mods, "load_key", return_value="k"), \
                mock.patch.object(download_mods, "Nexus", FakeNexus), \
                mock.patch.object(download_mods.urllib.request, "urlopen", no_network):
            rc = download_mods.main()
        self.assertEqual(rc, 0)
        self.assertIn("[url] U", buf.getvalue())
        self.assertIn("1 file(s) to download", buf.getvalue())
        self.assertTrue(os.path.isdir(f"{self.root}/dest"))


if __name__ == "__main__":
    unittest.main()
