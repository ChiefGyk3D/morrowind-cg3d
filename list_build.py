#!/usr/bin/env python3
"""Print the live build: data= order, Nexus id, file count, plugins and their state.

Plugin flags: C = enabled in content=, G = enabled in groundcover=, - = present
but not enabled (deliberate alternatives / unused modules; see MODS.md).
"""
import json, os, re, sys

CFG = os.path.expanduser("~/.var/app/org.openmw.OpenMW/config/openmw/openmw.cfg")
MANIFEST = os.path.join(os.path.dirname(os.path.abspath(__file__)), "config", "nexus_manifest.json")
EXT = (".esp", ".esm", ".omwaddon", ".omwscripts")


def main():
    cfg = sys.argv[1] if len(sys.argv) > 1 else CFG
    lines = open(cfg, encoding="utf-8").read().split("\n")
    dirs = [re.sub(r'^data="?|"?$', "", l) for l in lines if l.startswith("data=")]
    content = [l[8:].strip() for l in lines if l.startswith("content=")]
    ground = [l[12:].strip() for l in lines if l.startswith("groundcover=")]
    cl, gl = {c.lower() for c in content}, {g.lower() for g in ground}
    by_folder = {}
    try:
        m = json.load(open(MANIFEST, encoding="utf-8"))
        for x in m["mods"]:
            by_folder.setdefault(x["folder"], []).append(str(x["id"]))
        for u in m.get("urls", []):
            by_folder.setdefault(u["folder"], []).append("gitlab")
    except FileNotFoundError:
        pass
    print(f"{len(dirs)} data paths, {len(content)} content, {len(ground)} groundcover\n")
    for d in dirs:
        rel = d.split("/mods/morrowind/mods/")[-1] if "/mods/morrowind/mods/" in d else d
        top = rel.split("/")[0]
        n = sum(len(f) for _, _, f in os.walk(d)) if os.path.isdir(d) else -1
        plugins = []
        try:
            for e in sorted(os.scandir(d), key=lambda e: e.name.lower()):
                if e.is_file() and e.name.lower().endswith(EXT):
                    flag = "C" if e.name.lower() in cl else ("G" if e.name.lower() in gl else "-")
                    plugins.append(f"{flag}:{e.name}")
        except FileNotFoundError:
            pass
        print(f"{rel:55s} nexus={','.join(by_folder.get(top, ['?'])):14s} files={n:6d}  {' | '.join(plugins)}")
    print("\ncontent= order:")
    for i, c in enumerate(content, 1):
        print(f"  {i:2d} {c}")
    print("\ngroundcover=:")
    for g in ground:
        print(f"     {g}")


if __name__ == "__main__":
    main()
