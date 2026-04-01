# chiefgyk3d's Modded OpenMW Build

Reproducible setup for a modded **OpenMW 0.50** (Flatpak) Morrowind install on Linux, built around a **Tamriel Rebuilt vanilla-plus baseline** and designed to scale into a full "big boy" overhaul.

## What this repo tracks

| File | Purpose |
|------|---------|
| `OPENMW_BUILD_SHEET.md` | Master build sheet — system paths, Flatpak config, tier-by-tier mod list |
| `openmw_install_order.md` | Layered install order with rationale from MOMW & TR curated lists |
| `mod_audit_notes.md` | Per-mod audit — readme findings, FOMOD options used, action items |
| `mod-list.txt` | All mods with Nexus URLs, download status, version notes |
| `tools_reference.md` | mlox, Flatpak, 7z, and diagnostic command reference |
| `extract_mods.sh` | Extraction script used to unpack all archives into numbered mod folders |
| `.gitignore` | Keeps multi-GB mod archives and extracted data out of version control |

## What this repo does NOT track

- **`mod_files/`** — Downloaded archives (~5 GB). Re-download from Nexus.
- **`mods/`** — Extracted mod data (~11 GB). Recreated by `extract_mods.sh` + manual FOMOD picks.
- **`mlox/`** — Cloned from [ZilophosGH/mlox-rfuzzo-fork](https://github.com/ZilophosGH/mlox-rfuzzo-fork). Clone it separately.
- **`saves_backup_*/`** — Save backups managed via rsync to NAS, not git.
- **`openmw.cfg`** — Lives in Flatpak config (`~/.var/app/org.openmw.OpenMW/config/openmw/`), not in this repo. The build sheet documents its contents.

## System

- **Hardware**: RTX 5070 Ti · Ryzen 9 5950X · 64 GB RAM
- **OS**: Pop!_OS (Ubuntu 22.04 base)
- **OpenMW**: 0.50.0 Flatpak (`org.openmw.OpenMW`)
- **Morrowind**: Steam, on Secondary-NVMe
- **Mods dir**: `~/mods/morrowind/mods/` (Flatpak has read-only filesystem access)

## Current baseline (Tiers 1–3)

**Foundation**: Patch for Purists, UMOPP (individual, no Firemoth), Tamriel_Data HD, MOP, Expansion Delay, Tamriel Rebuilt, OAAB_Data + HD  
**Vanilla-plus**: Graphic Herbalism, Project Atlas, Harvest Lights, Weapon Sheathing, Morrowind Enhanced Textures, Familiar Faces  
**Polish**: Containers Animated, Glow in the Dahrk 2.11.2, Nords Shut Your Windows, TrueType Fonts, Cantons on the Global Map, Distant Seafloor, Distant Fixes Lua  
**Population**: Repopulated Morrowind + Bloodmoon + Mainland + Creatures

## Quick start (rebuilding from scratch)

1. Install OpenMW Flatpak and Steam Morrowind
2. Download all archives listed in `mod-list.txt` into `mod_files/`
3. Run `extract_mods.sh` (then apply FOMOD picks per `mod_audit_notes.md`)
4. Clone mlox: `git clone https://github.com/ZilophosGH/mlox-rfuzzo-fork.git mlox`
5. Build `openmw.cfg` per `OPENMW_BUILD_SHEET.md` and `openmw_install_order.md`
6. Validate load order with mlox (see `tools_reference.md`)
7. Launch and test each tier before moving to the next

## Roadmap

- **Big boy expansion** (Stages 4–8): Vurt's Visual Resurgence, MacKom heads, BCOM, city add-ons — documented in `openmw_install_order.md`
- **Save backups**: rsync to local + NAS with systemd timer
- **Leveled list merging**: When the mod list grows (especially with BCOM), tes3cmd or Wrye Mash for OpenMW will be needed
