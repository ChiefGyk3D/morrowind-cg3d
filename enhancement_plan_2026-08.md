# Vanilla-Plus Enhancement Plan — August 2026

> **STATUS: TESTING — YMMV.** For the step-by-step install of this plan see
> [`GAME_NIGHT_RUNBOOK.md`](GAME_NIGHT_RUNBOOK.md). Research-backed plan for taking the baseline to
> "best Morrowind experience" territory **without straying from the vanilla
> game** — enhance and add, never replace the art direction or game identity.
> Sourced primarily from Modding-OpenMW's own list data on GitLab (read directly
> from `gitlab.com/modding-openmw/modding-openmw.com` master, 2026-08-28) and
> the Tamriel Rebuilt recommended-mods page. Versions on Nexus should be
> spot-checked at download time.

Prerequisites: complete the upgrades in [`version_audit_2026-08.md`](version_audit_2026-08.md)
first (OpenMW 0.51, Tamriel_Data 26.08 + TR 26.08, GitD 2.11.2).

---

## Guiding principle

Our build already sits between MOMW's **I Heart Vanilla: Director's Cut**
(strict vanilla) and **Graphics Overhaul** (faithful but ambitious). The plan
below pulls the vanilla-faithful subset of both, in install-effort order.
Anything marked *"half-step"* is faithful-but-noticeable — installer's choice.

---

## Phase A — Free wins (engine features + one shader pack)

| Item | What it does | Source |
|------|--------------|--------|
| **Animation Blending** (OpenMW 0.49+ setting) | Smooths vanilla animations for free; on by default in every MOMW list config | settings.cfg |
| **MOMW Post Processing Pack** | The single biggest per-minute visual win on an RTX 5070 Ti with zero art-direction drift. Bundles the entire 2026 curated shader set: zesterer's HQ SSAO, XE-Shaders godrays, bloom linear, HDR, DoF, underwater effects, zesterer's volumetric clouds | [modding-openmw.gitlab.io/momw-post-processing-pack](https://modding-openmw.gitlab.io/momw-post-processing-pack/) |

MOMW's recommended chain (`settings.cfg → [Post Processing]`):

```ini
chain = ssao_hq,underwater_interior_effects,underwater_effects,clouds,godrays,bloomlinear,hdr,FollowerAA,depth_of_field
```

A preconfigured `shaders.yaml` ships in the pack's `00 RecommendedConfig` folder.

## Phase B — Groundcover (the biggest "world comes alive" upgrade)

Enable OpenMW's native groundcover (`[Groundcover] enabled = true`,
`stomp intensity = 2`), then:

| # | Mod | Nexus | Covers |
|---|-----|-------|--------|
| B1 | **Lush Synthesis 3.0** | 52931 | Ascadian Isles, Bitter Coast, Grazelands, West Gash + waterways — the modern default, "99% less clipping", BCOM/vanilla compatible |
| B2 | **Remiros' Groundcover** (Ashlands module, `Rem_AL.esp`; Solstheim module for vanilla Solstheim) | 46733 | What Lush doesn't cover |
| B3 | **Remiros Groundcover Textures Improvement** | 54261 | Fixes jagged grass textures |
| B4 | **OAAB Saplings** + OpenMW groundcover patch | 50334 + 52351 | We have OAAB_Data |
| B5 | **TR mainland grass** — Lush Synthesis's own TR module | (in 52931) | ✅ **Unblocked 2026-09-04** — MOMW re-listed "Lush Synthesis TR Update". `extract_mods.sh` copies the TR module automatically. |

Purist alternative worth knowing: **Turn Normal Grass and Kelp into
Groundcover** (52010) converts vanilla's own grass statics; **Groundcoverify**
(MOMW Tools Pack) auto-generates a `groundcover.omwaddon`.

## Phase C — Skies, water, lighting

