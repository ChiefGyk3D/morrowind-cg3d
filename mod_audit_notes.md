# Mod Audit: Per-Mod Notes & Findings

> **STATUS: TESTING — YMMV.** "Installed correctly" below means the files are in
> place per each mod's docs, not that everything has been fully play-tested yet.

Audit date: 2026-03-31  
All readmes, FOMOD configs, and Nexus/TR/MOMW documentation reviewed.

---

## 001 — Patch for Purists (v5.0.6)

**Source**: readme in `Docs/Patch for Purists Readme.txt`

- **Requirements**: Morrowind, Tribunal, Bloodmoon (all three).
- **content= position**: AFTER Morrowind.esm, Tribunal.esm, Bloodmoon.esm.
- **Recommended companion mods**: Morrowind Code Patch (N/A for OpenMW), MOP, Expansion Delay.
- **Incompatible with**: UMP, MPP, Morrowind Rebirth, Script Improvements, GOTY Script Tidy.
- **MCP note**: PfP references two MCP options ("Separate axe inventory sounds", "Creature voiceover enable"). These are N/A for OpenMW — OpenMW handles these natively or differently.
- **Status**: ✅ Installed correctly. No missing steps.

---

## 002 — Unofficial Morrowind Official Plugins Patched (v3.2.1)

