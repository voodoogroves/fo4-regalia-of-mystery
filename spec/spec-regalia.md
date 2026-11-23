# Spec: Regalia of Mystery (set-wide)

*Status: DRAFT, plan not yet built or tested. Decisions that apply to the whole plugin, not one item. Item specs: `spec-blade-of-bastet.md` (0.1). Intent: `concept-spec.md`. Each fact is marked **Verified** (read from the game files or the xEdit source on 2026-11-22) or **To verify** (needs xEdit or in-game testing).*

## Plugin

- One light plugin (`.esl`), no scripts, no archives, no vanilla record overrides.
- **Filename: `RegaliaOfMystery.esl`** (decided). It must not change once saves exist, so it covers the whole set, not just the Blade. The public title (e.g. on Nexus) can differ.
- **EditorID prefix: `MoM_`** (decided), used on every new record.
- **Master dependencies:** `Fallout4.esm` only for 0.1. No DLC asset is used. Any later DLC or Creation Club asset is listed here when used, because it becomes a hard requirement.

## Versions

0.1 is the Blade of Bastet; 0.2 is the Veil plus one more item; later 0.x add the rest; 1.0 is the release. Eye of Ra is non-visible before 1.0.

## Discovery (when the recipes appear)

**Discovery gate:**
- Quest `MS04` = `QUST 00027556`. Stages that exist (from the quest's log text): `25` Kent's call, `100` Kent wants a costume from Hubris Comics, `200` found the costume, `390` refused to be the Shroud, `400` agreed to be the Shroud (wear the costume, patrol), `410`-`1360` the missions, `1400` Sinjin dealt with, `1425` the Silver Shroud story wrapped up.
- **Gate: the player has answered Kent, either way (stage 390 or later).** Refuse at 390 ("I am the Mistress") or accept at 400; both unlock the recipe, and players still at stages 25 to 200 do not get it.
- **Single condition:** `GetStage(MS04) >= 390`. `GetStage` is condition index `58` (Verified in the xEdit definitions); `>=` is Type `96`; comparison value `390`; Run On Subject `0`. No item check (an item check cannot see stored gear) and no OR.
- **Fallback if `GetStage` misbehaves:** two conditions, `GetStageDone(MS04, 390) == 1` OR `GetStageDone(MS04, 400) == 1` (`GetStageDone` is index `59`; OR flag `1` on the first).
- Rejected: stage 200 (found the costume; loses the choice theme), 1425 (too late), 390 alone (probably excludes everyone who accepts the role).
- Condition encoding (Verified): the `MS04` quest is the vanilla Silver Shroud quest; the costume items (`MS04_SilverShroudCostume 000E1A25` etc.) are not needed under this gate.
- *To verify in-game:* that `GetStage` returns the highest/most recent stage (not reset when the quest advances or completes), that stage 390 is set on refusal and 400 on acceptance, and that the recipe stays visible after the quest finishes.


## Crafting station and category

**Workbench: Chemistry Station (keyword `WorkbenchChemlab`).** Verified: in Fallout4.esm, the DLC and the installed Creation Club files, the 20 recipes that create a weapon item (mines and grenades) all use this station; the weapon and armor workbenches are built around mods, not new items. **Category keyword: `RecipeUtility`** (Verified). The Chemistry Station recipes use six categories: `RecipeDrug` (14), `RecipeHealing` (12), `RecipePoison` (9), `RecipeGrenade` (7), `RecipeMines` (5), `RecipeUtility` (2). Weapons there are only grenades and mines; no category fits a melee weapon, and Utility is the catch-all (its recipes are Cutting Fluid, Vegetable Starch and Reactor Coolant). A brand-new category keyword is not recommended: I could not confirm the menu would show it.


## Instructions item

## Instructions item

**What a holotape can be (Verified, xEdit definitions and the game's `NOTE` records):** a note has a type, either `Sound`, `Voice`, `Program` or `Terminal`. A text holotape is the **Terminal** type: its record points at a `TERM` (terminal) record that holds the text. Vanilla has such holotapes with no script (e.g. `InstM03OberlyHolotape`), including a Silver Shroud one (`MS04_CollectibleSilverShroudTVScript`). So a text holotape needs two new records (`NOTE` + `TERM`) and no Papyrus.

**Getting it to the player without editing vanilla:** it cannot be placed in the world or given by a script, so it would have to be a craftable item shown with the recipes.

**Proposed for 0.1:** put the instructions in the Blade's own description text (`DESC`), which should show in the crafting menu. That is the cheapest option: no extra records. Add the craftable Terminal holotape later if a longer explanation is wanted.

*To verify:* that the item description shows in the Chemistry Station crafting menu; and (only for the later holotape) that a recipe can create a `NOTE` and that it opens its terminal from the inventory.


## Later options (not for 0.1)

- **Own crafting category** on the Chemistry Station, and a **craftable holotape** for the instructions. Chris has seen other mods do both and can find examples when we want them; they replace my "could not confirm" notes above. Locked for now: `RecipeUtility` and description-only instructions.


## Test plan (set-wide)

1. Plugin loads as a light master with no errors in xEdit.
2. Recipes are hidden until the discovery condition is met, then appear.
3. The item description (instructions) shows in the Chemistry Station crafting menu.

## Open items (set-wide)

- In-game test of `GetStage(MS04) >= 390` (including after the quest finishes); item description in the crafting menu; whether recipes can create a holotape (only for the later holotape).