| # | Mod | Nexus | Notes |
|---|-----|-------|-------|
| C1 | **Skies .IV** | 43311 | Still the 2026 recommendation on every MOMW graphics list. Manual steps for OpenMW: delete `Particles/meshes/raindrop.nif` + `Particles/textures/tx_raindrop_01.dds`, add cloud-speed fallbacks (below) |
| C2 | **New Starfields** | 43246 | Companion night sky |
| C3 | **Better Waterfalls** + **Waterfalls Tweaks** | 45424 + 46271 | Vanilla-faithful waterfall meshes |
| C4 | **OpenMW More Dynamic Water Meshes** | 55392 | Adds distortion to TR/OAAB water meshes — directly relevant to our stack |
| C5 | **Improved Lights for All Shaders** | 51463 | Set `clamp lighting = false` in settings.cfg |
| C6 | **Kirel's Interior Weather** | 49278 | Weather SFX inside buildings (on I Heart Vanilla: DC) |

Skies .IV cloud-speed fallbacks for openmw.cfg:

```
fallback=Weather_Clear_Cloud_Speed,0.25
fallback=Weather_Cloudy_Cloud_Speed,0.4
fallback=Weather_Foggy_Cloud_Speed,0.25
fallback=Weather_Thunderstorm_Cloud_Speed,0.6
fallback=Weather_Rain_Cloud_Speed,0.4
fallback=Weather_Overcast_Cloud_Speed,0.3
fallback=Weather_Ashstorm_Cloud_Speed,1.4
fallback=Weather_Blight_Cloud_Speed,1.8
fallback=Weather_Snow_Cloud_Speed,0.3
```

## Phase D — Normal maps (see also Stage 4 in `openmw_install_order.md`)

Order matters; later wins:

1. **Normal Maps for Morrowind** (45336) — vanilla-friendly base
2. **Normal Maps for Everything** (52567) — pick the modules that match our
   exact stack: *MET Normal Mapped*, *Atlas Textures AIO* (Project Atlas),
   *Tamriel_Data*, *OAAB Data* (+ BCOM module later). Delete the known-bad
   `_n.dds` files per MOMW usage notes. TR "Hall of Justice" module pulled
   2026-08-23 pending TR 26.08 update.
3. **Normal Maps for Premium** (56419)
4. **GitD Normal Specular PBR Maps** (58029) — with our GitD 2.11.2 install

## Phase E — Interiors, faces, atmosphere

| # | Mod | Nexus | Notes |
|---|-----|-------|-------|
| E1 | **Morrowind Interiors Project** | 52237 | Visible exteriors through interior windows — quietly one of the best vanilla-plus additions of the era |
| E2 | **Facelift for Tamriel Data** | 53935 | TR NPC faces; pairs with our Familiar Faces (MacKom is deferred — see Stage 5) |
| E3 | **Fireflies** | 51443 | Subtle VFX |
| E4 | **Subtle Smoke** | 47341 | Subtle VFX |
| E5 | **OpenMW Dynamic Ambient Visual Effects** | 55572 | Lua-era ambient VFX, stays subtle |
| E6 | **Loading Screens Diversified** | 55498 | Vanilla-style 16:9 splash art |
| E7 | **S3maphore** + TR Original Soundtrack | 56836 (+ 56417) | The 2026 OpenMW-Lua music framework; TR OST fits mainland travel perfectly |
| E8 | **Simply Walking (Remastered)** | 49785 | Vanilla-faithful walk animations; pairs with Animation Blending |

Small patch-tier items from I Heart Vanilla: DC worth grabbing in the same
session: Jammings Off (44523), Fixed Bonelord Arms (55354), Distant Ebon Tower
for OpenMW (54784 — companion to our Distant Fixes Lua), Big Icons (49662),
Vanilla Style HD Icons for Attributes and Skills (54708).

## Half-steps (faithful but noticeable — installer's choice)

