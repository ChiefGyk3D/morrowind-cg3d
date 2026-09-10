#!/usr/bin/env python3
"""Verify every content= plugin's masters load before it (TES3 header MAST records).

Reads openmw.cfg, resolves each content= entry across the data= paths (case-
insensitive, last data path wins like the VFS), parses the TES3 header, and
reports any plugin whose master is missing or listed after it. .omwscripts
entries are skipped. Exit 1 on problems. Called by check_setup.sh.
"""
import os, re, struct, sys

CFG = os.path.expanduser("~/.var/app/org.openmw.OpenMW/config/openmw/openmw.cfg")
BASE = {"morrowind.esm", "tribunal.esm", "bloodmoon.esm"}


def masters_of(path):
    """Return the master file names from a TES3 plugin header."""
    with open(path, "rb") as f:
        head = f.read(16)
        if len(head) < 16 or head[:4] != b"TES3":
            return []
        size = struct.unpack("<I", head[4:8])[0]
        data = f.read(size)
    out, i = [], 0
    while i + 8 <= len(data):
        tag = data[i:i + 4]; ln = struct.unpack("<I", data[i + 4:i + 8])[0]
        body = data[i + 8:i + 8 + ln]
        if tag == b"MAST":
            out.append(body.rstrip(b"\x00").decode("cp1252", "replace"))
        i += 8 + ln
    return out


def main():
    cfg = sys.argv[1] if len(sys.argv) > 1 else CFG
    lines = open(cfg, encoding="utf-8").read().split("\n")
    data_dirs = [re.sub(r'^data="?|"?$', "", l) for l in lines if l.startswith("data=")]
    content = [l[8:].strip() for l in lines if l.startswith("content=")]
    # VFS view: filename (lower) -> path, later data dirs override earlier
    vfs = {}
    for d in data_dirs:
        try:
            for e in os.scandir(d):
                if e.is_file():
                    vfs[e.name.lower()] = e.path
        except FileNotFoundError:
            pass
    problems = 0
    seen = set()
    for name in content:
        low = name.lower()
        if low.endswith(".omwscripts"):
            seen.add(low); continue
        if low in BASE:
            seen.add(low); continue
        path = vfs.get(low)
        if not path:
            print(f"  ERROR: {name}: not found in any data path"); problems += 1; seen.add(low); continue
        for m in masters_of(path):
            ml = m.lower()
            if ml in seen:
                continue
            if ml in {c.lower() for c in content}:
                print(f"  ERROR: {name} needs master '{m}' but it loads LATER in content="); problems += 1
            elif ml in BASE:
                pass
            else:
                print(f"  ERROR: {name} needs master '{m}' which is not in content= at all"); problems += 1
        seen.add(low)
    print(f"  {len(content)} plugins checked, {problems} master-order problem(s).")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
