#!/bin/bash
set -euo pipefail

# Morrowind Mod Extraction Script
# Extracts each archive into its numbered mod folder with correct structure.
# Each mod folder must have game data (meshes/, textures/, .esp, .esm) at root.
#
# Safe to re-run: skips missing archives with a warning instead of aborting,
# and reports any mod folder that ended up empty at the end.
#
# Archive matching: entries use GLOBS (newest matching file wins), so a
# re-downloaded Tamriel Rebuilt / Tamriel_Data / etc. is picked up without
# editing this script. Nexus filenames look like "<Name>-<id>-<ver>-<ts>.7z".
#
# Sections:
#   BASELINE   (Tiers 1-3 + Repopulated) — the March 2026 build, required
#   ADDITIONS  (2026-09 enhancement plan)  — optional; a missing archive is
#                                            reported as "not downloaded", not
#                                            as an error

ARCHIVES="${ARCHIVES_DIR:-$HOME/mods/morrowind/mod_files}"
MODS="${MODS_DIR:-$HOME/mods/morrowind/mods}"

ISSUES=()
NOTES=()

require_tool() {
    command -v "$1" >/dev/null 2>&1 || {
        echo "ERROR: required tool '$1' not found. Install it first ($2)." >&2
        exit 1
    }
}

require_tool 7z "e.g. sudo apt install p7zip-full"
require_tool unrar "e.g. sudo apt install unrar"

if [[ ! -d "$ARCHIVES" ]]; then
    echo "ERROR: archive directory not found: $ARCHIVES" >&2
    echo "Download the archives listed in mod-list.txt there first." >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# find_archive GLOB -> prints newest matching file in $ARCHIVES (empty if none)
find_archive() {
    local glob="$1"
    find "$ARCHIVES" -maxdepth 1 -type f -iname "$glob" -printf '%T@ %p\n' 2>/dev/null \
        | sort -rn | head -1 | cut -d' ' -f2-
}

# have_archive GLOB LABEL [optional]
# Sets $ARCHIVE on success. Missing required archives are ISSUES; missing
# optional ones are NOTES (the enhancement additions are all optional).
ARCHIVE=""
have_archive() {
    local glob="$1" label="$2" optional="${3:-}"
    ARCHIVE=$(find_archive "$glob")
    if [[ -z "$ARCHIVE" ]]; then
        if [[ -n "$optional" ]]; then
            echo "  (not downloaded — skipping; pattern: $glob)"
            NOTES+=("$label: not downloaded (looked for '$glob')")
        else
            echo "  MISSING ARCHIVE: no file matching '$glob' — skipping."
            ISSUES+=("$label: archive not found (looked for '$glob')")
        fi
        return 1
    fi
    echo "  Archive: $(basename "$ARCHIVE")"
}

# 7z/cp failures are tolerated per-step, so an empty folder is the symptom of
# a bad extraction (wrong FOMOD prefix, corrupt archive). Catch it here.
verify() {
    local target="$1" label="$2"
    if [[ -z "$(find "$target" -mindepth 1 -print -quit 2>/dev/null)" ]]; then
        echo "  WARNING: $target is empty — extraction likely failed."
        ISSUES+=("$label: no files extracted into $target")
    fi
}

# Extract any archive type to a directory (7z handles 7z/zip; unrar for rar)
extract_any() {
    local archive="$1" dest="$2"
    mkdir -p "$dest"
    case "${archive,,}" in
        *.rar) unrar x -o+ "$archive" "$dest/" > /dev/null 2>&1 || true ;;
        *)     7z x "$archive" -o"$dest" -r -y > /dev/null 2>&1 || true ;;
    esac
}

# Helper: extract FOMOD "00 Core" style folders into target dir
# Usage: extract_fomod ARCHIVE TARGET_DIR FOLDER_PREFIX...
extract_fomod() {
    local archive="$1"
    local target="$2"
    shift 2
    local tmpdir
    tmpdir=$(mktemp -d)
    mkdir -p "$target"
    for prefix in "$@"; do
        7z x "$archive" -o"$tmpdir" "${prefix}/*" -r -y > /dev/null 2>&1 || true
        if [[ -d "$tmpdir/$prefix" ]]; then
            cp -a "$tmpdir/$prefix"/. "$target"/
        else
            echo "  WARNING: '$prefix' not found in $(basename "$archive")"
            ISSUES+=("$(basename "$target"): FOMOD folder '$prefix' missing from archive")
        fi
    done
    rm -rf "$tmpdir"
}

