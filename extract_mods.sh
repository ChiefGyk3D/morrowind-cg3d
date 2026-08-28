#!/bin/bash
set -euo pipefail

# Morrowind Mod Extraction Script
# Extracts each archive into its numbered mod folder with correct structure.
# Each mod folder must have game data (meshes/, textures/, .esp, .esm) at root.
#
# Safe to re-run: skips missing archives with a warning instead of aborting,
# and reports any mod folder that ended up empty at the end.

ARCHIVES="$HOME/mods/morrowind/mod_files"
MODS="$HOME/mods/morrowind/mods"

ISSUES=()

require_tool() {
    command -v "$1" >/dev/null 2>&1 || {
        echo "ERROR: required tool '$1' not found. Install it first ($2)." >&2
        exit 1
    }
}

# Archives use both 7z and rar; fail fast if either extractor is absent.
require_tool 7z "e.g. sudo apt install p7zip-full"
require_tool unrar "e.g. sudo apt install unrar"

if [[ ! -d "$ARCHIVES" ]]; then
    echo "ERROR: archive directory not found: $ARCHIVES" >&2
    echo "Download the archives listed in mod-list.txt there first." >&2
    exit 1
fi

# Returns success if the archive exists; otherwise records an issue and the
# caller skips that mod instead of the whole script dying mid-run.
have_archive() {
    local archive="$1" label="$2"
    if [[ ! -f "$archive" ]]; then
        echo "  MISSING ARCHIVE: $(basename "$archive") — skipping."
        ISSUES+=("$label: archive not found: $(basename "$archive")")
        return 1
    fi
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
    7z x "$archive" -o"$tmpdir" -r -y > /dev/null 2>&1 || true
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
    7z x "$archive" -o"$tmpdir" -r -y > /dev/null 2>&1 || true
    if [[ -d "$tmpdir/$folder" ]]; then
        cp -a "$tmpdir/$folder"/. "$target"/
    fi
    rm -rf "$tmpdir"
}

echo "=========================================="
echo "MORROWIND MOD EXTRACTION"
echo "=========================================="

# --- TIER 1 ---

echo "[1/21] 001 Patch for Purists (flat structure)..."
if have_archive "$ARCHIVES/Patch for Purists-45096-5-0-6-1765845457.7z" "001 Patch for Purists"; then
    7z x "$ARCHIVES/Patch for Purists-45096-5-0-6-1765845457.7z" \
        -o"$MODS/001_patch_for_purists" -r -y > /dev/null 2>&1 || true
    verify "$MODS/001_patch_for_purists" "001 Patch for Purists"
    echo "  Done."
fi

echo "[2/21] 002 UMOPP Merged + Compatibility ESP..."
if have_archive "$ARCHIVES/Unofficial Morrowind Official Plugins Patched-43931-3-2-1-1709596838.7z" "002 UMOPP"; then
    extract_fomod "$ARCHIVES/Unofficial Morrowind Official Plugins Patched-43931-3-2-1-1709596838.7z" \
        "$MODS/002_umopp" \
        "08 UMOPP Merged" "09 UMOPP Compatibility Merged"
    # The 09 Compat ESP overwrites the 08 ESP (same filename), giving us PfP-compatible version
    verify "$MODS/002_umopp" "002 UMOPP"
    echo "  Done."
fi

echo "[3/21] 003 Expansion Delay (flat structure)..."
if have_archive "$ARCHIVES/Expansion Delay-47588-1-3-1612481103.zip" "003 Expansion Delay"; then
    7z x "$ARCHIVES/Expansion Delay-47588-1-3-1612481103.zip" \
        -o"$MODS/003_expansion_delay" -r -y > /dev/null 2>&1 || true
    verify "$MODS/003_expansion_delay" "003 Expansion Delay"
    echo "  Done."
fi

echo "[4/21] 004 Morrowind Optimization Patch..."
if have_archive "$ARCHIVES/Morrowind Optimization Patch-45384-1-18-0-1751572864.7z" "004 MOP"; then
    extract_fomod "$ARCHIVES/Morrowind Optimization Patch-45384-1-18-0-1751572864.7z" \
        "$MODS/004_morrowind_optimization_patch" \
        "00 Core"
    verify "$MODS/004_morrowind_optimization_patch" "004 MOP"
    echo "  Done."
fi

echo "[5/21] 005 Tamriel Data (HD) — this is ~2.2GB, please wait..."
if have_archive "$ARCHIVES/Tamriel Data (HD)-44537-25-05-1746144713.7z" "005 Tamriel Data"; then
    extract_fomod "$ARCHIVES/Tamriel Data (HD)-44537-25-05-1746144713.7z" \
        "$MODS/005_tamriel_data" \
        "00 Data Files"
    verify "$MODS/005_tamriel_data" "005 Tamriel Data"
    echo "  Done."
