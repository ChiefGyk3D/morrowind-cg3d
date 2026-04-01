#!/bin/bash
set -euo pipefail

# Morrowind Mod Extraction Script
# Extracts each archive into its numbered mod folder with correct structure.
# Each mod folder must have game data (meshes/, textures/, .esp, .esm) at root.

ARCHIVES="$HOME/mods/morrowind/mod_files"
MODS="$HOME/mods/morrowind/mods"

# Helper: extract FOMOD "00 Core" style folders into target dir
# Usage: extract_fomod ARCHIVE TARGET_DIR FOLDER_PREFIX...
extract_fomod() {
    local archive="$1"
    local target="$2"
    shift 2
    local tmpdir
    tmpdir=$(mktemp -d)
    for prefix in "$@"; do
        7z x "$archive" -o"$tmpdir" "${prefix}/*" -r -y > /dev/null 2>&1 || true
        if [[ -d "$tmpdir/$prefix" ]]; then
            cp -a "$tmpdir/$prefix"/. "$target"/
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
    7z x "$archive" -o"$tmpdir" -r -y > /dev/null 2>&1
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
    7z x "$archive" -o"$tmpdir" -r -y > /dev/null 2>&1
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
7z x "$ARCHIVES/Patch for Purists-45096-5-0-6-1765845457.7z" \
    -o"$MODS/001_patch_for_purists" -r -y > /dev/null 2>&1
echo "  Done."

echo "[2/21] 002 UMOPP Merged + Compatibility ESP..."
extract_fomod "$ARCHIVES/Unofficial Morrowind Official Plugins Patched-43931-3-2-1-1709596838.7z" \
    "$MODS/002_umopp" \
    "08 UMOPP Merged" "09 UMOPP Compatibility Merged"
# The 09 Compat ESP overwrites the 08 ESP (same filename), giving us PfP-compatible version
echo "  Done."

echo "[3/21] 003 Expansion Delay (flat structure)..."
7z x "$ARCHIVES/Expansion Delay-47588-1-3-1612481103.zip" \
    -o"$MODS/003_expansion_delay" -r -y > /dev/null 2>&1
echo "  Done."

echo "[4/21] 004 Morrowind Optimization Patch..."
extract_fomod "$ARCHIVES/Morrowind Optimization Patch-45384-1-18-0-1751572864.7z" \
    "$MODS/004_morrowind_optimization_patch" \
    "00 Core"
echo "  Done."

echo "[5/21] 005 Tamriel Data (HD) — this is ~2.2GB, please wait..."
extract_fomod "$ARCHIVES/Tamriel Data (HD)-44537-25-05-1746144713.7z" \
    "$MODS/005_tamriel_data" \
    "00 Data Files"
echo "  Done."

echo "[6/21] 006 Tamriel Rebuilt..."
extract_fomod "$ARCHIVES/Tamriel Rebuilt 25.08.12-42145-25-08-12-1755040619.7z" \
    "$MODS/006_tamriel_rebuilt" \
    "00 Core"
echo "  Done."

# --- TIER 2 ---

echo "[7/21] 101 Graphic Herbalism..."
extract_fomod "$ARCHIVES/Graphic Herbalism MWSE - OpenMW-46599-1-04-1558643353.7z" \
    "$MODS/101_graphic_herbalism" \
    "00 Core + Vanilla Meshes"
echo "  Done."

echo "[8/21] 102 Harvest Lights (Lua mod — flat extract)..."
7z x "$ARCHIVES/harvest-lights.zip" \
    -o"$MODS/102_harvest_lights" -r -y > /dev/null 2>&1
echo "  Done."

echo "[9/21] 103 Weapon Sheathing..."
extract_datafiles "$ARCHIVES/WeaponSheathing1.6-OpenMW-46069-1-6-1565439130.7z" \
    "$MODS/103_weapon_sheathing"
echo "  Done."

echo "[10/21] 104 Project Atlas..."
extract_fomod "$ARCHIVES/Project Atlas-45399-0-7-5-1747751438.7z" \
    "$MODS/104_project_atlas" \
    "00 Core"
echo "  Done."

echo "[11/21] 105 Morrowind Enhanced Textures — this is ~2.4GB, please wait..."
extract_named "$ARCHIVES/Morrowind Enhanced Textures 6.1-46221-6-1-1698010415.zip" \
    "$MODS/105_morrowind_enhanced_textures" \
    "MET 6-1 main"
echo "  Done."

echo "[12/21] 106 Familiar Faces..."
tmpdir=$(mktemp -d)
7z x "$ARCHIVES/Familiar Faces-50093-2-1-1678377705.zip" -o"$tmpdir" -r -y > /dev/null 2>&1
# Copy main Meshes/ folder (at root), skip optional subfolder
if [[ -d "$tmpdir/Meshes" ]]; then
    cp -a "$tmpdir/Meshes" "$MODS/106_familiar_faces/"
fi
rm -rf "$tmpdir"
echo "  Done."

# --- TIER 3 ---

echo "[13/21] 201 Containers Animated..."
extract_named "$ARCHIVES/OpenMW Containers Animated-46232-1-2-2-1574060105.zip" \
    "$MODS/201_containers_animated" \
    "Containers Animated"
echo "  Done."

echo "[14/21] 202 Glow in the Dahrk — SKIPPING (v3.3.0 downloaded, need v2.11.2)..."
echo "  *** Download v2.11.2 from Old files on Nexus and re-extract. ***"

echo "[15/21] 203 Nords Shut Your Windows (Core + Purist option)..."
tmpdir=$(mktemp -d)
unrar x -o+ "$ARCHIVES/Nords shut your windows-50087-2-1-1709742311.rar" "$tmpdir/" > /dev/null 2>&1
# Core has textures + base meshes, Purist has simpler replacement meshes
if [[ -d "$tmpdir/00 Core" ]]; then
    cp -a "$tmpdir/00 Core"/. "$MODS/203_nords_shut_your_windows"/
fi
if [[ -d "$tmpdir/04 Purist" ]]; then
    cp -a "$tmpdir/04 Purist"/. "$MODS/203_nords_shut_your_windows"/
fi
rm -rf "$tmpdir"
echo "  Done."

echo "[16/21] 204 TrueType Fonts..."
extract_named "$ARCHIVES/Fonts-46854-1-0-1559397215.zip" \
    "$MODS/204_truetype_fonts" \
    "Fonts"
echo "  Done."

echo "[17/21] 205 Cantons on the Global Map..."
extract_datafiles "$ARCHIVES/Cantons_on_the_Global_Map_v1.1-50534-1-1-1639771891.zip" \
    "$MODS/205_cantons_global_map"
echo "  Done."

echo "[18/21] 206 Distant Seafloor..."
extract_fomod "$ARCHIVES/Distant_Seafloor_2.00-50796-2-00-1655819832.zip" \
    "$MODS/206_distant_seafloor" \
    "00 Core"
echo "  Done."

echo "[19/21] 207 Distant Fixes Lua Edition (flat extract)..."
7z x "$ARCHIVES/distant-fixes-lua-edition.zip" \
    -o"$MODS/207_distant_fixes_lua" -r -y > /dev/null 2>&1
echo "  Done."

# --- REPOPULATED ---

echo "[20/21] 301 Repopulated Morrowind (Core + main + Bloodmoon + TR)..."
extract_fomod "$ARCHIVES/Repopulated Morrowind-51174-2-6-1703824812.zip" \
    "$MODS/301_repopulated_morrowind" \
    "00 Core" "01 Repopulated Morrowind" "03 Bloodmoon" "05 Tamriel Rebuilt"
echo "  Done."

echo "[21/21] 302 Repopulated Creatures..."
tmpdir=$(mktemp -d)
7z x "$ARCHIVES/Repopulated Creatures-55628-1-1-1746140786.zip" -o"$tmpdir" -r -y > /dev/null 2>&1
if [[ -d "$tmpdir/Repopulated Creatures/Data Files" ]]; then
    cp -a "$tmpdir/Repopulated Creatures/Data Files"/. "$MODS/302_repopulated_creatures"/
fi
rm -rf "$tmpdir"
echo "  Done."

echo ""
echo "[BONUS] OAAB_Data..."
extract_fomod "$ARCHIVES/OAAB_Data-49042-2-5-1-1764958680.7z" \
    "$MODS/OAAB_Data" \
    "00 Core"
echo "  Done."

echo ""
echo "=========================================="
echo "EXTRACTION COMPLETE"
echo "=========================================="
echo ""
echo "SKIPPED:"
echo "  - 202 Glow in the Dahrk (wrong version — need v2.11.2)"
echo ""
echo "Verify with: ls -1 ~/mods/morrowind/mods/*/  | head -100"
