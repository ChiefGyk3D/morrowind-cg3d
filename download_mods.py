#!/usr/bin/env python3
"""Download every archive in config/nexus_manifest.json via the Nexus Mods API.

Needs a Nexus **Premium** account: the API's download_link endpoint only hands
out links without the website's key/expires handshake for premium users.

Key: put your Personal API Key (nexusmods.com -> account -> API Access) in
    ~/.config/nexusmods/apikey    (chmod 600; one line)
or export NEXUS_API_KEY. The key is never written anywhere else.

    ./download_mods.py --list            # what would be fetched, no downloads
    ./download_mods.py                   # fetch everything missing
    ./download_mods.py --only 45886      # one mod (id or folder substring)
    ./download_mods.py --force           # re-download even if present

Files land in ~/mods/morrowind/mod_files with their Nexus file names, so
extract_mods.sh picks them up unchanged. Existing files of the same name and
size are skipped. One request at a time with a polite delay; the API budget is
2,500 calls/day — a full run uses ~2 per mod plus 1 per file.

STATUS: TESTING — YMMV.
"""
import argparse, fnmatch, hashlib, json, os, sys, time, urllib.parse, urllib.request

API = "https://api.nexusmods.com/v1"
HOME = os.path.expanduser("~")
DEST_DEFAULT = f"{HOME}/mods/morrowind/mod_files"
MANIFEST = os.path.join(os.path.dirname(os.path.abspath(__file__)), "config", "nexus_manifest.json")
KEY_FILE = f"{HOME}/.config/nexusmods/apikey"
UA = "morrowind-cg3d/1.0 (+https://github.com/ChiefGyk3D/morrowind-cg3d)"
DELAY = 1.5  # seconds between API calls

CATEGORY_IDS = {"main": 1, "update": 2, "optional": 3, "old": 4, "misc": 5, "deleted": 6, "archived": 7}
DEFAULT_CATEGORIES = {"main", "update", "optional", "misc"}


def load_key():
    k = os.environ.get("NEXUS_API_KEY", "").strip()
    if not k and os.path.isfile(KEY_FILE):
        k = open(KEY_FILE, encoding="utf-8").read().strip()
    if not k:
        sys.exit(f"No API key: put it in {KEY_FILE} (chmod 600) or export NEXUS_API_KEY")
    return k


class Nexus:
    def __init__(self, key, game):
        self.key, self.game, self.last = key, game, 0.0

    def get(self, path):
        wait = DELAY - (time.time() - self.last)
        if wait > 0:
            time.sleep(wait)
        req = urllib.request.Request(f"{API}{path}", headers={
            "apikey": self.key, "User-Agent": UA, "Application-Name": "morrowind-cg3d",
            "Application-Version": "1.0", "Accept": "application/json"})
        with urllib.request.urlopen(req, timeout=60) as r:
            remaining = r.headers.get("x-rl-daily-remaining")
            self.last = time.time()
            return json.load(r), remaining

    def validate(self):
        d, _ = self.get("/users/validate.json")
        return d

    def files(self, mod_id):
        d, rem = self.get(f"/games/{self.game}/mods/{mod_id}/files.json")
        return d.get("files", []), rem

    def download_link(self, mod_id, file_id):
        d, _ = self.get(f"/games/{self.game}/mods/{mod_id}/files/{file_id}/download_link.json")
        # list of {name, short_name, URI}; take the first CDN
        return d[0]["URI"] if d else None


def pick(files, rule):
    """Newest file whose name matches the rule (glob, category set, optional version pin)."""
    cats = {rule["category"]} if "category" in rule else DEFAULT_CATEGORIES
    want_ids = {CATEGORY_IDS[c] for c in cats}
    cands = []
    for f in files:
        if f.get("category_id") not in want_ids:
            continue
        name = f.get("file_name") or f.get("name") or ""
        if not fnmatch.fnmatch(name.lower(), rule["match"].lower()):
            continue
        if "version" in rule and str(f.get("version", "")).strip() != rule["version"]:
            continue
        cands.append(f)
    if not cands:
        return None
    cands.sort(key=lambda f: (f.get("uploaded_timestamp", 0), f.get("file_id", 0)), reverse=True)
    return cands[0]


def human(n):
    for u in ("B", "KB", "MB", "GB"):
        if n < 1024:
            return f"{n:.0f} {u}"
        n /= 1024
    return f"{n:.1f} TB"


def safe_url(url):
    """Nexus CDN links carry the raw file name (spaces etc.); percent-encode the path."""
    u = urllib.parse.urlsplit(url)
    return urllib.parse.urlunsplit((u.scheme, u.netloc, urllib.parse.quote(u.path), u.query, u.fragment))


