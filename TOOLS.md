# TOOLS.md — the scripts in this repo, and the external tools

## Scripts in this repo

| Script | What it does | Run |
|---|---|---|
| `download_mods.py` | Nexus Mods API downloader (Premium). Reads `config/nexus_manifest.json`, resolves each rule to the newest matching file, skips what's already in `mod_files/` by name + size, verifies sizes / the GitLab pack's sha256. Key: `~/.config/nexusmods/apikey` (chmod 600) or `NEXUS_API_KEY`. | `--list` (resolve only), `--only <id or folder>`, `--force`, `--files <id…>` (dump what Nexus offers) |
| `extract_mods.sh` | Every archive in `mod_files/` → its numbered `mods/` folder, taking exactly the modules `MODS.md` lists. Newest matching archive wins; 0-byte and `.part` files ignored; Nexus's dash- and space-delimited names both match. Handles FOMOD numbered folders, `Data Files` wrappers, multi-download mods (`extract_all`), and per-mod deletions (Skies raindrops, bad normal maps). Prints a NOTES block of skipped optional modules. | `ARCHIVES_DIR=… MODS_DIR=…` to test elsewhere |
| `update_gitlab_mods.sh` | The 11 MOMW GitLab Lua mods at their latest tags, packaged like each project's own `pkg.sh`. | `all`, `core`, `qol`, or a name |
| `apply_config.py` | Applies the build to `openmw.cfg` + `settings.cfg`: `data=` for folders that exist, `content=` / `groundcover=` for plugins that exist (masters-safe placement, Lua scripts last), removals, Skies fallbacks, section-aware merge of `config/settings-tuning.cfg`. Idempotent; backs up first. | `--dry-run`, `--refresh <Hz>`, `--no-settings` |
| `check_setup.sh` | Pre-launch health check: every `data=` exists and is non-empty, every `content=` / `groundcover=` / `fallback-archive=` resolves, no plugin in both lists, `[Groundcover] enabled`, every installed `.omwscripts` enabled, master order (via `check_masters.py`), OpenMW ≥ 0.51, host NVIDIA driver ↔ Flatpak GL extension, framerate limit. 0 errors before launching. | |
| `check_masters.py` | Reads each plugin's TES3 header and verifies its masters load earlier. | `check_masters.py [openmw.cfg]` |
| `list_build.py` | Prints the live build: data order, Nexus IDs, file counts, plugins with enabled / groundcover / unused flags. | |
| `backup/backup_openmw_saves.sh` | Hardlink-deduplicated snapshots of saves + both configs, optional NAS mirror, systemd user timer. | `backup/README.md` |

Config inputs: `config/nexus_manifest.json` (what to download),
`config/settings-tuning.cfg` (what `settings.cfg` gets), `config/openmw-fallbacks-skies-iv.cfg`.

## External tools

### PLOX — load-order sorter

https://github.com/rfuzzo/plox · Nexus 54262. Rust rewrite of mlox that
understands `.omwaddon` / `.omwscripts`. Use it as a sanity check, not as an
authority: Modding-OpenMW hand-sorts its lists and warns that sorters break
them. `check_masters.py` covers the hard constraint (masters first); PLOX
catches soft ordering advice from the community rules.

### Delta Plugin — leveled-list and record merging

https://gitlab.com/portmod/delta-plugin (Linux binaries on the releases page;
also in the MOMW Tools Pack). Merges every mergeable record type, reading the
load order from `openmw.cfg`. Needed once several plugins touch the same
leveled lists (Yet Another Guard Diversity + Repopulated Morrowind, Wares,
Tamrielic Integrations, BCOM).

```bash
mkdir -p ~/mods/morrowind/mods/999_merged
# if re-running: remove the old content=merged.omwaddon line first
delta_plugin -c ~/.var/app/org.openmw.OpenMW/config/openmw/openmw.cfg \
    merge ~/mods/morrowind/mods/999_merged/merged.omwaddon
# then: data= for 999_merged LAST, content=merged.omwaddon LAST; re-run after any plugin change
```

Errors = the merge is incomplete. Warnings = real conflicts to patch, not ignore.

### tes3cmd, OpenMW-Validator

Both ship in the MOMW Tools Pack (https://gitlab.com/modding-openmw/momw-tools-pack).
The pack's Configurator pipeline does not support the Flatpak; the individual
CLIs run fine against the Flatpak config dir. `tes3cmd` is what a few MOMW
usage notes call for (cell deletes for TOTSP compatibility); OpenMW-Validator
is worth a run after any large plugin change.

## Flatpak OpenMW

```bash
flatpak run org.openmw.OpenMW               # play
flatpak run org.openmw.OpenMW --launcher    # launcher / settings UI
flatpak info org.openmw.OpenMW | grep Version
flatpak update org.openmw.OpenMW
flatpak override --user org.openmw.OpenMW --filesystem=$HOME/mods/morrowind:ro   # always name the app
```

| What | Path |
|---|---|
| Config | `~/.var/app/org.openmw.OpenMW/config/openmw/openmw.cfg`, `settings.cfg`, `shaders.yaml` |
| Log | `~/.var/app/org.openmw.OpenMW/config/openmw/openmw.log` |
| Saves | `~/.var/app/org.openmw.OpenMW/data/openmw/saves/` |
| Screenshots (F12) | `~/.var/app/org.openmw.OpenMW/data/openmw/screenshots/` |
| Override | `~/.local/share/flatpak/overrides/org.openmw.OpenMW` |

## Diagnostics

```bash
grep -E ' E\] ' ~/.var/app/org.openmw.OpenMW/config/openmw/openmw.log          # engine errors
grep -E ' W\] ' ~/.var/app/org.openmw.OpenMW/config/openmw/openmw.log | sort | uniq -c | sort -rn | head
7z l -ba -slt archive.7z | grep '^Path = ' | sed 's/^Path = //' | awk -F/ '{print $1}' | sort -u   # archive layout
```

Who deletes / defines a record (the Waterfalls Tweaks hunt): scan each plugin's
records for a `NAME` subrecord equal to the id and report the record type and
the deleted flag — `check_masters.py` has the TES3 record walker to copy.

## References

- Modding-OpenMW: https://modding-openmw.com/ (lists, per-mod usage notes, MOMW Patches)
- Expanded Vanilla list: https://modding-openmw.com/lists/expanded-vanilla/
- Tamriel Rebuilt: https://www.tamriel-rebuilt.org/ (recommended / incompatible mods pages)
- OpenMW settings reference: https://openmw.readthedocs.io/en/latest/reference/modding/settings/index.html
- Nexus API: https://app.swaggerhub.com/apis-docs/NexusMods/nexus-mods_public_api_params_in_form_data/1.0
