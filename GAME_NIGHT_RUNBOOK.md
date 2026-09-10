# Game Night Runbook — September 2026

> **STATUS: TESTING — YMMV.** One ordered list, two sessions, every command
> and download in sequence. Everything here is cross-referenced to the deeper
> docs, but you should not need to open them on the night.
>
> Hardware assumed: Ryzen 9 5950X · 64 GB · RTX 5070 Ti · Pop!_OS · OpenMW
> Flatpak. The settings in `config/` are tuned for exactly this.

**Do not do the install and the play on the same night.** Prep Night is ~2
hours of downloads and checks; Game Night is a fresh character in a finished
build.

---

## Session A — Prep Night

### A1. Safety first (5 min)

```bash
cd ~/mods/morrowind
git pull                                   # this repo, latest scripts
mkdir -p ~/.config/systemd/user
cp backup/openmw-backup.{service,timer} ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now openmw-backup.timer
./backup/backup_openmw_saves.sh            # snapshot the March-era saves + cfg NOW
ls ~/mods/morrowind/saves_backup_local/    # confirm a timestamped folder exists
```

Optional NAS mirror: see `backup/README.md` (`~/.config/openmw-backup.conf`).

### A2. Engine + driver (5 min)

```bash
flatpak update -y                          # OpenMW 0.50 -> 0.51 + NVIDIA GL extension
flatpak info org.openmw.OpenMW | grep Version
nvidia-smi --query-gpu=driver_version --format=csv,noheader
flatpak list --runtime | grep nvidia       # must match the host driver version
```

The Flatpak NVIDIA extension must match the host driver **exactly**
(`org.freedesktop.Platform.GL.nvidia-580-65-06` for driver 580.65.06). A
mismatch after a Pop!_OS driver update = black screen. `check_setup.sh` (A7)
verifies this for you; Blackwell (50-series) also needs 570+.

### A3. Downloads (~45 min, mostly waiting on Nexus)

**Premium + API key (the fast way, and the rebuild-from-nothing way):**

```bash
mkdir -p ~/.config/nexusmods && chmod 700 ~/.config/nexusmods
nano ~/.config/nexusmods/apikey        # paste the Personal API Key, one line
chmod 600 ~/.config/nexusmods/apikey
cd ~/mods/morrowind
./download_mods.py --list              # resolves every file in config/nexus_manifest.json
./download_mods.py                     # fetches whatever is missing, Nexus filenames intact
```

Key: nexusmods.com → your avatar → **Settings → API Access → Personal API
Key**. The key never leaves that file. `--list` works on a free account;
downloads need Premium. Then skip to A4.

**By hand (no Premium):** all into `~/mods/morrowind/mod_files/`. Log in to
Nexus first. **Keep the Nexus filenames** — the extractor matches on the Nexus
mod ID in the name.

**Nexus rate-limits by IP.** One tab at a time; wait for each download to
finish before opening the next page. Do not use a browser with AdNauseam
enabled. If you get the "abnormally high number of requests" page, close
every Nexus tab and leave it alone for 15 minutes — every retry restarts the
clock.

**Which files** below is the set Modding-OpenMW (MOMW) uses for a no-BCOM,
MET + Project Atlas stack. Multi-file mods list every file to take; the
extractor takes exactly those and lists what it skipped.

**Required — the upgrade chain** (`version_audit_2026-08.md`):

| # | Mod | Which files | Link |
|---|-----|-------------|------|
| 1 | **Tamriel_Data (HD) 26.08** | The one main file. The HD version moved to **its own Nexus page (59927)**; 44537 is now the SD version. Extractor takes `00 Data Files` + `01 Data Files - Normal Maps`. | https://www.nexusmods.com/morrowind/mods/59927?tab=files |
| 2 | **Tamriel Rebuilt 26.08** "Poison Song" | Main file. Extractor takes `00 Core` + `01 Faction Integration` (adds `TR_Factions.esp`). | https://www.nexusmods.com/morrowind/mods/42145?tab=files |
| 3 | **Glow in the Dahrk 2.11.2** | Files → **Old files** → v2.11.2 (NOT 3.x). Already in `mod_files`. Extractor takes `00 Core`, `01 Hi Res Window Texture Replacer`, `04 Telvanni Dormers on Vvardenfell`, `05 Raven Rock Glass Windows`; skips the Interior Sunrays / Nord Glass / Dark Molag Mar / Windoors modules. | https://www.nexusmods.com/morrowind/mods/45886?tab=files |

