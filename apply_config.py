#!/usr/bin/env python3
"""Apply the 2026-09 build to openmw.cfg + settings.cfg (Runbook A5 + A6).

Idempotent and measured: every data= line is added only if the folder exists
and is non-empty; every content=/groundcover= line only if that plugin file
exists in one of the data= folders. Re-run after adding mods. Backs up both
files first. --dry-run prints the plan without writing.

STATUS: TESTING — YMMV.
"""
import argparse, datetime, os, re, shutil, sys

HOME = os.path.expanduser("~")
CFG_DIR = f"{HOME}/.var/app/org.openmw.OpenMW/config/openmw"
OPENMW_CFG = f"{CFG_DIR}/openmw.cfg"
SETTINGS_CFG = f"{CFG_DIR}/settings.cfg"
MODS = f"{HOME}/mods/morrowind/mods"
REPO = os.path.dirname(os.path.abspath(__file__))
TUNING = f"{REPO}/config/settings-tuning.cfg"
SKIES_FALLBACKS = f"{REPO}/config/openmw-fallbacks-skies-iv.cfg"
BACKUP_DIR = f"{HOME}/mods/morrowind/saves_backup_local/config_before_apply"

# ---- data= paths, in load order, relative to MODS ---------------------------
# (insert_after: existing data= folder name to slot in behind; None = append)
DATA_ADDITIONS = [
    ("105_morrowind_enhanced_textures/atlas", "105_morrowind_enhanced_textures"),
    # graphics
    ("407_normal_maps_for_morrowind", None),
    ("408_normal_maps_for_everything", None),
    ("409_gitd_normal_pbr", None),
    ("405_skies_iv", None),
    ("406_new_starfields", None),
    ("412_better_waterfalls", None),
    ("413_waterfalls_tweaks", None),
    ("414_more_dynamic_water_meshes", None),
    ("415_improved_lights_all_shaders", None),
    ("416_kirels_interior_weather", None),
    ("411_morrowind_interiors_project", None),
    ("410_facelift_tamriel_data", None),
    # grass
    ("402_lush_synthesis", None),
    ("402_lush_synthesis/LUSH_VANILLA", None),
    ("402_lush_synthesis/LUSH_UNDERWATER", None),
    ("402_lush_synthesis/LUSH_SO", None),
    ("403_remiros_groundcover", None),
    ("404_remiros_groundcover_textures", None),
    ("417_oaab_saplings", None),
    ("418_lush_synthesis_tr", None),
    # shaders
    ("401_momw_post_processing_pack/01 XE-Shaders", None),
    ("401_momw_post_processing_pack/02 OMWFX-Shaders", None),
    ("401_momw_post_processing_pack/03 ZesterersVolumetricClouds", None),
    ("401_momw_post_processing_pack/04 WareyaOpenMWShaders", None),
    ("401_momw_post_processing_pack/05 SlippyDinkerOpenMWShaders", None),
    ("401_momw_post_processing_pack/07 ZesterersSSAO", None),
    # gameplay / QoL
    ("501_ldm_context_matters", None),
    ("502_protective_guards", None),
    ("514_arukinns_better_books", None),
    ("504_book_jackets_hd", None),
    ("515_melchiors_manuscripts", None),
    ("505_ui_modes", None),
    ("506_pause_control", None),
    ("507_friendly_autosave", None),
    ("508_quickselect", None),
    ("509_go_home", None),
    ("510_light_hotkey", None),
    ("511_convenient_thief_tools", None),
    ("512_smart_ammo", None),
    ("513_shield_unequipper", None),
]

