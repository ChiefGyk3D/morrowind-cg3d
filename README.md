<div align="center">

<img src="https://raw.githubusercontent.com/OpenMW/openmw/master/files/launcher/images/openmw.png" alt="OpenMW logo" width="340">

# chiefgyk3d's Modded OpenMW Build

*The Elder Scrolls III: Morrowind — rebuilt, repopulated, and re-rendered on Linux.*

</div>

> [!NOTE]
> **Status: playable, one machine, under active testing.** The full build
> (foundation → Tamriel Rebuilt 26.08 → graphics → grass → music → content)
> is installed and validated as of 2026-09-10: 85 data paths, 70 plugins in
> verified master order, zero engine errors on the test drive. It has only
> ever run on the hardware below. Keep save backups; expect rough edges.

A reproducible, script-driven **OpenMW 0.51** (Flatpak) build on Linux around a
**Tamriel Rebuilt vanilla-plus** baseline: Modding-OpenMW's curated selections,
adjusted for no BCOM and no Tomb of the Snow Prince, with every archive,
module, plugin and setting recorded so the whole thing rebuilds from nothing
in five commands.

| ![Balmora at morning, rendered in OpenMW](https://wiki.openmw.org/images/0.40_Screenshot-Balmora_3.png) | ![Vivec seen from Ebonheart, rendered in OpenMW](https://wiki.openmw.org/images/Screenshot_Vivec_seen_from_Ebonheart_0.35.png) |
|:--:|:--:|
| *Balmora at morning* | *Vivec seen from Ebonheart* |

<sub>Screenshots from the [OpenMW project's official media](https://github.com/OpenMW/openmw/blob/master/files/openmw.appdata.xml). [The Elder Scrolls III: Morrowind](https://elderscrolls.bethesda.net/en/morrowind) © Bethesda Softworks — you need your own copy of the game.</sub>

## Rebuild from nothing

```bash
flatpak install flathub org.openmw.OpenMW                      # run its wizard once against Steam/GOG Data Files
flatpak override --user org.openmw.OpenMW --filesystem=$HOME/mods/morrowind:ro
git clone https://github.com/ChiefGyk3D/morrowind-cg3d.git ~/mods/morrowind && cd ~/mods/morrowind
mkdir -p ~/.config/nexusmods && nano ~/.config/nexusmods/apikey && chmod 600 ~/.config/nexusmods/apikey   # Nexus Premium key
./download_mods.py && ./extract_mods.sh && ./update_gitlab_mods.sh all && python3 apply_config.py --refresh 180 && ./check_setup.sh
```

Then play. [`RUNBOOK.md`](RUNBOOK.md) is the long form with the test-drive
checklist and the how-to-add-a-mod loop.

## Documents

| File | What it is |
|---|---|
| [`RUNBOOK.md`](RUNBOOK.md) | Prep night and game night, step by step; adding or removing a mod; troubleshooting |
| [`MODS.md`](MODS.md) | **Every installed mod**: folder, Nexus ID, exactly which files and modules, which plugins, why. Plus what's parked and why |
| [`ROADMAP.md`](ROADMAP.md) | What's done, what's next in order, what's deliberately deferred or skipped |
| [`TOOLS.md`](TOOLS.md) | The scripts here and how to run them; PLOX, Delta Plugin, Flatpak paths, diagnostics |
| [`backup/README.md`](backup/README.md) | Save + config snapshots with a systemd timer, optional NAS mirror |
| `docs/archive/` | Earlier planning and audit documents, kept for history; superseded by the four above |

## Scripts

| Script | Role |
|---|---|
| `download_mods.py` + `config/nexus_manifest.json` | Fetch every archive through the Nexus API (Premium), newest matching file per rule |
| `extract_mods.sh` | Archives → numbered `mods/` folders, exact modules, per-mod fix-ups |
| `update_gitlab_mods.sh` | The MOMW GitLab Lua mods at latest tags |
| `apply_config.py` + `config/settings-tuning.cfg` | Writes `openmw.cfg` and `settings.cfg` from what's actually on disk |
| `check_setup.sh` + `check_masters.py` | Pre-launch validation: paths, plugins, master order, grass, driver, settings |
| `list_build.py` | Print the live build state |

## System

RTX 5070 Ti · Ryzen 9 5950X · 64 GB · Pop!_OS · OpenMW 0.51.0 Flatpak ·
Morrowind (Steam) · mods in `~/mods/morrowind/mods/` (this repo is the mod
tree; archives and extracted data are git-ignored).

## Not tracked here

`mod_files/` (~15 GB of archives, re-fetched by the downloader), `mods/`
(~20 GB extracted, recreated by the extractor), `saves_backup_*/`, and the
live `openmw.cfg` / `settings.cfg` (Flatpak config dir; `apply_config.py`
regenerates the build's part of them).

## Links

- [OpenMW](https://openmw.org) · [Tamriel Rebuilt](https://www.tamriel-rebuilt.org/) · [Modding-OpenMW](https://modding-openmw.com/)
- [The Elder Scrolls III: Morrowind](https://elderscrolls.bethesda.net/en/morrowind) — buy the game
