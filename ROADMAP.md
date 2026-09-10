# ROADMAP.md — done, next, deferred

Guiding principle: vanilla-plus. Enhance and restore; don't rebalance, don't
convert. Selections come from Modding-OpenMW's curated lists (mainly
**Expanded Vanilla**, which adds content while keeping the vanilla feel),
adjusted for a build with **no BCOM and no Tomb of the Snow Prince**.
Everything installed is itemised in [`MODS.md`](MODS.md).

## Done

| When | What |
|---|---|
| 2026-03 | Baseline: foundation, vanilla-plus, polish, Repopulated Morrowind. |
| 2026-09-09 | OpenMW 0.51 · Tamriel_Data 26.08 · Tamriel Rebuilt 26.08 "Poison Song" · GitD 2.11.2 with all modules · UMOPP 3.3.0. Enhancement phases A–G: post-processing pack, groundcover (Lush, Remiros, Saplings, Fantasia TR), skies/water/lighting, normal maps, interiors/faces, QoL Lua, tuned settings. Repo tooling: manifest + API downloader, extractor rewrite, config applier, master-order check. |
| 2026-09-10 | Phase H tier 1 world half: OAAB Grazelands, Tel Mora, Twin Lamps, AFFresh, Cutting Room Floor, Roaring Arena. Phase E atmosphere: Fireflies, Subtle Smoke, Simply Walking, Loading Screens Diversified. Music: S3maphore + TR soundtrack + Vindsvept + seven MUSE packs. Weapon Sheathing finally enabled. |

## Next, in order

1. **Phase H tier 1, factions half.** Rise of House Telvanni 1.52 (27545) +
   Uvirith's Legacy 3.53 (Dropbox via MOMW; needs MOMW Patches 32 and Null's
   Minor Patches for TR) + Building Up Uvirith's Legacy; Imperial Legion
   Expansion (44469, use its own plugin — no BCOM); Imperial Factions (49855 +
   MOMW Patches 21); Join the Dark Brotherhood (48858); Quests for Clans and
   Vampire Legends (49486). Delta Plugin becomes mandatory here.
2. **Tier 2 life layer.** Yet Another Guard Diversity "Full Cephalopod" +
   Expanded Imperials (45894, 47583); Bards of Bardenfell (53278); Sload and
   Slavers (49074); Sloadic Transports (50546); Shady Sam (53304); Diverse
   Khajiit (48832); Nordic Dagon Fel NPCs (52390); M'Aiq on the Mainland
   (45674); Wandering Umbra (44913); Traveling Guar Riders (52788); Repopulated
   Waters (53653); Friends and Foes (49251, with its Repopulated Morrowind
   patch and OpenMW book fix). Dialogue: Djangos Dialogue (47253), Greetings
   for No Lore (46063), FMBP Greet Service (50937), Idle Talk (46948), Local
   Lore (48063). Mages Guild interiors: 48321, 45750, 57059. Vivec Voice Addon
   (589, Sound folder only, plugin from Alvazir's Various Patches).
3. **Tier 3 systems.** Wares Ultimate (52013), Tamrielic Integrations (57488),
   Expansions Integrated (47861), Improved Inns Expanded (48610, skip its BCOM
   folder), Wandering Creature Merchants Lua, Signpost Fast Travel, Best
   Friends Forever (59384) + Persuasive Speech (47388), OAAB Shipwrecks
   (51364 + TR patch), Tombs and Towers (49131), The Ashen Divide (49047),
   Kogoruhn (51615). Sun's Dusk (57526) if survival appeals.
4. **Visual half-steps.** Vurt's Morrowind Visual Resurgence (56037, after
   MET, delete its three bad textures per MOMW); Westly's Faces Refurbished
   (51214, MOMW's MacKom replacement — pick one head ecosystem, never mix);
   tree replacers (Grazelands Acacia, West Gash Tree Replacer, Remiros'
   Ascadian Isles Trees 2); Normal Maps for Premium (56419).
5. **Small fixes / UI.** trav's Books Enhanced, Big Icons (49662), HD attribute
   icons (54708), NoPopUp Chargen, Distant Ebon Tower (54784), Jammings Off
   (44523), Fixed Bonelord Arms (55354). Audio set: Voice Overhaul (51215),
   MAO Spell Sounds, openmw-footsteps, Store Entrance Chimes (+ TR add-on),
   Sea of Sound / Atmospheric Sound Effects Expanded.
6. **Engine and tooling.** MSAA 8 and SSR in the chain if the frame rate
   allows; PLOX as a routine step; `RepopulatedMainland.ESP` back in once the
   author confirms TR 26.08; Distant Seafloor's Bloodmoon edges fix reviewed.

## Bigger decisions, deliberately deferred

- **Tomb of the Snow Prince** (46810): a full Solstheim rebuild, highest
  value and highest patch burden (Repopulated Morrowind, CRF, Roaring Arena,
  Wares all ship TOTSP variants). Only once everything above is stable.
- **Beautiful Cities of Morrowind** 3.3.0+ (49231): changes every town and
  forces the BCOM variants of many mods above (Repopulated Morrowind's `02
  BCOM` module, Roaring Arena's Vivec option, MOMW Patches 06/09/16/22/24/38/
  68/89). A decision, not an add. City extras (Maar Gan, Nordic Dagon Fel,
  Hanging Gardens of Suran, Velothi Wall Art, Concept Art Palace, Bell Towers)
  follow it.
- **Kilcunda's Balmora** vs Balmora Gravemarket: pick one, later.
- **MacKom head family**: pulled from MOMW lists 2026-08-23 (broken with TD
  26.08). Westly's is the path if Familiar Faces + Facelift isn't enough.

## Not on Modding-OpenMW at all (so not planned)

Sea of Destiny, Julan Ashlander Companion, Cheeky Companions, The Sable
Dragon, Vivec Expansion, Great House Dagoth, Ashfall (MWSE), Immersive Travel,
"Dwemer Adventure", Ashlander Trader, RTX Remix (needs the original engine).

## Deliberately skipped (strays from vanilla)

Magicka regeneration; Natural Character Growth + Skill Evolution; Better
Merchants Skills / For the Right Price; MDMD, Beware the Sixth House,
Tribunal/Bloodmoon Rebalance; Morrowind Anti-Cheese; Morrowind Comes Alive
(replaced by Repopulated Morrowind + Friends and Foes).

## Conflict notes carried forward

- **Repopulated Morrowind:** nothing planned is flagged against it; Friends and
  Foes ships an explicit patch; MOMW Patches 66 pairs it with The Wolverine Hall.
- **Tamriel Rebuilt 26.08:** TR patches exist for CRF (in), Shipwrecks, YAGD
  Expanded Imperials, Guar Riders, Rowing NPCs, Friends and Foes. Uvirith's
  Legacy's bundled TR add-on is stale → Null's Minor Patches.
- **Patch for Purists:** only TOTSP ships its own PfP plugin.
- **Leveled lists:** Delta Plugin once YAGD / Wares / Tamrielic Integrations
  share lists with Repopulated Morrowind (`TOOLS.md`).
