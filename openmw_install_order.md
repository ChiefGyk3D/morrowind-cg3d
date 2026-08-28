# OpenMW Mod Install Order & Layering Guide

> **STATUS: TESTING — YMMV.** Order below is sourced from MOMW/TR guidance but is
> still being validated tier by tier on one machine.

**System**: OpenMW 0.50.0 Flatpak · RTX 5070 Ti · Ryzen 9 5950X · 64 GB RAM · Pop!_OS  
**Principle**: Later `data=` entries override earlier ones — foundation first, then textures/meshes, then city/world overhauls, then NPC/population, then compatibility patches.  
**Sources**: [Modding-OpenMW "I Heart Vanilla: DC"](https://modding-openmw.com/lists/i-heart-vanilla-directors-cut/), [TR Recommended Mods](https://www.tamriel-rebuilt.org/recommended-mods), [Modding-OpenMW CFG Generator](https://modding-openmw.com/cfg/total-overhaul/)

---

## Layering Order (data= paths)

The curated OpenMW lists organize like this:

1. **Patches** — bug fixes, no gameplay changes
2. **Modding Resources** — Tamriel_Data, OAAB_Data (shared assets)
3. **Meshes / Performance** — MOP, Graphic Herbalism, Project Atlas
4. **Landmass / Content** — Tamriel Rebuilt
5. **Textures** — MET, texture upscales
6. **Lighting** — Harvest Lights, GitD, Nords
7. **Animations** — Containers Animated, Weapon Sheathing
8. **Distant** — Distant Seafloor, Distant Fixes
9. **NPCs** — Familiar Faces, heads/bodies
10. **UI** — Fonts, map patches
11. **World Population** — Repopulated Morrowind, Repopulated Creatures
12. **Compatibility Patches** — last, so they override everything

---

## Tier 1: Foundation (install first, test before proceeding)

| # | Mod | Layer | Notes |
|---|-----|-------|-------|
| 1 | Patch for Purists | Patches | Supersedes MPP/UMP. Use alongside MOP + Expansion Delay. content= AFTER Morrowind/Tribunal/Bloodmoon. |
| 2 | Unofficial Morrowind Official Plugins Patched | Patches | Individual plugins ONLY (no Firemoth — conflicts with TR). |
| 3 | Tamriel_Data (HD) | Resources | Must be before any mod that depends on it (TR, OAAB, Repopulated). File patcher only needed for saves from build ≤16.09. |
| 4 | Morrowind Optimization Patch | Meshes | Goes AFTER TD in data=. PA and GH build on top of MOP. |
| 5 | Expansion Delay | Patches/QoL | Just an ESP. Content order: after UMOPP ESPs. |
| 6 | Tamriel Rebuilt | Landmass | Depends on TD. data= AFTER meshes/performance layer so it can rely on MOP meshes. |

### Why this order
- Modding-OpenMW puts PfP + UMOPP in the "Patches" section first.
- TD goes before landmass mods and any mod that depends on it.
- MOP sits in "Meshes/Performance" before landmass/content additions.
- TR is the landmass anchor and depends on TD.
- Expansion Delay is QoL that should be stable before adding content.

---

## Tier 2: Vanilla-Plus (meshes, textures, gameplay tweaks)

| # | Mod | Layer | Notes |
|---|-----|-------|-------|
| 7 | Graphic Herbalism (MWSE & OpenMW) | Meshes | OpenMW only needs the MESHES, not MWSE scripts. Install AFTER MOP (MOP is the base). Do NOT use reflection-mapped options. |
| 8 | Project Atlas | Meshes | Extension of MOP. Install AFTER MOP and GH per TR recommendation. Needs atlas textures (MET folder or manual). |
| 9 | Harvest Lights | Lighting | Enhancement for GH. Requires OpenMW 0.49+. Supports TR natively. |
| 10 | Weapon Sheathing | Animation | TR weapons supported natively via TD. |
| 11 | Morrowind Enhanced Textures | Textures | Main AI-upscale layer. Recommended by TR. Contains pre-generated PA atlas textures. |
| 12 | Familiar Faces | NPCs | Vanilla-purist face mesh fix. Compatible with any texture replacer. Recommended by TR. |

### Why this order
- GH and PA sit in the curated "Meshes/Performance" layer.
- Harvest Lights explicitly enhances GH → after it.
- Weapon Sheathing is safe in the animation layer, TR has native support via TD.
- MET is the main texture layer and is specifically recommended by TR.
- Familiar Faces is a clean NPC-face upgrade, also TR-recommended.

---

## Tier 3: Polish (lighting, animation, UI, distant)

| # | Mod | Layer | Notes |
|---|-----|-------|-------|
| 13 | OpenMW Containers Animated | Animation | Native OpenMW 0.46+ feature. Optional kollop meshes in "Optional" folder. |
| 14 | Glow in the Dahrk **2.11.2** | Lighting | **OpenMW MUST use v2.11.2** — v3.0+ light rays not supported. TR patch already merged into TD. |
| 15 | Nords Shut Your Windows | Lighting | **Requires GitD** — install AFTER GitD. Uses "00 Core" + choice of style (we use "00 Core" only = Purist). |
| 16 | TrueType Fonts | UI | Fonts folder only. |
| 17 | Cantons on the Global Map | UI | Just an ESP. |
| 18 | Distant Seafloor | Distant | ESM must load before Bloodmoon in content=. |
| 19 | Distant Fixes: Lua Edition | Distant | **Incompatible with**: Dynamic Distant Buildings, Dynamic Distant Buildings Lua. Supports BCOM, TR, many others natively. |

### Why this order
- Containers Animated is in the curated "Animation" layer.
- GitD + Nords are in the "Lighting/Interiors" layer. TR says OpenMW users stick to GitD 2.11.2.
- Fonts + Cantons are UI polish.
- Distant mods go last in visual layers — distant/detail conflicts show up fast.

---

## Stage 4–8: Big Boy Expansion (future, after Tier 1–3 are stable)

### Stage 4: Big Texture/Visual Stack
| # | Mod | Layer | Notes (2026-08 research) |
|---|-----|-------|--------------------------|
| 20 | Vurt's Morrowind Visual Resurgence (Nexus 56037) | Textures | On MOMW Graphics Overhaul, loaded AFTER MET so it wins overlaps. Get HD version + OAAB Retexture + VFX Patch; delete 3 bad textures per MOMW usage notes. "Overhaul-tier faithful" — half a step past strict vanilla-plus. |
| 21 | Tamriel Data Texture Upscale | Textures | ⚠️ Pulled from MOMW lists 2026-08-23 pending TD 26.08 update — verify before installing. |
| 22 | OAAB Full Upscale | Textures | |
| 23 | Normal Maps for Morrowind (Nexus 45336) | Normal Maps | Classic vanilla-friendly base layer. |
| 24 | Normal Maps for Everything (Nexus 52567) | Normal Maps | The key pack: ships per-mod modules for exactly our stack — MET, Project Atlas ("Atlas Textures AIO"), Tamriel_Data, OAAB, BCOM. Pick modules matching installed texture packs; old MET-conflict folklore is obsolete. Requires manual deletion of known-bad `_n.dds` files (list in MOMW usage notes). TR "Hall of Justice" module pulled 2026-08-23 pending TR 26.08 update. |
| 25 | Normal Maps for Premium (Nexus 56419) | Normal Maps | Covers mods used on MOMW lists; load after 23/24. |
| 26 | GitD Normal Specular PBR Maps (Nexus 58029) | Normal Maps | Pairs with our pending Glow in the Dahrk 2.11.2 install. |
| 27 | V.I.P. - Vegetto's Important Patches | Compat Patches | |

### Stage 5: Heads / Faces / Character Appearance

> ⚠️ **PLAN CHANGED (2026-08-23)**: MOMW removed MacKom's Humanoid Heads and all
> eight satellite mods from their lists — "not yet updated for the current
> Tamriel Data (HD) release, causing issues with newly added face models."
> The MacKom stack below is **deferred** until it's patched for TD 26.08.

Current vanilla-faithful path (available now):

| # | Mod | Layer | Notes |
|---|-----|-------|-------|
| 28 | Facelift for Tamriel Data (Nexus 53935) | NPCs | TR/TD NPC face enhancement; pairs with our Familiar Faces. On MOMW I Heart Vanilla: DC. |
| 29 | Facelift (Nexus 47617) | NPCs | Base-game companion to 28, same vanilla-enhancement lane. |
| 30 | Westly's Faces Refurbished (Nexus 51214) | NPCs | HD but "vanilla-like feeling" — MOMW's Graphics Overhaul replacement for MacKom (added 2026-08-23). Optional bigger step. |

Deferred (revisit once updated for Tamriel_Data 26.08): MacKom's Humanoid Heads,
New Hairs / Expressive Eyes for MacKom's, Dandion's Familiar Looks fixes, the TR
MacKom head/hair replacers and patches.

**Rule**: Pick ONE head ecosystem. Do not mix Facelift/Westly's with MacKom.

### Stage 6: City Overhaul Core
| # | Mod | Layer |
|---|-----|-------|
| 36 | Beautiful Cities of Morrowind **3.3.0+** | Cities |

Install BCOM **before** city add-ons and **before** Repopulated Morrowind if you want BCOM compatibility pieces. TR_BCOM_Patch.ESP and other addon patches exist.

2026-08 notes: use v3.3.0 (2026-04-19) or later, download "BCOM Core" +
"Patches" (patches go in a `Patches/` subfolder); the "Various BCoM and OpenMW
patches" companion (Nexus 51194) and MOMW Patches hub
(gitlab.com/modding-openmw/momw-patches) carry current fixes. Verify TR 26.08
compatibility patches when this stage lands, and sort with PLOX afterwards.

### Stage 7: City Extras (on top of BCOM)
| # | Mod | Layer |
|---|-----|-------|
| 37 | Maar Gan - Town of Pilgrimage | Cities |
| 38 | Nordic Dagon Fel | Cities |
| 39 | Hanging Gardens of Suran | Cities |
| 40 | Velothi Wall Art | Cities |
| 41 | Concept Art Palace (Vivec City) | Cities |
| 42 | Better Flames for Concept Art Palace - OpenMW | Cities |
| 43 | Humble Prayer Hall | Cities |
| 44 | Guar Stables of Vivec | Cities |
| 45 | Bell Towers of Vvardenfell | Cities |
| 46 | Bell Towers Directional Sound | Cities |

### Stage 8: World Population (after BCOM)
| # | Mod | Layer |
|---|-----|-------|
| 47 | Repopulated Morrowind | Population |
| 48 | Repopulated Creatures | Population |

**Important**: If using BCOM, install BCOM first, Repopulated Morrowind after. Repopulated Morrowind includes a "02 BCOM Repopulated Morrowind" FOMOD option.

---

## Caution

This is the **mod layering order**, not the final **plugin load order**. For big builds, use the [Modding-OpenMW CFG Generator](https://modding-openmw.com/cfg/total-overhaul/) because many mods have alternate folders, patches, and options.

Safe workflow:
1. Install in the order above
2. Test after each stage
3. Use mlox to validate plugin load order
4. Work out final `data=` lines from actual extracted folders
