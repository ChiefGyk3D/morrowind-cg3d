# MORROWIND OPENMW LINUX FLATPAK BUILD SHEET

> **STATUS: TESTING — YMMV.** This sheet reflects a build that is still being
> validated tier by tier on one machine. Follow the validation checklists and
> keep backups; do not treat any section as battle-tested yet.

## GOAL

Build a stable but scalable OpenMW setup on Linux using Flatpak OpenMW, starting with a
Tamriel Rebuilt vanilla-plus baseline and then adding more "alive", prettier, and more
heavily enhanced mods as desired.

## IMPORTANT NOTES

- Modding-OpenMW's current curated lists require OpenMW 0.50+.
- Their automated Linux workflows do NOT support Flatpak OpenMW.
- Flatpak OpenMW is still fine for manual installs through openmw.cfg and separate data paths.
- If you go very large, use the Modding-OpenMW CFG Generator snippets and NOT "enable every plugin".

## FOLDER LAYOUT (as used by this build)

This matches what `extract_mods.sh` actually produces under `~/mods/morrowind/`:

```
~/mods/morrowind/
├── mod_files/                       # downloaded archives (~5 GB, not in git)
├── mods/
│   ├── 001_patch_for_purists/
│   ├── 002_umopp/
│   ├── 003_expansion_delay/
│   ├── 004_morrowind_optimization_patch/
│   ├── 005_tamriel_data/
│   ├── 006_tamriel_rebuilt/
│   ├── OAAB_Data/
│   ├── 101_graphic_herbalism/
│   ├── 102_harvest_lights/
│   ├── 103_weapon_sheathing/
│   ├── 104_project_atlas/
│   ├── 105_morrowind_enhanced_textures/
│   ├── 106_familiar_faces/
│   ├── 201_containers_animated/
│   ├── 202_glow_in_the_dahrk/       # v2.11.2 ONLY — currently pending re-download
│   ├── 203_nords_shut_your_windows/
│   ├── 204_truetype_fonts/
│   ├── 205_cantons_global_map/
│   ├── 206_distant_seafloor/
│   ├── 207_distant_fixes_lua/       # replaces Dynamic Distant Buildings (they conflict)
│   ├── 301_repopulated_morrowind/
│   └── 302_repopulated_creatures/
├── mlox/                            # cloned separately
└── saves_backup_*/                  # rsync'd save backups (not in git)
```

Future big-boy folders (303 BCOM, 304/305 normal maps, 306 bodies/heads) follow the
same numbering scheme when they land.

## PREP CHECKLIST

- [ ] Confirm OpenMW is 0.50 or newer
- [ ] Back up ~/.var/app/org.openmw.OpenMW/config/openmw/openmw.cfg
- [ ] Keep all mod archives in ~/mods/morrowind/mod_files/
- [ ] Extract each mod into its own numbered folder under ~/mods/morrowind/mods/ (extract_mods.sh does this)
- [ ] Grant Flatpak OpenMW read access to ~/mods/morrowind
- [ ] Add one mod folder at a time to openmw.cfg as a separate data= line
- [ ] If a mod includes a BSA, add fallback-archive= for it
- [ ] Test after each tier instead of dumping everything in at once

## FLATPAK ACCESS

Use Flatseal or a flatpak override so OpenMW can read your game/mod folder.

```bash
flatpak override --user org.openmw.OpenMW --filesystem=$HOME/mods/morrowind:ro
```

**Always name the app** (`org.openmw.OpenMW`) — running `flatpak override --user
--filesystem=...` without an app ID grants the folder to EVERY Flatpak app on the
system. `:ro` keeps the grant read-only; OpenMW only needs to read mod data.

## OPENMW CONFIG

Flatpak OpenMW does NOT use `~/.config/openmw/`. The real config path is:
```
~/.var/app/org.openmw.OpenMW/config/openmw/openmw.cfg
```
(Non-Flatpak installs use `~/.config/openmw/openmw.cfg`.)

Backup:
```bash
mkdir -p ~/mods/morrowind/backups
cp ~/.var/app/org.openmw.OpenMW/config/openmw/openmw.cfg \
   ~/mods/morrowind/backups/openmw.cfg.$(date +%Y%m%d).bak
```

---

## BASELINE BUILD: TIER 1

These are the must-install backbone mods.

- [ ] 001 Patch for Purists
- [ ] 002 Unofficial Morrowind Official Plugins Patched
- [ ] 003 Expansion Delay
- [ ] 004 Morrowind Optimization Patch
- [ ] 005 Tamriel_Data (HD)
- [ ] 006 Tamriel Rebuilt
- [ ] OAAB_Data (shared asset library — required by BCOM later, integrates with Repopulated Morrowind)

### Tier 1 validation