fi

echo "[6/21] 006 Tamriel Rebuilt..."
if have_archive "$ARCHIVES/Tamriel Rebuilt 25.08.12-42145-25-08-12-1755040619.7z" "006 Tamriel Rebuilt"; then
    extract_fomod "$ARCHIVES/Tamriel Rebuilt 25.08.12-42145-25-08-12-1755040619.7z" \
        "$MODS/006_tamriel_rebuilt" \
        "00 Core"
    verify "$MODS/006_tamriel_rebuilt" "006 Tamriel Rebuilt"
    echo "  Done."
fi

# --- TIER 2 ---

echo "[7/21] 101 Graphic Herbalism..."
if have_archive "$ARCHIVES/Graphic Herbalism MWSE - OpenMW-46599-1-04-1558643353.7z" "101 Graphic Herbalism"; then
    extract_fomod "$ARCHIVES/Graphic Herbalism MWSE - OpenMW-46599-1-04-1558643353.7z" \
        "$MODS/101_graphic_herbalism" \
        "00 Core + Vanilla Meshes"
    verify "$MODS/101_graphic_herbalism" "101 Graphic Herbalism"
    echo "  Done."
fi

echo "[8/21] 102 Harvest Lights (Lua mod — flat extract)..."
if have_archive "$ARCHIVES/harvest-lights.zip" "102 Harvest Lights"; then
    7z x "$ARCHIVES/harvest-lights.zip" \
        -o"$MODS/102_harvest_lights" -r -y > /dev/null 2>&1 || true
    verify "$MODS/102_harvest_lights" "102 Harvest Lights"
    echo "  Done."
fi

echo "[9/21] 103 Weapon Sheathing..."
if have_archive "$ARCHIVES/WeaponSheathing1.6-OpenMW-46069-1-6-1565439130.7z" "103 Weapon Sheathing"; then
    extract_datafiles "$ARCHIVES/WeaponSheathing1.6-OpenMW-46069-1-6-1565439130.7z" \
        "$MODS/103_weapon_sheathing"
    verify "$MODS/103_weapon_sheathing" "103 Weapon Sheathing"
    echo "  Done."
fi

echo "[10/21] 104 Project Atlas..."
if have_archive "$ARCHIVES/Project Atlas-45399-0-7-5-1747751438.7z" "104 Project Atlas"; then
    extract_fomod "$ARCHIVES/Project Atlas-45399-0-7-5-1747751438.7z" \
        "$MODS/104_project_atlas" \
        "00 Core"
    verify "$MODS/104_project_atlas" "104 Project Atlas"
    echo "  Done."
fi

echo "[11/21] 105 Morrowind Enhanced Textures — this is ~2.4GB, please wait..."
if have_archive "$ARCHIVES/Morrowind Enhanced Textures 6.1-46221-6-1-1698010415.zip" "105 MET"; then
    extract_named "$ARCHIVES/Morrowind Enhanced Textures 6.1-46221-6-1-1698010415.zip" \
        "$MODS/105_morrowind_enhanced_textures" \
        "MET 6-1 main"
    verify "$MODS/105_morrowind_enhanced_textures" "105 MET"
    echo "  Done."
fi

echo "[12/21] 106 Familiar Faces..."
if have_archive "$ARCHIVES/Familiar Faces-50093-2-1-1678377705.zip" "106 Familiar Faces"; then
    tmpdir=$(mktemp -d)
    7z x "$ARCHIVES/Familiar Faces-50093-2-1-1678377705.zip" -o"$tmpdir" -r -y > /dev/null 2>&1 || true
    # Copy main Meshes/ folder (at root), skip optional subfolder
    mkdir -p "$MODS/106_familiar_faces"
    if [[ -d "$tmpdir/Meshes" ]]; then
        cp -a "$tmpdir/Meshes" "$MODS/106_familiar_faces/"
    fi
    rm -rf "$tmpdir"
    verify "$MODS/106_familiar_faces" "106 Familiar Faces"
    echo "  Done."
fi

# --- TIER 3 ---

echo "[13/21] 201 Containers Animated..."
if have_archive "$ARCHIVES/OpenMW Containers Animated-46232-1-2-2-1574060105.zip" "201 Containers Animated"; then
    extract_named "$ARCHIVES/OpenMW Containers Animated-46232-1-2-2-1574060105.zip" \
        "$MODS/201_containers_animated" \
        "Containers Animated"
    verify "$MODS/201_containers_animated" "201 Containers Animated"
    echo "  Done."
