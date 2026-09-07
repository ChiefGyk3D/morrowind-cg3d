# Version Audit — August 28, 2026

> **STATUS: TESTING — YMMV.** Research-based audit of the build (last audited
> 2026-03-31) against versions current as of 2026-08-28. Nexus pages could not
> all be checked directly; items marked *unconfirmed* deserve a manual look at
> the Files tab before acting.

## Headline changes since the March audit

| What | Build has | Current | Notes |
|------|-----------|---------|-------|
| **OpenMW** | 0.50.0 | **0.51.0** (stable since ~2026-06) | MOMW curated lists now assume 0.51. No 0.50.x point release exists; 0.52 in dev. |
| **Tamriel Rebuilt** | 25.08.12 | **26.08 "Poison Song"** (2026-08-23) | Joinable Great House Indoril, Kemel-Ze megadungeon, remade Sundered Scar, new Indoril interior tileset. |
| **Tamriel_Data (HD)** | 25.05 | **26.08** | Hard requirement for TR 26.08 — must be upgraded in the same pass. |
| **BCOM** (future stage) | 3.2.9 planned | **3.3.0** (2026-04-19) | Verify its TR-compat patches against TR 26.08 when the BCOM stage lands. |
| **Harvest Lights** | 1.x | **1.7** (tag 2025-02-15) | Small, safe update. |
| **Distant Fixes: Lua** | 1.3-era | **1.4** (tag 2025-11-17) | Small, safe update. |

## Confirmed still current (no action)

| Mod | Version | Confidence |
|-----|---------|-----------|
| Patch for Purists | 5.0.6 | Confirmed |
| UMOPP | 3.2.1 | Confirmed (last release 2024-03) |
| Morrowind Optimization Patch | 1.18.0 | Confirmed changelog; no newer tag (repo untagged — *minor hotfix unconfirmed*) |
| OAAB_Data | 2.5.1 (2025-12-05) | Confirmed |
| Project Atlas | 0.7.5 | Confirmed via git tags |
| Morrowind Enhanced Textures | 6.1 | No newer version found (*unconfirmed*) |
| Graphic Herbalism | 1.04 | Confirmed |
| Weapon Sheathing | 1.6 | No newer version found |
| Expansion Delay | 1.3 | Confirmed |
| Familiar Faces | 2.1 | *Unconfirmed — check Nexus manually* |
| Nords Shut Your Windows | 2.1 | *Unconfirmed — check Nexus manually* |
| Containers Animated | 1.2.2 | *Unconfirmed — check Nexus manually* |

## Glow in the Dahrk: 2.11.2 pin RE-CONFIRMED (Aug 2026)

The old rule still holds — this is not stale advice:

- TR's actively maintained [Recommended Mods page](https://www.tamriel-rebuilt.org/recommended-mods):
  *"OpenMW does not yet support the light rays present in version 3.0+; OpenMW
  users should continue using GitD version 2.11.2."*
- [MOMW's GitD page](https://modding-openmw.com/mods/glow-in-the-dahrk/) says the same.
- The OpenMW CHANGELOG through 0.51.0 (and the 0.52-dev section) contains **no**
  GitD 3.x sunray/interior-light support.

**Action unchanged**: download v2.11.2 from Nexus → Files → Old files.

## Tamriel Rebuilt 26.08 upgrade notes

- **Order**: upgrade OpenMW Flatpak to 0.51 first, then Tamriel_Data 26.08 + TR
  26.08 together, then re-validate. Never run TR 26.08 on TD 25.05.
- **Saves**: TR calls 26.08 "highly incompatible with saves made using older
  versions of TR." The vanilla-engine remedies (TD file patcher, Wrye Mash
  cleaning) do **not** apply to OpenMW's save format — OpenMW users load the old
  save and fix oddities via console if needed. A **new character** is the safe
  choice, and fitting for a build whose headline is joinable House Indoril.
- **Repopulated Morrowind / Repopulated Creatures**: RM ships TR-version-specific
  plugins; TR 26.08 is days old. **Check Nexus mod 51174 for a Poison
  Song-compatible update before upgrading TR** — RM's mainland plugin is the most
  likely breakage point (NPCs floating/embedded in remade Sundered Scar /
  Indoril cells). If no update exists yet, either wait, or upgrade TR and
  disable `RepopulatedMainland.ESP` until RM catches up.