# Helper: extract "Data Files/" wrapper
extract_datafiles() {
    local archive="$1"
    local target="$2"
    local tmpdir
    tmpdir=$(mktemp -d)
    mkdir -p "$target"
    extract_any "$archive" "$tmpdir"
    if [[ -d "$tmpdir/Data Files" ]]; then
        cp -a "$tmpdir/Data Files"/. "$target"/
    fi
    rm -rf "$tmpdir"
}

# Helper: extract named wrapper folder
extract_named() {
    local archive="$1"
    local target="$2"
    local folder="$3"
    local tmpdir
    tmpdir=$(mktemp -d)
    mkdir -p "$target"
    extract_any "$archive" "$tmpdir"
    if [[ -d "$tmpdir/$folder" ]]; then
        cp -a "$tmpdir/$folder"/. "$target"/
    fi
    rm -rf "$tmpdir"
}

# Is this directory a mod data root? (game data folders or plugin files at top)
is_data_root() {
    local d="$1"
    find "$d" -maxdepth 1 \( -iname meshes -o -iname textures -o -iname icons -o -iname fonts \
        -o -iname sound -o -iname music -o -iname splash -o -iname bookart -o -iname shaders \
        -o -iname scripts -o -iname l10n -o -iname '*.esp' -o -iname '*.esm' \
        -o -iname '*.omwaddon' -o -iname '*.omwscripts' -o -iname '*.bsa' \) -print -quit 2>/dev/null \
        | grep -q .
}

