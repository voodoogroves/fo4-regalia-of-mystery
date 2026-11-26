# Next steps

As of 2026-11-26. Start by reading [`build-spec.md`](build-spec.md); section 3.6 there lists what is not yet seen in game. Ask the owner which item to take; the order is a suggestion.

## 1. Release (suggested next)

- [x] One plugin, `RegaliaOfMystery.esp`, light-flagged, tested in game (2026-11-26).
- [x] Art packed into two `.ba2` archives and a release zip (`build/package.py`, version 0.9.0).
- [x] The zip tested in game with the three loose art mods off (2026-11-26).
- [x] Licence chosen; release page and zip readme drafted ([`release-page.md`](release-page.md)).
- [x] Build 0.9.1 (2026-11-26).
- [x] The pre-release Deck session (screenshots, add-after-visit test, crafting without cheats). Broken Sword and Blade rename not tested.
- [x] Published 0.9.1 (2026-11-26): <https://www.nexusmods.com/fallout4/mods/111907>. The plugin filename must not change now.
- [ ] Nexus AI policy: new rules are enforced from 2027-01-02; check the page's disclosure and permission fields before then.

## 2. Checks (can ride along with the test above)

- [ ] Veil poison gas immunity (untested; needs a working gas source).
- [x] Voice grips: the fixed medallions and screw plates look good in game (2026-11-26).
- [ ] Broken Sword inventory look and scrapping; whether the Blade can be renamed at a workbench. Not tested as of 2026-11-26; the release does not wait on them.

## 3. Open decisions

- [ ] Blade: switch to the standard Penetrating legendary? Recommended, not decided. Free test: drop the Blade, click it, `amod 001F4426`. If wanted: build that mod in, remove our 30% entry, keep the Eye's route to 100%.
- [ ] Eye boosts: Blade, Garb and Voice are tuned. The Veil is left as is. Revisit only if play shows a problem.
- [ ] Optional flavour holotape for Cryptos (a text holotape cannot gate recipes).

## 4. Tuning and looks

- [ ] Voice burst range (outer radius 128; the dummy registered it to about 300).
- [ ] Voice gold mid-tones (`make_gold44.py`: `GAIN`, `SHADOWS`).
- [ ] Garb: green and body read light (try `CHARCOAL_GAIN` 0.38, `CHARCOAL_CAP` 0.24, `GAIN` 1.15, `CAP` 0.55); thinner chevrons; shoes; the cowl's dark corner.
- [ ] Blade: gold hilt; glow.
- [ ] Recipe amounts (Garb, Veil, Voice) if they feel wrong in play.
- [ ] Custom meshes for the broken items.
- [ ] **Parked, after 0.9.1** (owner, 2026-11-26: on hold while it needs Outfit Studio): add Nuka Girl gloves and boots to the Garb, retextured to match. Female gloves are a separate shape (`NukaSpaceGirl_Gloves:0` in `Meshes\DLC04\Clothes\NukaSpaceSuit\NukaSpaceSuitF_Body.nif`; first person `NukaSpaceGirl_Gloves_1stPerson:0` in `NukaSpaceGirlF_Body_1stPerson.nif`). Boots appear to be part of the body shape and need Outfit Studio. Untried idea for the gloves alone: a script that strips the other shapes from a copy of the mesh.

## 5. For 1.0

- [ ] An invisible locket as the final Eye of Ra.
- [x] AI position and shipping recolored textures and the sketch: decided (build spec section 6).
- [x] Cryptos picture replaced by the screenshot sketch and seen in game.
- [ ] Optional: the sketch's legs end in a hard edge on the reading page.
- [ ] Re-check lore details (including the diary's) against primary sources.

## 6. Housekeeping

- [x] Cleanup (2026-11-26): old test plugins moved to `tools/our-assets/old-plugins/`; art prototypes, previews, release staging folders, merged branches and all but the newest `ModOrganizer.ini` backup removed.
- [x] No test plugins are left in the game's `Data` folder (2026-11-26); all are in `old-plugins/`. To compare against the merge: `compare_chain.py --data <old-plugins> --new <release/0.9.0/package/RegaliaOfMystery.esp>`. A save that used test plugins needs them copied back.
- [ ] The `rom*.txt` batch files in the game folder, once testing is over.

## 7. PlayStation (a separate project, suggested after 1.0)

The owner has a PlayStation, so it can be tested. Console players get mods only through Bethesda's Creations, uploaded from the Creation Kit ([upload steps](https://help.bethesda.net/app/answers/detail/a_id/33438/~/how-do-i-upload-and-share-my-fallout-4-mod)). PlayStation archives, `.nif` and `.dds` have been supported since 18 August 2026 ([patch notes](https://help.bethesda.net/app/answers/detail/a_id/72995/), read 2026-11-26).

- [ ] Spike, without publishing: will the Creation Kit pack our two archives for PlayStation? Work on a copy of the plugin; the published file stays as it is.
- [ ] Main doubt: `.bgsm` material files are not in the new file-type list and neither page mentions them. All 12 recolors go through them.
- [ ] Run the Kit. On the Steam Deck it crashed at startup the same way four times (2026-11-26): access violation at `CreationKit.exe+0x63d9d4`, three times through MO2 and once from Steam without it, so MO2 is not the cause. The install changed no existing game file. Next: one other Proton version, otherwise a Windows PC. An MO2 entry **Creation Kit** exists.
- [ ] Before any upload: read the Creations terms (content and AI rules), and revisit the recolored-texture risk for that platform.
- [ ] Test on the owner's PlayStation (Nuka-World required).
