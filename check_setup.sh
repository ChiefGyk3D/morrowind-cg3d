#!/bin/bash
set -euo pipefail

# OpenMW config health check.
# Validates openmw.cfg against the filesystem BEFORE you launch the game:
#   - every data=  path exists and is non-empty
#   - every content= plugin actually exists in some data path (case-insensitive,
#     the way OpenMW's VFS resolves it)
#   - every fallback-archive= BSA is findable
#   - duplicate content= entries
#   - known build issues (empty Glow in the Dahrk folder)
#
# Usage: ./check_setup.sh [path/to/openmw.cfg]
#        (defaults to the Flatpak config, then ~/.config/openmw/openmw.cfg)

CFG="${1:-}"
if [[ -z "$CFG" ]]; then
    for candidate in \
        "$HOME/.var/app/org.openmw.OpenMW/config/openmw/openmw.cfg" \
        "$HOME/.config/openmw/openmw.cfg"; do
        [[ -f "$candidate" ]] && CFG="$candidate" && break
    done
fi
if [[ -z "$CFG" || ! -f "$CFG" ]]; then
    echo "ERROR: openmw.cfg not found (looked in Flatpak and ~/.config paths)." >&2
    echo "Usage: $0 [path/to/openmw.cfg]" >&2
    exit 1
fi

echo "Checking: $CFG"
echo ""

ERRORS=0
WARNINGS=0

err()  { echo "  ERROR: $*";   ERRORS=$((ERRORS + 1)); }
warn() { echo "  WARNING: $*"; WARNINGS=$((WARNINGS + 1)); }

# Strip a data= value: remove surrounding quotes. openmw.cfg escapes '&' and '"'
# inside quoted values with '&' — flag those rather than mis-parse them.
strip_quotes() {
    local v="$1"
    v="${v%\"}"
    v="${v#\"}"
    printf '%s' "$v"
}

mapfile -t DATA_PATHS < <(grep '^data=' "$CFG" | sed 's/^data=//')
mapfile -t CONTENT < <(grep '^content=' "$CFG" | sed 's/^content=//')
mapfile -t ARCHIVES < <(grep '^fallback-archive=' "$CFG" | sed 's/^fallback-archive=//')

echo "--- data= paths (${#DATA_PATHS[@]}) ---"
GOOD_PATHS=()
for raw in "${DATA_PATHS[@]}"; do
    p=$(strip_quotes "$raw")
    if [[ "$p" == *"&"* ]]; then
        warn "data path contains '&' (openmw.cfg escape char) — verify by hand: $raw"
    fi
    if [[ ! -d "$p" ]]; then
        err "data path does not exist: $p"
        continue
    fi
    if [[ -z "$(find "$p" -mindepth 1 -print -quit 2>/dev/null)" ]]; then
        if [[ "$p" == *glow_in_the_dahrk* || "$p" == *202* ]]; then
            warn "Glow in the Dahrk folder is EMPTY (known issue — need v2.11.2 from Nexus Old files): $p"
        else
            err "data path is empty: $p"
        fi
        continue
    fi
    GOOD_PATHS+=("$p")
done
echo "  ${#GOOD_PATHS[@]} of ${#DATA_PATHS[@]} data paths OK."
echo ""

