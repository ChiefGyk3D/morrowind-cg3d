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
    find "$ARCHIVES" -maxdepth 1 -type f -size +0 -iname "$glob" -not -iname '*.part' -not -iname '*.crdownload' -printf '%T@ %p\n' 2>/dev/null \
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
        if [[ -d "$tmpdir/$prefix/Data Files" ]]; then
            # module wraps its data (TR 26.08: "00 Core/Data Files/...")
            cp -a "$tmpdir/$prefix/Data Files"/. "$target"/
        elif [[ -d "$tmpdir/$prefix" ]]; then
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
# extract_all GLOB LABEL TARGET [module globs...]
# Like have_archive+extract_auto, but for mods whose Nexus page is SEVERAL
# downloads (meshes + textures, main + Bloodmoon, one file per module...).
# Every matching archive is extracted into TARGET (sorted by name). Missing
# is a NOTE (all callers are optional additions). Returns 1 if nothing found.
extract_all() {
    local glob="$1" label="$2" target="$3"; shift 3
    local -a found
    mapfile -t found < <(find "$ARCHIVES" -maxdepth 1 -type f -size +0 -iname "$glob" -not -iname '*.part' -not -iname '*.crdownload' | sort)
    if (( ${#found[@]} == 0 )); then
        echo "  (not downloaded — skipping; pattern: $glob)"
        NOTES+=("$label: not downloaded (looked for '$glob')")
        return 1
    fi
    local a
    for a in "${found[@]}"; do
        echo "  Archive: $(basename "$a")"
        extract_auto "$a" "$target" "$@"
    done
    verify "$target" "$label"
    echo "  Done."
}

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
if have_archive "Patch for Purists*[- ]45096[- ]*" "001 Patch for Purists"; then
    7z x "$ARCHIVE" -o"$MODS/001_patch_for_purists" -r -y > /dev/null 2>&1 || true
    verify "$MODS/001_patch_for_purists" "001 Patch for Purists"
    echo "  Done."
fi

echo "[2/21] 002 UMOPP 3.3.0 — merged compatibility (No Firemoth) + Siege at Firemoth..."
# UMOPP readme: "DO NOT USE BOTH THE MERGED AND INDIVIDUAL VERSIONS TOGETHER" and for
# OpenMW/manual installs "ONLY INSTALL THE FOLDER MARKED 000 MANUAL INSTALL ONLY".
# That folder = assets + Merged Compatibility No-Firemoth ESP (the TR-friendly one)
# + Siege at Firemoth.esp + UMOPP_BetterArmorPatch.esp (Better Morrowind Armor only — not enabled).
# content= "Unofficial Morrowind Official Plugins Patched.ESP" + "Siege at Firemoth.esp"
if have_archive "Unofficial Morrowind Official Plugins Patched*[- ]43931[- ]*" "002 UMOPP"; then
    rm -rf "$MODS/002_umopp"   # 3.2.1 layout left individual ESPs behind; start clean
    extract_fomod "$ARCHIVE" "$MODS/002_umopp" "000 MANUAL INSTALL ONLY USE THIS FOLDER 000"
    verify "$MODS/002_umopp" "002 UMOPP"
    echo "  Done."
fi

echo "[3/21] 003 Expansion Delay (flat structure)..."
if have_archive "Expansion Delay*[- ]47588[- ]*" "003 Expansion Delay"; then
    7z x "$ARCHIVE" -o"$MODS/003_expansion_delay" -r -y > /dev/null 2>&1 || true
    verify "$MODS/003_expansion_delay" "003 Expansion Delay"
    echo "  Done."
fi

echo "[4/21] 004 Morrowind Optimization Patch..."
if have_archive "Morrowind Optimization Patch*[- ]45384[- ]*" "004 MOP"; then
    extract_fomod "$ARCHIVE" "$MODS/004_morrowind_optimization_patch" "00 Core"
    verify "$MODS/004_morrowind_optimization_patch" "004 MOP"
    echo "  Done."
fi

echo "[5/21] 005 Tamriel_Data HD (00 Data Files + 01 Normal Maps; Nexus 59927, old page 44537)..."
TD_ARCHIVE=""
for g in "*[- ]59927[- ]*" "Tamriel Data (HD)*[- ]44537[- ]*"; do TD_ARCHIVE=$(find_archive "$g"); [[ -n "$TD_ARCHIVE" ]] && break; done
if [[ -z "$TD_ARCHIVE" ]]; then
    echo "  MISSING ARCHIVE: Tamriel_Data HD (Nexus 59927) — skipping."; ISSUES+=("005 Tamriel Data: archive not found (looked for '*-59927-*' / 'Tamriel Data (HD)-44537-*')")
else
    ARCHIVE="$TD_ARCHIVE"; echo "  Archive: $(basename "$ARCHIVE")"
    extract_fomod "$ARCHIVE" "$MODS/005_tamriel_data" "00 Data Files" "01 Data Files - Normal Maps"
    verify "$MODS/005_tamriel_data" "005 Tamriel Data"
    echo "  Done."
fi

echo "[6/21] 006 Tamriel Rebuilt (newest download wins: 26.08 'Poison Song')..."
if have_archive "Tamriel Rebuilt*[- ]42145[- ]*" "006 Tamriel Rebuilt"; then
    extract_fomod "$ARCHIVE" "$MODS/006_tamriel_rebuilt" "00 Core" "01 Faction Integration"   # MOMW TO/EV: both; content= TR_Factions.esp
    verify "$MODS/006_tamriel_rebuilt" "006 Tamriel Rebuilt"
    echo "  Done."
fi

# ===========================================================================
# BASELINE — TIER 2
# ===========================================================================

echo "[7/21] 101 Graphic Herbalism..."
if have_archive "Graphic Herbalism MWSE - OpenMW*[- ]46599[- ]*" "101 Graphic Herbalism"; then
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
if have_archive "WeaponSheathing**[- ]46069[- ]*" "103 Weapon Sheathing"; then
    extract_datafiles "$ARCHIVE" "$MODS/103_weapon_sheathing"
    verify "$MODS/103_weapon_sheathing" "103 Weapon Sheathing"
    echo "  Done."
fi

echo "[10/21] 104 Project Atlas..."
if have_archive "Project Atlas*[- ]45399[- ]*" "104 Project Atlas"; then
    extract_fomod "$ARCHIVE" "$MODS/104_project_atlas" "00 Core" "01 Textures - MET" "02 Urns - Smoothed" "03 Redware - Smoothed" "06 Glow in the Dahrk Patch" "07 Graphic Herbalism Patch" "08 ILFAS Patch"   # MOMW Starter Pack (no BCOM) set; ILFAS = Improved Lights (415)
    verify "$MODS/104_project_atlas" "104 Project Atlas"
    echo "  Done."
fi

echo "[11/21] 105 Morrowind Enhanced Textures — ~2.4GB, please wait..."
if have_archive "Morrowind Enhanced Textures**[- ]46221[- ]*" "105 MET"; then
    extract_named "$ARCHIVE" "$MODS/105_morrowind_enhanced_textures" "MET 6-1 main"
    verify "$MODS/105_morrowind_enhanced_textures" "105 MET"
    # MOMW: also the "Interface and main menu" file (into the MET root) and the
    # "MET 6 Atlas textures" file (into an atlas/ sub-folder = its own data= line).
    if have_archive "*Interface**[- ]46221[- ]*" "105b MET Interface and main menu" optional; then
        extract_auto "$ARCHIVE" "$MODS/105_morrowind_enhanced_textures"
    fi
    if have_archive "*Atlas**[- ]46221[- ]*" "105c MET 6 Atlas textures" optional; then
        extract_auto "$ARCHIVE" "$MODS/105_morrowind_enhanced_textures/atlas"
        echo "  atlas/ needs its own data= line AFTER the MET root and AFTER 104_project_atlas."
    fi
    echo "  Done."
fi

echo "[12/21] 106 Familiar Faces..."
if have_archive "Familiar Faces*[- ]50093[- ]*" "106 Familiar Faces"; then
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
if have_archive "OpenMW Containers Animated*[- ]46232[- ]*" "201 Containers Animated"; then
    extract_named "$ARCHIVE" "$MODS/201_containers_animated" "Containers Animated"
    verify "$MODS/201_containers_animated" "201 Containers Animated"
    echo "  Done."
fi

echo "[14/21] 202 Glow in the Dahrk — v2.11.2 ONLY (OpenMW does not support 3.x light rays)..."
if have_archive "Glow in the Dahrk-45886-2-11-2-*" "202 Glow in the Dahrk 2.11.2"; then
    # MOMW set, in 2.11.2's numbering: core, hi-res windows, Telvanni dormers, Raven Rock.
    # Skipped: "Interior Sunrays" variants (MWSE), 03 Nord Glass, 06 Dark Molag Mar, 07 Windoors.
    # content= GITD_Telvanni_Dormers.ESP + GITD_WL_RR_Interiors.esp
    extract_auto "$ARCHIVE" "$MODS/202_glow_in_the_dahrk" "01 Hi Res*" "04 Telvanni Dormers*" "05 Raven Rock Glass Windows"
    verify "$MODS/202_glow_in_the_dahrk" "202 Glow in the Dahrk"
    echo "  Done."
else
    if [[ -n "$(find_archive 'Glow in the Dahrk-45886-3-*')" ]]; then
        echo "  *** A GitD 3.x archive is present but is NOT usable on OpenMW. ***"
    fi
    echo "  *** Download v2.11.2 from Nexus 45886 -> Files -> Old files, re-run. ***"
fi

echo "[15/21] 203 Nords Shut Your Windows (Core + Purist option)..."
if have_archive "Nords shut your windows*[- ]50087[- ]*" "203 Nords Shut Your Windows"; then
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
if have_archive "Fonts*[- ]46854[- ]*" "204 TrueType Fonts"; then
    extract_named "$ARCHIVE" "$MODS/204_truetype_fonts" "Fonts"
    verify "$MODS/204_truetype_fonts" "204 TrueType Fonts"
    echo "  Done."
fi

echo "[17/21] 205 Cantons on the Global Map..."
if have_archive "Cantons_on_the_Global_Map**[- ]50534[- ]*" "205 Cantons"; then
    extract_datafiles "$ARCHIVE" "$MODS/205_cantons_global_map"
    verify "$MODS/205_cantons_global_map" "205 Cantons"
    echo "  Done."
fi

echo "[18/21] 206 Distant Seafloor..."
if have_archive "Distant_Seafloor**[- ]50796[- ]*" "206 Distant Seafloor"; then
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
if have_archive "Repopulated Morrowind*[- ]51174[- ]*" "301 Repopulated Morrowind"; then
    extract_fomod "$ARCHIVE" "$MODS/301_repopulated_morrowind" \
        "00 Core" "01 Repopulated Morrowind" "03 Bloodmoon" "05 Tamriel Rebuilt"
    verify "$MODS/301_repopulated_morrowind" "301 Repopulated Morrowind"
    echo "  NOTE: leave RepopulatedMainland.ESP OUT of content= until RM confirms TR 26.08 support."
    echo "  Done."
fi

echo "[21/21] 302 Repopulated Creatures (1.2: 00 Core + 02 Vvardenfell and Mainland Dialogue Edits)..."
if have_archive "Repopulated Creatures*[- ]55628[- ]*" "302 Repopulated Creatures"; then
    # 1.1 shipped a "Data Files" wrapper; 1.2 is FOMOD-style. extract_auto handles both.
    # content= RepopulatedCreatures.ESP + RepopulatedCreatures_DialogueEdits.ESP (TR-aware variant)
    extract_auto "$ARCHIVE" "$MODS/302_repopulated_creatures" "02 Vvardenfell and Mainland*"
    verify "$MODS/302_repopulated_creatures" "302 Repopulated Creatures"
    echo "  Done."
fi

echo "[BONUS] OAAB_Data..."
if have_archive "OAAB_Data*[- ]49042[- ]*" "OAAB_Data"; then
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

echo "[ADD] 402 Lush Synthesis (groundcover= lines, NOT content=)..."
# Archive (measured 2026-09-09): meshes/ textures/ at root + folders LUSH_VANILLA
# (land plugins lush3_ac/ai/al/bc/gl/wg), LUSH_UNDERWATER (RI=rivers, SE=seas,
# variants BM/TOTSP/CYR/TR/WoM), LUSH_SO (Solstheim), LUSH_BCOM, LUSH_TR (22.11-era,
# superseded by 418 Fantasia), textures_halfsize (low-VRAM alt), modmaker_tools.
# Extracted flat; each used folder is its own data= line (root, LUSH_VANILLA,
# LUSH_UNDERWATER, LUSH_SO). groundcover= see runbook A5.
extract_all "*[- ]52931[- ]*" "402 Lush Synthesis" "$MODS/402_lush_synthesis" || true

echo "[ADD] 418 Fantasia Grass Mod - Lush Synthesis TR Update (TR 26.08 grass)..."
# MOMW data path: "Lush Synthesis - TR/Data files"; groundcover= lush3_TR_merged.esp
# Nexus 60006 has two files: "Lush Synthesis TR" (ours) and "Fantasia Grass Mod TR" (for the
# Fantasia grass family, NOT used).
extract_all "Lush Synthesis TR*60006*" "418 Fantasia Lush Synthesis TR Update" "$MODS/418_lush_synthesis_tr" || true

echo "[ADD] 403 Remiros' Groundcover (groundcover= Rem_AL.esp only; Lush covers the rest)..."
# MOMW: "00 Core OpenMW" + "01b Thicker Grass OpenMW". 03 TR Plugins not used (Fantasia covers TR).
# Archive ships MGE XE and OpenMW variants of every module — exact names only.
if ARCHIVE=$(find_archive "*[- ]46733[- ]*") && [[ -n "$ARCHIVE" ]]; then
    echo "  Archive: $(basename "$ARCHIVE")"
    extract_fomod "$ARCHIVE" "$MODS/403_remiros_groundcover" "00 Core OpenMW" "01b Thicker Grass OpenMW"
    verify "$MODS/403_remiros_groundcover" "403 Remiros Groundcover"
    echo "  Done."
else
    echo "  (not downloaded — skipping; pattern: *[- ]46733[- ]*)"; NOTES+=("403 Remiros Groundcover: not downloaded (looked for '*[- ]46733[- ]*')")
fi

echo "[ADD] 404 Remiros Groundcover Textures Improvement..."
extract_all "*[- ]54261[- ]*" "404 Remiros Groundcover Textures" "$MODS/404_remiros_groundcover_textures" || true

echo "[ADD] 405 Skies .IV (\"Skies - .IV\" + Particles merged; raindrop files removed)..."
# MOMW: use "Skies - .IV" + "Particles", skip "Skies - Vanilla". Folders carry no
# 00/01 prefixes so extract_auto can't pick them — merge the two wanted ones here.
mapfile -t SKIES_ARCHIVES < <(find "$ARCHIVES" -maxdepth 1 -type f -size +0 -iname "*[- ]43311[- ]*" -not -iname '*.part' | sort)
if (( ${#SKIES_ARCHIVES[@]} == 0 )); then
    echo "  (not downloaded — skipping; pattern: *-43311-*)"; NOTES+=("405 Skies IV: not downloaded (looked for '*-43311-*')")
else
    T="$MODS/405_skies_iv"; mkdir -p "$T"
    for ARCHIVE in "${SKIES_ARCHIVES[@]}"; do
        echo "  Archive: $(basename "$ARCHIVE")"
        tmpdir=$(mktemp -d); extract_any "$ARCHIVE" "$tmpdir"
        got=0
        while IFS= read -r -d '' d; do
            b=$(basename "$d")
            case "$b" in
                "Skies - .IV"|Particles) echo "    + $b"; cp -a "$d"/. "$T"/; got=1 ;;
                "Skies - Vanilla") echo "    - $b (skipped: alternative look)" ;;
            esac
        done < <(find "$tmpdir" -mindepth 1 -maxdepth 3 -type d \( -name "Skies - .IV" -o -name "Particles" -o -name "Skies - Vanilla" \) -print0 | sort -z)
        if (( ! got )); then echo "  WARNING: expected 'Skies - .IV' / 'Particles' folders not found — extracted as-is."; cp -a "$tmpdir"/. "$T"/; ISSUES+=("405 Skies IV: unexpected layout, sort manually"); fi
        rm -rf "$tmpdir"
    done
    # MOMW usage notes: these two files break on OpenMW
    find "$T" -iname 'raindrop.nif' -print -delete | sed 's/^/    removed: /'
    find "$T" -iname 'tx_raindrop_01.dds' -print -delete | sed 's/^/    removed: /'
    find "$T" -maxdepth 1 -type f -iname 'merge these into*' -delete   # empty marker files from the zip
    verify "$T" "405 Skies IV"
    NOTES+=("405: append config/openmw-fallbacks-skies-iv.cfg (10 cloud-speed lines) to openmw.cfg")
    echo "  Done."
fi

echo "[ADD] 406 New Starfields (00 Core + MOMW's suggested option 7)..."
# MOMW: "00 Core" always; optionally exactly ONE option folder — their pick is "01 Option 7 (100% Opacity)".
extract_all "*[- ]43246[- ]*" "406 New Starfields" "$MODS/406_new_starfields" "01 Option 7 (100% Opacity)" || true

echo "[ADD] 407 Normal Maps for Morrowind (modules per MOMW: 01a/03/04/05/07/08/09b)..."
# Nexus 45336 ships as separate numbered downloads (and/or one archive with
# numbered folders). Take EVERY matching archive, keep only the modules MOMW
# recommends for a MET/Atlas stack, then drop the four known-bad _nh.dds files.
NMFM_WANT=("01a*" "03 *" "04 *" "05 *" "07 *" "08 *" "09b*")
mapfile -t NMFM_ARCHIVES < <(find "$ARCHIVES" -maxdepth 1 -type f -size +0 -iname "*[- ]45336[- ]*" -not -iname '*.part' | sort)
if (( ${#NMFM_ARCHIVES[@]} == 0 )); then
    echo "  (not downloaded — skipping; pattern: *[- ]45336[- ]*)"
    NOTES+=("407 Normal Maps for Morrowind: not downloaded (looked for '*[- ]45336[- ]*')")
else
    T="$MODS/407_normal_maps_for_morrowind"; mkdir -p "$T"
    for ARCHIVE in "${NMFM_ARCHIVES[@]}"; do
        echo "  Archive: $(basename "$ARCHIVE")"
        tmpdir=$(mktemp -d); extract_any "$ARCHIVE" "$tmpdir"; root="$tmpdir"
        while :; do
            mapfile -t entries < <(find "$root" -mindepth 1 -maxdepth 1 -not -name '__MACOSX' -not -name 'fomod')
            if (( ${#entries[@]} == 1 )) && [[ -d "${entries[0]}" ]] && ! is_data_root "$root" \
               && [[ ! "$(basename "${entries[0]}")" =~ ^[0-9][0-9][a-z]?\  ]]; then root="${entries[0]}"; else break; fi
        done
        if compgen -G "$root/[0-9][0-9]*" > /dev/null; then
            echo "  Layout: numbered module folders"
            skipped=()
            for d in "$root"/[0-9][0-9]*/; do
                d=${d%/}; b=$(basename "$d"); want=0
                for g in "${NMFM_WANT[@]}"; do [[ "$b" == $g ]] && want=1; done
                if (( want )); then echo "    + $b"; cp -a "$d"/. "$T"/; else skipped+=("$b"); fi
            done
            (( ${#skipped[@]} )) && printf '    - skipped (not in MOMW list): %s\n' "${skipped[@]}"
        elif is_data_root "$root"; then
            echo "  Layout: flat (single module download)"; cp -a "$root"/. "$T"/
        else
            echo "  WARNING: unrecognised layout — extracted as-is."; cp -a "$root"/. "$T"/
            ISSUES+=("407 Normal Maps for Morrowind: unrecognised layout in $(basename "$ARCHIVE")")
        fi
        rm -rf "$tmpdir"
    done
    # MOMW usage notes: these four normal maps are bad, delete them
    for bad in Tx_emperor_parasol_01_nh.dds Tx_emperor_parasol_02_nh.dds Tx_emperor_parasol_03_nh.dds tx_ma_lava05a_nh.dds; do
        find "$T" -iname "$bad" -print -delete | sed 's/^/    removed known-bad: /'
    done
    verify "$T" "407 Normal Maps for Morrowind"
    NOTES+=("407: needs settings.cfg [Shaders] auto use object/terrain normal+specular maps = true (in config/settings-tuning.cfg)")
    echo "  Done."
fi

echo "[ADD] 408 Normal Maps for Everything (modules for OUR stack only)..."
# Nexus 52567 is ~48 separate downloads (one per texture pack). MOMW data paths
# name each module; we take only the ones covering packs we actually run.
# Two modules carry numbered sub-folders: take Vanilla 01+02, Atlas 03 (MET) only.
NMFE_WANT=(
    "Vanilla Textures Normal Mapped*"
    "01 Vanilla Textures Normal Mapped*"
    "02 Expansion Resource Conflicts*"
    "Atlas Textures*Normal Mapped*"
    "03 Morrowind Enhanced Textures Atlas*"
    "Morrowind Enhanced Textures Normal Mapped*"
    "OAAB Data*Normal Mapped*"
    "TR_PC_SHOTN*"
    "Tamriel*Data*Normal Mapped*"
)
NMFE_SKIP_REASON="not in our stack (see MOMW data paths); Hall of Justice pulled pending TR 26.08"
nmfe_want() { local g; for g in "${NMFE_WANT[@]}"; do [[ "$1" == $g ]] && return 0; done; return 1; }
# nmfe_take DIR TARGET — copy a module dir; recurse into wanted numbered sub-folders
nmfe_take() {
    local d="$1" T="$2" sub b
    if compgen -G "$d/[0-9][0-9] *" > /dev/null; then
        for sub in "$d"/[0-9][0-9]\ */; do
            sub=${sub%/}; b=$(basename "$sub")
            if nmfe_want "$b"; then echo "      + $b"; cp -a "$sub"/. "$T"/; else echo "      - $b (skipped)"; fi
        done
    else
        cp -a "$d"/. "$T"/
    fi
}
mapfile -t NMFE_ARCHIVES < <(find "$ARCHIVES" -maxdepth 1 -type f -size +0 -iname "*[- ]52567[- ]*" -not -iname '*.part' | sort)
if (( ${#NMFE_ARCHIVES[@]} == 0 )); then
    echo "  (not downloaded — skipping; pattern: *[- ]52567[- ]*)"
    NOTES+=("408 Normal Maps for Everything: not downloaded (looked for '*[- ]52567[- ]*')")
else
    T="$MODS/408_normal_maps_for_everything"; mkdir -p "$T"; copied=0
    for ARCHIVE in "${NMFE_ARCHIVES[@]}"; do
        echo "  Archive: $(basename "$ARCHIVE")"
        tmpdir=$(mktemp -d); extract_any "$ARCHIVE" "$tmpdir"; root="$tmpdir"
        # unwrap non-module wrapper folders (stop at a module name we know, or a data root)
        while :; do
            mapfile -t entries < <(find "$root" -mindepth 1 -maxdepth 1 -not -name '__MACOSX' -not -name 'fomod')
            if (( ${#entries[@]} == 1 )) && [[ -d "${entries[0]}" ]] && ! is_data_root "$root" \
               && ! nmfe_want "$(basename "${entries[0]}")"; then root="${entries[0]}"; else break; fi
        done
        if is_data_root "$root"; then
            # single-module download with data at root: trust the archive name
            b=$(basename "$ARCHIVE"); b=${b%%-52567-*}; b=${b#Normal Maps for Everything}; b=${b# - }; b=${b# }
            if [[ -z "$b" ]] || nmfe_want "$b"; then echo "    + (flat) ${b:-unnamed}"; cp -a "$root"/. "$T"/; copied=$((copied+1))
            else echo "    - (flat) $b (skipped: $NMFE_SKIP_REASON)"; fi
        else
            while IFS= read -r -d '' d; do
                b=$(basename "$d")
                if nmfe_want "$b"; then echo "    + $b"; nmfe_take "$d" "$T"; copied=$((copied+1))
                else echo "    - $b (skipped: $NMFE_SKIP_REASON)"; fi
            done < <(find "$root" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)
        fi
        rm -rf "$tmpdir"
    done
    (( copied == 0 )) && ISSUES+=("408 Normal Maps for Everything: no modules matched our stack — check archive names")
    verify "$T" "408 Normal Maps for Everything"
    NOTES+=("408: needs the same four settings.cfg [Shaders] 'auto use ... maps = true' lines as 407")
    echo "  Done."
fi

echo "[ADD] 409 GitD Normal Specular PBR Maps..."
if have_archive "*Normal and Specular*[- ]58029[- ]*" "409 GitD Normal and Specular Maps" optional; then
    extract_auto "$ARCHIVE" "$MODS/409_gitd_normal_pbr"
    verify "$MODS/409_gitd_normal_pbr" "409 GitD PBR Maps"
    echo "  Done."
fi

echo "[ADD] 410 Facelift for Tamriel Data..."
# Two main files on Nexus (Facelift_TR_Meshes + Facelift_TR_Textures) -> one folder.
extract_all "*[- ]53935[- ]*" "410 Facelift for Tamriel Data" "$MODS/410_facelift_tamriel_data" || true

echo "[ADD] 411 Morrowind Interiors Project..."
# Main file + optional Bloodmoon file; both ship a "Data Files" wrapper.
# content= MorrowindInteriorsProject.ESP, _Bloodmoon.ESP, _TR.ESP (after TR).
# "Anthology Solstheim" file is for a mod we do not run — excluded by name.
extract_all "Morrowind Interiors Project*[- ]52237[- ]*" "411 Morrowind Interiors Project" "$MODS/411_morrowind_interiors_project" || true

echo "[ADD] 412 Better Waterfalls..."
# FOMOD: 00 Core + "02 Tamriel Rebuilt Water" (MOMW); 01 stays out.
extract_all "*[- ]45424[- ]*" "412 Better Waterfalls" "$MODS/412_better_waterfalls" "*Tamriel Rebuilt*" || true

echo "[ADD] 413 Waterfalls Tweaks — REMOVED 2026-09-09 (deletes vanilla light 'bc mushroom 64' that TR uses 892x)."
echo "[ADD] 414 OpenMW More Dynamic Water Meshes..."
if have_archive "*[- ]55392[- ]*" "414 More Dynamic Water Meshes" optional; then
    extract_auto "$ARCHIVE" "$MODS/414_more_dynamic_water_meshes"
    verify "$MODS/414_more_dynamic_water_meshes" "414 More Dynamic Water Meshes"
    echo "  Done."
fi

echo "[ADD] 415 Improved Lights for All Shaders (set 'clamp lighting = false')..."
# FOMOD: 00 Core + "01 Smoke and Steam Emitters" (MOMW takes both). settings.cfg: clamp lighting = false
extract_all "*[- ]51463[- ]*" "415 Improved Lights for All Shaders" "$MODS/415_improved_lights_all_shaders" "*Smoke*" || true

echo "[ADD] 416 Kirel's Interior Weather..."
# Download ONLY the "(Cleaned and updated with tes3cmd)" file. content= k_weather.esp
extract_all "*[- ]49278[- ]*" "416 Kirel's Interior Weather" "$MODS/416_kirels_interior_weather" || true

echo "[ADD] 417 OAAB Saplings (00 Core + 10 Openmw Groundcover Patch)..."
# MOMW: content= "OAAB_Saplings OpenMW Patch.ESP"; groundcover= OAAB_Saplings.esm.
# Nexus 52351 (separate groundcover patch) is DEPRECATED — folded into folder 10. Not used.
extract_all "*[- ]50334[- ]*" "417 OAAB Saplings" "$MODS/417_oaab_saplings" "10 *" || true

echo "[ADD] 501 LDM - Context Matters (Nexus 48273)..."
# content= "LDM - Context Matters 1.7.ESP" (after PfP and TR)
extract_all "*[- ]48273[- ]*" "501 LDM Context Matters" "$MODS/501_ldm_context_matters" || true

echo "[ADD] 502 Protective Guards (OpenMW) 2.0..."
# v2.0 (2026-08-31): content= protective_guards.omwscripts (renamed from
# protective_guards_for_omw.omwscripts); has an in-game settings menu.
# The "Factions and NPCs Protections" add-on (54858) is a 1.x fork under the old
# script name — running both = two guard systems. Superseded; NOT extracted.
extract_all "*[- ]46992[- ]*" "502 Protective Guards" "$MODS/502_protective_guards" || true

echo "[ADD] 514 Arukinn's Better Books and Scrolls (MOMW order: Arukinn -> Book Jackets -> MMM)..."
extract_all "*[- ]43100[- ]*" "514 Arukinns Better Books" "$MODS/514_arukinns_better_books" || true

echo "[ADD] 504 Book Jackets Complete Collection HD (+ optional OAAB book jackets)..."
# MOMW path: book-jackets/00 Core; content= book-jackets.esp
extract_all "*[- ]55402[- ]*" "504 Book Jackets HD" "$MODS/504_book_jackets_hd" || true
# Optional: "OAABBookJackets" file from MOMW's Various Mods and Patches (Nexus 56176)
# -> content= OAAB_BookJackets.omwaddon after OAAB_Data.esm and book-jackets.esp
extract_all "*BookJackets*[- ]56176[- ]*" "504b OAAB Book Jackets (Various Mods and Patches)" "$MODS/504_book_jackets_hd" || true

echo "[ADD] 515 Melchior's Magnificent Manuscripts (00 Core + 01 Book Jackets Patch)..."
extract_all "*[- ]45626[- ]*" "515 Melchiors Magnificent Manuscripts" "$MODS/515_melchiors_manuscripts" "01 Book Jackets Patch" || true

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