# extract_auto ARCHIVE TARGET
# For archives whose exact layout we haven't audited. Detects, in order:
#   1. "Data Files/" wrapper                  -> copy its contents
#   2. FOMOD-style numbered folders           -> copy "00 *" (core) folders,
#      list the optional ones for manual review
#   3. single wrapper folder                  -> descend and re-check
#   4. game data at archive root              -> copy flat
# Prints what it found so the result can be sanity-checked against the readme.
extract_auto() {
    local archive="$1" target="$2"
    shift 2
    local extra_globs=("$@")   # optional FOMOD folder globs to ALSO copy
    local tmpdir root
    tmpdir=$(mktemp -d)
    mkdir -p "$target"
    extract_any "$archive" "$tmpdir"
    root="$tmpdir"

    # 3. unwrap single top-level folder (possibly nested) unless it's a data root
    while :; do
        local entries
        mapfile -t entries < <(find "$root" -mindepth 1 -maxdepth 1 -not -name '__MACOSX' -not -name 'fomod')
        if (( ${#entries[@]} == 1 )) && [[ -d "${entries[0]}" ]] && ! is_data_root "$root"; then
            root="${entries[0]}"
        else
            break
        fi
    done

    if [[ -d "$root/Data Files" ]]; then
        echo "  Layout: 'Data Files/' wrapper"
        cp -a "$root/Data Files"/. "$target"/
    elif compgen -G "$root/00 *" > /dev/null; then
        echo "  Layout: FOMOD-style numbered folders"
        local core optional=()
        for core in "$root"/00\ *; do
            echo "    + $(basename "$core")"
            cp -a "$core"/. "$target"/
        done
        local d g want
        for d in "$root"/*/; do
            d=${d%/}
            [[ "$(basename "$d")" == 00\ * || "$(basename "$d")" == fomod ]] && continue
            want=0
            for g in "${extra_globs[@]}"; do
                # shellcheck disable=SC2053
                [[ "$(basename "$d")" == $g ]] && want=1
            done
            if (( want )); then
                echo "    + $(basename "$d") (requested module)"
                cp -a "$d"/. "$target"/
            else
                optional+=("$(basename "$d")")
            fi
        done
        if (( ${#optional[@]} )); then
            echo "    optional folders NOT copied (review readme, copy manually if wanted):"
            printf '      - %s\n' "${optional[@]}"
            NOTES+=("$(basename "$target"): optional FOMOD folders not copied: $(IFS=';'; echo "${optional[*]}")")
        fi
    elif is_data_root "$root"; then
        echo "  Layout: flat (data at root)"
        cp -a "$root"/. "$target"/
    else
        echo "  WARNING: could not recognise layout — extracted as-is for manual sorting."
        cp -a "$root"/. "$target"/
        ISSUES+=("$(basename "$target"): unrecognised archive layout, needs manual sorting")
    fi
    rm -rf "$tmpdir"
}

echo "=========================================="
echo "MORROWIND MOD EXTRACTION"
echo "  archives: $ARCHIVES"
echo "  mods:     $MODS"
echo "=========================================="

# ===========================================================================
# BASELINE — TIER 1
# ===========================================================================

echo "[1/21] 001 Patch for Purists (flat structure)..."
if have_archive "Patch for Purists-45096-*" "001 Patch for Purists"; then
    7z x "$ARCHIVE" -o"$MODS/001_patch_for_purists" -r -y > /dev/null 2>&1 || true
    verify "$MODS/001_patch_for_purists" "001 Patch for Purists"
    echo "  Done."
fi

echo "[2/21] 002 UMOPP Merged + Compatibility ESP..."
if have_archive "Unofficial Morrowind Official Plugins Patched-43931-*" "002 UMOPP"; then
    extract_fomod "$ARCHIVE" "$MODS/002_umopp" \
        "08 UMOPP Merged" "09 UMOPP Compatibility Merged"
    # The 09 Compat ESP overwrites the 08 ESP (same filename), giving us PfP-compatible version
    verify "$MODS/002_umopp" "002 UMOPP"
    echo "  Done."
fi

echo "[3/21] 003 Expansion Delay (flat structure)..."
if have_archive "Expansion Delay-47588-*" "003 Expansion Delay"; then
    7z x "$ARCHIVE" -o"$MODS/003_expansion_delay" -r -y > /dev/null 2>&1 || true
    verify "$MODS/003_expansion_delay" "003 Expansion Delay"
    echo "  Done."
fi

echo "[4/21] 004 Morrowind Optimization Patch..."
if have_archive "Morrowind Optimization Patch-45384-*" "004 MOP"; then
    extract_fomod "$ARCHIVE" "$MODS/004_morrowind_optimization_patch" "00 Core"
    verify "$MODS/004_morrowind_optimization_patch" "004 MOP"
    echo "  Done."
fi

echo "[5/21] 005 Tamriel Data (HD) — ~2.2GB, please wait (newest download wins: 26.08 required by TR 26.08)..."
if have_archive "Tamriel Data (HD)-44537-*" "005 Tamriel Data"; then
    extract_fomod "$ARCHIVE" "$MODS/005_tamriel_data" "00 Data Files"
    verify "$MODS/005_tamriel_data" "005 Tamriel Data"
    echo "  Done."
fi

echo "[6/21] 006 Tamriel Rebuilt (newest download wins: 26.08 'Poison Song')..."
if have_archive "Tamriel Rebuilt*-42145-*" "006 Tamriel Rebuilt"; then
    extract_fomod "$ARCHIVE" "$MODS/006_tamriel_rebuilt" "00 Core"
    verify "$MODS/006_tamriel_rebuilt" "006 Tamriel Rebuilt"
    echo "  Done."
fi

# ===========================================================================
# BASELINE — TIER 2
# ===========================================================================

echo "[7/21] 101 Graphic Herbalism..."
if have_archive "Graphic Herbalism MWSE - OpenMW-46599-*" "101 Graphic Herbalism"; then
    extract_fomod "$ARCHIVE" "$MODS/101_graphic_herbalism" "00 Core + Vanilla Meshes"
    verify "$MODS/101_graphic_herbalism" "101 Graphic Herbalism"
    echo "  Done."
fi

echo "[8/21] 102 Harvest Lights — handled by update_gitlab_mods.sh (pulls latest tag from GitLab)."
if [[ -f "$ARCHIVES/harvest-lights.zip" && ! -f "$MODS/102_harvest_lights/version.txt" ]]; then
    echo "  Found a manual harvest-lights.zip and no updater install — extracting it as a fallback."
    7z x "$ARCHIVES/harvest-lights.zip" -o"$MODS/102_harvest_lights" -r -y > /dev/null 2>&1 || true
    verify "$MODS/102_harvest_lights" "102 Harvest Lights"
fi

echo "[9/21] 103 Weapon Sheathing..."
if have_archive "WeaponSheathing*-46069-*" "103 Weapon Sheathing"; then
    extract_datafiles "$ARCHIVE" "$MODS/103_weapon_sheathing"
    verify "$MODS/103_weapon_sheathing" "103 Weapon Sheathing"
    echo "  Done."
fi

echo "[10/21] 104 Project Atlas..."
if have_archive "Project Atlas-45399-*" "104 Project Atlas"; then
    extract_fomod "$ARCHIVE" "$MODS/104_project_atlas" "00 Core"
    verify "$MODS/104_project_atlas" "104 Project Atlas"
    echo "  Done."
fi

echo "[11/21] 105 Morrowind Enhanced Textures — ~2.4GB, please wait..."
if have_archive "Morrowind Enhanced Textures*-46221-*" "105 MET"; then
    extract_named "$ARCHIVE" "$MODS/105_morrowind_enhanced_textures" "MET 6-1 main"
    verify "$MODS/105_morrowind_enhanced_textures" "105 MET"
    echo "  Done."
fi

echo "[12/21] 106 Familiar Faces..."
if have_archive "Familiar Faces-50093-*" "106 Familiar Faces"; then
    tmpdir=$(mktemp -d)
    7z x "$ARCHIVE" -o"$tmpdir" -r -y > /dev/null 2>&1 || true
    # Copy main Meshes/ folder (at root), skip optional subfolder
    mkdir -p "$MODS/106_familiar_faces"
    if [[ -d "$tmpdir/Meshes" ]]; then
        cp -a "$tmpdir/Meshes" "$MODS/106_familiar_faces/"
    fi
    rm -rf "$tmpdir"
    verify "$MODS/106_familiar_faces" "106 Familiar Faces"
    echo "  Done."
fi

# ===========================================================================
# BASELINE — TIER 3
# ===========================================================================

echo "[13/21] 201 Containers Animated..."
if have_archive "OpenMW Containers Animated-46232-*" "201 Containers Animated"; then
    extract_named "$ARCHIVE" "$MODS/201_containers_animated" "Containers Animated"
    verify "$MODS/201_containers_animated" "201 Containers Animated"
    echo "  Done."
fi

echo "[14/21] 202 Glow in the Dahrk — v2.11.2 ONLY (OpenMW does not support 3.x light rays)..."
if have_archive "Glow in the Dahrk-45886-2-11-2-*" "202 Glow in the Dahrk 2.11.2"; then
    extract_auto "$ARCHIVE" "$MODS/202_glow_in_the_dahrk"
    verify "$MODS/202_glow_in_the_dahrk" "202 Glow in the Dahrk"
    echo "  Done."
else
    if [[ -n "$(find_archive 'Glow in the Dahrk-45886-3-*')" ]]; then
        echo "  *** A GitD 3.x archive is present but is NOT usable on OpenMW. ***"
    fi
    echo "  *** Download v2.11.2 from Nexus 45886 -> Files -> Old files, re-run. ***"
fi

echo "[15/21] 203 Nords Shut Your Windows (Core + Purist option)..."
if have_archive "Nords shut your windows-50087-*" "203 Nords Shut Your Windows"; then
    tmpdir=$(mktemp -d)
    extract_any "$ARCHIVE" "$tmpdir"
    # Core has textures + base meshes, Purist has simpler replacement meshes
    mkdir -p "$MODS/203_nords_shut_your_windows"
    if [[ -d "$tmpdir/00 Core" ]]; then
        cp -a "$tmpdir/00 Core"/. "$MODS/203_nords_shut_your_windows"/
    fi
    if [[ -d "$tmpdir/04 Purist" ]]; then
        cp -a "$tmpdir/04 Purist"/. "$MODS/203_nords_shut_your_windows"/
    fi
    rm -rf "$tmpdir"
    verify "$MODS/203_nords_shut_your_windows" "203 Nords Shut Your Windows"
    echo "  Done."
fi

echo "[16/21] 204 TrueType Fonts..."
if have_archive "Fonts-46854-*" "204 TrueType Fonts"; then
    extract_named "$ARCHIVE" "$MODS/204_truetype_fonts" "Fonts"
    verify "$MODS/204_truetype_fonts" "204 TrueType Fonts"
    echo "  Done."
fi

echo "[17/21] 205 Cantons on the Global Map..."
if have_archive "Cantons_on_the_Global_Map*-50534-*" "205 Cantons"; then
    extract_datafiles "$ARCHIVE" "$MODS/205_cantons_global_map"
    verify "$MODS/205_cantons_global_map" "205 Cantons"
    echo "  Done."
fi

echo "[18/21] 206 Distant Seafloor..."
if have_archive "Distant_Seafloor*-50796-*" "206 Distant Seafloor"; then
    extract_fomod "$ARCHIVE" "$MODS/206_distant_seafloor" "00 Core"
    verify "$MODS/206_distant_seafloor" "206 Distant Seafloor"
    echo "  Done."
fi

echo "[19/21] 207 Distant Fixes Lua Edition — handled by update_gitlab_mods.sh (pulls latest tag from GitLab)."
if [[ -f "$ARCHIVES/distant-fixes-lua-edition.zip" && ! -f "$MODS/207_distant_fixes_lua/version.txt" ]]; then
    echo "  Found a manual zip and no updater install — extracting it as a fallback."
    7z x "$ARCHIVES/distant-fixes-lua-edition.zip" -o"$MODS/207_distant_fixes_lua" -r -y > /dev/null 2>&1 || true
    verify "$MODS/207_distant_fixes_lua" "207 Distant Fixes Lua"
fi

# ===========================================================================
# BASELINE — REPOPULATED + OAAB
# ===========================================================================

echo "[20/21] 301 Repopulated Morrowind (Core + main + Bloodmoon + TR)..."
if have_archive "Repopulated Morrowind-51174-*" "301 Repopulated Morrowind"; then
    extract_fomod "$ARCHIVE" "$MODS/301_repopulated_morrowind" \
        "00 Core" "01 Repopulated Morrowind" "03 Bloodmoon" "05 Tamriel Rebuilt"
    verify "$MODS/301_repopulated_morrowind" "301 Repopulated Morrowind"
    echo "  NOTE: leave RepopulatedMainland.ESP OUT of content= until RM confirms TR 26.08 support."
    echo "  Done."
fi

echo "[21/21] 302 Repopulated Creatures..."
if have_archive "Repopulated Creatures-55628-*" "302 Repopulated Creatures"; then
    tmpdir=$(mktemp -d)
    7z x "$ARCHIVE" -o"$tmpdir" -r -y > /dev/null 2>&1 || true
    mkdir -p "$MODS/302_repopulated_creatures"
    if [[ -d "$tmpdir/Repopulated Creatures/Data Files" ]]; then
        cp -a "$tmpdir/Repopulated Creatures/Data Files"/. "$MODS/302_repopulated_creatures"/
    fi
    rm -rf "$tmpdir"
    verify "$MODS/302_repopulated_creatures" "302 Repopulated Creatures"
    echo "  Done."
fi

echo ""
echo "[BONUS] OAAB_Data..."
if have_archive "OAAB_Data-49042-*" "OAAB_Data"; then
    extract_fomod "$ARCHIVE" "$MODS/OAAB_Data" "00 Core"
    verify "$MODS/OAAB_Data" "OAAB_Data"
    echo "  Done."
fi

# ===========================================================================
# ADDITIONS — 2026-09 enhancement plan (all optional; see enhancement_plan_2026-08.md
# and GAME_NIGHT_RUNBOOK.md). Layouts not yet audited -> extract_auto + review.
# ===========================================================================

echo ""
echo "------------------------------------------"
echo "ADDITIONS (optional — enhancement plan)"
echo "------------------------------------------"

echo "[ADD] 401 MOMW Post Processing Pack (each numbered folder is its own data= path)..."
if have_archive "momw-post-processing-pack*.zip" "401 MOMW Post Processing Pack" optional; then
    tmpdir=$(mktemp -d)
    extract_any "$ARCHIVE" "$tmpdir"
    mkdir -p "$MODS/401_momw_post_processing_pack"
    # Keep the numbered folders separate (that is how MOMW registers them);
    # 00 RecommendedConfig holds shaders.yaml for the OpenMW config dir.
    for d in "$tmpdir"/*/; do
        d=${d%/}
        [[ "$(basename "$d")" == "web" ]] && continue
        cp -a "$d" "$MODS/401_momw_post_processing_pack/"
        echo "    + $(basename "$d")"
    done
    rm -rf "$tmpdir"
    verify "$MODS/401_momw_post_processing_pack" "401 MOMW Post Processing Pack"
    echo "  Register data= lines for 01/02/03/04/07 folders; copy '00 RecommendedConfig/shaders.yaml'"
    echo "  to ~/.var/app/org.openmw.OpenMW/config/openmw/ (see runbook)."
    echo "  Done."
fi

echo "[ADD] 402 Lush Synthesis (groundcover — register ESPs as groundcover= lines, NOT content=)..."
if have_archive "Lush Synthesis*-52931-*" "402 Lush Synthesis" optional; then
    # TR grass module unblocked by MOMW 2026-09-04 — include it
    extract_auto "$ARCHIVE" "$MODS/402_lush_synthesis" "*Tamriel Rebuilt*" "*TR*"
    verify "$MODS/402_lush_synthesis" "402 Lush Synthesis"
    echo "  Done."
fi

echo "[ADD] 403 Remiros' Groundcover (Ashlands / Solstheim modules — groundcover= lines)..."
if have_archive "Remiros*Groundcover*-46733-*" "403 Remiros Groundcover" optional; then
    extract_auto "$ARCHIVE" "$MODS/403_remiros_groundcover"
    verify "$MODS/403_remiros_groundcover" "403 Remiros Groundcover"
    echo "  Done."
fi

echo "[ADD] 404 Remiros Groundcover Textures Improvement..."
if have_archive "*Groundcover Textures Improvement*-54261-*" "404 Remiros Groundcover Textures" optional; then
    extract_auto "$ARCHIVE" "$MODS/404_remiros_groundcover_textures"
    verify "$MODS/404_remiros_groundcover_textures" "404 Remiros Groundcover Textures"
    echo "  Done."
fi

echo "[ADD] 405 Skies .IV (+ OpenMW fixups: raindrop files removed automatically)..."
if have_archive "Skies*-43311-*" "405 Skies IV" optional; then
    extract_auto "$ARCHIVE" "$MODS/405_skies_iv"
    # MOMW usage notes: these two files break on OpenMW
    find "$MODS/405_skies_iv" -ipath '*particles/meshes/raindrop.nif' -delete 2>/dev/null || true
    find "$MODS/405_skies_iv" -ipath '*particles/textures/tx_raindrop_01.dds' -delete 2>/dev/null || true
    echo "  Removed Particles raindrop.nif / tx_raindrop_01.dds (OpenMW fix)."
    echo "  Add config/openmw-fallbacks-skies-iv.cfg lines to openmw.cfg."
    verify "$MODS/405_skies_iv" "405 Skies IV"
    echo "  Done."
fi

echo "[ADD] 406 New Starfields..."
if have_archive "New Starfields*-43246-*" "406 New Starfields" optional; then
    extract_auto "$ARCHIVE" "$MODS/406_new_starfields"
    verify "$MODS/406_new_starfields" "406 New Starfields"
    echo "  Done."
fi

echo "[ADD] 407 Normal Maps for Morrowind..."
if have_archive "Normal Maps for Morrowind*-45336-*" "407 Normal Maps for Morrowind" optional; then
    extract_auto "$ARCHIVE" "$MODS/407_normal_maps_for_morrowind"
    verify "$MODS/407_normal_maps_for_morrowind" "407 Normal Maps for Morrowind"
    echo "  Done."
fi

echo "[ADD] 408 Normal Maps for Everything (modules matching OUR texture stack only)..."
if have_archive "Normal Maps for Everything*-52567-*" "408 Normal Maps for Everything" optional; then
    tmpdir=$(mktemp -d)
    extract_any "$ARCHIVE" "$tmpdir"
    mkdir -p "$MODS/408_normal_maps_for_everything"
    # Unwrap a single top-level wrapper folder if present
    nmroot="$tmpdir"
    mapfile -t _top < <(find "$nmroot" -mindepth 1 -maxdepth 1 -not -name '__MACOSX')
    if (( ${#_top[@]} == 1 )) && [[ -d "${_top[0]}" ]]; then nmroot="${_top[0]}"; fi
    # Ship-with-modules pack: copy only modules for packs we actually run.
    # Everything else is listed so it can be reviewed against MOMW usage notes.
    copied=0
    while IFS= read -r -d '' d; do
        name=$(basename "$d")
        case "${name,,}" in
            *enhanced\ textures*|*met*|*atlas*|*tamriel_data*|*tamriel\ data*|*oaab*|*core*|*vanilla*)
                echo "    + $name"; cp -a "$d"/. "$MODS/408_normal_maps_for_everything"/; copied=$((copied+1)) ;;
            *bcom*|*beautiful*|*hall\ of\ justice*|fomod)
                echo "    - $name (skipped: not in our stack / pulled pending TR 26.08)" ;;
            *)
                echo "    ? $name (skipped: unknown module — review)" ;;
        esac
    done < <(find "$nmroot" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)
    rm -rf "$tmpdir"
    if (( copied == 0 )); then
        ISSUES+=("408 Normal Maps for Everything: no modules matched our stack — extract manually")
    fi
    verify "$MODS/408_normal_maps_for_everything" "408 Normal Maps for Everything"
    echo "  REMEMBER: delete the known-bad *_n.dds files per MOMW usage notes (see runbook)."
    echo "  Done."
fi

echo "[ADD] 409 GitD Normal Specular PBR Maps..."
if have_archive "*Glow in the Dahrk*Normal*-58029-*" "409 GitD PBR Maps" optional; then
    extract_auto "$ARCHIVE" "$MODS/409_gitd_normal_pbr"
    verify "$MODS/409_gitd_normal_pbr" "409 GitD PBR Maps"
    echo "  Done."
fi

echo "[ADD] 410 Facelift for Tamriel Data..."
if have_archive "Facelift for Tamriel Data*-53935-*" "410 Facelift for Tamriel Data" optional; then
    extract_auto "$ARCHIVE" "$MODS/410_facelift_tamriel_data"
    verify "$MODS/410_facelift_tamriel_data" "410 Facelift for Tamriel Data"
    echo "  Done."
fi

echo "[ADD] 411 Morrowind Interiors Project..."
if have_archive "Morrowind Interiors Project*-52237-*" "411 Morrowind Interiors Project" optional; then
    extract_auto "$ARCHIVE" "$MODS/411_morrowind_interiors_project"
    verify "$MODS/411_morrowind_interiors_project" "411 Morrowind Interiors Project"
    echo "  Done."
fi

echo "[ADD] 412 Better Waterfalls..."
if have_archive "Better Waterfalls*-45424-*" "412 Better Waterfalls" optional; then
    extract_auto "$ARCHIVE" "$MODS/412_better_waterfalls"
    verify "$MODS/412_better_waterfalls" "412 Better Waterfalls"
    echo "  Done."
fi

echo "[ADD] 413 Waterfalls Tweaks..."
if have_archive "Waterfalls Tweaks*-46271-*" "413 Waterfalls Tweaks" optional; then
    extract_auto "$ARCHIVE" "$MODS/413_waterfalls_tweaks"
    verify "$MODS/413_waterfalls_tweaks" "413 Waterfalls Tweaks"
    echo "  Done."
fi

echo "[ADD] 414 OpenMW More Dynamic Water Meshes..."
if have_archive "*More Dynamic Water Meshes*-55392-*" "414 More Dynamic Water Meshes" optional; then
    extract_auto "$ARCHIVE" "$MODS/414_more_dynamic_water_meshes"
    verify "$MODS/414_more_dynamic_water_meshes" "414 More Dynamic Water Meshes"
    echo "  Done."
fi

echo "[ADD] 415 Improved Lights for All Shaders (set 'clamp lighting = false')..."
if have_archive "Improved Lights for All Shaders*-51463-*" "415 Improved Lights for All Shaders" optional; then
    extract_auto "$ARCHIVE" "$MODS/415_improved_lights_all_shaders"
    verify "$MODS/415_improved_lights_all_shaders" "415 Improved Lights for All Shaders"
    echo "  Done."
fi

echo "[ADD] 416 Kirel's Interior Weather..."
if have_archive "Kirel*Interior Weather*-49278-*" "416 Kirel's Interior Weather" optional; then
    extract_auto "$ARCHIVE" "$MODS/416_kirels_interior_weather"
    verify "$MODS/416_kirels_interior_weather" "416 Kirel's Interior Weather"
    echo "  Done."
fi

echo "[ADD] 417 OAAB Saplings + OpenMW groundcover patch..."
if have_archive "OAAB*Saplings*-50334-*" "417 OAAB Saplings" optional; then
    extract_auto "$ARCHIVE" "$MODS/417_oaab_saplings"
    verify "$MODS/417_oaab_saplings" "417 OAAB Saplings"
    echo "  Done."
fi
if have_archive "*Saplings*Groundcover*-52351-*" "417b OAAB Saplings groundcover patch" optional; then
    extract_auto "$ARCHIVE" "$MODS/417_oaab_saplings"
    echo "  Done."
fi

echo "[ADD] 501 LDM - Context Matters..."
if have_archive "*Context Matters*" "501 LDM Context Matters" optional; then
    extract_auto "$ARCHIVE" "$MODS/501_ldm_context_matters"
    verify "$MODS/501_ldm_context_matters" "501 LDM Context Matters"
    echo "  Done."
fi

echo "[ADD] 502 Protective Guards (OpenMW) + 503 Factions and NPCs Protections..."
if have_archive "Protective Guards*-46992-*" "502 Protective Guards" optional; then
    extract_auto "$ARCHIVE" "$MODS/502_protective_guards"
    verify "$MODS/502_protective_guards" "502 Protective Guards"
    echo "  Done."
fi
if have_archive "*Protections*-54858-*" "503 Protective Guards Factions add-on" optional; then
    extract_auto "$ARCHIVE" "$MODS/503_protective_guards_factions"
    verify "$MODS/503_protective_guards_factions" "503 Protective Guards Factions add-on"
    echo "  Done."
fi

echo "[ADD] 504 Book Jackets Complete Collection HD..."
if have_archive "Book Jackets*-55402-*" "504 Book Jackets HD" optional; then
    extract_auto "$ARCHIVE" "$MODS/504_book_jackets_hd"
    verify "$MODS/504_book_jackets_hd" "504 Book Jackets HD"
    echo "  Done."
fi

echo "[ADD] 5xx GitLab Lua QoL mods (UI Modes, Pause Control, Friendly Autosave, ...) —"
echo "      handled by: ./update_gitlab_mods.sh qol"

# ===========================================================================

echo ""
echo "=========================================="
echo "EXTRACTION COMPLETE"
echo "=========================================="
echo ""
if ((${#NOTES[@]})); then
    echo "NOTES (${#NOTES[@]}) — optional items not installed / needing review:"
    printf '  - %s\n' "${NOTES[@]}"
    echo ""
fi
if ((${#ISSUES[@]})); then
    echo "ISSUES DETECTED (${#ISSUES[@]}):"
    printf '  - %s\n' "${ISSUES[@]}"
    echo ""
    echo "Fix the above (re-download archive, correct FOMOD folder name) and re-run."
    exit 1
else
    echo "No issues detected."
fi
echo ""
echo "Next: ./update_gitlab_mods.sh all   then   ./check_setup.sh"
