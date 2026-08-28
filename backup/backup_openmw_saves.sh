#!/bin/bash
set -euo pipefail

# OpenMW save backup — local hardlink-deduplicated snapshots + optional NAS sync.
# Run by hand or from the systemd timer in this directory (see backup/README.md).
#
# Snapshots use rsync --link-dest against the previous snapshot, so daily
# backups of unchanged saves cost almost no disk. openmw.cfg + settings.cfg are
# captured alongside each snapshot, since a save is only as good as the load
# order it was made with.
#
# Override any default below in ~/.config/openmw-backup.conf (plain bash,
# sourced if present) — keeps NAS hostnames/paths out of the git repo, e.g.:
#   NAS_DEST="user@nas.local:/volume1/backups/morrowind"
#   KEEP_SNAPSHOTS=60

FLATPAK_APP="$HOME/.var/app/org.openmw.OpenMW"
SAVES_DIR="$FLATPAK_APP/data/openmw/saves"
CONFIG_DIR="$FLATPAK_APP/config/openmw"
BACKUP_ROOT="$HOME/mods/morrowind/saves_backup_local"
NAS_DEST=""            # empty = skip NAS sync. MUST be a dedicated directory:
                       # the sync mirrors with --delete.
KEEP_SNAPSHOTS=30
LOCK_FILE="${XDG_RUNTIME_DIR:-/tmp}/openmw-backup.lock"

CONF="$HOME/.config/openmw-backup.conf"
# shellcheck source=/dev/null
[[ -f "$CONF" ]] && source "$CONF"

exec 9>"$LOCK_FILE"
if ! flock -n 9; then
    echo "Another backup is already running — exiting."
    exit 0
fi

command -v rsync >/dev/null 2>&1 || { echo "ERROR: rsync not found." >&2; exit 1; }

if [[ ! -d "$SAVES_DIR" ]] || \
   [[ -z "$(find "$SAVES_DIR" -mindepth 1 -name '*.omwsave' -print -quit 2>/dev/null)" ]]; then
    echo "No saves found in $SAVES_DIR — nothing to back up."
    exit 0
fi

STAMP=$(date +%Y%m%d-%H%M%S)
SNAP_DIR="$BACKUP_ROOT/$STAMP"
mkdir -p "$SNAP_DIR"

LINK_DEST=()
if [[ -d "$BACKUP_ROOT/latest/saves" ]]; then
    LINK_DEST=(--link-dest="$BACKUP_ROOT/latest/saves")
fi

echo "Backing up saves -> $SNAP_DIR"
rsync -a "${LINK_DEST[@]}" "$SAVES_DIR"/ "$SNAP_DIR/saves"/

mkdir -p "$SNAP_DIR/config"
for f in openmw.cfg settings.cfg; do
    [[ -f "$CONFIG_DIR/$f" ]] && cp -a "$CONFIG_DIR/$f" "$SNAP_DIR/config/"
done

ln -sfn "$SNAP_DIR" "$BACKUP_ROOT/latest"

# Prune old snapshots (dirs named by timestamp; 'latest' is a symlink, untouched)
mapfile -t SNAPSHOTS < <(find "$BACKUP_ROOT" -mindepth 1 -maxdepth 1 -type d -name '20*' | sort)
COUNT=${#SNAPSHOTS[@]}
if (( COUNT > KEEP_SNAPSHOTS )); then
    echo "Pruning to newest $KEEP_SNAPSHOTS snapshots..."
    for old in "${SNAPSHOTS[@]:0:COUNT-KEEP_SNAPSHOTS}"; do
        echo "  removing $old"
        rm -rf "$old"
    done
fi

if [[ -n "$NAS_DEST" ]]; then
    echo "Syncing to NAS: $NAS_DEST"
    # -H preserves the hardlink dedup on the NAS copy; --delete mirrors pruning
    if rsync -azH --delete "$BACKUP_ROOT"/ "$NAS_DEST"/; then
        echo "NAS sync OK."
    else
        echo "WARNING: NAS sync failed (rsync exit $?) — local snapshot is intact." >&2
        exit 2
    fi
fi

echo "Backup complete: $SNAP_DIR"