**Source**: No readme extracted (archive didn't include one at top level).

- **FOMOD options**: Individual plugin folders + compat folders. We extracted 7 individual plugins (adamantiumarmor, AreaEffectArrows, bcsounds, entertainers, EBQ_Artifact, LeFemmArmor, master_index) with assets + compat ESP overrides.
- **Firemoth exclusion**: Siege of Firemoth ESP was deliberately excluded — conflicts with TR's own Fort Firemoth content. TR's `scripts/tamrielrebuilt/firemothcomp.lua` checks for `TR_Firemoth_remover.esp` and shows a warning popup.
- **Status**: ✅ Installed correctly. No missing steps.

---

## 003 — Expansion Delay (v1.3)

**Source**: readme in `Docs/Expansion Delay ReadMe.txt`

- **Requirements**: Morrowind, Tribunal, Bloodmoon.
- **What it does**: Delays DB attacks until Hlaalu Hortator. Limits Bloodmoon dialogue to level 6+. Disables Louis Beauchamp until BM main quest starts.
- **Install**: Just the ESP.
- **Status**: ✅ Installed correctly. No missing steps.

---

## 004 — Morrowind Optimization Patch (v1.18.0)

**Source**: No readme in extracted folder. FOMOD archive reviewed.

- **FOMOD options extracted**:
  - 00 Core ✅
  - 01 Lake Fjalding Anti-Suck ✅
  - 02 Weapon Sheathing Patch ✅
  - 05 Graphic Herbalism Patch ✅
- **Key note (from GH readme)**: "MOP was used as the base for Graphic Herbalism. Load GH meshes after MOP."
- **Key note (from TR site)**: "Project Atlas — install after MOP."
- **data= position**: Before GH and PA. ✅
- **Status**: ✅ Installed correctly. All applicable FOMOD options extracted.

---

## 005 — Tamriel_Data HD (v25.05)

**Source**: `Docs/TamrielData_Usage.txt`, `TamrielData_Filepatcher.txt`, `TamrielData_Changelog.txt`

- **FOMOD options extracted**:
  - 00 Data Files ✅
  - 01 Data Files - Normal Maps ✅
- **File patcher**: Only needed for saves from build 16.09 or earlier. **Not applicable** to fresh installs.
- **Asset usage**: BSA files (PT_Data.bsa, TR_Data.bsa) contain assets. Some assets restricted to mods with TD dependency. Fine for our setup.
- **OpenMW note**: TD includes `.omwscripts` for OpenMW fallbacks from MWSE-only features.
- **data= position**: Before MOP (resources before meshes). ✅
- **Status**: ✅ Installed correctly. No missing steps.

---

## 006 — Tamriel Rebuilt (v25.08.12)

**Source**: No readme in extracted folder. TR website reviewed.

- **Dependencies**: Tamriel_Data.esm (confirmed present).
- **content=**: TR_Mainland.esm + tamrielrebuilt.omwscripts.
- **TR includes**: Own Fort Firemoth content (hence Firemoth UMOPP exclusion), GH-compatible flora natively, Weapon Sheathing support via TD, GitD assets merged into TD.
- **data= position**: After meshes/performance layer. ✅
- **Status**: ✅ Installed correctly.

---

## OAAB_Data (v2.5.1)

**Source**: No readme in extracted folder.

- **FOMOD options extracted**:
  - 00 Core ✅
  - 06 Animated Containers ✅
- **Dependencies**: Used by TR and several other mods.
- **Note**: Repopulated Morrowind has an optional `RepopulatedMorrowind_OAAB_Data.ESP` that integrates OAAB equipment into RM's NPCs.
- **⚠️ ACTION ITEM**: Consider extracting `RepopulatedMorrowind_OAAB_Data.ESP` from folder `06 Optional Plugins` in the RM archive and adding to content=. This would give RM's NPCs OAAB_Data equipment diversity.
- **Status**: ✅ Core installed. Optional RM integration available.

---

## 101 — Graphic Herbalism (v1.04)

**Source**: `docs/Graphic Herbalism MWSE & OMW readme.txt`, `GH FAQ & Troubleshooting.txt`

- **OpenMW users**: Only need the MESHES. Not the MWSE scripts.
- **Install order**: "Install GH meshes AFTER all flora/ore replacers" and "AFTER MOP".
- **Do NOT use (OpenMW)**: Pherim Reflection Mapped, Pherim Pulsing Kwama Reflect, Apel's Mucksponge Bumpmapped, Trama Bumpmapped — reflection maps not supported.
- **Compatibility**:
  - MOP: "MOP was used as the base. Load vanilla GH meshes after MOP." ✅
  - Animated Containers: "AC will override kollop behavior because GH ignores scripted containers." Noted.
  - TR/PT: "Meshes included in separate download." We don't need separate TR meshes since TR flora supports GH natively.
- **GH best order for vanilla**: 00 Vanilla Meshes → optional replacers → atlas patches.
- **data= position**: After MOP. ✅
- **Status**: ✅ Installed correctly. No missing steps for vanilla OpenMW.

---

## 102 — Harvest Lights (v1.x)

**Source**: `README.md`

- **Requirements**: OpenMW 0.49+. ✅ (We have 0.50.0)
- **Dependencies**: Designed for use with Graphic Herbalism. Supports TD IDs natively.
- **Install**: data= path + `content=harvest-lights.omwscripts`.
- **Known issue**: [OpenMW engine bug](https://gitlab.com/OpenMW/openmw/-/issues/7799) causes FPS drop when harvesting — not related to this mod.
- **Note**: Lights won't be disabled near objects harvested in existing saves (awaiting Lua API).
- **Status**: ✅ Installed correctly.

---

## 103 — Weapon Sheathing (v1.6)

**Source**: No readme extracted.

- **Install**: Animations/ and Meshes/ folders only (no ESP needed for OpenMW).
- **TR support**: Native via TD — many TR weapons have sheath/quiver models.
- **MOP patch**: MOP includes a Weapon Sheathing patch folder (02), which we extracted into MOP. ✅
- **Status**: ✅ Installed correctly.

---

## 104 — Project Atlas (v0.7.5)

**Source**: No readme at top level. FOMOD archive reviewed.

- **FOMOD options extracted**:
  - 00 Core (meshes) ✅
  - 01 Textures - MET (atlas textures for MET) ✅
  - 02 Urns - Smoothed ✅
  - 03 Redware - Smoothed ✅
  - 04 Emperor Parasols - Smoothed ✅
  - 05 Wood Poles - Hi-Res Texture ✅
  - MOP GH Patch ✅
- **Key note**: "Extension of MOP — install after MOP" (TR site).
- **Atlas textures**: Critical — without `textures/atl/*.dds`, meshes show pink. We have these from "01 Textures - MET". ✅
- **MET note**: Morrowind Enhanced Textures "contains pre-generated textures for Project Atlas" (TR site). So MET and PA's MET textures may overlap (MET's are presumably higher quality).
- **data= position**: After MOP and GH. ✅
- **Status**: ✅ Installed correctly. All applicable FOMOD options extracted.

---

## 105 — Morrowind Enhanced Textures (v6.1)

**Source**: No readme extracted.

- **What it is**: AI-upscaled textures for the entire vanilla game.
- **Recommended by TR**: "The currently recommended algorithmic (AI-based) texture upscale."
- **PA compatibility**: "Contains pre-generated textures for Project Atlas." So MET includes its own atlas textures.
- **data= position**: After meshes layer, before lighting. ✅
- **Status**: ✅ Installed correctly.

---

## 106 — Familiar Faces (v2.1)

**Source**: No readme extracted.

- **What it is**: Tweaks vanilla face meshes to use original textures better. Also light body mesh fixes.
- **Recommended by TR**: "Vanilla-purist-friendly mod. Compatible with whichever texture replacer."
- **data= position**: In NPCs layer. ✅
- **Status**: ✅ Installed correctly.

---

## 201 — OpenMW Containers Animated (v1.2.2)

**Source**: `OpenMW Containers Animated readme.txt`

- **Requirements**: OpenMW 0.46+. ✅
- **Install**: Meshes + ESP (registers sound records only). Optional folder has animated kollops.
- **Notes**:
  - "Does not provide any scripts and does not alter any container records."
  - "Not compatible with original qqqbbb Animated Containers mod."
  - Can be used in total conversions using MW assets.
  - GH note: "AC will override kollop behavior because GH ignores scripted containers."
- **Optional kollops**: Not extracted. These are in the "Optional" folder of the archive. Cosmetic only.
- **Status**: ✅ Installed correctly.

---

## 202 — Glow in the Dahrk

**Source**: Archive is v3.3.0 (WRONG VERSION).

- **⚠️ CRITICAL**: OpenMW does NOT support v3.0+ light rays. TR recommends GitD **v2.11.2** for OpenMW.
- **Nords Shut Your Windows DEPENDS on GitD**. Without GitD, the Nords meshes reference GitD switch nodes that won't function.
- **TR note**: "The TR patch is not needed, as the assets are already merged into Tamriel_Data."
- **data= position**: Should be in Lighting layer, before Nords.
- **⚠️ ACTION ITEM**: Download GitD v2.11.2 from Nexus Old Files tab, extract, add data= + content= lines.
- **Status**: ❌ NOT INSTALLED. Wrong version downloaded. Folder empty.

---

## 203 — Nords Shut Your Windows (v2.1)

**Source**: `Readme.txt`

- **Requirements**: Morrowind, Tribunal, Bloodmoon, MGE XE (N/A for OpenMW), **Glow in the Dahrk**.
- **⚠️ DEPENDENCY**: Requires GitD. GitD is currently NOT installed.
- **FOMOD options**:
  - 00 Core Files ✅ (required meshes/textures)
  - 01 Vanilla style (optional: vanilla stones on windows)
  - 02 Interior sunrays (optional)
  - 03 Vanilla style sunrays (optional)
  - We extracted: Core (Purist meshes merged into Meshes/) ✅
- **Install order**: "Install this mod AFTER Glow in the Dahrk."
- **Incompatible with**: Other Nordic window replacers.
- **data= position**: After GitD in Lighting layer. ✅ (once GitD is installed)
- **Status**: ⚠️ Meshes installed, but **GitD dependency missing**. Will not function correctly without GitD.

---

## 204 — TrueType Fonts

**Source**: No readme extracted.

- **Install**: Just Fonts/ folder (Ayembedt.ttf, DejaVuLGCSansMono.ttf, Pelagiad.ttf, openmw_font.xml).
- **Status**: ✅ Installed correctly.

---

## 205 — Cantons on the Global Map (v1.1)

**Source**: No readme extracted.

- **Install**: Just the ESP.
- **Status**: ✅ Installed correctly.

---

## 206 — Distant Seafloor (v2.00)

**Source**: No readme extracted.

- **Install**: ESM file.
- **⚠️ IMPORTANT**: `distant_seafloor_2.00.esm` must load BEFORE Bloodmoon.esm in content= (OpenMW engine requirement — ESM dependency ordering).
- **Status**: ✅ Installed correctly. Content= position verified.

---

## 207 — Distant Fixes: Lua Edition

**Source**: `README.md`, `CHANGELOG.md`, `TESTING.md`

- **Requirements**: OpenMW 0.49+. ✅
- **Install**: data= path + `content=distant-fixes-lua-edition.omwscripts`.
- **Supports YAML-based data** — any mod can ship its own `.yml` for distant fixes.
- **Supported content**: Morrowind, Bloodmoon, BCOM, several Telvanni mods, more.
- **⚠️ INCOMPATIBLE WITH**: Dynamic Distant Buildings for OpenMW, Dynamic Distant Buildings Lua, Distant Fixes for specific mods (RoHT, UL, UM — those are bundled here).
- **Can be added to existing saves**: Startup/update fixes trigger on specific quest stages.
- **Status**: ✅ Installed correctly.

---

## 301 — Repopulated Morrowind (v2.6)

**Source**: `Docs/RepopulatedMorrowind_Readme.txt`, FOMOD archive reviewed.

- **Dependencies**: Tamriel_Data. ✅
- **FOMOD options extracted**:
  - 00 Core ✅ (ESM + meshes + icons + textures)
  - 01 Repopulated Morrowind ✅ (non-BCOM ESP, 6445 bytes) — correct since we don't have BCOM
  - 03 Bloodmoon ✅ (RepopulatedBloodmoon.ESP)
  - 05 Tamriel Rebuilt ✅ (RepopulatedMainland.ESP)
  - 07 AM Sounds ✅
- **NOT extracted (correct)**:
  - 02 BCOM Repopulated Morrowind — we don't use BCOM
  - 04 Tomb of the Snow Prince — we don't use TotSP
  - 08 Silent AM Sounds — mutually exclusive with 07
  - 09 Images — FOMOD images only
  - 10 Compatibility Patches — we don't use Animated Morrowind or Immersive Mournhold
- **⚠️ OPTIONAL**: `06 Optional Plugins/RepopulatedMorrowind_OAAB_Data.ESP` — since we have OAAB_Data, this 35KB ESP would give RM's NPCs OAAB equipment. Worth considering.
- **Supported optional mods** (we don't have these, noted for future):
  - Ceremonial Adamantium Armor, Mage Robes, Morag Tong variants, Weapons Expansion, many more.
  - Redaynia Restored, Province Cyrodiil (RepopulatedStirk), SHotN (RepopulatedSkyrim)
- **BCOM note**: "If using BCOM, install BCOM first, RM after." The BCOM ESP (02) is 17691 bytes vs non-BCOM (01) at 6445 bytes. **Must switch to 02 if BCOM is added later.**
- **Status**: ✅ Installed correctly for non-BCOM. OAAB optional plugin available.

---

## 302 — Repopulated Creatures (v1.1)

**Source**: No readme extracted.

- **What it does**: Distributes TD creatures, undead, and Daedra to Vvardenfell via leveled lists + hand placement.
- **Dependencies**: Tamriel_Data. ✅
- **Mentioned by TR**: In "Mods aligning vanilla with the wider Tamriel" section.
- **Status**: ✅ Installed correctly.

---

## Summary of Action Items

| Priority | Item | Status |
|----------|------|--------|
| **HIGH** | Download GitD v2.11.2 from Nexus Old Files | ❌ Not done |
| **HIGH** | Extract + configure GitD 2.11.2 in 202_glow_in_the_dahrk | ❌ Blocked on download |
| **MEDIUM** | Extract RepopulatedMorrowind_OAAB_Data.ESP | ❌ Not done (optional enhancement) |
| **LOW** | Consider MOMW Tools Pack for leveled list merging | Not started (noted by mlox) |
| **INFO** | Nords Shut Your Windows works but depends on GitD | ⚠️ GitD missing |
| **INFO** | Containers Animated Optional kollops not extracted | Cosmetic only |
| **FUTURE** | If adding BCOM: swap RM ESP from folder 01 to folder 02 | For Stage 6 |
| **FUTURE** | If adding SHotN/PC: extract RepopulatedSkyrim/RepopulatedStirk ESPs | For expansion |