fi

echo "[14/21] 202 Glow in the Dahrk — SKIPPING (v3.3.0 downloaded, need v2.11.2)..."
echo "  *** Download v2.11.2 from Old files on Nexus and re-extract. ***"

echo "[15/21] 203 Nords Shut Your Windows (Core + Purist option)..."
if have_archive "$ARCHIVES/Nords shut your windows-50087-2-1-1709742311.rar" "203 Nords Shut Your Windows"; then
    tmpdir=$(mktemp -d)
    unrar x -o+ "$ARCHIVES/Nords shut your windows-50087-2-1-1709742311.rar" "$tmpdir/" > /dev/null 2>&1 || true
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
if have_archive "$ARCHIVES/Fonts-46854-1-0-1559397215.zip" "204 TrueType Fonts"; then
    extract_named "$ARCHIVES/Fonts-46854-1-0-1559397215.zip" \
        "$MODS/204_truetype_fonts" \
        "Fonts"
    verify "$MODS/204_truetype_fonts" "204 TrueType Fonts"
    echo "  Done."
fi

echo "[17/21] 205 Cantons on the Global Map..."
if have_archive "$ARCHIVES/Cantons_on_the_Global_Map_v1.1-50534-1-1-1639771891.zip" "205 Cantons"; then
    extract_datafiles "$ARCHIVES/Cantons_on_the_Global_Map_v1.1-50534-1-1-1639771891.zip" \
        "$MODS/205_cantons_global_map"
    verify "$MODS/205_cantons_global_map" "205 Cantons"
    echo "  Done."
fi

echo "[18/21] 206 Distant Seafloor..."
if have_archive "$ARCHIVES/Distant_Seafloor_2.00-50796-2-00-1655819832.zip" "206 Distant Seafloor"; then
    extract_fomod "$ARCHIVES/Distant_Seafloor_2.00-50796-2-00-1655819832.zip" \
        "$MODS/206_distant_seafloor" \
        "00 Core"
    verify "$MODS/206_distant_seafloor" "206 Distant Seafloor"
    echo "  Done."
fi

echo "[19/21] 207 Distant Fixes Lua Edition (flat extract)..."
if have_archive "$ARCHIVES/distant-fixes-lua-edition.zip" "207 Distant Fixes Lua"; then
    7z x "$ARCHIVES/distant-fixes-lua-edition.zip" \
        -o"$MODS/207_distant_fixes_lua" -r -y > /dev/null 2>&1 || true
    verify "$MODS/207_distant_fixes_lua" "207 Distant Fixes Lua"
    echo "  Done."
fi

# --- REPOPULATED ---

echo "[20/21] 301 Repopulated Morrowind (Core + main + Bloodmoon + TR)..."
if have_archive "$ARCHIVES/Repopulated Morrowind-51174-2-6-1703824812.zip" "301 Repopulated Morrowind"; then
    extract_fomod "$ARCHIVES/Repopulated Morrowind-51174-2-6-1703824812.zip" \
        "$MODS/301_repopulated_morrowind" \
        "00 Core" "01 Repopulated Morrowind" "03 Bloodmoon" "05 Tamriel Rebuilt"
    verify "$MODS/301_repopulated_morrowind" "301 Repopulated Morrowind"
    echo "  Done."
fi

echo "[21/21] 302 Repopulated Creatures..."
if have_archive "$ARCHIVES/Repopulated Creatures-55628-1-1-1746140786.zip" "302 Repopulated Creatures"; then
    tmpdir=$(mktemp -d)
    7z x "$ARCHIVES/Repopulated Creatures-55628-1-1-1746140786.zip" -o"$tmpdir" -r -y > /dev/null 2>&1 || true
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
if have_archive "$ARCHIVES/OAAB_Data-49042-2-5-1-1764958680.7z" "OAAB_Data"; then
    extract_fomod "$ARCHIVES/OAAB_Data-49042-2-5-1-1764958680.7z" \
        "$MODS/OAAB_Data" \
        "00 Core"
    verify "$MODS/OAAB_Data" "OAAB_Data"
    echo "  Done."
fi

echo ""
echo "=========================================="
echo "EXTRACTION COMPLETE"
echo "=========================================="
echo ""
echo "SKIPPED BY DESIGN:"
echo "  - 202 Glow in the Dahrk (wrong version — need v2.11.2)"
echo ""
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
echo "Verify with: ls -1 ~/mods/morrowind/mods/*/  | head -100"
