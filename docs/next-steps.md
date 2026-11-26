# Next steps

As of 2026-11-26. Start by reading [`build-spec.md`](build-spec.md); section 3.6 there lists what is not yet seen in game. Ask the owner which item to take; the order is a suggestion.

## 1. Release (suggested next)

- [x] One plugin, `RegaliaOfMystery.esp`, light-flagged, tested in game (2026-11-26).
- [x] Art packed into two `.ba2` archives and a release zip (`build/package.py`, version 0.9.0).
- [x] The zip tested in game with the three loose art mods off (2026-11-26).
- [x] Licence chosen; release page and zip readme drafted ([`release-page.md`](release-page.md)).
- [x] Build 0.9.1 (2026-11-26).
- [ ] The one Deck session in `release-page.md` (crafting without cheats, small checks, screenshots; the add-after-visit test passed).
- [ ] Upload (owner).

## 2. Checks (can ride along with the test above)

- [ ] Veil poison gas immunity (untested; needs a working gas source).
- [ ] Voice grips: the fixed medallions and screw plates in game (art only).
- [ ] Broken Sword inventory look and scrapping; whether the Blade can be renamed at a workbench.

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

## 5. For 1.0

- [ ] An invisible locket as the final Eye of Ra.
- [x] AI position and shipping recolored textures and the sketch: decided (build spec section 6).
- [x] Cryptos picture replaced by the screenshot sketch and seen in game.
- [ ] Optional: the sketch's legs end in a hard edge on the reading page.
- [ ] Re-check lore details (including the diary's) against primary sources.

## 6. Housekeeping

- [ ] Old test plugins in the game's `Data` folder and in `tools/our-assets/old-plugins/` (ask first). The six chain plugins are only needed by `compare_chain.py`.
- [ ] The `rom*.txt` batch files in the game folder, once testing is over.
- [ ] Old `ModOrganizer.ini.bak-*` files.
