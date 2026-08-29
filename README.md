<div align="center">

<img src="https://raw.githubusercontent.com/OpenMW/openmw/master/files/launcher/images/openmw.png" alt="OpenMW logo" width="340">

# chiefgyk3d's Modded OpenMW Build

*The Elder Scrolls III: Morrowind — rebuilt, repopulated, and re-rendered on Linux.*

</div>

> [!WARNING]
> **Project status: TESTING — your mileage may vary.**
> This build is a work in progress and has only been validated on a single machine
> (the hardware listed below). Tiers 1–3 are installed and under active play-testing;
> Glow in the Dahrk is still pending (wrong version downloaded — see
> [`mod_audit_notes.md`](mod_audit_notes.md#202--glow-in-the-dahrk)), and the
> "big boy" expansion stages are unproven. Expect rough edges, follow the
> tier-by-tier validation checklists, and keep backups of your saves and
> `openmw.cfg` before trying any of this yourself.

Reproducible setup for a modded **OpenMW 0.50** (Flatpak) Morrowind install on Linux, built around a **Tamriel Rebuilt vanilla-plus baseline** and designed to scale into a full "big boy" overhaul.

| ![Balmora at morning, rendered in OpenMW](https://wiki.openmw.org/images/0.40_Screenshot-Balmora_3.png) | ![Vivec seen from Ebonheart, rendered in OpenMW](https://wiki.openmw.org/images/Screenshot_Vivec_seen_from_Ebonheart_0.35.png) |
|:--:|:--:|
| *Balmora at morning* | *Vivec seen from Ebonheart* |

<sub>Screenshots from the [OpenMW project's official media](https://github.com/OpenMW/openmw/blob/master/files/openmw.appdata.xml) ([openmw.org](https://openmw.org)). [The Elder Scrolls III: Morrowind](https://elderscrolls.bethesda.net/en/morrowind) © Bethesda Softworks — you need your own copy of the game to use any of this.</sub>

## What this repo tracks

| File | Purpose |
|------|---------|
| `OPENMW_BUILD_SHEET.md` | Master build sheet — system paths, Flatpak config, tier-by-tier mod list |
| `version_audit_2026-08.md` | August 2026 version audit — what's outdated, upgrade order, TR 26.08 notes |
| `enhancement_plan_2026-08.md` | Researched vanilla-plus enhancement plan — graphics, QoL, engine settings |
| `openmw_install_order.md` | Layered install order with rationale from MOMW & TR curated lists |
| `mod_audit_notes.md` | Per-mod audit — readme findings, FOMOD options used, action items |
| `mod-list.txt` | All mods with Nexus URLs, download status, version notes |
| `tools_reference.md` | mlox, Flatpak, 7z, and diagnostic command reference |
| `extract_mods.sh` | Extraction script used to unpack all archives into numbered mod folders |
| `update_gitlab_mods.sh` | Auto-updates the GitLab-hosted Lua mods (Harvest Lights, Distant Fixes) to their latest tags |
| `check_setup.sh` | Pre-launch health check — validates every `data=`/`content=`/`fallback-archive=` line against disk |
| `backup/` | Save-backup automation — rsync snapshot script + systemd user timer (see `backup/README.md`) |
| `config/` | Ready-to-copy config snippets — tuned `settings.cfg` block, Skies .IV fallbacks |
| `.gitignore` | Keeps multi-GB mod archives and extracted data out of version control |

## What this repo does NOT track

- **`mod_files/`** — Downloaded archives (~5 GB). Re-download from Nexus.
- **`mods/`** — Extracted mod data (~11 GB). Recreated by `extract_mods.sh` + manual FOMOD picks.
- **`mlox/`** — Cloned from [ZilophosGH/mlox-rfuzzo-fork](https://github.com/ZilophosGH/mlox-rfuzzo-fork). Clone it separately.
- **`saves_backup_*/`** — Save backups managed via rsync to NAS, not git.
- **`openmw.cfg`** — Lives in Flatpak config (`~/.var/app/org.openmw.OpenMW/config/openmw/`), not in this repo. The build sheet documents its contents.

## System

- **Hardware**: RTX 5070 Ti · Ryzen 9 5950X · 64 GB RAM
- **OS**: Pop!_OS (Ubuntu 22.04 base)
- **OpenMW**: 0.50.0 Flatpak (`org.openmw.OpenMW`)
- **Morrowind**: Steam, on Secondary-NVMe
- **Mods dir**: `~/mods/morrowind/mods/` (Flatpak has read-only filesystem access)

## Current baseline (Tiers 1–3)

**Foundation**: Patch for Purists, UMOPP (individual, no Firemoth), Tamriel_Data HD, MOP, Expansion Delay, Tamriel Rebuilt, OAAB_Data + HD
**Vanilla-plus**: Graphic Herbalism, Project Atlas, Harvest Lights, Weapon Sheathing, Morrowind Enhanced Textures, Familiar Faces
**Polish**: Containers Animated, Glow in the Dahrk 2.11.2 *(pending — see known issues)*, Nords Shut Your Windows, TrueType Fonts, Cantons on the Global Map, Distant Seafloor, Distant Fixes Lua
**Population**: Repopulated Morrowind + Bloodmoon + Mainland + Creatures

## Known issues (testing status)

| Issue | Impact | Status |
|-------|--------|--------|
| **Tamriel Rebuilt 26.08 "Poison Song"** released 2026-08-23 (build has 25.08) | Joinable House Indoril, Kemel-Ze, remade Sundered Scar — plus TD 26.08 hard requirement and save incompatibility | ⬆️ Upgrade path in [`version_audit_2026-08.md`](version_audit_2026-08.md) |
| **OpenMW 0.51.0** is current stable (build has 0.50.0) | MOMW curated lists now assume 0.51 | ⬆️ `flatpak update` |
| Glow in the Dahrk v3.3.0 downloaded, but OpenMW needs **v2.11.2** (pin re-verified Aug 2026) | Windows don't glow at night; Nords Shut Your Windows meshes reference GitD nodes that won't function | ❌ Re-download from Nexus "Old files" |
| MacKom head family broken with Tamriel_Data 26.08 (pulled from MOMW lists 2026-08-23) | Stage 5 plan changed — Facelift for Tamriel Data / Westly's Faces Refurbished instead | 🔄 Plan updated in `openmw_install_order.md` |
| Repopulated Morrowind may lag behind TR 26.08 | `RepopulatedMainland.ESP` is the likely breakage when TR upgrades | ⏸️ Check Nexus before TR upgrade |
| `RepopulatedMorrowind_OAAB_Data.ESP` not extracted | RM NPCs miss out on OAAB equipment variety | Optional enhancement |
| Leveled-list merging not yet set up | Needed once BCOM / big-boy mods land | Future (Delta Plugin via MOMW Tools Pack) |

Full details in [`mod_audit_notes.md`](mod_audit_notes.md) and [`version_audit_2026-08.md`](version_audit_2026-08.md).

## Quick start (rebuilding from scratch)

1. Install OpenMW Flatpak and Steam Morrowind
2. Download all archives listed in `mod-list.txt` into `mod_files/`
3. Run `extract_mods.sh` (then apply FOMOD picks per `mod_audit_notes.md`)
4. Run `update_gitlab_mods.sh` to pull the latest Harvest Lights + Distant Fixes from GitLab
5. Build `openmw.cfg` per `OPENMW_BUILD_SHEET.md` and `openmw_install_order.md`
6. Validate load order with PLOX (see `tools_reference.md`)
7. Run `check_setup.sh` — fix any errors it reports
8. Launch and test each tier before moving to the next
9. Set up save backups: `backup/README.md`

## Roadmap

- **August 2026 upgrades** ([`version_audit_2026-08.md`](version_audit_2026-08.md)): OpenMW 0.51 → Tamriel_Data 26.08 + TR 26.08 "Poison Song" → GitD 2.11.2
- **Vanilla-plus enhancement phases** ([`enhancement_plan_2026-08.md`](enhancement_plan_2026-08.md)): post-processing, groundcover, skies/water, normal maps, interiors/faces, QoL Lua mods, tuned settings.cfg
- **Big boy expansion** (Stages 4–8): Vurt's Visual Resurgence, BCOM 3.3.0+, city add-ons, heads (Facelift/Westly's now; MacKom deferred) — documented in `openmw_install_order.md`
- ✅ **Save backups**: built — snapshot script + systemd timer in [`backup/`](backup/README.md); install per its README
- ✅ **Leveled list merging**: tooling chosen and documented — Delta Plugin workflow in `tools_reference.md`, needed once BCOM lands

## Links

- [OpenMW](https://openmw.org) — the open-source Morrowind engine this build runs on
- [The Elder Scrolls III: Morrowind](https://elderscrolls.bethesda.net/en/morrowind) — buy the game (required)
- [Tamriel Rebuilt](https://www.tamriel-rebuilt.org/) — the mainland project at the heart of this build
- [Modding-OpenMW](https://modding-openmw.com/) — curated lists this build is based on

---

## 💝 Support This Project

If you find chiefgyk3d's Modded OpenMW Build useful, consider supporting continued development.
Everything is also collected at **[support.chiefgyk3d.com](https://support.chiefgyk3d.com)**.

### Recurring Support

<div align="center">
<table>
  <tr>
    <td align="center" width="150">
      <a href="https://patreon.com/chiefgyk3d" title="Patreon">
        <img src="media/icons/patreon.svg" width="36" height="36" alt="Patreon"><br>
        <sub><b>Patreon</b></sub>
      </a>
    </td>
    <td align="center" width="150">
      <a href="https://streamelements.com/chiefgyk3d/tip" title="StreamElements">
        <img src="media/streamelements.png" width="36" height="36" alt="StreamElements"><br>
        <sub><b>StreamElements</b></sub>
      </a>
    </td>
    <td align="center" width="150">
      <a href="https://shop.chiefgyk3d.com/" title="Merch Store">
        <img src="media/icons/merch.svg" width="36" height="36" alt="Merch"><br>
        <sub><b>Merch Store</b></sub>
      </a>
    </td>
  </tr>
</table>
</div>

### Cryptocurrency Tips

<div align="center">
<table>
  <tr>
    <td align="center" width="60"><img src="media/icons/bitcoin.svg" width="28" height="28" alt="Bitcoin"></td>
    <td><b>Bitcoin</b><br><code>bc1qztdzcy2wyavj2tsuandu4p0tcklzttvdnzalla</code></td>
  </tr>
  <tr>
    <td align="center" width="60"><img src="media/icons/monero.svg" width="28" height="28" alt="Monero"></td>
    <td><b>Monero</b><br><code>84Y34QubRwQYK2HNviezeH9r6aRcPvgWmKtDkN3EwiuVbp6sNLhm9ffRgs6BA9X1n9jY7wEN16ZEpiEngZbecXseUrW8SeQ</code></td>
  </tr>
  <tr>
    <td align="center" width="60"><img src="media/icons/ethereum.svg" width="28" height="28" alt="Ethereum"></td>
    <td><b>Ethereum</b><br><code>0x554f18cfB684889c3A60219BDBE7b050C39335ED</code></td>
  </tr>
  <tr>
    <td align="center" width="60"><img src="media/icons/solana.svg" width="28" height="28" alt="Solana"></td>
    <td><b>Solana</b><br><code>5T8h3HbyvHgLxwXgchRYbHSqRjZyAr8J7uwjLN9Fh8Jh</code></td>
  </tr>
</table>
</div>

---

## 👤 Author & Socials

<div align="center">
<table>
  <tr>
    <td align="center" width="90"><a href="https://social.chiefgyk3d.com/@chiefgyk3d" title="Mastodon"><img src="media/icons/mastodon.svg" width="30" height="30" alt="Mastodon"><br><sub>Mastodon</sub></a></td>
    <td align="center" width="90"><a href="https://bsky.app/profile/chiefgyk3d.com" title="Bluesky"><img src="media/icons/bluesky.svg" width="30" height="30" alt="Bluesky"><br><sub>Bluesky</sub></a></td>
    <td align="center" width="90"><a href="https://twitch.tv/chiefgyk3d" title="Twitch"><img src="media/icons/twitch.svg" width="30" height="30" alt="Twitch"><br><sub>Twitch</sub></a></td>
    <td align="center" width="90"><a href="https://www.youtube.com/channel/UCvFY4KyqVBuYd7JAl3NRyiQ" title="YouTube"><img src="media/icons/youtube.svg" width="30" height="30" alt="YouTube"><br><sub>YouTube</sub></a></td>
    <td align="center" width="90"><a href="https://kick.com/chiefgyk3d" title="Kick"><img src="media/icons/kick.svg" width="30" height="30" alt="Kick"><br><sub>Kick</sub></a></td>
    <td align="center" width="90"><a href="https://www.tiktok.com/@chiefgyk3d" title="TikTok"><img src="media/icons/tiktok.svg" width="30" height="30" alt="TikTok"><br><sub>TikTok</sub></a></td>
    <td align="center" width="90"><a href="https://discord.chiefgyk3d.com" title="Discord"><img src="media/icons/discord.svg" width="30" height="30" alt="Discord"><br><sub>Discord</sub></a></td>
    <td align="center" width="90"><a href="https://matrix-invite.chiefgyk3d.com" title="Matrix"><img src="media/icons/matrix.svg" width="30" height="30" alt="Matrix"><br><sub>Matrix</sub></a></td>
  </tr>
</table>
</div>

<div align="center"><sub>Made with ❤️ by <a href="https://github.com/ChiefGyk3D">ChiefGyk3D</a></sub></div>