CONTENT_REMOVE = [
    "RepopulatedMainland.ESP",        # until RM confirms TR 26.08
    # UMOPP 3.3.0: merged plugin replaces the individual ones ("do not use both")
    "adamantiumarmor.esp", "AreaEffectArrows.esp", "bcsounds.esp", "entertainers.esp",
    "EBQ_Artifact.esp", "LeFemmArmor.esp", "master_index.esp",
]
# (plugin, insert_after existing content= entry or None = before the .omwscripts block)
CONTENT_ESP = [
    ("TR_Factions.esp", "TR_Mainland.esm"),
    ("Unofficial Morrowind Official Plugins Patched.ESP", "RepopulatedMorrowind.ESM"),
    ("Siege at Firemoth.esp", "Unofficial Morrowind Official Plugins Patched.ESP"),
    ("RepopulatedCreatures_DialogueEdits.ESP", "RepopulatedCreatures.ESP"),
    ("GITD_Telvanni_Dormers.ESP", None),
    ("GITD_WL_RR_Interiors.esp", None),
    ("MorrowindInteriorsProject.ESP", None),
    ("MorrowindInteriorsProject_Bloodmoon.ESP", None),
    ("MorrowindInteriorsProject_TR.ESP", None),
    ("Waterfalls Tweaks.esp", None),
    ("k_weather.esp", None),
    ("OAAB_Saplings OpenMW Patch.ESP", None),
    ("book-jackets.esp", None),
    ("OAAB_BookJackets.omwaddon", None),
    ("LDM - Context Matters 1.7.ESP", None),
]
CONTENT_SCRIPTS = [
    "protective_guards.omwscripts",
    "UiModes.omwscripts", "pause-control.omwscripts", "friendly-autosave.omwscripts",
    "QuickSelect.omwscripts", "go-home.omwscripts", "LightHotkey.omwscripts",
    "convenient-thief-tools.omwscripts", "smart-ammo.omwscripts", "shield-unequipper.omwscripts",
]
GROUNDCOVER = [
    "lush3_ac.esp", "lush3_ai.esp", "lush3_bc.esp", "lush3_gl.esp", "lush3_wg.esp",
    "Rem_AL.esp", "lush3_SO_BM.esp", "lush3_RI_BM.esp", "lush3_SE_BM.esp",
    "OAAB_Saplings.esm", "lush3_TR_merged.esp",
]

# ---- helpers ---------------------------------------------------------------
def nonempty_dir(p):
    return os.path.isdir(p) and any(os.scandir(p))

def find_plugin(name, data_dirs):
    """Case-insensitive lookup of a plugin file in the data dirs (OpenMW is CI on Linux for content=)."""
    for d in data_dirs:
        try:
            for e in os.scandir(d):
                if e.is_file() and e.name.lower() == name.lower():
                    return e.name
        except FileNotFoundError:
            pass
    return None

def backup(path):
    os.makedirs(BACKUP_DIR, exist_ok=True)
    stamp = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
    dst = f"{BACKUP_DIR}/{os.path.basename(path)}.{stamp}"
    shutil.copy2(path, dst)
    return dst

# ---- openmw.cfg -------------------------------------------------------------
def apply_openmw_cfg(dry):
    lines = open(OPENMW_CFG, encoding="utf-8").read().split("\n")
    plan = []

    def data_line(rel):
        return f'data="{MODS}/{rel}"'

    existing_data = [l for l in lines if l.startswith("data=")]
    data_dirs = [re.sub(r'^data="?|"?$', "", l) for l in existing_data]

    # data= additions
    for rel, after in DATA_ADDITIONS:
        full = f"{MODS}/{rel}"
        line = data_line(rel)
        if line in lines:
            continue
        if not nonempty_dir(full):
            plan.append(f"  skip data (missing/empty): {rel}")
            continue
        if after:
            idx = next((i for i, l in enumerate(lines) if l.startswith("data=") and l.rstrip('"').endswith(after)), None)
            if idx is not None:
                lines.insert(idx + 1, line); plan.append(f"  + data after {after}: {rel}"); data_dirs.append(full); continue
        # append after the last data= line
        last = max(i for i, l in enumerate(lines) if l.startswith("data="))
        lines.insert(last + 1, line); plan.append(f"  + data: {rel}"); data_dirs.append(full)

    # content= removals
    for name in CONTENT_REMOVE:
        before = len(lines)
        lines = [l for l in lines if l.strip().lower() != f"content={name}".lower()]
        if len(lines) != before:
            plan.append(f"  - content: {name}")

    def has_content(name):
        return any(l.strip().lower() == f"content={name}".lower() for l in lines)

    def content_indices():
        return [i for i, l in enumerate(lines) if l.startswith("content=")]

    # ESP-type content
    for name, after in CONTENT_ESP:
        real = find_plugin(name, data_dirs)
        if not real:
            plan.append(f"  skip content (not found): {name}"); continue
        if has_content(real):
            continue
        idxs = content_indices()
        if after:
            ai = next((i for i in idxs if lines[i].strip().lower() == f"content={after}".lower()), None)
            if ai is not None:
                lines.insert(ai + 1, f"content={real}"); plan.append(f"  + content after {after}: {real}"); continue
        # after the LAST plugin that is not a Lua script (masters must precede dependents;
        # .omwscripts entries can sit anywhere, and the baseline has some mid-list)
        last_plugin = max(i for i in idxs if not lines[i].lower().endswith(".omwscripts"))
        lines.insert(last_plugin + 1, f"content={real}"); plan.append(f"  + content: {real}")

    # scripts at the end of the content block
    for name in CONTENT_SCRIPTS:
        real = find_plugin(name, data_dirs)
        if not real:
            plan.append(f"  skip content (not found): {name}"); continue
        if has_content(real):
            continue
        idxs = content_indices()
        lines.insert(idxs[-1] + 1, f"content={real}"); plan.append(f"  + content (lua): {real}")

    # groundcover=
    for name in GROUNDCOVER:
        real = find_plugin(name, data_dirs)
        if not real:
            plan.append(f"  skip groundcover (not found): {name}"); continue
        if any(l.strip().lower() == f"groundcover={real}".lower() for l in lines):
            continue
        idxs = [i for i, l in enumerate(lines) if l.startswith("groundcover=")] or content_indices()
        lines.insert(idxs[-1] + 1, f"groundcover={real}"); plan.append(f"  + groundcover: {real}")

    # Skies .IV fallbacks (only if Skies is installed)
    if nonempty_dir(f"{MODS}/405_skies_iv"):
        fb = [l for l in open(SKIES_FALLBACKS, encoding="utf-8").read().split("\n") if l.startswith("fallback=")]
        missing = [l for l in fb if l not in lines]
        if missing:
            last_fb = max(i for i, l in enumerate(lines) if l.startswith("fallback="))
            for j, l in enumerate(missing):
                lines.insert(last_fb + 1 + j, l)
            plan.append(f"  + {len(missing)} Skies .IV fallback= lines")

    print("openmw.cfg plan:"); print("\n".join(plan) or "  (no changes)")
    if not dry and plan:
        b = backup(OPENMW_CFG); print(f"  backup: {b}")
        open(OPENMW_CFG, "w", encoding="utf-8").write("\n".join(lines))
        print("  written.")

