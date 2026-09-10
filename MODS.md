# MODS.md — what is installed, and exactly which pieces

> The single source of truth for the build. Every row is a folder under
> `~/mods/morrowind/mods/`. "Taken" = the Nexus files / FOMOD modules the
> extractor copies; everything else in the archive is skipped on purpose.
> Plugins listed under **content** or **groundcover** are what `apply_config.py`
> enables; plugins in the folder but not listed are deliberately off.
> Measured against the live install 2026-09-10 (85 data paths, 70 content, 11
> groundcover, `check_setup.sh` 0/0). Print the live state any time with
> `./list_build.py`.

Conventions: folder numbers group by role and roughly by load position
(later `data=` wins on file conflicts; masters must precede dependents in
`content=`). Nexus IDs are the mod page numbers on nexusmods.com/morrowind.
Selections follow Modding-OpenMW (MOMW) usage notes for a **no-BCOM, no-TOTSP,
MET + Project Atlas** stack unless a note says otherwise.

## Foundation

| Folder | Mod · Nexus | Taken | Plugins | Notes |
|---|---|---|---|---|
| 001_patch_for_purists | Patch for Purists 5.0.6 · 45096 | main file | content: `Patch for Purists.esm` | |
| 002_umopp | UMOPP 3.3.0 · 43931 | **only** the `000 MANUAL INSTALL ONLY USE THIS FOLDER 000` module | content: `Unofficial Morrowind Official Plugins Patched.ESP` (merged compatibility, No Firemoth), `Siege at Firemoth.esp` | Readme: never mix merged and individual plugins. `UMOPP_BetterArmorPatch.esp` off (Better Morrowind Armor not run). |
| 003_expansion_delay | Expansion Delay 1.3 · 47588 | main | content: `Expansion Delay.ESP` | |
| 004_morrowind_optimization_patch | MOP 1.18 · 45384 | `00 Core` | content: `Lake Fjalding Anti-Suck.ESP` | |
| 005_tamriel_data | Tamriel_Data HD 26.08 · **59927** | `00 Data Files` + `01 Data Files - Normal Maps` | content: `Tamriel_Data.esm`, `Tamriel_Data.omwscripts` | HD moved to its own Nexus page; 44537 is now SD. |
| OAAB_Data | OAAB_Data 2.6.2 · 49042 | `00 Core` (SD file) | content: `OAAB_Data.esm` | |
| 006_tamriel_rebuilt | Tamriel Rebuilt 26.08 "Poison Song" · 42145 | `00 Core` + `01 Faction Integration` (both wrap a `Data Files/`) | content: `TR_Mainland.esm`, `TR_Factions.esp`, `tamrielrebuilt.omwscripts` | `02 Firemoth Remover` not taken (UMOPP's No-Firemoth merge covers it). New character required after 25.x. |

## Vanilla-plus

| Folder | Mod · Nexus | Taken | Plugins | Notes |
|---|---|---|---|---|
| 101_graphic_herbalism | Graphic Herbalism MWSE/OpenMW 1.04 · 46599 | `00 Core + Vanilla Meshes` | none (settings: `graphic herbalism = true`) | |
| 102_harvest_lights | Harvest Lights · GitLab | `update_gitlab_mods.sh` | content: `harvest-lights.omwscripts` | |
| 103_weapon_sheathing | Weapon Sheathing 1.6 OpenMW · 46069 | `Data Files` | none (settings: `weapon sheathing`, `shield sheathing`, `use additional anim sources` = true) | Those keys were missing until 2026-09-10; the mod was inert before. |
| 104_project_atlas | Project Atlas 0.7.5 · 45399 | `00 Core`, `01 Textures - MET`, `02 Urns - Smoothed`, `03 Redware - Smoothed`, `06 Glow in the Dahrk Patch`, `07 Graphic Herbalism Patch`, `08 ILFAS Patch` | none | MOMW Starter Pack set (no BCOM deletion list). Loads after GitD core so its patched meshes win. |
| 105_morrowind_enhanced_textures | MET 6.1 · 46221 | main + `Interface and main menu` + `MET 6 Atlas textures` (→ `atlas/`, its own data= line after 104 and 105) | none | |
| 106_familiar_faces | Familiar Faces 2.1 · 50093 | main | none | Pairs with 410. |

## Polish

| Folder | Mod · Nexus | Taken | Plugins | Notes |
|---|---|---|---|---|
| 201_containers_animated | OpenMW Containers Animated 1.2.2 · 46232 | main | content: `Containers Animated.esp` | |
| 202_glow_in_the_dahrk | Glow in the Dahrk **2.11.2** · 45886 (Old files) | `00 Core`, `01 Hi Res Window Texture Replacer`, `04 Telvanni Dormers on Vvardenfell`, `05 Raven Rock Glass Windows` | content: `GITD_Telvanni_Dormers.ESP`, `GITD_WL_RR_Interiors.esp` | 3.x is MWSE-only. Interior Sunrays / Nord Glass / Dark Molag Mar / Windoors modules off; `_NoUvirith` variant off. 411 ships its own `GITD_WL_RR_Interiors.esp` that overrides this one (intended). |
| 203_nords_shut_your_windows | Nords Shut Your Windows 2.1 · 50087 | Core + Purist option | none | Depends on GitD nodes. |
| 204_truetype_fonts | TrueType Fonts · 46854 | `Fonts` | none | |
| 205_cantons_global_map | Cantons on the Global Map 1.1 · 50534 | `Data Files` | content: `Cantons_on_the_Global_Map_v1.1.esp` | |
| 206_distant_seafloor | Distant Seafloor 2.01 · 50796 | `00 Core` | content: `distant_seafloor_2.00.esm` (name unchanged in 2.01) | `01 Patch for vanilla Solstheim` (bloodmoon edges fix) not reviewed yet. |
| 207_distant_fixes_lua | Distant Fixes — Lua Edition · GitLab | `update_gitlab_mods.sh` | content: `distant-fixes-lua-edition.omwscripts` | |

## Population

| Folder | Mod · Nexus | Taken | Plugins | Notes |
|---|---|---|---|---|
| 301_repopulated_morrowind | Repopulated Morrowind 2.6 · 51174 | `00 Core`, `01 Repopulated Morrowind`, `03 Bloodmoon`, `05 Tamriel Rebuilt`, + `10 Compatability Patches/RepopulatedMorrowind_CRF_AldRedaynia.ESP` | content: `RepopulatedMorrowind.ESM`, `RepopulatedMorrowind.esp`, `RepopulatedBloodmoon.ESP`, `RepopulatedMorrowind_CRF_AldRedaynia.ESP` | **`RepopulatedMainland.ESP` stays off** until the author confirms TR 26.08. `02 BCOM` module not taken. |
| 302_repopulated_creatures | Repopulated Creatures 1.2 · 55628 | `00 Core` + `02 Vvardenfell and Mainland Dialogue Edits` | content: `RepopulatedCreatures.ESP`, `RepopulatedCreatures_DialogueEdits.ESP` | |

## Graphics (2026-09 enhancement phases A–D)

| Folder | Mod · Nexus | Taken | Plugins | Notes |
|---|---|---|---|---|
| 401_momw_post_processing_pack | MOMW Post Processing Pack · GitLab (sha256-checked) | folders `01 XE-Shaders`, `02 OMWFX-Shaders`, `03 ZesterersVolumetricClouds`, `04 WareyaOpenMWShaders`, `05 SlippyDinkerOpenMWShaders`, `07 ZesterersSSAO`, each its own data= line; `00 RecommendedConfig/shaders.yaml` → config dir | none (chain in settings: `ssao_hq, underwater_interior_effects, underwater_effects, clouds, godrays, bloom_soft, hdr, FollowerAA`) | The pack ships no `bloomlinear`; `bloom_soft` substitutes. `Cinematic Boken DoF.omwscripts` off. Toggle extras (SSR, sunshafts, wetworld) live with F2. |
| 407_normal_maps_for_morrowind | Normal Maps for Morrowind · 45336 | separate downloads **01a Shacks docks and ships (Lysol compatible), 03 Telvanni, 04 Daedric, 05 Redoran, 07 Terrain, 08 Rocks, 09b Swirlwood (Ket's)** | none | Extractor deletes the four known-bad `_nh.dds`. 02 Hlaalu / 06 Velothi downloaded by accident, parked. |
| 408_normal_maps_for_everything | Normal Maps for Everything · 52567 | of ~48 downloads: **Vanilla Textures Normal Mapped** (01 + 02 inside), **Atlas Textures AIO Normal Mapped** (03 MET only), **Morrowind Enhanced Textures Normal Mapped**, **OAAB Data Normal Mapped**, **Tamriel_Data Normal Mapped** | none | Allowlisted by name in the extractor. Hall of Justice stays out. |
| 409_gitd_normal_pbr | GitD Normal and Specular Maps · 58029 | the "Normal and Specular Maps" file (not "PBR") | none | Only useful with GitD's `01 Hi Res` module. |
| 405_skies_iv | Skies .IV · 43311 | `Skies - .IV` + `Particles` merged | none; 10 `fallback=` cloud-speed lines (`config/openmw-fallbacks-skies-iv.cfg`) | Extractor deletes `raindrop.nif` / `tx_raindrop_01.dds`. `Skies - Vanilla`, Moons variants off. |
| 406_new_starfields | New Starfields 2.2 · 43246 | `00 Core` + `01 Option 7 (100% Opacity)` | none | 8 options × 4 opacities exist; swap the option folder if preferred. |
| 412_better_waterfalls | Better Waterfalls 2.0.1 · 45424 | `00 Core` + `02 Tamriel Rebuilt Water` | none | Before 414. |
| 414_more_dynamic_water_meshes | OpenMW Dynamic Water Meshes 0.51 · 55392 | main | none | TR/OAAB water distortion. |
| 415_improved_lights_all_shaders | Improved Lights for All Shaders 1.3 · 51463 | `00 Core` + `01 Smoke and Steam Emitters` | none (settings: `clamp lighting = false`) | Project Atlas `08 ILFAS Patch` pairs with it. |
| 416_kirels_interior_weather | Kirel's Interior Weather (tes3cmd-cleaned) · 49278 | that one file | content: `k_weather.esp` | `(louder sounds)` variant off. Its vanilla-era scripts log harmless `=` warnings. |
| 411_morrowind_interiors_project | Morrowind Interiors Project 0.7.5.1 · 52237 | main + `Bloodmoon` file | content: `MorrowindInteriorsProject.ESP`, `_Bloodmoon.ESP`, `_TR.ESP` | `Anthology Solstheim` file parked (relocated Solstheim only). |
| 410_facelift_tamriel_data | Facelift for Tamriel Data 0.17 · 53935 | `Facelift_TR_Meshes` + `Facelift_TR_Textures` | none | |
| 420_fireflies | Fireflies 1.2 · 51443 | main | content: `RP_fireflies.ESP` | Needs Tamriel_Data. |
| 421_subtle_smoke | Subtle Smoke · 47341 | main | none | |
| 422_simply_walking | Simply Walking Remastered · 49785 | `Simply Walking Weapon Sheathing Edition` | none | Needs 103's settings keys. |
| 423_loading_screens_diversified | Loading Screens Diversified 1.2 (16:9) · 55498 | `00 Core` + `01 Unused Bethesda` + `02 New Vanilla Creatures` | none (settings: `[GUI] stretch menu background = true`) | `03 Main Menu Replacer` off (MET's Interface owns the menu). Alternative: Gonzo's Splash Screens (EV's pick). |

## Grass (groundcover system, never `content=`)

One plugin per region. `[Groundcover] enabled = true`, `stomp intensity = 2`.

| Folder | Mod · Nexus | Taken | groundcover= | Notes |
|---|---|---|---|---|
| 402_lush_synthesis (+ `/LUSH_VANILLA`, `/LUSH_UNDERWATER`, `/LUSH_SO` as data= lines) | Lush Synthesis 3.0 · 52931 | main; folders root, LUSH_VANILLA, LUSH_UNDERWATER, LUSH_SO | `lush3_ac`, `lush3_ai`, `lush3_bc`, `lush3_wg` (Vvardenfell land), `lush3_SO_BM` (Solstheim), `lush3_RI_BM` (rivers), `lush3_SE_BM` (seas) | `lush3_al` off (Remiros AL instead), `lush3_gl` off since 2026-09-10 (601's patch instead). `_flowerfields` / `_trackless` are alternatives. `_TOTSP` / `_CYR` / `_WoM` / `_TR_` variants off. `LUSH_BCOM`, `LUSH_TR` (22.11-era), `textures_halfsize` unused. |
| 403_remiros_groundcover | Remiros' Groundcover 4.1 · 46733 | `00 Core OpenMW` + `01b Thicker Grass OpenMW` | `Rem_AL.esp` (Ashlands) | MGE XE variants, `01a No Mushrooms`, `02 Vanilla Resolution`, `03 TR Plugins`, `04 Legend of Chemua` off. Other `Rem_*` regions off (Lush covers them). |
| 404_remiros_groundcover_textures | Remiros Groundcover Textures Improvement · 54261 | main | — | |
| 417_oaab_saplings | OAAB Saplings 2.4.0.2 · 50334 | `00 Core` + `10 Openmw Groundcover Patch` | `OAAB_Saplings.esm`; content: `OAAB_Saplings OpenMW Patch.ESP` | Nexus 52351 (separate patch) is deprecated. Patches for BCOM / Stonewood / Seawall / etc. off. |
| 418_lush_synthesis_tr | Fantasia Grass Mod – Lush Synthesis TR Update 1.0 · 60006 | the **"Lush Synthesis TR"** file (not "Fantasia Grass Mod TR") | `lush3_TR_merged.esp` | MOMW's TR 26.08 grass. |
| 601_oaab_grazelands (see Content) | — | `01 Remiros Groundcover GL Patch` | `Rem_GL - OAAB Landscape.esp` | Grazelands grass matched to the OAAB landscape. `Rem_GL.esp` off. |

## Music (S3maphore)

All pluginless except the framework; each a data= line. Playlists live in
430's folders `01 Tamriel Rebuilt Playlists`, `03 Muse Expansion Playlists`,
`04 Vindsvept Solstheim`; the audio lives in 431–439.

| Folder | Mod · Nexus | Plugins / notes |
|---|---|---|
| 429_h3lp_yours3lf | H3lp Yours3lf 0.82 · 56417 | content: `H3lp Yours3lf.esp` — **master of S3maphore.esp**, must precede it |
| 430_s3maphore | S3maphore 0.963 · 56836 | `00 Core` + the three playlist folders above; content: `S3maphore.esp`. Cyrodiil, Crystal City, Songbook, Starwind, Redguard, Nordic Lands, Inns playlists off. |
| 431_tr_soundtrack | Tamriel Rebuilt – Original Soundtrack · 47254 | `00 core` |
| 432_vindsvept_solstheim | Vindsvept Solstheim 1.1 · 53597 | |
| 433–439 | MUSE Expansion 2.0: Hlaalu 54639, Ashlander 51255, Redoran 55082, Sixth House 51082 (1.1), Daedric 51993, Dwemer 51169, Tomb 51407 | one folder each |

## Gameplay and QoL

| Folder | Mod · Nexus | Taken | Plugins | Notes |
|---|---|---|---|---|
| 501_ldm_context_matters | LDM – Context Matters 1.7 · 48273 | main | content: `LDM - Context Matters 1.7.ESP` | After PfP and TR. |
| 502_protective_guards | Protective Guards (OpenMW) **2.0** · 46992 | main | content: `protective_guards.omwscripts` | Renamed script in 2.0; in-game settings menu. The Factions add-on (54858) is a 1.x fork — incompatible, parked. |
| 504_book_jackets_hd | Book Jackets Complete Collection HD · 55402, + OAAB_BookJackets from Various Mods and Patches · 56176 | `book-jackets/00 Core`; the OAABBookJackets file | content: `book-jackets.esp`, `OAAB_BookJackets.omwaddon` | Order: 514 → 504 → 515 (MOMW). |
| 514_arukinns_better_books | Arukinn's Better Books and Scrolls · 43100 | main | none | |
| 515_melchiors_manuscripts | Melchior's Magnificent Manuscripts 1.3 · 45626 | `00 Core` + `01 Book Jackets Patch` | none | |
| 505–513 | MOMW GitLab Lua: UI Modes, Pause Control, Friendly Autosave, Quickselect, Go Home!, Light Hotkey, Convenient Thief Tools, Smart Ammo, Shield Unequipper | `update_gitlab_mods.sh all` | content: `UiModes`, `pause-control`, `friendly-autosave`, `QuickSelect`, `go-home`, `LightHotkey`, `convenient-thief-tools`, `smart-ammo`, `shield-unequipper` `.omwscripts` | `go-home-locking-doors` and `-fr` variants off. |

## Content — towns, quests, factions (Phase H tier 1, world half, 2026-09-10)

| Folder | Mod · Nexus | Taken | Plugins | Notes |
|---|---|---|---|---|
| 604_affresh | AFFresh 1.4 · 53006 | main | content: `AFFresh.esm` | ~30 quests on vanilla NPCs. |
| 602_oaab_tel_mora | OAAB Tel Mora 5.0.0 · 46177 | `00 Core`, `01 Female Guards`, `02 HD Textures`, `03 OpenMW Addons` | content: `OAAB_Tel Mora.esm`, `OAAB_Tel Mora_Female Guards.ESP` | `03 MWSE Addons` off. |
| 601_oaab_grazelands | OAAB Grazelands 2.2.1 · 49075 | `00 Core`, `03 HD Textures`, `01 Remiros Groundcover GL Patch` | content: `OAAB_Grazelands.ESP`; groundcover as above | Vos / Tel Vos overhaul, 16+ quests. `01 … for Trackless Grazelands` and `02 Old Vos Tradepost` need mods we don't run. |
| 603_oaab_twin_lamps | OAAB Brother Juniper's Twin Lamps 2.5 · 51424 | main | content: `OAAB Brother Junipers Twin Lamps.esp` | Joinable faction, ~20 quests. Extended Cut / Slave Escort optionals off. |
| 606_roaring_arena | Roaring Arena 1.2 · 50954 | `00 Core`, `07 Optional Plugins/BloodmoonOptions/01 Bloodmoon`, `RoaringArena_OAAB.ESP`, `RoaringArena_MageRobes.ESP`; `Empty Generated Voice Lines` → `noVO/` (no data= line by default) | content: `RoaringArena.esm`, `RoaringArena.esp`, `RoaringArena_OAAB.ESP`, `RoaringArena_MageRobes.ESP`, `RoaringArena_Solstheim.ESP` | Vanilla Vivec, so no `02 Vivec Options` folder. MOMW silences the AI-generated speeches via `noVO/`; we keep them — add a data= line for `606_roaring_arena/noVO` to silence. |
| 605_cutting_room_floor (+ `/optimized_banner`) | Cutting Room Floor – Modular 1.8 · 47307 | `Modular` + `Modular Patches/Tamriel Rebuilt` + `High Resolution Textures` (all unwrapped into the root) + `Optimized Banner` → `optimized_banner/`; `Splash/` deleted | content (MOMW Expanded Vanilla subset): `Free Slaves`, `Characters`, `Missing Persons TR`, `Dead Heroes`, `Extra Jobs`, `Extra Orders`, `Quests`, `Items TR`, `Voice Lines`, `Herders`, `Ald Redaynia`, `Ald-ruhn Underground` (+ 301's `RepopulatedMorrowind_CRF_AldRedaynia.ESP` right after Ald Redaynia) | The other 26 ESPs in the folder are off by design (EV enables 12 + Snow Prince, which needs TOTSP). |

## Settings keys owed to mods

All live in `config/settings-tuning.cfg` and are applied by `apply_config.py`:
`[Shaders]` four `auto use … maps = true` (407/408), `clamp lighting = false`
(415); `[Groundcover] enabled = true`, `stomp intensity = 2` (402/403/417);
`[Game] graphic herbalism = true` (101), `weapon sheathing`, `shield sheathing`,
`use additional anim sources` (103/422); `[GUI] stretch menu background = true`
(423); `[Post Processing] chain` (401); `[Navigator] max navmeshdb file size`
(TR-scale worlds).

## Parked (downloaded, deliberately not installed)

In `mod_files/_not_used/`: Normal Maps for Morrowind 02 Hlaalu / 06 Velothi;
Fantasia Grass Mod v2 (56570) and its "Fantasia Grass Mod TR" file; GitD
"PBR" file; Morrowind Interiors Project "Anthology Solstheim"; Protective
Guards Factions add-on (54858); Waterfalls Tweaks (46271 — its ESP deletes the
vanilla light `bc mushroom 64` that TR references 892 times); duplicate MET
downloads. Never installed: Morrowind Comes Alive 8.2 (MOMW: partially working;
Repopulated Morrowind is its replacement), Tamriel_Data SD (44537), GitD 3.x.

## Data-path order (why)

Foundation → OAAB → MOP → herbalism/atlas → TR → MET (+ atlas) → Lua baseline
→ GitD → polish → population → normal maps → sky/water/light → interiors/faces
→ grass → shaders → QoL → books → atmosphere → music → content. Later paths
override earlier files, which is what puts Project Atlas's GitD patch over GitD,
MET's atlas over Project Atlas, and Interiors Project's Raven Rock plugin over
GitD's. `apply_config.py` owns this order; `check_masters.py` proves the
`content=` order every run.
