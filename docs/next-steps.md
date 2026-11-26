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

## 3. Placement and story (placed: see the build spec)

**Story (decided 2026-11-25):** a seeker came from Appalachia carrying a tattered dress and a broken Eye, to remake the regalia. Hurt, she lost or could not retrieve the rest and left a diary asking whoever finds it to carry on. Text: [`diary-text.md`](diary-text.md).

Built by `BuildWorld.pas` (`RegaliaWorld4`); positions and contents are in the [build spec](build-spec.md). Placement seen in game and good (2026-11-25).

**Next session**

- [ ] Tune the diary's wording ([`diary-text.md`](diary-text.md)), then rebuild (`BuildWorld.pas`, new plugin number).
- [ ] Check round 4: each note opens where it lies and fits the page; Cryptos is readable over the sketch, grants the perk and stays; the "Mystery: ..." names; a repair at the Chemistry Station.
- [ ] After an area reset: she, the notes and the containers are still right, and taken items stay gone.
- [ ] A grenade test near the loose notes.
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
