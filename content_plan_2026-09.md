# Content plan — more NPCs, more life, more to do (Phase H)

> **STATUS: PLANNED — nothing here is installed yet.** Researched 2026-09-09
> against modding-openmw.com (MOMW) only, mainly the **Expanded Vanilla** (EV)
> list ("preserve the look and feel of the vanilla game while adding a large
> amount of new content", 434 mods, OpenMW 0.51). Every Nexus ID below is the
> one MOMW prints. Nothing was verified against Nexus itself.

Goal: the best vanilla-plus Morrowind — more NPCs and life in the world, more
quests and factions — on top of the 2026-09 build (`GAME_NIGHT_RUNBOOK.md`).
No BCOM, no Rebirth, no total conversions.

**The no-BCOM rule.** EV assumes Beautiful Cities of Morrowind and for several
mods says "you only need the data path, a replacement plugin was provided by
BCOM". We have no BCOM, so for those mods **use the mod's own Nexus plugin**
and skip every BCOM-flavoured MOMW patch / `BCOM` sub-folder. Flagged below.

Downloads: add each mod to `config/nexus_manifest.json` and run
`./download_mods.py` (Premium API). Install one tier per prep night, test,
then the next.

## Verdict on things already downloaded

| Item | Verdict |
|---|---|
| Arukinn's Better Books and Scrolls (43100) | **Use.** MOMW TO order: Arukinn → Book Jackets HD → Melchior's Magnificent Manuscripts. Extractor entry 514. |
| Melchior's Magnificent Manuscripts (45626) | **Use** `00 Core` + `01 Book Jackets Patch`. Extractor entry 515, data= after 504. |
| OAAB_BookJackets (56176) | Keep (MOMW's Various Mods and Patches carries it, TO 7.13.0). `OAAB_BookJackets.omwaddon` after `book-jackets.esp`. |
| GitD "PBR" file (58029) | Not used; the "Normal and Specular Maps" file is the OpenMW one. Parked. |
| MIP "Anthology Solstheim" file | Not used (Anthology/TOTSP Solstheim coordinates). Parked. |
| Fantasia Grass Mod v2 (56570) | Not on MOMW, overlaps Lush. Parked. |
| Morrowind Comes Alive 8.2 (6006) | **Leave uninstalled.** MOMW: "Partially Working", in no list; its listed alternatives are Repopulated Morrowind (which we run) and Friends and Foes. |

## Tier 1 — big content, low risk (all in Expanded Vanilla)

| # | Mod | Nexus | What it adds | Install notes (MOMW) |
|---|-----|-------|--------------|----------------------|
| H1 | **OAAB Grazelands** | 49075 | Overhaul of Vos / Tel Vos and the northern Grazelands, "16+ new quests with approximately 18,000 words of dialogue" | `00 Core` + `03 HD Textures` + `01 Remiros Groundcover GL Patch for Trackless Grazelands`. content= `OAAB_Grazelands.ESP`; groundcover= `Rem_GL - OAAB Landscape.esp`. MOMW Patches `08 Trackless Grazeland For OpenMW`. |
| H2 | **OAAB Tel Mora** | 46177 | New buildings + quests in Tel Mora, lore-friendly scale | `00 Core`, `01 Female Guards`, `02 HD Textures`, `03 OpenMW Addons`. content= `OAAB_Tel Mora.esm`, `OAAB_Tel Mora_Female Guards.ESP`. |
| H3 | **OAAB Brother Juniper's Twin Lamps** | 51424 | Joinable Twin Lamps faction, ~20 quests | content= `OAAB Brother Junipers Twin Lamps.esp`. MOMW Patches ships `Rem_BC Brother Junipers Twin Lamps patch.esp` (grass; we use Lush BC so n/a). |
| H4 | **AFFresh** | 53006 | ~30 quests on vanilla NPCs, new-character friendly | content= `AFFresh.esm`. |
| H5 | **Cutting Room Floor – Modular** | 47307 | Restores cut NPCs, quests, dialogue, voice | Files: `Modular` + `Modular Patches` + `High Resolution Textures` + `Optimized Banner` (into `optimized_banner/`). Plugins: Free Slaves / Characters / Missing Persons TR / Dead Heroes / Extra Jobs / Extra Orders / Quests / Items TR / Voice Lines / Herders / Ald Redaynia / Ald-ruhn Underground (**not** Snow Prince). Enable Repopulated Morrowind's `RepopulatedMorrowind_CRF_AldRedaynia.ESP`. Delete `Splash`. |
| H6 | **Rise of House Telvanni 1.52** | 27545 | Telvanni Archmagister quest line | Main file + `Flask mesh update` (into `FlaskMeshUpdate/`). content= `Rise of House Telvanni.esm`. (2.0 exists, Nexus 48225, but EV stays on 1.52 for Uvirith's Legacy.) |
| H7 | **Uvirith's Legacy 3.53** + Building Up UL | Dropbox via MOMW / — | Tel Uvirith as a real stronghold | **No-BCOM:** use `Uvirith's Legacy_3.53.esp` + `UL_3.5_RoHT_1.52_Add-on.esp` + MOMW Patches `32 OpenMW Fixes` (`UL_3.5_OpenMW_1.3_Add-on.esp`); TR add-on from **Null's Minor Patches** (the bundled one is stale). settings: `apply lighting to environment maps = true`. Building Up UL: `Building Up Uvirith's Legacy1.1.ESP`, NOT its `Fast Eddie Fix`. |
| H8 | **Imperial Legion Expansion** | 44469 | Legion overhaul: quests, items, NPCs | **No-BCOM:** use the Nexus plugin; skip MOMW Patches 68. |
| H9 | **Imperial Factions** | 49855 | Mages / Thieves / Fighters Guild overhaul | Use MOMW Patches `21 Imperial Factions Patched` (`Imperial Factions.ESP`) — not BCOM-specific. Closest thing to a "Mages Guild overhaul". |
| H10 | **Join the Dark Brotherhood** | 48858 | 30+ quests | content= `Dark Brotherhood.esp`. |
| H11 | **Quests for Clans and Vampire Legends** | 49486 | 90+ vampire quests, 7 factions (needs OAAB + TD — have both) | Main `v1.4.1`; delete `Splash`. Optional companion: Quarra Clan – Refreshed (48955). |
| H12 | **Roaring Arena – Betting and Bloodletting** | 50954 | Arena with 130 fighters, betting, crowds; same author as Repopulated Morrowind | Main + `Missing Assets Hotfix` + `Empty Generated Voice Lines` (into `noVO/`). **No-BCOM:** pick the non-BCOM Vivec option; skip the TOTSP Bloodmoon option. content= `RoaringArena.esm`, `RoaringArena.ESP`, `_MageRobes.ESP`, `_OAAB.ESP`, `_Solstheim.ESP`. |

## Tier 2 — NPC life and ambience (small, cheap)

| # | Mod | Nexus | Notes |
|---|-----|-------|-------|
| H13 | Yet Another Guard Diversity ("Full Cephalopod") + Expanded Imperials | 45894 + 47583 | **No-BCOM:** use YAGD's own ESP. MOMW: "Delta Plugin is required for this to function properly" (leveled-list merge with Repopulated Morrowind — `tools_reference.md`). Expanded Imperials adds `- TR.ESP` + `- Bloodmoon.ESP`. |
| H14 | Bards of Bardenfell | 53278 | 14 bards in taverns. `Bards of Bardenfell.esp`. |
| H15 | Sload and Slavers | 49074 | **No-BCOM:** own plugin. `Data Files` + `Upscaled Textures`. |
| H16 | Sloadic Transports | 50546 | Airship at Molag Mar; "use only one .esp". |
| H17 | Shady Sam | 53304 | Night fence + Legion bounty quest (OAAB). |
| H18 | Diverse Khajiit · Nordic Dagon Fel NPCs · M'Aiq on the Mainland · Wandering Umbra | 48832 · 52390 · 45674 · 44913 | All EV, no notes. |
| H19 | Traveling Guar Riders (OpenMW) · Repopulated Waters – Rowing NPCs | 52788 · 53653 | Same author as Repopulated Morrowind; both ship `_TR.ESP`. Not list-tested. |
| H20 | **Friends and Foes** | 49251 | MOMW's other MCA substitute; `00 Core` + `01 TR addon` + **`02 Repopulated Morrowind Patch`** + `OpenMWBookFix` (separate file, into `OpenMWBookFix/`). Skip `03 BCoM patch`. content= `F&F_base.esm`, `F&F_TR.ESP`. Not list-tested. |
| H21 | Dialogue: Djangos Dialogue 1.4 · Greetings for No Lore · FMBP Greet Service · Idle Talk · Local Lore (Silt Strider Animation Restored edition) | 47253 · 46063 · 50937 · 46948 · 48063 | LDM already in. Idle Talk = 200+ voice entries from edited originals. Quest Voice Greetings (52273) / Immersive Morrowind (54513) are ElevenAI — taste. |
| H22 | Mages Guild interiors: Ald-Ruhn MG Expansion · Caldera MG Expanded · Vivec MG Redone | 48321 · 45750 · 57059 | Not in EV; interior-only, low risk. |
| H23 | Vivec Voice Addon (Tribunal Version) | 589 | "Only the `Sound` folder… use the plugin from Alvazir's Various Patches" (EV #29). |

## Tier 3 — systems (world density, travel, companions)

| # | Mod | Nexus | Notes |
|---|-----|-------|-------|
| H24 | Wares Ultimate | 52013 | `Wares-base.esm`, `Wares_lists_OAAB.ESP`, `Wares_lists_TD.ESP`, `Wares_traders.ESP`. |
| H25 | Tamrielic Integrations | 57488 | TD/OAAB gear into leveled lists; three ESPs. |
| H26 | Expansions Integrated | 47861 | `Expansions Integrated - Fewer BM Creatures.esp`; pairs with Expansion Delay. |
| H27 | Improved Inns Expanded | 48610 | Skip `05 BCOM Version`. |
| H28 | Wandering Creature Merchants: Lua Edition · Signpost Fast Travel | GitLab · EV #425 | Lua. |
| H29 | Best Friends Forever + Persuasive Speech (OpenMW) | 59384 + 47388 | The OpenMW companion path ("recruit nearly any NPC"). Julan / Cheeky Companions are not on MOMW. |
| H30 | OAAB Shipwrecks (+ TR patch, + Uncharted Artifacts assets) · OAAB Tombs and Towers · OAAB The Ashen Divide · Kogoruhn – Extinct City | 51364 · 49131 · 49047 · 51615 | Landscape / dungeon content, all clean. Kogoruhn + RoHT → MOMW Patches 80. |
| H31 | Sun's Dusk – Needs and Survival (OpenMW) | 57526 | The OpenMW Ashfall equivalent (Lua). Not in lists. Optional. |
| H32 | S3maphore + MUSE packs + TR OST · Fireflies · Subtle Smoke · Simply Walking (WS Edition) | 56836 · 51443 · 47341 · 49785 | Phase E leftovers, all EV. |

## Deferred

- **Tomb of the Snow Prince** (46810): highest value, highest patch burden
  (Repopulated Morrowind, CRF, Roaring Arena, Wares, Vanilla-friendly
  Creatures all carry TOTSP variants). Only after the base stack is stable.
- Kilcunda's Balmora (44149): viable without BCOM, but overlaps Balmora
  Gravemarket (EV #208). Pick one later.
- Not on MOMW at all: Sea of Destiny, Julan, Cheeky Companions, The Sable
  Dragon, Vivec Expansion, Great House Dagoth, Ashfall, Immersive Travel,
  "Dwemer Adventure", Ashlander Trader.

## Conflict summary

- **Repopulated Morrowind:** nothing above is flagged against it; Friends and
  Foes ships an explicit RM patch; MCA is an alternative, not a companion.
- **Tamriel Rebuilt 26.08:** TR patches exist for CRF, Shipwrecks, YAGD
  Expanded Imperials, Guar Riders, Rowing NPCs, Friends and Foes. Uvirith's
  Legacy's bundled TR add-on is stale → Null's Minor Patches.
- **Patch for Purists:** nothing flagged (only TOTSP ships its own PfP plugin).
- **Delta Plugin** becomes mandatory once YAGD + Repopulated Morrowind share
  leveled lists (`tools_reference.md`).
