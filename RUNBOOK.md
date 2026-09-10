# RUNBOOK.md — prep night, game night, adding mods

> Hardware assumed: Ryzen 9 5950X · 64 GB · RTX 5070 Ti (180 Hz 1440p) ·
> Pop!_OS · OpenMW 0.51 Flatpak. Everything here is one command per step;
> what each command actually does is in [`TOOLS.md`](TOOLS.md), what it
> installs is in [`MODS.md`](MODS.md).

Do not do the install and the play on the same night.

## 0. One-time setup

```bash
# Flatpak OpenMW must be able to read the mod tree (read-only; always name the app)
flatpak override --user org.openmw.OpenMW --filesystem=$HOME/mods/morrowind:ro

# this repo IS the mod tree
git clone https://github.com/ChiefGyk3D/morrowind-cg3d.git ~/mods/morrowind

# Nexus Premium API key (nexusmods.com → avatar → Settings → API Access → Personal API Key)
mkdir -p ~/.config/nexusmods && chmod 700 ~/.config/nexusmods
nano ~/.config/nexusmods/apikey && chmod 600 ~/.config/nexusmods/apikey
```

Config lives in `~/.var/app/org.openmw.OpenMW/config/openmw/` (Flatpak), not
`~/.config/openmw/`. Run OpenMW's wizard once against the Steam `Data Files`
before anything else.

## 1. Prep night (~1 h, mostly downloads)

### 1.1 Safety

```bash
cd ~/mods/morrowind && git pull
cp backup/openmw-backup.{service,timer} ~/.config/systemd/user/ && systemctl --user daemon-reload
systemctl --user enable --now openmw-backup.timer
./backup/backup_openmw_saves.sh          # snapshot saves + openmw.cfg + settings.cfg now
```

### 1.2 Engine and driver

```bash
flatpak update -y
./check_setup.sh                          # also verifies OpenMW ≥ 0.51 and driver ↔ Flatpak GL extension
```

The Flatpak NVIDIA GL extension must match the host driver exactly
(`org.freedesktop.Platform.GL.nvidia-595-84` for driver 595.84). A mismatch
after a Pop!_OS driver update is the classic black screen.

### 1.3 Download

```bash
./download_mods.py --list                 # resolve every file in config/nexus_manifest.json
./download_mods.py                        # fetch what's missing, Nexus filenames intact
```

No Premium? `--list` still works; download the listed files by hand into
`mod_files/` keeping the Nexus filenames. Nexus rate-limits by IP: one tab at
a time, no AdNauseam, and if you get the "abnormally high number of requests"
page, close every Nexus tab for 15 minutes — every retry restarts the clock.

### 1.4 Extract

```bash
./extract_mods.sh                         # every archive → numbered mods/ folder, exact modules per MODS.md
./update_gitlab_mods.sh all               # the 11 MOMW GitLab Lua mods
cp "mods/401_momw_post_processing_pack/00 RecommendedConfig/shaders.yaml" \
   ~/.var/app/org.openmw.OpenMW/config/openmw/
```

Read the extractor's NOTES block: it lists every optional module it skipped.

### 1.5 Configure

```bash
python3 apply_config.py --dry-run --refresh 180    # plan only
python3 apply_config.py --refresh 180              # backs up, then writes openmw.cfg + settings.cfg
```

`--refresh` is your monitor's refresh rate (framerate limit). The applier
only adds what exists on disk, never mixes `content=` and `groundcover=`,
places plugins after their masters, and merges `config/settings-tuning.cfg`
section by section. Backups land in `saves_backup_local/config_before_apply/`.

### 1.6 Validate, then a ten-minute test drive

```bash
./check_setup.sh                          # 0 errors required: paths, plugins, masters, groundcover, driver, settings
```

Launch (`flatpak run org.openmw.OpenMW`), start a **throwaway** new game:

- [ ] main menu renders, no missing-master popup
- [ ] Seyda Neen: grass, waterfalls, no pink/yellow assets
- [ ] `set gamehour to 22` → windows glow (Glow in the Dahrk)
- [ ] F2 → post-processing chain listed and toggleable
- [ ] `coc "Almas Thirr"` loads a TR 26.08 cell (you spawn in the river under
      the cantons; `tcl` to fly up — NPCs "on air" from below is one-sided
      walkway geometry, not a fault)
- [ ] F3 → frame rate; if pinned at the cap with headroom, MSAA 8 is free
- [ ] `grep -E ' E\] ' ~/.var/app/org.openmw.OpenMW/config/openmw/openmw.log` is empty

## 2. Game night

1. `./backup/backup_openmw_saves.sh`
2. **New character.** TR 26.08 is incompatible with pre-26.08 saves.
3. First hour: play, don't tune. Note anything odd, fix it next prep night.
4. Afterwards: `journalctl --user -u openmw-backup.service -n 5` to confirm
   the nightly backup (00:08 local) is landing.

## 3. Adding a mod (the repeatable way)

1. `./download_mods.py --files <nexus id>` — see what Nexus offers.
2. Add an entry to `config/nexus_manifest.json` (id, folder, file rules).
3. Add an extractor entry in `extract_mods.sh` (`extract_all` with the module
   globs; look at the archive with `7z l` first). Modding-OpenMW's mod page
   tells you which modules and plugins its lists take.
4. Add the folder to `DATA_ADDITIONS` and the plugins to `CONTENT_ESP` /
   `CONTENT_SCRIPTS` / `GROUNDCOVER` in `apply_config.py`, plus any settings
   key to `config/settings-tuning.cfg`.
5. `./download_mods.py && ./extract_mods.sh && python3 apply_config.py && ./check_setup.sh`
6. Row in `MODS.md`, status in `ROADMAP.md`, test drive, commit.

Removing one is the mirror: `CONTENT_REMOVE` / `GROUNDCOVER_REMOVE` in the
applier, park the archive in `mod_files/_not_used/`.

## 4. Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| Black screen / "failed to create GL context" | Flatpak NVIDIA ext ≠ host driver | `flatpak update`; `check_setup.sh` names the extension |
| Missing master on launch | plugin before its master, or master removed | `check_setup.sh` (runs `check_masters.py`) |
| Pink/yellow meshes or textures | data= path missing or wrong order | `check_setup.sh`; `apply_config.py` re-applies order |
| No grass | grass ESP in `content=`, or `[Groundcover] enabled` missing | `check_setup.sh` flags both |
| Windows don't glow at night | GitD not 2.11.2 | `MODS.md` 202 |
| Lua mod does nothing | no `content=<name>.omwscripts` | `check_setup.sh` warns per installed script |
| "Cell reference … not found" spam | a plugin deleted a vanilla record another mod uses | find it with the record scan in `TOOLS.md`; Waterfalls Tweaks was one |
| Menus at 1000+ FPS, GPU screaming | no framerate limit | `apply_config.py --refresh <Hz>` |
| Old save loads weird after TR upgrade | expected | new character |

If something breaks, disable newest additions first (content → music →
atmosphere → grass → graphics), never Tamriel_Data or TR once dependents are
active.
