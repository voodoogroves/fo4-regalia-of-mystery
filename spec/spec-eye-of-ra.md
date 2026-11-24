# Spec: Eye of Ra (the Broken Eye, the Cryptos holotape, the repair recipe)

Status: DESIGN, nothing built (2026-11-24). Part of the Regalia of Mystery set; the Blade is `spec-blade-of-bastet.md`, set-wide rules are in `spec-regalia.md`. Placement in the world is parked (see the end).

## What exists already (Verified in game 2026-11-24)

`MoM_ARMO_EyeOfRa` "Jury-Rigged Eye of Ra": a copy of the Nuka-World Shock Collar (`DLC04_ShockCollar`, `06029AFA`), Neck slot, our keyword `MoM_EyeOfRa_KW`, no script or enchantment. Worn with the Blade it raises the armor penetration from 30% to 100% (the perk's second entry, `WornHasKeyword`). It makes the plugin require `DLCNukaWorld.esm` (Chris accepts that). The final Eye can be an invisible locket later. The Eye of Ra is a gem or necklace (Chris).

## The idea (Chris, 2026-11-24)

The player finds a **Broken Eye of Ra** and a **holotape** that explains how to rebuild the Regalia; the holotape unlocks the recipes, including the Eye's repair. Framing: the player is rebuilding the Eye from schematics, so the Jury-Rigged Eye is the repaired result.

**Limit on "reading unlocks recipes" (Inferred, not tested):** a recipe condition cannot see whether a holotape was played. It can see **possession** (`GetItemCount <holotape> >= 1`, function 47, on the player). The set-wide spec already warns that item checks cannot see stored gear, so a player who puts the holotape in a workshop container loses the recipes. Options: (a) no holotape gate; the holotape explains, the recipes use the quest gate (recommended); (b) the holotape as a possession gate, fragile; (c) a small Papyrus script that sets a flag on reading (not available: no compiler set up). **(d) found 2026-11-24, recommended: an item that adds a perk when read, with no script of ours (see "A perk on read" below); recipes then check `HasPerk`, which stored gear cannot affect.**

## The records

1. **`MoM_MISC_BrokenEyeOfRa`, "Broken Eye of Ra"** (`MISC`): a copy of the vanilla `SilverLocket` (`00059B34`: model `Props\LocketSilver.nif`, value 10, weight 0.1). Changes: the name; no scrap components (or one `UnscrappableObject` keyword, `001CC46A`, as the legendary mods use) so it is not scrapped by accident; a plain pickup like the original. *To verify:* that the keyword stops scrapping; the inventory look (a locket).
2. **`MoM_TERM_Cryptos`** (`TERM`) and **`MoM_NOTE_Cryptos`, "Cryptos: Regalia of Mystery"** (`NOTE`, Terminal type): a text holotape, no script. Vanilla text holotapes with no script exist (`InstM03OberlyHolotape`; the Silver Shroud one, `MS04_CollectibleSilverShroudTVScript`, `001B8FF9`, which sits in Hubris Comics). Copy one and its terminal and replace the text. *To read first (lookup):* the structure of `001B8FF9` and its `TERM` (field names; the menu items). "Cryptos" is the Fallout 76 terminal under Riverside Manor (Chris; the tape that starts the Blade quest there).
3. **`MoM_COBJ_EyeOfRa`, the repair recipe** (`COBJ`): creates `MoM_ARMO_EyeOfRa`; ingredients the Broken Eye (1) plus materials (proposal: Crystal 2, Silver 2, Circuitry 2, Adhesive 2: a gem set in rewired parts; adjust when played); Chemistry Station (`WorkbenchChemlab`, `00102158`), category `RecipeUtility` (`0006980C`), as the Blade's recipe. Conditions: see below.

Supporting changes to existing records: the Blade's recipe `MoM_COBJ_BladeOfBastet` gains its conditions (below).

## Gates

- **Blade recipe and Eye repair:** `GetStage(MS04) >= 390` (index 58, Type 96, value 390; see `spec-regalia.md`: 390 is "refused to be the Shroud", 400 "agreed", so this opens right after Kent's offer, early in the quest), and for the Blade `HasPerk Blacksmith02` (index 448). Same gate for both so they appear together.
- **The Cryptos item:** the recommended gate is the perk it teaches (`HasPerk MoM_PERK_Cryptos`, see below); a holotape cannot do it.
- *To verify:* `GetStage` after the quest finishes; that the holotape count condition behaves in a recipe; that a recipe stays visible when the Broken Eye is not owned (it should show greyed).

## A perk on read (Verified in the vanilla records 2026-11-24; the in-game behaviour is untested)

A `BOOK` record can add a perk when read: its `DNAM` has the flag **Add Perk** and a **Teaches** field naming the `PERK` (vanilla perk magazines: `PerkMagGrognakTheBarbarian01` `0008E741` teaches `Barbarian` `0008E3A6`; keywords `FeaturedItem` and `PerkMagKeyword`; inventory art `INAM` a `STAT`; preview transform `Misc_MagazineFix`; its own mesh, here `Props\GrognakComic\Comic_GrognakJan.nif`). The vanilla magazines also carry a script `CA_SkillMagazineScript` with a property `CA_Event_ReadSkillBook`, apparently only an event for challenges; whether the perk applies **without** it is *inferred, to test*. A plain readable `BOOK` (the Silver Shroud Photo, `0018AC1E`, mesh `Props\Photo01LowPoly_SilverShroud.nif`) has `Flags = 0` and no perk. A holotape (`NOTE`) cannot add a perk (a terminal needs a script fragment for any action).

**Design with it:** the Cryptos item becomes a `BOOK` with Add Perk and Teaches = `MoM_PERK_Cryptos` (a new perk with no effect entries, copied from a vanilla magazine perk and emptied; it exists only to be held). Recipes (the Blade and the Eye repair) get the condition **`HasPerk MoM_PERK_Cryptos`** (function 448) in place of, or with, `GetStage(MS04) >= 390`. This fixes the stored-gear problem: a held perk cannot be put in a workshop container. Reading it is a real event in the Pip-Boy.

**The look:** no Silver Shroud or Mistress comic exists as a `BOOK` (only the photo). Options: (1) copy the photo record (`0018AC1E`, free Silver Shroud art) and add the perk fields: a photograph with notes; (2) reuse a vanilla magazine mesh (a comic or journal) with a rename; (3) new art later (needs a texture, a material and tools not installed here; the gold-tint research applies). A paper note is the same `BOOK` type, so it can carry the perk too. The `FIMD` (Featured Item Message) is the popup shown when a magazine is first picked up.

**The holotape stays possible** as an extra, flavour only (`NOTE` Terminal type, `MS04_CollectibleSilverShroudTVScript` `001B8FF9` is the template: model `Props\Holotape_Prop.nif`, preview transform `MiscHolotape`, pick-up sound `ITMHolotapeUp`, terminal `MS04_SilverShroudScriptTerminal` `001B8FFA`).

**To verify in game:** that reading a copy of the photo (or a magazine copy) with Add Perk and Teaches adds the perk with no script of ours; where it shows (Pip-Boy perks, magazines); that `HasPerk` on a recipe unlocks it; what happens if the book is read twice.

## Round 10 result (`BuildBladeCryptos.pas`, plugin `RegaliaCryptos1`; Verified in game 2026-11-24, Test profile)

- **Reading a `BOOK` with Add Perk + Teaches adds the perk with no script of ours: confirmed.** `player.hasperk <Cryptos Notes>` was 0 before reading the book and 1 after. **The perk stays after the book is stashed** in a container. (The vanilla magazines' `CA_SkillMagazineScript` is therefore not needed for the grant.)
- **A recipe with a `HasPerk` condition is shown but greyed out and cannot be selected until the perk is held** (Chris had every ingredient for the Blade and it was still greyed). So a `HasPerk` condition locks a recipe visibly; it does not hide it. Whether non-perk conditions (the quest-stage check) hide it is not yet tested.
- **Reported:** neither the Blade nor the Broken Eye appeared in the scrap lists of the stations Chris checked, so neither was scrappable (the Broken Eye carries the `UnscrappableObject` keyword; the Blade was not given one).
- **Not yet reported:** whether the recipes become selectable after the perk is added; how the perk shows in the Pip-Boy (the copy has `Num Ranks = 10`, inherited from the Barbarian perk); the book's inventory look and text; the repair itself.
- **Design question (open):** visible-but-locked (the `HasPerk` behaviour: a breadcrumb that points players at the book) versus hidden until the story gate. Layered option: `GetStage(MS04) >= 390` (expected to hide) plus `HasPerk` (locks).

## Holotape text (draft, original wording; nothing copied from Fallout 76 or the radio plays)

Title: *Cryptos: Regalia of Mystery.* A short menu of three entries:
- **Notes.** "Recovered notes from a collector of the Silver Shroud serials, on rebuilding the gear of the Mistress of Mystery: her blade, and the gem she wore at her throat."
- **The Blade.** "An officer's sword at a Chemistry Station. Silver, gold and a crystal go into the hilt; the edge is lightened and honed. It finds the gaps in armor, and bleeds what it cuts."
- **The Eye.** "The gem is gone; what is left is broken. A rewired collar will hold a crystal as well as a chain did. Rebuild it, wear it, and the Blade ignores armor entirely."

## Open

- Lookups needed before building: the NOTE/TERM structure (`001B8FF9`), and a recipe that creates a `MISC` or `ARMO` with conditions (the Blade's recipe is the template).
- The Broken Eye and the holotape's world placement: parked (below).
- **A candidate image for the Cryptos photo** (Chris, 2026-11-24): an illustration with a large red gem brooch, saved OUTSIDE the repos at `~/Games/mo2-lint/tools/our-assets/photo-candidates/candidate-01-red-gem-brooch.png` (source and licence unknown, repos are public, so it is not committed; it may also be a reference for the Eye's look). Using it would need a texture and a material (tools not installed; see the gold-tint research).
- The final, invisible Eye (for 1.0): its own record, replacing the collar base.

## Placement (parked, 2026-11-24)

Candidate: **Hubris Comics** (`HubrisComics01`, `CELL 0004542D`), a ruin with no owner (no theft), already holding the Silver Shroud costume, photo, script note and a quest locker (`MS04SilverShroudHoldingContainer`, `REFR 0008BB21`, whose base `Prewar_Locker_01` `00018F7B` is shared: do not edit it). Plan: our own new container placed beside it, holding the two items, so no vanilla record is edited. Alternative: the Memory Den (Kent's radio station, `GoodneighborTheMemoryDen`), busier and may count as stealing. To place it we need a spot: in game, `player.getpos x`, `y`, `z` there. The gate opens at stage 390 (right after answering Kent), so players reaching Hubris Comics earlier still get nothing until then.