**Baseline updates found by `download_mods.py` on 2026-09-09** (newest-wins, the
extractor handles the new layouts): UMOPP **3.3.0** (merged compatibility plugin
replaces the seven individual ESPs — its readme forbids mixing them; `Siege at
Firemoth.esp` separate), OAAB_Data **2.6.2**, Distant Seafloor **2.01** (same
master name), Repopulated Creatures **1.2** (adds
`RepopulatedCreatures_DialogueEdits.ESP`, TR-aware variant).

**Baseline top-ups** (the March build was missing these; optional but MOMW-standard):

| # | Mod | Which files | Link |
|---|-----|-------------|------|
| 3a | **Morrowind Enhanced Textures** | Two extra files: **`Interface and main menu`** and **`MET 6 Atlas textures`** (the 6.1 main file is already present). Atlas textures land in `105_.../atlas/` = its own `data=` line. | https://www.nexusmods.com/morrowind/mods/46221?tab=files |
| 3b | **Project Atlas** | No download — already present. Extractor now also takes `01 Textures - MET`, `02 Urns - Smoothed`, `03 Redware - Smoothed`, `06 Glow in the Dahrk Patch`, `07 Graphic Herbalism Patch`, `08 ILFAS Patch`. | — |

**Recommended — the enhancement plan** (biggest wins first; skip any you
don't feel like tonight, the extractor treats them as optional):

| # | Mod | Which files | Link |
|---|-----|-------------|------|
| 4 | **MOMW Post Processing Pack** | Already downloaded (GitLab, sha256-verified). | https://modding-openmw.gitlab.io/momw-post-processing-pack/ |
| 5 | **Lush Synthesis 3.0** (grass) | Main file only. Used folders: root, `LUSH_VANILLA` (Vvardenfell land grass), `LUSH_UNDERWATER`, `LUSH_SO` (Solstheim). Not used: `LUSH_BCOM`, `LUSH_TR` (22.11-era TR grass, see #5a), `textures_halfsize`. | https://www.nexusmods.com/morrowind/mods/52931?tab=files |
| 5a | **Fantasia Grass Mod – Lush Synthesis TR Update** | Main file. This is MOMW's TR 26.08 grass (`lush3_TR_merged.esp` as groundcover). | https://www.nexusmods.com/morrowind/mods/60006?tab=files |
| 6 | **Remiros' Groundcover** | Main file. Extractor takes `00 Core OpenMW` + `01b Thicker Grass OpenMW`; `03 TR Plugins` not used (Fantasia covers TR). | https://www.nexusmods.com/morrowind/mods/46733?tab=files |
| 7 | **Remiros Groundcover Textures Improvement** | Main file (single). | https://www.nexusmods.com/morrowind/mods/54261?tab=files |
| 8 | **Skies .IV** | Main file. Extractor merges `Skies - .IV` + `Particles`, skips `Skies - Vanilla`, deletes the two raindrop files. Needs the 10 `fallback=` lines (A5). | https://www.nexusmods.com/morrowind/mods/43311?tab=files |
| 9 | **New Starfields** | Main file. Extractor takes `00 Core` + `01 Option 7 (100% Opacity)` (MOMW's pick; 8 options exist, swap if you prefer another). | https://www.nexusmods.com/morrowind/mods/43246?tab=files |
| 10 | **Normal Maps for Morrowind** | Separate module downloads — take **01a Shacks docks and ships (Lysol compatible)**, **03 Telvanni**, **04 Daedric**, **05 Redoran**, **07 Terrain**, **08 Rocks**, **09b Swirlwood (Ket's Swirlwood)**. Skip 02, 06, plain 01/09. Extractor deletes the 4 known-bad `_nh.dds`. | https://www.nexusmods.com/morrowind/mods/45336?tab=files |
| 11 | **Normal Maps for Everything** | ~48 separate downloads — take only **Vanilla Textures Normal Mapped** (01 + 02 inside), **Atlas Textures Normal Mapped** (03 MET inside; not 01), **Morrowind Enhanced Textures Normal Mapped**, **OAAB Data Textures Normal Mapped**, **TR_PC_SHOTN Normal Mapped** (if still listed; TD 26.08 ships its own normal maps). Skip everything else, incl. Hall of Justice. | https://www.nexusmods.com/morrowind/mods/52567?tab=files |
| 12 | **GitD Normal Specular PBR Maps** | Main file (single). Only does anything with GitD's `01 Hi Res` module (#3). | https://www.nexusmods.com/morrowind/mods/58029?tab=files |
| 13 | **Facelift for Tamriel Data** | **Both** main files: `Facelift_TR_Meshes` and `Facelift_TR_Textures`. | https://www.nexusmods.com/morrowind/mods/53935?tab=files |
| 14 | **Morrowind Interiors Project** | Main file **and** the optional `Bloodmoon` file. | https://www.nexusmods.com/morrowind/mods/52237?tab=files |
| 15 | **Better Waterfalls** | Main file. Extractor takes `00 Core` + `02 Tamriel Rebuilt Water`, skips 01. | https://www.nexusmods.com/morrowind/mods/45424?tab=files |
| 15a | **Waterfalls Tweaks** (optional, not in any MOMW list) | Main file. Ships 3 ESPs — enable exactly ONE (`Waterfalls Tweaks.esp`). | https://www.nexusmods.com/morrowind/mods/46271?tab=files |
| 16 | **OpenMW More Dynamic Water Meshes** | Main file (single). | https://www.nexusmods.com/morrowind/mods/55392?tab=files |
| 17 | **Improved Lights for All Shaders** | Main file. Extractor takes `00 Core` + `01 Smoke and Steam Emitters`. Needs `clamp lighting = false` (A6). | https://www.nexusmods.com/morrowind/mods/51463?tab=files |
| 18 | **Kirel's Interior Weather** | ONLY the file named **"(Cleaned and updated with tes3cmd)"**. | https://www.nexusmods.com/morrowind/mods/49278?tab=files |
| 19 | **OAAB Saplings** | Main file. Extractor takes `00 Core` + `10 Openmw Groundcover Patch`. **Do not download Nexus 52351** (deprecated; folded into folder 10). | https://www.nexusmods.com/morrowind/mods/50334?tab=files |
| 20 | **LDM – Context Matters** | Main file (single). | https://www.nexusmods.com/morrowind/mods/48273?tab=files |
| 21 | **Protective Guards (OpenMW) 2.0** | Main file. v2.0 (2026-08-31) has its own settings menu; the separate Factions add-on (54858) is a 1.x fork and is **not** used with 2.0. | https://www.nexusmods.com/morrowind/mods/46992?tab=files |
| 22 | **Book Jackets Complete Collection HD** | Main file. Optional extra: the **`OAABBookJackets`** file from MOMW's *Various Mods and Patches* (56176). | https://www.nexusmods.com/morrowind/mods/55402?tab=files · https://www.nexusmods.com/morrowind/mods/56176?tab=files |

The GitLab Lua mods (Harvest Lights, Distant Fixes, UI Modes, Pause Control,
Friendly Autosave, Quickselect, Go Home!, Light Hotkey, Convenient Thief
Tools, Smart Ammo, Shield Unequipper) need **no download** — A4 fetches them.

### A4. Extract (~15 min, mostly Tamriel_Data)

```bash
cd ~/mods/morrowind
./extract_mods.sh                          # newest TD/TR win; every multi-file mod handled
./update_gitlab_mods.sh all                # 11 GitLab Lua mods, latest tags
```

Read the extractor's NOTES block: it lists optional FOMOD folders it did not
copy so you can decide. The raindrop files (Skies .IV) and the known-bad
normal maps (Normal Maps for Morrowind) are deleted automatically. One
manual step:

- **Post-processing config**:
  ```bash
  cp "mods/401_momw_post_processing_pack/00 RecommendedConfig/shaders.yaml" \
     ~/.var/app/org.openmw.OpenMW/config/openmw/
  ```

### A5 + A6. Apply the config (2 min) — one command

```bash
cd ~/mods/morrowind
python3 apply_config.py --dry-run --refresh 180   # 180 = the 1440p panel's refresh; prints the plan
python3 apply_config.py --refresh 180             # backs up both files, then writes
```

`apply_config.py` is measured, not blind: it adds a `data=` line only for a
folder that exists and is non-empty, a `content=` / `groundcover=` line only
for a plugin that is actually present, removes `RepopulatedMainland.ESP`,
appends the Skies .IV fallbacks, and merges `config/settings-tuning.cfg`
section-by-section into `settings.cfg` (existing sections kept). Backups land
in `saves_backup_local/config_before_apply/`. Re-run any time; it is
idempotent. What it applies is exactly the reference below.

### Reference — what A5 writes to openmw.cfg

File: `~/.var/app/org.openmw.OpenMW/config/openmw/openmw.cfg` (it's in the
backup from A1 if you need to roll back).

**data= lines** — replace `YOURUSER`; order matters (later overrides earlier).
Baseline block is in `OPENMW_BUILD_SHEET.md`. One baseline addition goes
right after the MET and Project Atlas lines:

```ini
data="/home/YOURUSER/mods/morrowind/mods/105_morrowind_enhanced_textures/atlas"   # MET 6 Atlas textures; after 104 + 105
```

Then append these AFTER the baseline block:

```ini
# --- 2026-09 additions (graphics) ---
data="/home/YOURUSER/mods/morrowind/mods/407_normal_maps_for_morrowind"
data="/home/YOURUSER/mods/morrowind/mods/408_normal_maps_for_everything"
data="/home/YOURUSER/mods/morrowind/mods/409_gitd_normal_pbr"
data="/home/YOURUSER/mods/morrowind/mods/405_skies_iv"
data="/home/YOURUSER/mods/morrowind/mods/406_new_starfields"
data="/home/YOURUSER/mods/morrowind/mods/412_better_waterfalls"
data="/home/YOURUSER/mods/morrowind/mods/413_waterfalls_tweaks"
data="/home/YOURUSER/mods/morrowind/mods/414_more_dynamic_water_meshes"
data="/home/YOURUSER/mods/morrowind/mods/415_improved_lights_all_shaders"
data="/home/YOURUSER/mods/morrowind/mods/416_kirels_interior_weather"
data="/home/YOURUSER/mods/morrowind/mods/411_morrowind_interiors_project"
data="/home/YOURUSER/mods/morrowind/mods/410_facelift_tamriel_data"
# --- grass (MOMW order: Lush, Remiros, Remiros textures, Saplings, Fantasia TR) ---
data="/home/YOURUSER/mods/morrowind/mods/402_lush_synthesis"
data="/home/YOURUSER/mods/morrowind/mods/402_lush_synthesis/LUSH_VANILLA"
data="/home/YOURUSER/mods/morrowind/mods/402_lush_synthesis/LUSH_UNDERWATER"
data="/home/YOURUSER/mods/morrowind/mods/402_lush_synthesis/LUSH_SO"
data="/home/YOURUSER/mods/morrowind/mods/403_remiros_groundcover"
data="/home/YOURUSER/mods/morrowind/mods/404_remiros_groundcover_textures"
data="/home/YOURUSER/mods/morrowind/mods/417_oaab_saplings"
data="/home/YOURUSER/mods/morrowind/mods/418_lush_synthesis_tr"
# --- shaders (each numbered folder is its own path) ---
data="/home/YOURUSER/mods/morrowind/mods/401_momw_post_processing_pack/01 XE-Shaders"
data="/home/YOURUSER/mods/morrowind/mods/401_momw_post_processing_pack/02 OMWFX-Shaders"
data="/home/YOURUSER/mods/morrowind/mods/401_momw_post_processing_pack/03 ZesterersVolumetricClouds"
data="/home/YOURUSER/mods/morrowind/mods/401_momw_post_processing_pack/04 WareyaOpenMWShaders"
data="/home/YOURUSER/mods/morrowind/mods/401_momw_post_processing_pack/05 SlippyDinkerOpenMWShaders"
data="/home/YOURUSER/mods/morrowind/mods/401_momw_post_processing_pack/07 ZesterersSSAO"
# --- gameplay / QoL ---
data="/home/YOURUSER/mods/morrowind/mods/501_ldm_context_matters"
data="/home/YOURUSER/mods/morrowind/mods/502_protective_guards"
data="/home/YOURUSER/mods/morrowind/mods/504_book_jackets_hd"
data="/home/YOURUSER/mods/morrowind/mods/505_ui_modes"
data="/home/YOURUSER/mods/morrowind/mods/506_pause_control"
data="/home/YOURUSER/mods/morrowind/mods/507_friendly_autosave"
data="/home/YOURUSER/mods/morrowind/mods/508_quickselect"
data="/home/YOURUSER/mods/morrowind/mods/509_go_home"
data="/home/YOURUSER/mods/morrowind/mods/510_light_hotkey"
data="/home/YOURUSER/mods/morrowind/mods/511_convenient_thief_tools"
data="/home/YOURUSER/mods/morrowind/mods/512_smart_ammo"
data="/home/YOURUSER/mods/morrowind/mods/513_shield_unequipper"
```

**content= lines** — ESMs first, then ESPs, then `.omwscripts`. The baseline
plugins stay as they were, with these changes:

- **Remove** `RepopulatedMainland.ESP` for now (Repopulated Morrowind has not
  confirmed TR 26.08 support; the Vvardenfell + Bloodmoon RM plugins are fine).
- **Add** `content=TR_Factions.esp` right after `TR_Mainland.esm` (Faction
  Integration module).
- **Add** the GitD 2.11.2 plugins: `GITD_Telvanni_Dormers.ESP` (NOT the
  `_NoUvirith` variant) and `GITD_WL_RR_Interiors.esp`.

Then add the new plugins. Nexus mods that ship a plugin (exact names per MOMW):

```ini
content=MorrowindInteriorsProject.ESP
content=MorrowindInteriorsProject_Bloodmoon.ESP
content=MorrowindInteriorsProject_TR.ESP          # after TR_Mainland.esm
content=Waterfalls Tweaks.esp                     # only if #15a; exactly ONE of its three
content=k_weather.esp                             # Kirel's
content=OAAB_Saplings OpenMW Patch.ESP            # content=; the .esm goes in groundcover=
content=book-jackets.esp
content=OAAB_BookJackets.omwaddon                 # only if the 56176 file was taken
content=LDM - Context Matters 1.7.ESP
```

Lua mods (`.omwscripts`, after all ESPs):

```ini
content=protective_guards.omwscripts              # v2.0 name (1.x was protective_guards_for_omw)
content=UiModes.omwscripts
content=pause-control.omwscripts
content=friendly-autosave.omwscripts
content=QuickSelect.omwscripts
content=go-home.omwscripts
content=LightHotkey.omwscripts
content=convenient-thief-tools.omwscripts
content=smart-ammo.omwscripts
content=shield-unequipper.omwscripts
```

`ls mods/4*/ mods/5*/ | grep -i -E 'esp|omwaddon|omwscripts'` lists what
actually got extracted, in case a mod updated its filenames.

**groundcover= lines — NOT content=.** Grass plugins go through OpenMW's
groundcover system. One plugin per region, no doubles:

```ini
# Vvardenfell land — Lush Synthesis LUSH_VANILLA (plain variants; the
# _flowerfields / _trackless files are alternatives to lush3_ai / lush3_gl)
groundcover=lush3_ac.esp
groundcover=lush3_ai.esp
groundcover=lush3_bc.esp
groundcover=lush3_gl.esp
groundcover=lush3_wg.esp
groundcover=Rem_AL.esp                            # Ashlands from Remiros (MOMW's pick) — so NOT lush3_al.esp
groundcover=lush3_SO_BM.esp                       # Solstheim (BM = vanilla Bloodmoon, no TOTSP)
# water — Lush LUSH_UNDERWATER, RI = rivers, SE = seas; BM variants (no TOTSP/CYR/WoM)
groundcover=lush3_RI_BM.esp
groundcover=lush3_SE_BM.esp
# saplings + TR
groundcover=OAAB_Saplings.esm
groundcover=lush3_TR_merged.esp                   # from 418 Fantasia (TR 26.08 grass)
```

Do NOT add: `lush3_al.esp` (Rem_AL covers it), the `_TOTSP` / `_CYR` / `_WoM` /
`_TR_` underwater variants, anything from `LUSH_BCOM` or `LUSH_TR`, the other
`Rem_*` regions, or the Saplings patch ESPs for mods we don't run.

**Skies .IV fallbacks** — append `config/openmw-fallbacks-skies-iv.cfg` (10
cloud-speed lines):
```bash
cat ~/mods/morrowind/config/openmw-fallbacks-skies-iv.cfg >> \
    ~/.var/app/org.openmw.OpenMW/config/openmw/openmw.cfg
```

### Reference — what A6 writes to settings.cfg

Merge `config/settings-tuning.cfg` into
`~/.var/app/org.openmw.OpenMW/config/openmw/settings.cfg` — section by section
(if `[Shadows]` already exists, put the keys in it; don't create a duplicate
section). Then:

- set `framerate limit` to your monitor's refresh rate
- `config/settings-tuning.cfg` already carries `clamp lighting = false` (Improved
  Lights) and the four `auto use ... maps = true` keys (Normal Maps mods); they are
  harmless if you skipped those mods

### A7. Validate, then a 10-minute test drive

```bash
cd ~/mods/morrowind
./check_setup.sh          # 0 errors required; it also checks driver ext + OpenMW version
```

Load order: run PLOX (`tools_reference.md`), apply what makes sense, re-check.

Launch: `flatpak run org.openmw.OpenMW`. In the launcher, confirm the
content list matches your `content=` lines, then start a **throwaway** new
game:

- [ ] Main menu renders, no missing-master popup
- [ ] Seyda Neen: grass present, windows glow after `set gamehour to 22` in
      console (~), waterfalls look right, no pink/yellow assets
- [ ] Press **F2** — post-processing chain visible, SSAO/godrays toggle
- [ ] `coc "Almas Thirr"` (TR) loads a 26.08 cell without errors
- [ ] `grep -E 'Error|Failed|missing' ~/.var/app/org.openmw.OpenMW/config/openmw/openmw.log | head`
      is empty or benign

Any red flag → `OPENMW_BUILD_SHEET.md` "Troubleshooting order" (disable the
newest additions first), or restore the A1 backup's `config/openmw.cfg`.

---

## Session B — Game Night

1. `./backup/backup_openmw_saves.sh` (30 s — also confirms the timer works)
2. Launch. **New character.** TR says pre-26.08 saves are "highly incompatible",
   and House Indoril is the whole point.
3. First hour, don't chase settings — play. If something's wrong, note it,
   finish the session, fix it on the next prep night.
4. Afterwards: `journalctl --user -u openmw-backup.service -n 5` to make sure
   the nightly backup is landing.

---

## Later prep nights (not this week)

- Repopulated Morrowind: re-check https://www.nexusmods.com/morrowind/mods/51174
  for a TR 26.08-compatible release, then re-add `RepopulatedMainland.ESP`.
- MacKom heads: still pulled from MOMW lists; Westly's Faces Refurbished
  (51214) is the vanilla-like HD option if Familiar Faces + Facelift isn't enough.
- Stage 6+ (BCOM 3.3.0+, Vurt's MVR): `openmw_install_order.md`, and switch
  on Delta Plugin merging (`tools_reference.md`) at that point.
- Phase E extras (Fireflies, Subtle Smoke, S3maphore + TR OST, Loading Screens
  Diversified, Simply Walking): `enhancement_plan_2026-08.md`.

---

## Quick troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| Black screen / "failed to create GL context" | Flatpak NVIDIA ext ≠ host driver | `flatpak update`; `./check_setup.sh` names the exact extension |
| Missing master on launch | plugin removed but still in `content=` | `./check_setup.sh` lists it; remove the line |
| Yellow/pink meshes or textures | data= path missing or wrong order | `./check_setup.sh`; put texture packs after mesh packs |
| No grass | ESPs in `content=` instead of `groundcover=`, or `[Groundcover] enabled` missing | fix A5 / A6 |
| Windows don't glow at night | GitD missing or 3.x installed | must be 2.11.2, folder `202_glow_in_the_dahrk` non-empty |
| Menus at 1000+ FPS, GPU screaming | no framerate limit | `[Video] framerate limit = <refresh>` |
| Lua mod does nothing | no `content=<name>.omwscripts` line | `./update_gitlab_mods.sh` prints the exact line |
| Old save loads weird after TR upgrade | expected | new character; or console-fix per TR notes |
