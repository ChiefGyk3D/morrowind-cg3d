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

All into `~/mods/morrowind/mod_files/`. Log in to Nexus first. **Keep the
Nexus filenames** — the extractor matches on them.

**Required — the upgrade chain** (`version_audit_2026-08.md`):

| # | Mod | Get | Link |
|---|-----|-----|------|
| 1 | **Tamriel_Data (HD) 26.08** | Main HD file | https://www.nexusmods.com/morrowind/mods/44537?tab=files |
| 2 | **Tamriel Rebuilt 26.08** "Poison Song" | Main file | https://www.nexusmods.com/morrowind/mods/42145?tab=files |
| 3 | **Glow in the Dahrk 2.11.2** | Files → **Old files** → v2.11.2 (NOT 3.x) | https://www.nexusmods.com/morrowind/mods/45886?tab=files |

**Recommended — Phase A/B/C/E of the enhancement plan** (biggest wins first;
skip any you don't feel like tonight, the extractor treats them as optional):

| # | Mod | Get | Link |
|---|-----|-----|------|
| 4 | **MOMW Post Processing Pack** | `momw-post-processing-pack.zip` | https://modding-openmw.gitlab.io/momw-post-processing-pack/ |
| 5 | **Lush Synthesis 3.0** (grass) | Main file | https://www.nexusmods.com/morrowind/mods/52931?tab=files |
| 6 | **Remiros' Groundcover** | Main file | https://www.nexusmods.com/morrowind/mods/46733?tab=files |
| 7 | **Remiros Groundcover Textures Improvement** | Main file | https://www.nexusmods.com/morrowind/mods/54261?tab=files |
| 8 | **Skies .IV** | Main file | https://www.nexusmods.com/morrowind/mods/43311?tab=files |
| 9 | **New Starfields** | Main file | https://www.nexusmods.com/morrowind/mods/43246?tab=files |
| 10 | **Normal Maps for Morrowind** | Main file | https://www.nexusmods.com/morrowind/mods/45336?tab=files |
| 11 | **Normal Maps for Everything** | Main file | https://www.nexusmods.com/morrowind/mods/52567?tab=files |
| 12 | **GitD Normal Specular PBR Maps** | Main file | https://www.nexusmods.com/morrowind/mods/58029?tab=files |
| 13 | **Facelift for Tamriel Data** | Main file | https://www.nexusmods.com/morrowind/mods/53935?tab=files |
| 14 | **Morrowind Interiors Project** | Main file | https://www.nexusmods.com/morrowind/mods/52237?tab=files |
| 15 | **Better Waterfalls** + **Waterfalls Tweaks** | Main files | https://www.nexusmods.com/morrowind/mods/45424 · https://www.nexusmods.com/morrowind/mods/46271 |
| 16 | **OpenMW More Dynamic Water Meshes** | Main file | https://www.nexusmods.com/morrowind/mods/55392?tab=files |
| 17 | **Improved Lights for All Shaders** | Main file | https://www.nexusmods.com/morrowind/mods/51463?tab=files |
| 18 | **Kirel's Interior Weather** | Main file | https://www.nexusmods.com/morrowind/mods/49278?tab=files |
| 19 | **OAAB Saplings** + groundcover patch | Main files | https://www.nexusmods.com/morrowind/mods/50334 · https://www.nexusmods.com/morrowind/mods/52351 |
| 20 | **LDM – Context Matters** | Main file | search Nexus: "LDM Context Matters" (Lucevar) |
| 21 | **Protective Guards (OpenMW)** + Factions add-on | Main files | https://www.nexusmods.com/morrowind/mods/46992 · https://www.nexusmods.com/morrowind/mods/54858 |
| 22 | **Book Jackets Complete Collection HD** | Main file | https://www.nexusmods.com/morrowind/mods/55402?tab=files |

The GitLab Lua mods (Harvest Lights, Distant Fixes, UI Modes, Pause Control,
Friendly Autosave, Quickselect, Go Home!, Light Hotkey, Convenient Thief
Tools, Smart Ammo, Shield Unequipper) need **no download** — A4 fetches them.

### A4. Extract (~15 min, mostly Tamriel_Data)

```bash
cd ~/mods/morrowind
./extract_mods.sh                          # newest TD/TR win; optional mods auto-detected
./update_gitlab_mods.sh all                # 11 GitLab Lua mods, latest tags
```

Read the extractor's NOTES block: it lists optional FOMOD folders it did not
copy (e.g. Remiros' Solstheim module) so you can decide. Then two manual
fix-ups it can't do for you:

- **Normal Maps for Everything**: delete the known-bad `_n.dds` files listed
  under "Usage notes" at https://modding-openmw.com/mods/normal-maps-for-everything/
- **Post-processing config**:
  ```bash
  cp "mods/401_momw_post_processing_pack/00 RecommendedConfig/shaders.yaml" \
     ~/.var/app/org.openmw.OpenMW/config/openmw/
  ```

### A5. openmw.cfg (~15 min)

File: `~/.var/app/org.openmw.OpenMW/config/openmw/openmw.cfg` (it's in the
backup from A1 if you need to roll back).

**data= lines** — replace `YOURUSER`; order matters (later overrides earlier).
Baseline block is in `OPENMW_BUILD_SHEET.md`; append these AFTER it:

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
data="/home/YOURUSER/mods/morrowind/mods/402_lush_synthesis"
data="/home/YOURUSER/mods/morrowind/mods/403_remiros_groundcover"
data="/home/YOURUSER/mods/morrowind/mods/404_remiros_groundcover_textures"
data="/home/YOURUSER/mods/morrowind/mods/417_oaab_saplings"
# --- shaders (each numbered folder is its own path) ---
data="/home/YOURUSER/mods/morrowind/mods/401_momw_post_processing_pack/01 XE-Shaders"
data="/home/YOURUSER/mods/morrowind/mods/401_momw_post_processing_pack/02 OMWFX-Shaders"
data="/home/YOURUSER/mods/morrowind/mods/401_momw_post_processing_pack/03 ZesterersVolumetricClouds"
data="/home/YOURUSER/mods/morrowind/mods/401_momw_post_processing_pack/04 WareyaOpenMWShaders"
data="/home/YOURUSER/mods/morrowind/mods/401_momw_post_processing_pack/07 ZesterersSSAO"
# --- gameplay / QoL ---
data="/home/YOURUSER/mods/morrowind/mods/501_ldm_context_matters"
data="/home/YOURUSER/mods/morrowind/mods/502_protective_guards"
data="/home/YOURUSER/mods/morrowind/mods/503_protective_guards_factions"
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
plugins stay as they were, with two changes:

- **Remove** `RepopulatedMainland.ESP` for now (Repopulated Morrowind has not
  confirmed TR 26.08 support; the Vvardenfell + Bloodmoon RM plugins are fine).
- **Add** the GitD 2.11.2 plugin (the `.esp` in `202_glow_in_the_dahrk`).

Then add the new plugins. Exact names for the Lua mods:

```ini
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

For the Nexus mods that ship an `.esp` (Protective Guards + add-on, LDM,
Book Jackets, Morrowind Interiors Project, Kirel's, Improved Lights, Facelift
for TD, Better Waterfalls, More Dynamic Water, OAAB Saplings), add
`content=<that file>` — `ls mods/5*/ mods/4*/ | grep -i esp` lists them.

**groundcover= lines — NOT content=.** Grass plugins go through OpenMW's
groundcover system:

```ini
groundcover=<each Lush Synthesis .esp in 402_lush_synthesis, incl. the TR one>
groundcover=Rem_AL.esp
groundcover=<the OAAB Saplings groundcover patch .esp>
```

**Skies .IV fallbacks** — append `config/openmw-fallbacks-skies-iv.cfg`:

```bash
cat ~/mods/morrowind/config/openmw-fallbacks-skies-iv.cfg >> \
    ~/.var/app/org.openmw.OpenMW/config/openmw/openmw.cfg
```

### A6. settings.cfg (5 min)

Merge `config/settings-tuning.cfg` into
`~/.var/app/org.openmw.OpenMW/config/openmw/settings.cfg` — section by section
(if `[Shadows]` already exists, put the keys in it; don't create a duplicate
section). Then:

- set `framerate limit` to your monitor's refresh rate
- if you installed Improved Lights for All Shaders: `[Shaders] clamp lighting = false`

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
| Bought item vanishes (gold taken), or only ONE of a pair; same items every time; console `AddItem` doesn't stick | **OpenMW 0.50 bug #8955** — restocking merchant stock shares an object id with your copy, so a Lua `Item:remove()` on the merchant's stack deletes yours too | Fixed in **0.51.0**: `flatpak update org.openmw.OpenMW`, confirm with `flatpak info`. Verify in-game with `player->GetItemCount "repair_journeyman_01"` before/after buying |