# Index every filename (lowercased, basename) across data paths, the way the
# VFS flattens them. Used for content= and fallback-archive= resolution.
INDEX_FILE=$(mktemp)
trap 'rm -f "$INDEX_FILE"' EXIT
if ((${#GOOD_PATHS[@]})); then
    find "${GOOD_PATHS[@]}" -maxdepth 1 -type f -printf '%f\n' 2>/dev/null \
        | tr '[:upper:]' '[:lower:]' | sort -u > "$INDEX_FILE"
fi

echo "--- content= plugins (${#CONTENT[@]}) ---"
FOUND=0
declare -A SEEN=()
for plugin in "${CONTENT[@]}"; do
    lower=$(printf '%s' "$plugin" | tr '[:upper:]' '[:lower:]')
    if [[ -n "${SEEN[$lower]:-}" ]]; then
        err "duplicate content= entry: $plugin"
        continue
    fi
    SEEN[$lower]=1
    # Base game masters live in the Morrowind Data Files dir OpenMW registers
    # from its own config machinery; don't fail on them if not in data= paths.
    case "$lower" in
        morrowind.esm|tribunal.esm|bloodmoon.esm)
            FOUND=$((FOUND + 1)); continue ;;
    esac
    if grep -qxF "$lower" "$INDEX_FILE"; then
        FOUND=$((FOUND + 1))
    else
        err "content= plugin not found in any data path: $plugin"
    fi
done
echo "  $FOUND of ${#CONTENT[@]} plugins resolved."
echo ""

echo "--- fallback-archive= BSAs (${#ARCHIVES[@]}) ---"
for bsa in "${ARCHIVES[@]}"; do
    lower=$(printf '%s' "$bsa" | tr '[:upper:]' '[:lower:]')
    case "$lower" in
        morrowind.bsa|tribunal.bsa|bloodmoon.bsa) continue ;;
    esac
    if ! grep -qxF "$lower" "$INDEX_FILE"; then
        err "fallback-archive not found in any data path: $bsa"
    fi
done
echo "  checked."
echo ""

# Build-specific sanity: mods that ship .omwscripts need their content= line
for scripts_name in harvest-lights.omwscripts distant-fixes-lua-edition.omwscripts; do
    if grep -qxF "$scripts_name" "$INDEX_FILE" 2>/dev/null; then
        if ! printf '%s\n' "${CONTENT[@]}" | tr '[:upper:]' '[:lower:]' | grep -qxF "$scripts_name"; then
            warn "$scripts_name is installed but has no content= line — the mod is inert."
        fi
    fi
done

echo ""
echo "--- OpenMW Flatpak + NVIDIA driver ---"
if command -v flatpak >/dev/null 2>&1; then
    omw_ver=$(flatpak info org.openmw.OpenMW 2>/dev/null | awk -F': *' '/^ *Version:/{print $2; exit}')
    if [[ -z "$omw_ver" ]]; then
        warn "org.openmw.OpenMW Flatpak not found for this user (native install? then ignore)"
    else
        echo "  OpenMW Flatpak version: $omw_ver"
        if [[ "$(printf '%s\n0.51\n' "$omw_ver" | sort -V | head -1)" != "0.51" ]]; then
            warn "OpenMW $omw_ver is older than 0.51 — run: flatpak update org.openmw.OpenMW"
        fi
    fi
    if command -v nvidia-smi >/dev/null 2>&1; then
        drv=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null | head -1 | tr -d ' ')
        if [[ -n "$drv" ]]; then
            ext="org.freedesktop.Platform.GL.nvidia-${drv//./-}"
            echo "  Host NVIDIA driver: $drv  (Flatpak needs extension $ext)"
            if flatpak list --runtime --columns=application 2>/dev/null | grep -qx "$ext"; then
                echo "  Matching Flatpak NVIDIA GL extension is installed."
            else
                err "Flatpak NVIDIA GL extension '$ext' NOT installed — the classic 'worked last week, black screen tonight' failure after a host driver update. Fix: flatpak update   (or: flatpak install flathub $ext)"
            fi
            if (( ${drv%%.*} < 570 )); then
                warn "Driver $drv is older than 570 — RTX 50-series (Blackwell) needs 570+."
            fi
        fi
    else
        echo "  nvidia-smi not found — skipping driver/extension match check."
    fi
else
    echo "  flatpak not found — skipping (native OpenMW install?)."
fi

SETTINGS="$(dirname "$CFG")/settings.cfg"
if [[ -f "$SETTINGS" ]]; then
    if ! grep -qE '^\s*framerate limit\s*=' "$SETTINGS"; then
        warn "settings.cfg has no 'framerate limit' — OpenMW runs uncapped (coil whine / heat in menus). See config/settings-tuning.cfg [Video]."
    fi
fi
echo ""

echo "=============================="
echo "RESULT: $ERRORS error(s), $WARNINGS warning(s)"
if (( ERRORS )); then
    echo "Fix errors before launching — missing plugins/paths mean missing masters or assets in-game."
    exit 1
fi
echo "Config looks launchable."