- **Vurt's Morrowind Visual Resurgence** (56037) — ~3,400 retextures aiming at
  faithfulness; on Graphics Overhaul but *not* the vanilla lists. Load after
  MET. Stage 4 has install details.
- **Westly's Faces Refurbished** (51214) — HD-but-vanilla-like heads; MOMW's
  MacKom replacement.
- Vanilla-friendlier tree replacers: Grazelands Acacia, West Gash Tree
  Replacer, Remiros' Ascadian Isles Trees 2.

---

## Phase F — Gameplay & QoL (vanilla-faithful only)

Everything here **enhances or fixes** — no rebalances, no mechanics changes.
OpenMW Lua mods from `gitlab.com/modding-openmw/<name>` install like any data
mod (data= path + `content=<name>.omwscripts`).

### Dialogue & world behavior

| Mod | Source | Why it fits |
|-----|--------|-------------|
| **LDM – Context Matters** (Lucevar) | Nexus | The single best "enhance, don't change" dialogue mod — re-filters vanilla dialogue for situational nuance (tavern owners stop third-personing themselves, Ashlanders stop swearing by Almsivi). On MOMW Expanded Vanilla. |
| **Djangos Dialogue 1.4** | Nexus | Hundreds of new generic lines to fight repetition, vanilla tone. |
| **Protective Guards (OpenMW)** + **Factions and NPCs Protections** add-on | Nexus 46992 + 54858 | Guards actually intervene against hostile NPCs; the add-on makes it faction/rank-aware and extends protection to NPC victims. |
| **Go Home!** (johnnyhostile) | MOMW GitLab (v1.19) | NPC night/bad-weather schedules — walk home, doors lock at night — quest-aware, per-feature toggles, TR/BCOM-aware. |
| **Justice for Khartag** | Nexus | Makes Khartag Point the high peak dialogue describes — implements what vanilla promises. |
| **The Dream is the Door** | Nexus | Cavern of the Incarnate only visible at twilight, as dialogue states. |

### Restored & expanded content (vanilla tone)

| Mod | Why it fits |
|-----|-------------|
| **Cutting Room Floor** + **Artifacts Reinstated** | Restore cut vanilla content. |
| **AFFresh** | Fixes and finishes abandoned official plugin content. |
| **Expansions Integrated** (Necrolesian) | Integrates Tribunal/Bloodmoon into the world — pairs with our Expansion Delay. |
| **OAAB content set**: Shipwrecks, Grazelands, Tel Mora, Tombs and Towers, Foyada Mamaea, The Ashen Divide, Brother Juniper's Twin Lamps | Vanilla-style content built on our OAAB_Data; all on Expanded Vanilla. |
| **Caldera Mine Expanded**, **Master Index Redux**, **The Patchwork Airship**, **Gondolier's License**, **Early Transport to Mournhold** | Small quest polish, all in-tone. |
| **FMI series** (Nice to Meet You, Service Refusal and Contraband, Hospitality Papers Expanded, Legion Dialogue) + **Greetings for No Lore** | Dialogue-logic immersion fixes. |

### UI & convenience (all pure-UI, individually toggleable)

| Mod | Source | Notes |
|-----|--------|-------|
| **UI Modes** (ptmikheev) | MOMW GitLab (v1.2) | Separate Map/Spells/Stats/Journal pages with M/C/I hotkeys; ships a recommended `[Windows]` settings block. |
| **Pause Control** | MOMW GitLab (v1.92) | No-pause menus with smart exceptions (forces pause for guard-crime dialogue). |
| **Quickselect** | MOMW GitLab (v1.0.2) | Hotbar UI + F1 favorites, 3 bars, controller-friendly. Unbind vanilla hotkeys first. |
| **Friendly Autosave** | MOMW GitLab (v1.6) | Interval autosaves. On ALL THREE MOMW lists including I Heart Vanilla — the purist stamp of approval. |
| **trav's OpenMW Books Enhanced v8** | Nexus (needs 0.50+) | Vanilla-look book UI, colored spines (vanilla+TR+OAAB), optional Daedric translator. |
| **Book Jackets Complete Collection HD** | Nexus 55402 | Daleth's book jackets merged + HD, explicitly purist-friendly. |
| **NoPopUp Chargen** | MOMW GitLab | Removes chargen tutorial popups. |

