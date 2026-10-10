#!/bin/bash
set -euo pipefail

# Installs / updates the GitLab-hosted OpenMW Lua mods to their latest tagged
# release, straight from the GitLab API. None of these need a Nexus login, so
# they are fully automatable.
#
# Per mod, everything at the repo root is copied EXCEPT build/site scaffolding
# (web/, Makefile, pkg.sh, .git*, ...). Verified against each project's own
# pkg.sh: this yields exactly the file set their official gitlab.io zip ships.
# A version.txt records the tag; re-runs are no-ops when already current.
#
# Usage: ./update_gitlab_mods.sh            # core (baseline: Harvest Lights, Distant Fixes)
#        ./update_gitlab_mods.sh qol        # enhancement-plan QoL Lua mods (5xx folders)
#        ./update_gitlab_mods.sh all        # both
#        ./update_gitlab_mods.sh <name>     # one mod, e.g. ui-modes
#
# After installing, add the content= lines listed at the end to openmw.cfg.

MODS="${MODS_DIR:-$HOME/mods/morrowind/mods}"
GITLAB_API="https://gitlab.com/api/v4"
GROUP="modding-openmw"

command -v curl >/dev/null 2>&1 || { echo "ERROR: curl not found." >&2; exit 1; }

# name | target folder | content= line(s) to add | group
# (content lines are informational — printed at the end)
CORE_MODS=(
    "harvest-lights|102_harvest_lights|harvest-lights.omwscripts"
    "distant-fixes-lua-edition|207_distant_fixes_lua|distant-fixes-lua-edition.omwscripts"
)
QOL_MODS=(
    "ui-modes|505_ui_modes|UiModes.omwscripts"
    "pause-control|506_pause_control|pause-control.omwscripts"
    "friendly-autosave|507_friendly_autosave|friendly-autosave.omwscripts"
    "quickselect|508_quickselect|QuickSelect.omwscripts"
    "go-home|509_go_home|go-home.omwscripts  (or go-home-locking-doors.omwscripts — pick ONE)"
    "light-hotkey|510_light_hotkey|LightHotkey.omwscripts"
    "convenient-thief-tools|511_convenient_thief_tools|convenient-thief-tools.omwscripts"
    "smart-ammo|512_smart_ammo|smart-ammo.omwscripts"
    "shield-unequipper|513_shield_unequipper|shield-unequipper.omwscripts"
)

# Repo-root entries that are build/site scaffolding, never mod content
DENY=(web .git .gitignore .gitlab-ci.yml .gitmodules .gitattributes .gitlab .vscode
      .DS_Store Makefile pkg.sh build.sh update-all-submodules.sh)

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

denied() {
    local name="$1" d
    for d in "${DENY[@]}"; do [[ "$name" == "$d" ]] && return 0; done
    return 1
}

# update_mod NAME TARGET_DIR
update_mod() {
    local name="$1" target="$2"
    local project="$GROUP/$name" project_enc="$GROUP%2F$name"

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
        "$GITLAB_API/projects/$project_enc/repository/archive.zip?sha=$tag"

    extract_zip "$zip" "$tmpdir/x"
    repo_base=$(find "$tmpdir/x" -mindepth 1 -maxdepth 1 -type d | head -1)
    if [[ -z "$repo_base" ]]; then
        echo "  ERROR: unexpected archive layout." >&2
        rm -rf "$tmpdir"
        return 1
    fi

    mkdir -p "$target"
    rm -rf "${target:?}"/*          # replace, so removed files don't linger
    local entry copied=0
    for entry in "$repo_base"/* "$repo_base"/.[!.]*; do
        [[ -e "$entry" ]] || continue
        denied "$(basename "$entry")" && continue
        cp -a "$entry" "$target/"
        copied=$((copied + 1))
    done
    echo "Mod version: $tag" > "$target/version.txt"
    rm -rf "$tmpdir"

    if ! find "$target" -maxdepth 1 -iname '*.omwscripts' -print -quit | grep -q .; then
        echo "  WARNING: no .omwscripts at mod root — layout may have changed, check README."
    fi
    echo "  Updated to $tag ($copied entries)."
}

SELECT="${1:-core}"
FAILED=0
INSTALLED=()

run_set() {
    local spec name target content
    for spec in "$@"; do
        IFS='|' read -r name target content <<< "$spec"
        if update_mod "$name" "$MODS/$target"; then
            INSTALLED+=("$target  ->  content=$content")
        else
            FAILED=1
        fi
    done
}

case "$SELECT" in
    core) run_set "${CORE_MODS[@]}" ;;
    qol)  run_set "${QOL_MODS[@]}" ;;
    all)  run_set "${CORE_MODS[@]}" "${QOL_MODS[@]}" ;;
    *)
        match=""
        for spec in "${CORE_MODS[@]}" "${QOL_MODS[@]}"; do
            [[ "$spec" == "$SELECT|"* ]] && match="$spec"
        done
        if [[ -z "$match" ]]; then
            echo "Unknown mod '$SELECT'. Known: $(printf '%s\n' "${CORE_MODS[@]}" "${QOL_MODS[@]}" | cut -d'|' -f1 | tr '\n' ' ')" >&2
            exit 1
        fi
        run_set "$match" ;;
esac

echo ""
if ((${#INSTALLED[@]})); then
    echo "Installed/verified. Make sure openmw.cfg has a data= line for each folder"
    echo "AND the matching content= line (Lua mods are inert without it):"
    printf '  %s\n' "${INSTALLED[@]}"
fi
if (( FAILED )); then
    echo ""; echo "Done with errors — see above."
    exit 1
fi
