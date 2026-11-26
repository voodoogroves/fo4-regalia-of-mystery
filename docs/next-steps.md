# Next steps

As of 2026-11-25. Start by reading [`build-spec.md`](build-spec.md). All five pieces, their broken forms and repair recipes work in game as a chain of test plugins. Items below are things we said we would get to later. Ask Chris which to take; the order is a suggestion.

## 1. Quick checks and one open decision

- [ ] Voice grips: see the fixed medallions and screw plates in game (art installed after the last look; no rebuild needed).
- [ ] **Blade: switch to the standard Penetrating legendary?** Recommended, not yet decided. Free test: drop the Blade, click it, `amod 001F4426`. If it is wanted: build that mod in (as the Voice does), remove our own 30% entry so they do not stack, and keep the Eye's route to 100%. The Veil (Poison Resistance `001F3072`, 25) was considered and the advice was to leave it.

## 2. The real plugin

- [ ] Merge the chain into one plugin, `RegaliaOfMystery`, from one script (the cross-plugin lookups disappear). Replace test strings and names (for example `Bastet Test Perk`, test descriptions).
- [ ] ESL flag: check that a light plugin can carry the Nuka-World master, and that it still works. Filename must not change once saves exist.
- [ ] Pack art into a `.ba2` named after the plugin (Windows `BSArch` under Proton, untried); then drop the loose-file ini settings. Check the licence position of shipping recoloured Bethesda textures.
- [ ] Add the ZeniMax disclaimer to the description and release page. Choose a licence for our own work (see how Nexus mods are licensed).
- [ ] Test on a fresh save with only the real plugin: book, every broken item, every recipe, every Eye boost.

## 3. Placement and story (the body is placed; the four containers are not)

**Story (decided 2026-11-25):** a seeker came from Appalachia carrying a tattered dress and a broken Eye, to remake the regalia. Hurt, she lost or could not retrieve the rest and left a diary asking whoever finds it to carry on. Text: [`diary-text.md`](diary-text.md).

| Spot | What is there |
|---|---|
| Rooftop of the raider building across the street: her body (the Mysterious Traveler, wearing the Tattered Dress) | Diary, Tattered Dress, Broken Eye |
| Inside Hubris Comics (`HubrisComics01`, `CELL 0004542D`) | Cryptos book, Broken Veil |
| Boston Common, near the swan boats (Swan's pond) | Broken Voice |
| Across the rooftops by Hubris Comics | Broken Blade |

- [ ] Chris gets each spot in game (`player.getpos x`, `y`, `z`; indoors or out; screenshot). Screenshots are kept outside the repos in `~/Games/mo2-lint/tools/our-assets/placement/`.
  - [x] Her body (built): **x 5514.07, y -18598.39**, z 1820 (moved off the wall and crates; first spot was 5748.90, -18637.97), raider building roof. Pose from vanilla `ACHR 001289CF`.
  - [x] Broken Voice, by the swan boats: x 11690.69, y -20003.33, z 597.63; **duffel bag**, facing not taken (`swan-boats.png`).
  - [x] Broken Blade, other rooftop: x 7408.37, y -18588.25, z 1856.75; suitcase, front toward the west (`blade-roof.png`).
  - [x] Broken Veil, inside Hubris: x 1666.60, y 203.69, z 780.50; a **first aid kit** on the floor to the left of the Silver Shroud costume (`veil-hubris-room.png`, `veil-hubris-pos.png`).
  - [x] Cryptos book, inside Hubris: x 2811.96, y -247.09, z 839.88, on top of the smallest file cabinet (position taken standing on it; `cryptos-room.png`, `cryptos-pos.png`). Container: **tool case** (`DN140_ToolcaseIntelKey` `001103E3`, copy with respawn off and its loot cleared).
- [ ] One of each look: suitcase (Blade), duffel bag (Voice), tool case (Cryptos), first aid kit (Veil). Idea, not yet decided: charcoal with emerald stripes on all four.
- [ ] Containers of our own that **do not refill**; do not edit vanilla records. Adding a placed actor to the exterior cell left the scenery looking normal.
- [x] The body and diary: built and verified (`BuildPose1.pas`, `RegaliaBody4`; see the build spec).
- [ ] Check after an area reset that she is still there and looted items stay gone.
- [ ] Put the new Cryptos text ([`cryptos-text.md`](cryptos-text.md)) on the book; the game still shows the old text.
- [ ] Optional flavour holotape for Cryptos (a text holotape cannot gate recipes).

## 4. Untested

- [ ] Veil gas immunity: HalluciGen, Inc. basement (quest Hazardous Material) or the Nuka-World Gauntlet gas room (quest Taken for a Ride); compare Veil off and the Hazmat Suit.
- [ ] Garb detection effect (hard to measure); the Eye's boost on the Veil's poison resistance.
- [ ] Blade bleed; whether the Blade can be renamed at a workbench; Broken Blade inventory look and scrapping.
- [ ] Whether the Voice's explosion staggers on its own (not separated from the legendary effect).

## 5. Tuning and looks

- [ ] Voice burst range: the dummy registered it (no damage) out to about 300, which may feel large (outer radius 128).
- [ ] Voice gold: optionally brighten the mid-tones toward the Blade's (`make_gold44.py`: `GAIN`, `SHADOWS`).
- [ ] Garb: the green and the body read too light (try `CHARCOAL_GAIN` 0.38, `CHARCOAL_CAP` 0.24, `GAIN` 1.15, `CAP` 0.55); thinner chevrons; shoes; the cowl's dark corner.
- [ ] Blade: gold hilt; glow.
- [ ] Recipe amounts (Garb, Veil, Voice) if they feel wrong in play.
- [ ] Custom meshes for the broken items.

## 6. For 1.0

- [ ] An invisible locket as the final Eye of Ra.
- [ ] Cryptos picture, before release: the pencil sketch was generated with Nano Banana (Gemini) from Fallout 76 wall art; check Bethesda's terms and the mod site's rules on AI art, and credit both.
- [ ] Re-check lore details against primary sources before quoting them anywhere.

## 7. Cleanup (ask Chris first)

- [ ] Old test plugins in the game's `Data` folder. **Keep** `RegaliaGold1`, `RegaliaGarb2`, `RegaliaVeil1`, `RegaliaBroken2`, `RegaliaVoice12` until the real plugin works. The other `Regalia*.esp` files are earlier rounds (`RegaliaVoice3`, `4`, `9` and `10` are known bad builds). Check each file's date and size before removing it.
- [ ] Old `ModOrganizer.ini.bak-*` files.
