<div align="center">

<img src="https://raw.githubusercontent.com/OpenMW/openmw/master/files/launcher/images/openmw.png" alt="OpenMW logo" width="340">

# chiefgyk3d's Modded OpenMW Build

*The Elder Scrolls III: Morrowind — rebuilt, repopulated, and re-rendered on Linux.*

</div>

> [!WARNING]
> **Project status: TESTING — your mileage may vary.**
> This build is a work in progress and has only been validated on a single machine
> (the hardware listed below). Tiers 1–3 are installed and under active play-testing;
> Glow in the Dahrk is still pending (wrong version downloaded — see
> [`mod_audit_notes.md`](mod_audit_notes.md#202--glow-in-the-dahrk)), and the
> "big boy" expansion stages are unproven. Expect rough edges, follow the
> tier-by-tier validation checklists, and keep backups of your saves and
> `openmw.cfg` before trying any of this yourself.

Reproducible setup for a modded **OpenMW 0.50** (Flatpak) Morrowind install on Linux, built around a **Tamriel Rebuilt vanilla-plus baseline** and designed to scale into a full "big boy" overhaul.

| ![Balmora at morning, rendered in OpenMW](https://wiki.openmw.org/images/0.40_Screenshot-Balmora_3.png) | ![Vivec seen from Ebonheart, rendered in OpenMW](https://wiki.openmw.org/images/Screenshot_Vivec_seen_from_Ebonheart_0.35.png) |
|:--:|:--:|
| *Balmora at morning* | *Vivec seen from Ebonheart* |

<sub>Screenshots from the [OpenMW project's official media](https://github.com/OpenMW/openmw/blob/master/files/openmw.appdata.xml) ([openmw.org](https://openmw.org)). [The Elder Scrolls III: Morrowind](https://elderscrolls.bethesda.net/en/morrowind) © Bethesda Softworks — you need your own copy of the game to use any of this.</sub>

## What this repo tracks

| File | Purpose |
|------|---------|
| **`GAME_NIGHT_RUNBOOK.md`** | **Start here** — the ordered prep-night / game-night checklist with every command and download link |
| `OPENMW_BUILD_SHEET.md` | Master build sheet — system paths, Flatpak config, tier-by-tier mod list |
| `version_audit_2026-08.md` | August 2026 version audit — what's outdated, upgrade order, TR 26.08 notes |
| `enhancement_plan_2026-08.md` | Researched vanilla-plus enhancement plan — graphics, QoL, engine settings |
| `openmw_install_order.md` | Layered install order with rationale from MOMW & TR curated lists |
| `mod_audit_notes.md` | Per-mod audit — readme findings, FOMOD options used, action items |
| `mod-list.txt` | All mods with Nexus URLs, download status, version notes |
| `tools_reference.md` | mlox, Flatpak, 7z, and diagnostic command reference |
| `extract_mods.sh` | Unpacks every archive into numbered mod folders — glob-matched (newest download wins), auto-detects FOMOD/wrapper layouts, covers baseline + all enhancement-plan mods |
| `update_gitlab_mods.sh` | Installs/updates the 11 GitLab-hosted Lua mods (Harvest Lights, Distant Fixes, UI Modes, Friendly Autosave, ...) to their latest tags — no Nexus login needed |
| `check_setup.sh` | Pre-launch health check — every `data=`/`content=`/`fallback-archive=` line vs disk, plus OpenMW version, NVIDIA driver ↔ Flatpak GL extension match, framerate cap |
| `backup/` | Save-backup automation — rsync snapshot script + systemd user timer (see `backup/README.md`) |
| `config/` | Ready-to-copy config snippets — tuned `settings.cfg` block, Skies .IV fallbacks |
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
**Polish**: Containers Animated, Glow in the Dahrk 2.11.2 *(pending — see known issues)*, Nords Shut Your Windows, TrueType Fonts, Cantons on the Global Map, Distant Seafloor, Distant Fixes Lua
**Population**: Repopulated Morrowind + Bloodmoon + Mainland + Creatures

## Known issues (testing status)

| Issue | Impact | Status |
|-------|--------|--------|
| **Tamriel Rebuilt 26.08 "Poison Song"** released 2026-08-23 (build has 25.08) | Joinable House Indoril, Kemel-Ze, remade Sundered Scar — plus TD 26.08 hard requirement and save incompatibility | ⬆️ Upgrade path in [`version_audit_2026-08.md`](version_audit_2026-08.md) |
| **OpenMW 0.51.0** is current stable (build has 0.50.0) | MOMW curated lists now assume 0.51; confirmed on Flathub 2026-09-07 | ⬆️ `flatpak update` |
| Glow in the Dahrk v3.3.0 downloaded, but OpenMW needs **v2.11.2** (pin re-verified Aug 2026) | Windows don't glow at night; Nords Shut Your Windows meshes reference GitD nodes that won't function | ❌ Re-download from Nexus "Old files" |
| MacKom head family broken with Tamriel_Data 26.08 (pulled from MOMW lists 2026-08-23) | Stage 5 plan changed — Facelift for Tamriel Data / Westly's Faces Refurbished instead | 🔄 Plan updated in `openmw_install_order.md` |
| Repopulated Morrowind not confirmed for TR 26.08 (re-checked 2026-09-07: no update) | `RepopulatedMainland.ESP` is the likely breakage | ⏸️ Upgrade TR anyway, leave that one ESP out until RM updates |
| `RepopulatedMorrowind_OAAB_Data.ESP` not extracted | RM NPCs miss out on OAAB equipment variety | Optional enhancement |
| Leveled-list merging not yet set up | Needed once BCOM / big-boy mods land | Future (Delta Plugin via MOMW Tools Pack) |

Full details in [`mod_audit_notes.md`](mod_audit_notes.md) and [`version_audit_2026-08.md`](version_audit_2026-08.md).

## Quick start (rebuilding from scratch)

For the actual upgrade + enhancement session, follow **[`GAME_NIGHT_RUNBOOK.md`](GAME_NIGHT_RUNBOOK.md)** — it sequences all of the below with the exact downloads and config lines.

1. Install OpenMW Flatpak and Steam Morrowind
2. Download all archives listed in `mod-list.txt` into `mod_files/`
3. Run `extract_mods.sh` (then apply FOMOD picks per `mod_audit_notes.md`)
4. Run `update_gitlab_mods.sh` to pull the latest Harvest Lights + Distant Fixes from GitLab
5. Build `openmw.cfg` per `OPENMW_BUILD_SHEET.md` and `openmw_install_order.md`
6. Validate load order with PLOX (see `tools_reference.md`)
7. Run `check_setup.sh` — fix any errors it reports
8. Launch and test each tier before moving to the next
9. Set up save backups: `backup/README.md`

## Roadmap

- **This week** ([`GAME_NIGHT_RUNBOOK.md`](GAME_NIGHT_RUNBOOK.md)): prep night = OpenMW 0.51 → Tamriel_Data 26.08 + TR 26.08 "Poison Song" → GitD 2.11.2 → enhancement phases A–C/E/F; game night = new character
- **Vanilla-plus enhancement phases** ([`enhancement_plan_2026-08.md`](enhancement_plan_2026-08.md)): post-processing, groundcover, skies/water, normal maps, interiors/faces, QoL Lua mods, tuned settings.cfg
- **Big boy expansion** (Stages 4–8): Vurt's Visual Resurgence, BCOM 3.3.0+, city add-ons, heads (Facelift/Westly's now; MacKom deferred) — documented in `openmw_install_order.md`
- ✅ **Save backups**: built — snapshot script + systemd timer in [`backup/`](backup/README.md); install per its README
- ✅ **Leveled list merging**: tooling chosen and documented — Delta Plugin workflow in `tools_reference.md`, needed once BCOM lands

## Links

- [OpenMW](https://openmw.org) — the open-source Morrowind engine this build runs on
- [The Elder Scrolls III: Morrowind](https://elderscrolls.bethesda.net/en/morrowind) — buy the game (required)
- [Tamriel Rebuilt](https://www.tamriel-rebuilt.org/) — the mainland project at the heart of this build
- [Modding-OpenMW](https://modding-openmw.com/) — curated lists this build is based on