- [ ] Game launches
- [ ] No missing masters
- [ ] Tamriel Rebuilt mainland loads
- [ ] No giant yellow missing mesh errors
- [ ] No immediate crashes in cities or while traveling

---

## BASELINE BUILD: TIER 2

These are the best next-step vanilla-plus upgrades.

- [ ] 101 Graphic Herbalism – MWSE and OpenMW Edition
- [ ] 102 Harvest Lights (OpenMW)
- [ ] 103 Weapon Sheathing
- [ ] 104 Project Atlas
- [ ] 105 Morrowind Enhanced Textures
- [ ] 106 Familiar Faces

### Tier 2 validation

- [ ] Harvesting works cleanly
- [ ] Sheathed weapons appear properly
- [ ] Major texture upgrades are visible
- [ ] No obvious broken assets in Seyda Neen, Balmora, Vivec

---

## BASELINE BUILD: TIER 3

These are optional polish extras.

- [ ] 201 OpenMW Containers Animated
- [ ] 202 Glow in the Dahrk 2.11.2 ONLY
- [ ] 203 Nords Shut Your Windows
- [ ] 204 TrueType Fonts for OpenMW
- [ ] 205 Cantons on the Global Map
- [ ] 206 Distant Seafloor for OpenMW
- [ ] 207 Distant Fixes: Lua Edition (NOT Dynamic Distant Buildings — the two are incompatible; Distant Fixes replaces it)

### Tier 3 validation

- [ ] Windows glow properly at night
- [ ] Fonts render correctly
- [ ] Distant scenery does not show broken geometry
- [ ] Containers animate without weird behavior

---

## THE MODERN MCA REPLACEMENT / "MORE ALIVE" OPTIONS

If you want to recreate the feeling of Morrowind Comes Alive without actually using MCA,
these are the main mods to look at first.

- [ ] **301 Repopulated Morrowind**
  - Best modern MCA-like option
  - Adds named and generic NPCs around Vvardenfell and Solstheim
  - Uses leveled lists for variety
  - Requires TR_Data
  - Supports landmasses, especially Tamriel Rebuilt, through optional plugins

- [ ] **302 Repopulated Creatures**
  - Good companion mod if you want the world itself to feel busier and less static

---

## "PRETTIER / MORE MODERN" BIG UPGRADE OPTIONS

If you want to go well beyond the 19-mod baseline, this is the order to think about it:

### STAGE A: High-value city/world prettiness

- [ ] **303 Beautiful Cities of Morrowind**
  - Overhauls almost every settlement
  - Vanilla-plus feeling
  - One of the best "wow, the world feels upgraded" mods

- [ ] **304 Normal Maps for Everything**
  - Big visual win for OpenMW
  - Adds high-quality normal maps and makes assets look more modern

- [ ] **305 Normal Maps for Morrowind / Tamriel Rebuilt / OAAB / related packs**
  - Best if you are using mainland content and broader asset ecosystems

### STAGE B: Better heads / bodies / faces

- [ ] **306 Bodies and Heads Replacers**
  Suggested family to investigate:
  - MacKom's Humanoid Heads
  - New Hairs for MacKom's Heads
  - Expressive Eyes for MacKom's Heads
  - Dandion's Familiar Looks fixes / related patches
  - TR heads replacers / Mackom style TR patches

This is one of the biggest differences between "still old-school Morrowind" and "this actually
looks remastered enough for a modern replay".

---

## RECOMMENDED BUILD PATHS

### PATH 1: STABLE + BIGGER

Use:
- Tier 1
- Tier 2
- Tier 3
- Repopulated Morrowind
- Repopulated Creatures
- Beautiful Cities of Morrowind
- Normal Maps for Everything

This is the best "enhanced but still sane" recommendation.

### PATH 2: HEAVY MANUAL BUILD

Use:
- Everything in Path 1
- Normal Maps for Morrowind / TR / OAAB
- Bodies and heads replacers
- Additional curated city, clutter, and quest additions

This is where hardware starts to matter more and you can really push things.

### PATH 3: FULL INSANITY / REMASTER ROUTE

If you truly want "Morrowind completely enhanced, prettier, alive, and loaded up":
- Graphics Overhaul = 377 mods
- Expanded Vanilla = 441 mods
- Total Overhaul = 619 mods

Use those as source lists / shopping lists, not as something to blindly install by hand all at once.

---

## RECOMMENDED TARGET (5070 Ti / 5950X / 64 GB RAM)

- Tier 1
- Tier 2
- Tier 3
- Repopulated Morrowind
- Repopulated Creatures
- Beautiful Cities of Morrowind
- Normal Maps for Everything
- Normal Maps for Morrowind / TR / OAAB
- A good heads + hairs + eyes package

That gives you:
- Bug fixes
- Better QoL
- Better cities
- Better population
- Better textures
- Better normals / lighting
- Better character faces
- Tamriel Rebuilt content