def fetch(url, dest, expect_size=None, sha256=None):
    tmp = dest + ".part"
    req = urllib.request.Request(safe_url(url), headers={"User-Agent": UA})
    h = hashlib.sha256() if sha256 else None
    done = 0
    with urllib.request.urlopen(req, timeout=120) as r, open(tmp, "wb") as out:
        total = int(r.headers.get("Content-Length") or 0) or expect_size or 0
        while True:
            chunk = r.read(1 << 20)
            if not chunk:
                break
            out.write(chunk); done += len(chunk)
            if h: h.update(chunk)
            if total and sys.stdout.isatty():
                print(f"\r    {human(done)} / {human(total)}", end="", flush=True)
    print(f"\r    {human(done)}" + (f" / {human(total)}" if total else ""))
    if expect_size and abs(done - expect_size) > 1024 * 64:  # Nexus sizes are rounded to KB
        os.remove(tmp); raise RuntimeError(f"size mismatch: got {done}, expected ~{expect_size}")
    if h and h.hexdigest() != sha256:
        os.remove(tmp); raise RuntimeError("sha256 mismatch")
    os.replace(tmp, dest)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--list", action="store_true", help="resolve files, download nothing")
    ap.add_argument("--only", help="mod id or folder substring")
    ap.add_argument("--force", action="store_true", help="re-download existing files")
    ap.add_argument("--dest", default=DEST_DEFAULT)
    ap.add_argument("--manifest", default=MANIFEST)
    ap.add_argument("--files", nargs="+", type=int, metavar="MOD_ID", help="dump every file Nexus offers for these mod ids, then exit")
    a = ap.parse_args()

    if a.files:
        nx = Nexus(load_key(), "morrowind")
        for mid in a.files:
            files, rem = nx.files(mid)
            print(f"[{mid}]  ({len(files)} files; API calls left today: {rem})")
            for f in sorted(files, key=lambda f: (f.get("category_id", 9), -f.get("uploaded_timestamp", 0))):
                print(f"    {str(f.get('category_name') or '?'):12} v{str(f.get('version') or ''):10} {human(int(f.get('size_in_bytes') or (f.get('size_kb') or 0)*1024 or 0)):>8}  {f.get('file_name')}")
        return 0

    m = json.load(open(a.manifest, encoding="utf-8"))
    os.makedirs(a.dest, exist_ok=True)
    nx = Nexus(load_key(), m.get("game", "morrowind"))

    me = nx.validate()
    prem = bool(me.get("is_premium") or me.get("is_premium?"))
    print(f"Nexus user: {me.get('name')}  premium: {prem}")
    if not prem and not a.list:
        sys.exit("Premium is required for API download links. Use --list, or download by hand.")

    plan, problems, notes = [], [], []
    for mod in m["mods"]:
        if a.only and a.only not in (str(mod["id"]), ) and a.only.lower() not in mod.get("folder", "").lower():
            continue
        try:
            files, rem = nx.files(mod["id"])
        except Exception as e:  # noqa: BLE001
            problems.append(f"{mod['id']} {mod['name']}: files.json failed: {e}"); continue
        print(f"[{mod['id']}] {mod['name']}   (API calls left today: {rem})")
        for rule in mod["files"]:
            f = pick(files, rule)
            if not f:
                msg = f"{mod['id']} {mod['name']}: no file matches '{rule['match']}'" + (f" v{rule['version']}" if "version" in rule else "")
                (notes if (mod.get("optional") or rule.get("optional")) else problems).append(msg)
                print(f"    ?? no match for '{rule['match']}'"); continue
            name = f.get("file_name") or f["name"]
            size = int(f.get("size_in_bytes") or f.get("size_kb", 0) * 1024 or 0)
            dest = os.path.join(a.dest, name)
            have = os.path.isfile(dest) and (size == 0 or abs(os.path.getsize(dest) - size) <= 1024 * 64)
            status = "have" if (have and not a.force) else "GET"
            print(f"    {status:4} {name}  [{f.get('category_name')}, v{f.get('version')}, {human(size)}]")
            if status == "GET":
                plan.append((mod, f, name, size, dest))

    for u in m.get("urls", []):
        if a.only and a.only.lower() not in u["folder"].lower():
            continue
        dest = os.path.join(a.dest, u["file_name"])
        status = "have" if (os.path.isfile(dest) and not a.force) else "GET"
        print(f"[url] {u['name']}\n    {status:4} {u['file_name']}")
        if status == "GET":
            plan.append((u, None, u["file_name"], 0, dest))

    print(f"\n{len(plan)} file(s) to download, {len(problems)} problem(s), {len(notes)} note(s).")
    for p in problems: print("  PROBLEM:", p)
    for n in notes: print("  note:", n)
    if a.list or not plan:
        return 1 if problems else 0

    failed = []
    for mod, f, name, size, dest in plan:
        print(f"\n-> {name}")
        try:
            if f is None:  # direct url entry
                sha = None
                if mod.get("sha256_url"):
                    with urllib.request.urlopen(urllib.request.Request(mod["sha256_url"], headers={"User-Agent": UA}), timeout=60) as r:
                        sha = r.read().decode().split()[0]
                fetch(mod["url"], dest, sha256=sha)
            else:
                link = nx.download_link(mod["id"], f["file_id"])
                if not link:
                    raise RuntimeError("no download link returned")
                fetch(link, dest, expect_size=size or None)
            print("    ok")
        except Exception as e:  # noqa: BLE001
            failed.append(f"{name}: {e}"); print(f"    FAILED: {e}")

    print(f"\nDone. {len(plan) - len(failed)} downloaded, {len(failed)} failed.")
    for x in failed: print("  FAILED:", x)
    print("Next: ./extract_mods.sh && ./update_gitlab_mods.sh all && python3 apply_config.py --dry-run")
    return 1 if (failed or problems) else 0


if __name__ == "__main__":
    sys.exit(main())
