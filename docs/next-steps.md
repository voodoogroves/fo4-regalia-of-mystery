# Next steps

As of 2026-11-26. Start by reading [`build-spec.md`](build-spec.md); section 3.6 there lists what is not yet seen in game. Ask the owner which item to take; the order is a suggestion.

## 1. The real plugin (suggested next)

- [ ] Merge the chain into one plugin, `RegaliaOfMystery`, from one script. Follow "What a merged plugin must do" in the build spec. Replace test strings (for example `Bastet Test Perk`).
- [ ] ESL flag: check that a light plugin can carry the Nuka-World master and still works. The filename must not change once saves exist.
- [ ] Pack art into a `.ba2` named after the plugin (Windows `BSArch` under Proton, untried); then drop the loose-file ini settings.
- [ ] Add the ZeniMax disclaimer to the description and release page. Choose a licence for our own work.
- [ ] Test on a fresh save with only the real plugin: both books, every found item, every recipe, every Eye boost.

## 2. Checks (can ride along with the test above)

- [ ] Everything in build spec 3.6.
- [ ] Voice grips: the fixed medallions and screw plates in game (art only).
- [ ] Broken Blade inventory look and scrapping; whether the Blade can be renamed at a workbench.

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
- [ ] Pictures before release: the pencil sketch was generated with Nano Banana (Gemini) from Fallout 76 wall art; check Bethesda's terms and the mod site's rules on AI art, and credit both. Also the position on shipping recoloured Bethesda textures.
- [ ] Re-check lore details (including the diary's) against primary sources.

## 6. Housekeeping

- [ ] Save the world-building facts to Alexandria `memory/fo4-mod/` (list at the end of build spec section 4; propose first).
- [ ] Old test plugins in the game's `Data` folder (ask first). **Keep** `RegaliaGold1`, `RegaliaGarb2`, `RegaliaVeil1`, `RegaliaBroken2`, `RegaliaVoice12`, `RegaliaWorld10` until the real plugin works.
- [ ] Old `ModOrganizer.ini.bak-*` files.