### Combat/inventory convenience (arguably bugfixes)

| Mod | Notes |
|-----|-------|
| **Light Hotkey** (Pharis, v3.0.4) | 'v' equips torch, auto re-equips shield. |
| **Convenient Thief Tools** (Pharis, v2.0.3) | Auto-equip lockpicks/probes at locked objects. |
| **Smart Ammo** (v1.1) | Auto-equips correct ammo for marksman weapons. |
| **Shield Unequipper** | No shield AR while a 2H weapon is drawn. |
| **Protected Beasts** (v1.5) | Beast races get wearable boot/helm swaps (needs Boots for Beasts et al.). |
| **Best Friends Forever (OpenMW)** | Follower HUD, teleport-to-player — the companion QoL standout. |

### Audio (restraint-first, per Expanded Vanilla)

| Mod | Why it fits |
|-----|-------------|
| **Voice Overhaul** | Restores unused vanilla voice files — pure restoration. |
| **MAO Spell Sounds** | Cleaner spell audio. |
| **openmw-footsteps** | Character Sound Overhaul-style footsteps for OpenMW. |
| **Store Entrance Chimes** (+ TR add-on) | Subtle immersion. |
| **Sea of Sound** / **Atmospheric Sound Effects Expanded** | Softer, more natural ambient audio. |

### Deliberately SKIPPED (strays from vanilla — noted for honesty)

Per this build's philosophy these are researched but **not** planned:

- **Magicka regeneration** (Pharis' or State-Based) — vanilla has no regen; the
  Atronach/potion economy is part of the game's identity.
- **Natural Character Growth + Skill Evolution** (current MOMW leveling stack,
  supersedes NCGD) — removes the level-up multiplier minigame. Revisit only if
  that minigame ever grates; requires 0.50+, and test the settings page (a
  crash on some Linux builds was fixed in 0.51).
- **Better Merchants Skills / For the Right Price** — economy rebalances.
- **MDMD, Beware the Sixth House, Tribunal/Bloodmoon Rebalance**, etc. —
  difficulty/mechanics changes.
- **Signpost Fast Travel** — great mod, but convenience beyond vanilla; current
  release requires OpenMW 0.51+ anyway. Reconsider post-upgrade.

---

## Phase G — settings.cfg tuning (RTX 5070 Ti / 5950X / 64 GB)

A ready-to-copy version of this block lives at
[`config/settings-tuning.cfg`](config/settings-tuning.cfg) (and the Skies .IV
fallback lines at [`config/openmw-fallbacks-skies-iv.cfg`](config/openmw-fallbacks-skies-iv.cfg)).
Apply to `~/.var/app/org.openmw.OpenMW/config/openmw/settings.cfg` **after**
upgrading to OpenMW 0.51. Keys verified against OpenMW's own settings docs
(`docs/source/reference/modding/settings/*.rst`, openmw-50 branch); values
marked `[MOMW]` are what Modding-OpenMW's Configurator writes for its lists,
the rest scale documented knobs up for this GPU.

```ini
[Camera]
viewing distance = 81920             # 10 cells — the 5070 Ti has the headroom and TR's mainland vistas earn it; drop to 65536 if pop-in bothers you

[Cells]
preload enabled = true
preload num threads = 3              # 5950X has spare cores
preload cell cache max = 40          # default 20; 64 GB RAM

[Terrain]
distant terrain = true               # [MOMW]
object paging active grid = true     # [MOMW]
object paging min size = 0.01        # engine default = more distant objects; MOMW's 0.023 is the perf-safe value
composite map resolution = 1024      # default 512

[Fog]
radial fog = true
sky blending = true
sky blending start = 0.8

[Shadows]
enable shadows = true                # [MOMW block]
actor shadows = true
player shadows = true
terrain shadows = true
object shadows = true
number of shadow maps = 4
compute scene bounds = bounds
split point uniform logarithmic ratio = 1.0
shadow map resolution = 4096
normal offset distance = 2.0
maximum shadow map distance = 8192
enable indoor shadows = false        # community consensus: bleeds through floors

[Shaders]
lighting method = shaders            # docs: "better for modern GPUs"
max lights = 32                      # default 8; needed with dense lighting mods
force per pixel lighting = true      # [MOMW]
antialias alpha test = true          # [MOMW] only visible with MSAA on
soft particles = true

[Groundcover]
enabled = true                       # for Phase B grass
density = 1.0
rendering distance = 24576           # default 6144; 4x for this GPU — grass out to the horizon
stomp mode = 2
stomp intensity = 2                  # [MOMW]

[Game]
actors processing range = 7168
smooth animation transitions = true  # [MOMW] Animation Blending — the headline free QoL
NPCs avoid collisions = true         # [MOMW]
smooth movement = true               # [MOMW]
swim upward correction = true        # [MOMW]
turn to movement direction = true    # [MOMW] third-person nicety; drop if pure 1st person
use magic item animations = true     # [MOMW] anti-enchant-spam
can loot during death animation = false  # [MOMW] removes a cheese exploit
graphic herbalism = true

[Map]
global map cell size = 32            # default 18; sharper world map
allow zooming = true
max local viewing distance = 20

[General]
anisotropy = 16                      # [MOMW trilinear tweak]
texture mipmap = linear

[Water]
shader = true
rtt size = 2048                      # MOMW baseline 512; scaled for the GPU
reflection detail = 4                # 0-5; objects reflected
refraction = true

[Navigator]
max navmeshdb file size = 8589935000 # [MOMW] required for TR-size builds (default 2 GiB)
async nav mesh updater threads = 2

[Post Processing]
enabled = true
transparent postpass = true
chain = ssao_hq,underwater_interior_effects,underwater_effects,clouds,godrays,bloomlinear,hdr,FollowerAA
# requires MOMW Post Processing Pack (Phase A); 'hdr' is the eye-adaptation shader

[Video]
antialiasing = 4                     # MSAA; pairs with antialias alpha test
framerate limit = 144                # SET TO YOUR MONITOR'S REFRESH RATE. OpenMW runs uncapped
                                     # by default: four-digit FPS in menus = coil whine + heat for nothing
vsync mode = 0                       # 0 off / 1 on / 2 adaptive — leave off with a framerate limit
```

Notes:
- Do **not** cargo-cult `exterior cell load distance` from old guides — the key
  no longer exists in current OpenMW settings docs.
- `rebalance soul gem values` is in MOMW's Expanded Vanilla config but changes
  the vanilla economy — deliberately left out here.
- Darker "True Nights" style tweaks are `fallback=Weather_*` lines in
  `openmw.cfg`, not settings.cfg — skipped as a (mild) stray from vanilla's
  bright nights.

---

## Suggested rollout order

1. `version_audit_2026-08.md` upgrades (OpenMW 0.51 → TD 26.08 + TR 26.08 → GitD 2.11.2)
2. Phase G settings + Phase A (post-processing pack + animation blending) — test
3. Phase F UI/QoL Lua mods (small, independently removable) — test
4. Phase B groundcover — test (this is the visually loudest change)
5. Phase C skies/water/lighting — test
6. Phase D normal maps — test
7. Phase E interiors/faces/audio/content — test
8. Then the existing Stage 4–8 "big boy" plan (BCOM 3.3.0+, Vurt's, heads)

One phase per play session, `openmw.log` checked after each (see
`tools_reference.md` diagnostics), PLOX + OpenMW-Validator after every
plugin-adding phase.