Without immediately jumping straight to 600+ mods.

---

## TROUBLESHOOTING ORDER

If something breaks, disable in this order:

1. [ ] Tier 3 extras first
2. [ ] Repopulated Creatures
3. [ ] Repopulated Morrowind optional plugins
4. [ ] Beautiful Cities of Morrowind
5. [ ] Bodies / heads replacers
6. [ ] Normal map packs
7. [ ] Tier 2 one by one

**Do NOT yank out Tamriel_Data or Tamriel Rebuilt casually once dependent mods are active.**

---

## OPENMW.CFG TEMPLATE SKELETON

Replace `YOURUSER` with your Linux username. Paths match the folders
`extract_mods.sh` creates. Later `data=` lines override earlier ones.

Tamriel_Data ships BSAs, so also register:
```ini
fallback-archive=PT_Data.bsa
fallback-archive=TR_Data.bsa
```

```ini
data="/home/YOURUSER/mods/morrowind/mods/001_patch_for_purists"
data="/home/YOURUSER/mods/morrowind/mods/002_umopp"
data="/home/YOURUSER/mods/morrowind/mods/003_expansion_delay"
data="/home/YOURUSER/mods/morrowind/mods/005_tamriel_data"
data="/home/YOURUSER/mods/morrowind/mods/OAAB_Data"
data="/home/YOURUSER/mods/morrowind/mods/004_morrowind_optimization_patch"
data="/home/YOURUSER/mods/morrowind/mods/006_tamriel_rebuilt"
data="/home/YOURUSER/mods/morrowind/mods/101_graphic_herbalism"
data="/home/YOURUSER/mods/morrowind/mods/104_project_atlas"
data="/home/YOURUSER/mods/morrowind/mods/105_morrowind_enhanced_textures"
data="/home/YOURUSER/mods/morrowind/mods/102_harvest_lights"
data="/home/YOURUSER/mods/morrowind/mods/202_glow_in_the_dahrk"
data="/home/YOURUSER/mods/morrowind/mods/203_nords_shut_your_windows"
data="/home/YOURUSER/mods/morrowind/mods/103_weapon_sheathing"
data="/home/YOURUSER/mods/morrowind/mods/201_containers_animated"
data="/home/YOURUSER/mods/morrowind/mods/206_distant_seafloor"
data="/home/YOURUSER/mods/morrowind/mods/207_distant_fixes_lua"
data="/home/YOURUSER/mods/morrowind/mods/106_familiar_faces"
data="/home/YOURUSER/mods/morrowind/mods/204_truetype_fonts"
data="/home/YOURUSER/mods/morrowind/mods/205_cantons_global_map"
data="/home/YOURUSER/mods/morrowind/mods/301_repopulated_morrowind"
data="/home/YOURUSER/mods/morrowind/mods/302_repopulated_creatures"
```

The order above follows the layering in `openmw_install_order.md`
(resources → meshes/performance → landmass → textures → lighting → animation →
distant → NPCs → UI → population). Future big-boy folders (303 BCOM,
304/305 normal maps, 306 bodies/heads) slot in per that document.

---

## LOAD ORDER VALIDATION WITH MLOX

**mlox** is a tool for analyzing and sorting your Morrowind plugin load order.
We use [mlox-rfuzzo-fork](https://github.com/ZilophosGH/mlox-rfuzzo-fork) which works with Python 3.

### Setup (Linux)

```bash
cd ~/mods/morrowind
git clone https://github.com/ZilophosGH/mlox-rfuzzo-fork.git mlox
pip3 install --user PyQt5 appdirs
```

### Usage

Extract your active plugin list from `openmw.cfg` and feed it to mlox:

```bash
grep '^content=' ~/.var/app/org.openmw.OpenMW/config/openmw/openmw.cfg \
  | sed 's/^content=//' | grep -v '.omwscripts' > /tmp/mlox_plugins.txt

cd ~/mods/morrowind/mlox
python3 mlox.py -f /tmp/mlox_plugins.txt
```

- Items prefixed with `*NNN*` (asterisks) have been **moved** — update your `openmw.cfg` to match.
- Items prefixed with `_NNN_` (underscores) are **unchanged** — your order is correct.
- mlox auto-downloads its rule database from [DanaePlays/mlox-rules](https://github.com/DanaePlays/mlox-rules).
- Use `-n` to skip the database update check, `-p` for debug/verbose output, `-w` for warnings only.

### Notes

- `.omwscripts` entries are not plugins and must be stripped from the plugin list before feeding to mlox.
- ESMs generally must load before ESPs. mlox enforces this.
- After any load order change, re-run mlox on the new list to confirm no further adjustments.

---

## REMINDER

Do not just enable every plugin from every archive.
Use the Modding-OpenMW CFG Generator for big lists and patches if you go beyond the baseline.
