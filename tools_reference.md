# OpenMW Modding Tools Reference

Tools used in this build, with setup and usage notes.

---

## mlox — Load Order Sorter

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
