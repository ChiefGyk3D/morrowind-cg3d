# OpenMW Save Backups

> **STATUS: TESTING — YMMV.** Script smoke-tested with fake data; run one
> manual backup and inspect the snapshot before trusting the timer.

Automated backups of OpenMW saves (plus the `openmw.cfg` / `settings.cfg` they
were made with) to hardlink-deduplicated local snapshots, optionally mirrored
to a NAS. Fulfills the "rsync to local + NAS with systemd timer" roadmap item.

## What it does

- `backup_openmw_saves.sh` snapshots
  `~/.var/app/org.openmw.OpenMW/data/openmw/saves/` into
  `~/mods/morrowind/saves_backup_local/<timestamp>/saves/` using rsync
  `--link-dest` against the previous snapshot — unchanged saves are hardlinks,
  so 30 daily snapshots cost barely more than one.
- Copies `openmw.cfg` + `settings.cfg` into each snapshot's `config/` — a save
  is only restorable against the load order it was made with.
- Maintains a `latest` symlink, prunes to the newest 30 snapshots.
- If `NAS_DEST` is set, mirrors the whole snapshot tree to the NAS with
  `rsync -azH --delete` (hardlinks preserved).
- `flock` guard prevents overlapping runs; exits cleanly (and quietly) when
  there are no saves yet.

The `saves_backup_*` pattern is already in `.gitignore`, so snapshots never
land in git.

## Setup

1. **Configure the NAS target** (optional — skipped when unset). Keep it out of
   git via the config file:

   ```bash
   cat > ~/.config/openmw-backup.conf <<'EOF'
   NAS_DEST="user@nas.local:/volume1/backups/morrowind"
   # KEEP_SNAPSHOTS=60
   EOF
   ```

   `NAS_DEST` must be a **dedicated directory** — the sync mirrors with
   `--delete`. SSH key auth should already be set up for the NAS
   (`ssh-copy-id user@nas.local`).

2. **Test a manual run**:

   ```bash
   ~/mods/morrowind/backup/backup_openmw_saves.sh
   ls -l ~/mods/morrowind/saves_backup_local/
   ```

3. **Install the systemd user units**:

   ```bash
   mkdir -p ~/.config/systemd/user
   cp ~/mods/morrowind/backup/openmw-backup.{service,timer} ~/.config/systemd/user/
   systemctl --user daemon-reload
   systemctl --user enable --now openmw-backup.timer
   systemctl --user list-timers openmw-backup.timer
   ```

4. **Logs / verification**:

   ```bash
   journalctl --user -u openmw-backup.service -n 30
   systemctl --user start openmw-backup.service   # fire one off manually
   ```

Notes:
- `Persistent=true` means a missed run (machine off at the scheduled time)
  fires at next boot/login.
- Timers for a user session run while you're logged in. To run without an
  active session (headless box): `loginctl enable-linger $USER`.
- Want more than daily? Edit `OnCalendar=` (e.g. `OnCalendar=*-*-* 00/6:00:00`
  for every 6 hours), then `systemctl --user daemon-reload`.

## Restoring

```bash
# Latest snapshot back into OpenMW (add --delete to remove newer saves too):
rsync -a ~/mods/morrowind/saves_backup_local/latest/saves/ \
         ~/.var/app/org.openmw.OpenMW/data/openmw/saves/

# Or cherry-pick a save from a specific snapshot:
ls ~/mods/morrowind/saves_backup_local/
cp ~/mods/morrowind/saves_backup_local/<timestamp>/saves/<character>/<save>.omwsave \
   ~/.var/app/org.openmw.OpenMW/data/openmw/saves/<character>/
```

The snapshot's `config/openmw.cfg` records exactly which plugins that save
expects — diff it against your live config if a restored save misbehaves.