# ---- settings.cfg -----------------------------------------------------------
def parse_ini(text):
    """Ordered {section: {key: value}} ignoring comments; keeps first-seen order."""
    sections, order = {}, []
    cur = None
    for raw in text.split("\n"):
        line = raw.split("#", 1)[0].rstrip()
        if not line.strip():
            continue
        m = re.match(r"\s*\[(.+?)\]\s*$", line)
        if m:
            cur = m.group(1); sections.setdefault(cur, {}); order.append(cur) if cur not in order else None; continue
        if "=" in line and cur is not None:
            k, v = line.split("=", 1); sections[cur][k.strip()] = v.strip()
    return sections, order

def apply_settings(dry, refresh):
    live_text = open(SETTINGS_CFG, encoding="utf-8").read()
    live, live_order = parse_ini(live_text)
    tune, tune_order = parse_ini(open(TUNING, encoding="utf-8").read())
    if refresh:
        tune.setdefault("Video", {})["framerate limit"] = str(refresh)
    plan = []
    for sec in tune_order:
        for k, v in tune[sec].items():
            old = live.get(sec, {}).get(k)
            if old != v:
                plan.append(f"  [{sec}] {k} = {v}" + (f"   (was {old})" if old is not None else ""))
                live.setdefault(sec, {})[k] = v
                if sec not in live_order: live_order.append(sec)
    print("settings.cfg plan:"); print("\n".join(plan) or "  (no changes)")
    if not dry and plan:
        b = backup(SETTINGS_CFG); print(f"  backup: {b}")
        header = live_text.split("\n[", 1)[0].rstrip() + "\n\n" if live_text.lstrip().startswith("#") else ""
        out = header
        for sec in live_order:
            out += f"[{sec}]\n" + "".join(f"{k} = {v}\n" for k, v in live[sec].items()) + "\n"
        open(SETTINGS_CFG, "w", encoding="utf-8").write(out)
        print("  written.")

if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--refresh", type=int, help="monitor refresh rate for [Video] framerate limit")
    ap.add_argument("--no-settings", action="store_true", help="only touch openmw.cfg")
    a = ap.parse_args()
    for f in (OPENMW_CFG, SETTINGS_CFG, TUNING, SKIES_FALLBACKS):
        if not os.path.isfile(f):
            sys.exit(f"missing: {f}")
    apply_openmw_cfg(a.dry_run)
    if not a.no_settings:
        apply_settings(a.dry_run, a.refresh)