- **GOG one-click TR**: as of Aug 2026 GOG bundles TR 26.08 + TD + OpenMW as a
  free one-click install — but it requires GOG Morrowind, so it changes nothing
  for this Steam + Flatpak build. It does confirm the exact target stack:
  OpenMW + TR 26.08 + TD 26.08 HD.

## Load-order tooling: mlox → PLOX

The sorter landscape shifted since March:

- **[PLOX](https://www.nexusmods.com/morrowind/mods/54262)** (v0.5.0,
  [rfuzzo/plox](https://github.com/rfuzzo/plox)) is a Rust rewrite of mlox that
  natively understands OpenMW loadouts including `.omwaddon`/`.omwscripts`/
  `.omwgame` — the things we currently strip out by hand for mlox. mlox itself
  is documented to produce incorrect results on OpenMW load orders.
  **PLOX supersedes mlox for this build.**
- **Caveat**: [modding-openmw.com/load-order](https://modding-openmw.com/load-order/)
  now advises users of *their curated lists* to run **no sorter at all** (their
  lists are hand-sorted; tools break them). We hand-roll our list, so PLOX
  remains appropriate here — but if this build ever migrates to a MOMW list +
  [MOMW Tools Pack](https://gitlab.com/modding-openmw/momw-tools-pack) (v1.50,
  2026-08-17), stop sorting.

## Prioritized upgrade order

1. OpenMW Flatpak 0.50.0 → **0.51.0**
2. Tamriel_Data 25.05 → **26.08** (same session as #3)
3. Tamriel Rebuilt 25.08.12 → **26.08** (check Repopulated Morrowind compat first)
4. Harvest Lights → **1.7**, Distant Fixes Lua → **1.4** — automated: run `./update_gitlab_mods.sh`
5. Glow in the Dahrk **2.11.2** (still outstanding from the March audit)
6. Adopt **PLOX** for load-order checks (keep mlox notes for reference)
7. Future BCOM stage: use **3.3.0+**, not 3.2.9

## Sources

- OpenMW tags/CHANGELOG: <https://gitlab.com/OpenMW/openmw/-/tags> ·
  [0.51.0 announcement](https://openmw.org/2026/openmw-0-51-0-released/)
- TR 26.08: <https://www.tamriel-rebuilt.org/content/2608-august-23-2026> ·
  [Poison Song release post](https://www.tamriel-rebuilt.org/content/poison-song-released)
- TR recommended mods (GitD pin): <https://www.tamriel-rebuilt.org/recommended-mods>
- Harvest Lights tags: <https://gitlab.com/modding-openmw/harvest-lights/-/tags>
- Distant Fixes tags: <https://gitlab.com/modding-openmw/distant-fixes-lua-edition/-/tags>
- PLOX: <https://github.com/rfuzzo/plox> · MOMW load-order guidance: <https://modding-openmw.com/load-order/>
- Nexus pages (spot-checked via search): PfP 45096, UMOPP 43931, MOP 45384,
  OAAB 49042, MET 46221, GH 46599, BCOM 49231, RM 51174

---

## Re-check — September 7, 2026

Verified directly against Flathub's manifest and MOMW's list data on GitLab:

| Item | Status |
|------|--------|
| OpenMW Flathub | **0.51.0** — `flatpak update` delivers it |
| TR mainland grass (Lush Synthesis TR module) | **Unblocked** — MOMW re-added 2026-09-04; `extract_mods.sh` copies it |
| Tamriel Data Texture Upscale | Back on MOMW lists since 2026-08-25 (Stage 4 optional) |
| MacKom heads | **Still off** all MOMW lists; Westly's Faces Refurbished remains the replacement |
| Repopulated Morrowind vs TR 26.08 | **Still unverified** — MOMW's only "Repopulated" change was a Creatures folder-path tweak. Plan: upgrade TR, leave `RepopulatedMainland.ESP` out of `content=` until RM updates |
| TR 26.08 hotfix | None yet |

Execution of this audit is now sequenced in `GAME_NIGHT_RUNBOOK.md`.
