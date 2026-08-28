#!/bin/bash
set -euo pipefail

# Updates the GitLab-hosted OpenMW Lua mods to their latest tagged release:
#   - Harvest Lights            -> mods/102_harvest_lights
#   - Distant Fixes: Lua Edition-> mods/207_distant_fixes_lua
#
# These are the only mods in the build that don't need a Nexus login, so their
# updates are fully automatable. The file set copied per mod mirrors each
# project's own pkg.sh (what the official gitlab.io zip contains), plus a
# version.txt recording the tag.
#
# Usage: ./update_gitlab_mods.sh            # update both
#        ./update_gitlab_mods.sh harvest    # just Harvest Lights
#        ./update_gitlab_mods.sh distant    # just Distant Fixes

MODS="${MODS_DIR:-$HOME/mods/morrowind/mods}"
GITLAB_API="https://gitlab.com/api/v4"

command -v curl >/dev/null 2>&1 || { echo "ERROR: curl not found." >&2; exit 1; }

# Extractor fallback chain: 7z (build standard) -> unzip -> python3 zipfile
extract_zip() {
    local zip="$1" dest="$2"
    if command -v 7z >/dev/null 2>&1; then
        7z x "$zip" -o"$dest" -y > /dev/null
    elif command -v unzip >/dev/null 2>&1; then
        unzip -q "$zip" -d "$dest"
    elif command -v python3 >/dev/null 2>&1; then
        python3 -m zipfile -e "$zip" "$dest"
    else
        echo "ERROR: need 7z, unzip, or python3 to extract archives." >&2
        exit 1
    fi
}

latest_tag() {
    local project_enc="$1"
    curl -sfL --max-time 30 "$GITLAB_API/projects/$project_enc/repository/tags?per_page=1" \
        | python3 -c "import json,sys; tags=json.load(sys.stdin); print(tags[0]['name'] if tags else '')"
}

# update_mod NAME GROUP/PROJECT TARGET_DIR PKG_PATH...
# PKG_PATHs are the files/dirs the project's own pkg.sh ships.
update_mod() {
    local name="$1" project="$2" target="$3"
    shift 3
    local project_enc="${project//\//%2F}"

    echo "== $name =="
    local tag
    tag=$(latest_tag "$project_enc")
    if [[ -z "$tag" ]]; then
        echo "  ERROR: could not determine latest tag for $project" >&2
        return 1
    fi
    echo "  Latest tag: $tag"

    if [[ -f "$target/version.txt" ]] && grep -q "Mod version: $tag\$" "$target/version.txt"; then
        echo "  Already up to date."
        return 0
    fi

    local tmpdir zip repo_base
    tmpdir=$(mktemp -d)
    zip="$tmpdir/src.zip"
    echo "  Downloading gitlab.com/$project @ $tag ..."
    curl -sfL --max-time 300 -o "$zip" \
        "https://gitlab.com/$project/-/archive/$tag/archive.zip?sha=$tag" || \
    curl -sfL --max-time 300 -o "$zip" \
        "$GITLAB_API/projects/$project_enc/repository/archive.zip?sha=$tag"

    extract_zip "$zip" "$tmpdir/x"
    # GitLab archives contain a single top-level dir named <project>-<tag>-<sha> or similar
    repo_base=$(find "$tmpdir/x" -mindepth 1 -maxdepth 1 -type d | head -1)
    if [[ -z "$repo_base" ]]; then
        echo "  ERROR: unexpected archive layout." >&2
        rm -rf "$tmpdir"
        return 1
    fi

    mkdir -p "$target"
    # Replace previous contents so removed files don't linger
    rm -rf "${target:?}"/*
    local missing=0
    for p in "$@"; do
        if [[ -e "$repo_base/$p" ]]; then
            cp -a "$repo_base/$p" "$target/"
        else
            echo "  WARNING: '$p' missing from archive (packaging may have changed — check the repo)."
            missing=1
        fi
    done
    echo "Mod version: $tag" > "$target/version.txt"
    rm -rf "$tmpdir"

    if (( missing )); then
        echo "  Updated to $tag with warnings."
    else
        echo "  Updated to $tag."
    fi
}

FILTER="${1:-all}"
FAILED=0

if [[ "$FILTER" == "all" || "$FILTER" == "harvest" ]]; then
    update_mod "Harvest Lights" "modding-openmw/harvest-lights" \
        "$MODS/102_harvest_lights" \
        CHANGELOG.md LICENSE README.md example-addon l10n scripts harvest-lights.omwscripts \
        || FAILED=1
fi

if [[ "$FILTER" == "all" || "$FILTER" == "distant" ]]; then
    update_mod "Distant Fixes: Lua Edition" "modding-openmw/distant-fixes-lua-edition" \
        "$MODS/207_distant_fixes_lua" \
        data scripts CHANGELOG.md l10n LICENSE README.md TESTING.md distant-fixes-lua-edition.omwscripts \
        || FAILED=1
fi

echo ""
if (( FAILED )); then
    echo "Done with errors — see above."
    exit 1
fi
echo "Done. Remember: content= lines for harvest-lights.omwscripts and"
echo "distant-fixes-lua-edition.omwscripts must stay present in openmw.cfg."
