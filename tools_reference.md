# OpenMW Modding Tools Reference

Tools used in this build, with setup and usage notes.

---

## PLOX — Load Order Sorter (current recommendation, 2026-08)

**Repo**: https://github.com/rfuzzo/plox · **Nexus**: https://www.nexusmods.com/morrowind/mods/54262
**Version**: 0.5.0

PLOX is a Rust rewrite of mlox by rfuzzo that natively understands OpenMW
loadouts — including `.omwaddon`, `.omwscripts`, and `.omwgame` files that we
currently have to strip out by hand before feeding mlox. mlox is documented to
produce incorrect results on OpenMW load orders, so **PLOX supersedes mlox for
this build**. GUI and CLI variants exist; it reads the same community rules.

Caveat: if this build ever migrates to a Modding-OpenMW curated list, run **no
sorter at all** — MOMW hand-sorts their lists and warns that sorting tools break
them (https://modding-openmw.com/load-order/). Their MOMW Tools Pack
(https://gitlab.com/modding-openmw/momw-tools-pack, v1.50) handles ordering
instead, and also bundles S3LightFixes, Groundcoverify, Delta Plugin, and
OpenMW-Validator.

Flatpak note: the MOMW Tools Pack README states verbatim that "The Flatpak
version of OpenMW is not supported!" — its Configurator pipeline is off the
table for this build. The individual CLI tools (S3LightFixes, Groundcoverify,
Delta Plugin, OpenMW-Validator) still run standalone against the Flatpak config
dir, and OpenMW-Validator is worth running after any load-order change.

---

## mlox — Load Order Sorter (legacy — kept for reference)

> **Note (2026-08)**: superseded by PLOX above for OpenMW use. These notes are
> retained because the workflow below was used to validate the current baseline.

**Repo**: https://github.com/ZilophosGH/mlox-rfuzzo-fork  
**Location**: `~/mods/morrowind/mlox/`  
**Version**: 1.1.5  
**Rules DB**: Auto-downloaded from https://github.com/DanaePlays/mlox-rules

### Setup (Linux, Python 3)

```bash
cd ~/mods/morrowind
git clone https://github.com/ZilophosGH/mlox-rfuzzo-fork.git mlox
pip3 install --user PyQt5 appdirs
```

### Usage

1. Extract active plugin list from openmw.cfg (strip .omwscripts — mlox doesn't handle those):

```bash
grep '^content=' ~/.var/app/org.openmw.OpenMW/config/openmw/openmw.cfg \
  | sed 's/^content=//' \
  | grep -v '.omwscripts' \
  > /tmp/mlox_plugins.txt
```

2. Run mlox in check mode:

```bash
cd ~/mods/morrowind/mlox
python3 mlox.py -f /tmp/mlox_plugins.txt
```

3. Interpret results:
   - `_NNN_` (underscores) = plugin stayed in place, order is correct
   - `*NNN*` (asterisks) = plugin was MOVED — update openmw.cfg to match
   - `[NOTE]` blocks are informational
   - `[WARNING]` blocks indicate potential issues

### Useful flags

| Flag | Purpose |
|------|---------|
| `-n` | Skip database update check (faster) |
| `-p` | Debug/verbose output |
| `-w` | Warnings only (no proposed order) |
| `-c` | Check mode, don't update (default) |
| `-u` | Update mode (writes changes — N/A for OpenMW, we use openmw.cfg) |
| `-e PLUGIN` | Explain dependency graph for a specific plugin |

### Notes

- mlox's compulsory steps note about leveled list merging (Wrye Mash, tes3cmd, TES3Merge) is important for large mod lists. For our baseline, this is not critical yet but becomes important with BCOM and other mods that alter leveled lists.
- mlox rules are community-maintained. If it suggests something that conflicts with known OpenMW behavior, trust the OpenMW/MOMW documentation first.
- The `[SIZE]` predicate defaults to True when reading from external file (our usage), so some size-based rules may be less accurate.

---

## Delta Plugin — Leveled-List / Record Merging

**Repo**: https://gitlab.com/portmod/delta-plugin (releases page has prebuilt Linux binaries)
**Version**: 0.25.3 · Also bundled in the MOMW Tools Pack

The roadmap's "leveled list merging" item. Delta Plugin merges **all record
types that can be meaningfully merged** (leveled lists included — no need for
tes3cmd/TES3Merge/Wrye Mash on top), reading the load order straight from
`openmw.cfg`. It detects additions *and* removals in leveled lists, which the
old tools don't.

Becomes necessary at BCOM/Stage 6 scale, when multiple plugins touch the same
leveled lists (e.g. Repopulated Morrowind + BCOM + OAAB integrations).

### Usage (against the Flatpak config)

```bash
# 1. Create a dedicated output mod folder, registered LAST in data= order:
mkdir -p ~/mods/morrowind/mods/999_merged

# 2. If re-running: remove the old merged plugin's content= line from
#    openmw.cfg first (never merge a merge into itself), then:
delta_plugin -c ~/.var/app/org.openmw.OpenMW/config/openmw/openmw.cfg \
    merge ~/mods/morrowind/mods/999_merged/merged.omwaddon

# 3. Add to openmw.cfg (data= line for 999_merged if not present, and
#    content=merged.omwaddon as the LAST content line). Re-run after ANY
#    plugin add/remove/reorder.
```

Notes:
- **Errors** during merge = something failed and the output is missing pieces.
  **Warnings** = real mod conflicts that can't merge cleanly — fix with compat
  patches rather than ignoring.
- `RAYON_NUM_THREADS=1` makes the log output readable when debugging.
- The repo ships a `BCoM_WaterWorks.ESP` patch fixing a known master-comparison
  issue — relevant when the BCOM stage lands.

---

## OpenMW Flatpak Commands

```bash
# Launch OpenMW
flatpak run org.openmw.OpenMW

# Launch OpenMW Launcher (for settings)
flatpak run org.openmw.OpenMW --launcher

# Check version
flatpak info org.openmw.OpenMW

# Update
flatpak update org.openmw.OpenMW

# Grant filesystem access
flatpak override --user org.openmw.OpenMW --filesystem=/path/to/mods:ro
```

### Key Flatpak paths

| What | Path |
|------|------|
| Config | `~/.var/app/org.openmw.OpenMW/config/openmw/openmw.cfg` |
| Saves | `~/.var/app/org.openmw.OpenMW/data/openmw/saves/` |
| Log | `~/.var/app/org.openmw.OpenMW/config/openmw/openmw.log` |
| Override | `~/.local/share/flatpak/overrides/org.openmw.OpenMW` |

---

## 7-Zip (p7zip) — Archive Extraction

```bash
# List contents
7z l archive.7z

# Extract to specific directory
7z x archive.7z -o/path/to/output

# Extract specific folder from archive
7z x archive.7z "folder_name/*" -o/path/to/output
```

---

## Useful Diagnostic Commands

```bash
# Check openmw.log for errors after launch
grep -E '(Error|Warning|Failed|missing)' ~/.var/app/org.openmw.OpenMW/config/openmw/openmw.log

# List all active data= paths
grep '^data=' ~/.var/app/org.openmw.OpenMW/config/openmw/openmw.cfg

# List all active content= entries
grep '^content=' ~/.var/app/org.openmw.OpenMW/config/openmw/openmw.cfg

# Verify a mod folder has expected structure (should have meshes/, textures/, etc or .esm/.esp at top level)
ls -la ~/mods/morrowind/mods/FOLDER_NAME/

# Check file count in a mod folder
find ~/mods/morrowind/mods/FOLDER_NAME/ -type f | wc -l
```

---

## References

- [Modding-OpenMW.com](https://modding-openmw.com/) — Curated mod lists and CFG generator for OpenMW
- [I Heart Vanilla: Director's Cut](https://modding-openmw.com/lists/i-heart-vanilla-directors-cut/) — Curated vanilla+ list with TR
- [Total Overhaul CFG Generator](https://modding-openmw.com/cfg/total-overhaul/) — For big mod lists
- [TR Recommended Mods](https://www.tamriel-rebuilt.org/recommended-mods) — Official TR compatibility recommendations
- [TR Incompatible Mods](https://www.tamriel-rebuilt.org/incompatible-mods) — Known conflicts
- [OpenMW Modding Docs](https://openmw.readthedocs.io/en/latest/reference/modding/mod-install.html) — Official install guide
- [mlox Rules Repo](https://github.com/DanaePlays/mlox-rules) — Community load order rules
