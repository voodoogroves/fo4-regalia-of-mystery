# Spec: Blade of Bastet (version 0.1)

*Status: DRAFT, plan not yet built or tested. Item-level mechanics for the Blade. Set-wide decisions (plugin name, discovery gate, workbench, instructions) are in `spec-regalia.md`; intent is summarised below. Each fact is marked **Verified** (read from the game files or the xEdit source on 2026-11-22) or **To verify** (needs xEdit or in-game testing).*

## Goal

Convert a Chinese Officer Sword the player already owns into the Blade of Bastet. It keeps the sword's vanilla stats and mods, and adds 30% built-in armor penetration. Later, with the Eye of Ra worn, it ignores all armor (not part of 0.1).


## Base record

| Item | Value | Status |
|---|---|---|
| Source weapon | `WEAP 00147BE4` `ChineseOfficerSword` | Verified |
| Keywords on the source | `Anims1hmWeapon`, `WeaponTypeMelee1H`, `QuickkeyMelee`, `ma_ChineseOfficerSword`, `AnimsStabWeapon`, `ObjectTypeWeapon` | Verified |
| Attach points | `ap_melee_MeleeMod`, `ap_Legendary` | Verified |
| Equip type | `RightHand` | Verified |
| Instance naming | `dn_CommonMelee` | Verified |

**New record:** `MoM_WEAP_BladeOfBastet`, a copy of the source with a new name. Keep `ma_ChineseOfficerSword` and both attach points so the vanilla sword mods still apply and the legendary slot stays open. *To verify:* that vanilla sword mods attach to the copy through that keyword.

Base damage and speed are inherited unchanged. **Verified (xEdit on `Fallout4.esm`, 2026-11-23):** the sword's base damage is on the weapon record itself, `DNAM` `Damage - Base` = **16**. Also: speed 1.0, reach 0.8, action point cost 35, crit damage multiplier 2.0, stagger Small, animation `OneHandSword`, value 50, weight 3.0. Its default template combination includes only `mod_melee_ChineseOfficerSword_Null` (`OMOD 00176DF8`), which has no properties, and the combination's own `Properties` list is empty, so nothing else adds damage. (The record's `Damage - Secondary` shows `-107374176.0`; it is an unused field.) The in-game number can still move with perks and other mods; check in-game.


## Build status (as-built, 2026-11-23)

Built by `build/xedit/BuildBlade.pas` in FO4Edit 4.1.5f: `RegaliaOfMystery.esp` (master `Fallout4.esm`) with `MoM_WEAP_BladeOfBastet` (copy of the sword; `EITM` = vanilla `enchModArmorPenetration`; template `ArmorPenetration` = 30; name and description as below) and `MoM_COBJ_BladeOfBastet` (the sword + Steel 4, Silver 3, Gold 2, Crystal 2, Adhesive 3; Chemistry Station; `RecipeUtility`; **no conditions yet**). All references resolve in xEdit. **Differences from this spec:** it is a plain `.esp` for now, not the planned `.esl` (the light flag is a later step); the template-level `ArmorPenetration` property and the `EITM` enchantment are written but **do not take effect in game** (tested 2026-11-23: the player's `ArmorPenetration` stays 0 and perk `001F4166` is absent; see "Armor penetration: in-game findings"). So the plugin as built crafts the sword but gives **no armor penetration**; the approach below is superseded. The sword copy keeps `ap_Legendary`, `ap_melee_MeleeMod` and the vanilla default mod, as specified.

**Observed in game (Chris, 2026-11-23, Test profile, ungated build):**
- The recipe appears at the Chemistry Station and crafting works; the result is the full sword.
- **The full description text shows in the crafting menu** (answers the "does it show / how much" question: all of it).
- **No description line shows once the item is crafted** and inspected, so the "instructions" sentence only helps in the crafting menu (acceptable for 0.1).
- **The crafting-menu preview shows only the hilt**, while the crafted item is the full sword. Likely cause (inferred, not checked): the weapon record's own model is the hilt and the blade comes from the default mod's model (`Blade.nif` on `mod_melee_ChineseOfficerSword_Null`), which the preview doesn't include. Cosmetic; leave for now.
- **Armor-penetration test, first results (hits to kill a Protectron, plain swings, single runs, Strength 10 so both swords show 32 damage):** plain sword 22 to 23; Blade with stat 30 = 22; a throwaway TEST build with stat 100 = 18. The reported armor formula predicts about 1.14x and about 2.15x fewer hits, so the effect is **smaller than predicted, or noise**. Early impression: the Blade's health bar drained faster. **Inconclusive at the time, since resolved:** those runs were on Very Hard, on a target whose real stats were unknown, and the effect was not there (see "Armor penetration: in-game findings"). Detail in Alexandria `memory/fo4-xedit-reference.md`.
- *Not yet answered:* whether the sword was consumed.


## Name and description (0.1)

**Name** (`FULL`): Blade of Bastet.

**Lore, what we know (2026-11-23):** the Blade of Bastet is a Fallout 76 weapon, the sword of the fictional Mistress of Mystery and part of her Regalia of Mystery. The Fallout 4 Silver Shroud radio plays mention it (reported as Episode 3, "In the Parlor of Mysteries", and Episode 5, "Into the Robot's Den"). In Fallout 76 it is a one-handed sword with increased armor penetration, and the Eye of Ra is a companion item that doubles that bonus. Fallout 76's armor penetration starts at 50%, so the doubling reaches 100%. Chris pointed to the Fandom page "Fallout 76 legendary weapon effects" (Anti-armor), which we could not read (HTTP 402); search results for the Anti-armor effect agree that it ignores 50% of the target's armor ([Fextralife](https://fallout76.wiki.fextralife.com/Anti-armor+Legendary+Effect), [Sportskeeda](https://sportskeeda.com/mmo/all-fallout-76-legendary-weapon-effects-explained); read as search summaries, not verbatim). We did not confirm that the Blade's built-in bonus is that same effect. Ours starts at 30% (the same as Fallout 4's own Penetrating legendary, which gives us a known control for testing) and the Eye takes it to 100%, so it is not a doubling. The 30 is a single number (the weapon's `ArmorPenetration` stat), so moving to 50 later, to match Fallout 76, is a one-field change; keep 30 for 0.1. *Confidence:* the radio-play episode numbers and the Eye of Ra detail come from a summarised read of `fallout.wiki`, not verbatim text; the Fextralife Fallout 76 page was read verbatim (one-handed, increased armor penetration). **No in-game description text was found** on either wiki page, and the `fandom.com` pages returned HTTP 402 (blocked) and were not read. Re-check the episode details against the radio plays themselves before quoting them anywhere.

**Text rule:** original wording only. Do not copy Fallout 76's item text or radio-play lines into the plugin.

**Description** (`DESC`), draft: *"A Chinese officer's sword reforged with silver, gold and a crystal-set hilt, in the manner of the Mistress of Mystery's blade. Ignores 30% of the target's damage and energy resistance. Craft it from a Chinese Officer Sword at a Chemistry Station."* The middle sentence restates the vanilla Penetrating effect's own wording (Verified: OMOD `001F4426`). The last sentence is the 0.1 "instructions" (see `spec-regalia.md`).

*To verify in-game:* that the description shows in the Chemistry Station crafting menu, and how much of it is shown (length limit unknown).


## The sword's vanilla mods (Verified from the game's OMOD records)

The sword has two attach points (`ap_melee_MeleeMod` and `ap_Legendary`) and four blade states:

| Mod | In-game name | Effect | Cost (perk gate) |
|---|---|---|---|
| `mod_melee_ChineseOfficerSword_Null` | No Upgrade | the base sword; changes nothing | free |
| `..._Serrated` | Serrated Blade | +75% damage; targets bleed (`EnchWeapModBleed`) | Steel 7, Oil 3, Fiberglass 4, Adhesive 3 (Blacksmith 2) |
| `..._Shock` | Electrified Blade | +5 electrical damage (`EnchWeapModShock`) | Rubber 3, Circuitry 3, Aluminum 8, Adhesive 4 (Blacksmith 2, Science 1) |
| `..._ShockAndSerrated` | Electrified Serrated Blade | both of the above | 26 components (Blacksmith 3, Science 1) |

No other mod slots exist besides the legendary slot. The copy should keep these so players can still stack bleed and shock on the Blade. *To verify:* that the copy's default mod list points at the vanilla "No Upgrade" mod and that all four attach. The base damage number is not in these mods (the standard state changes nothing); it is on the weapon record (16, see above). The default mod `mod_melee_ChineseOfficerSword_Null` (`OMOD 00176DF8`) targets keyword `ma_ChineseOfficerSword`, attach point `ap_melee_MeleeMod`, and has no properties (Verified).


## Armor penetration (the one change)

**How vanilla does it (Verified):**
- Weapon stat `ArmorPenetration` (AVIF `00097341`): 0 to 100, a percentage of the target's armor ignored.
- Legendary "Penetrating": OMOD `001F4426` (description: "Ignores 30% of the target's damage and energy resistance.") adds two properties that matter: `Enchantments` ADD `enchModArmorPenetration` (`ENCH 001F4425`) and `ActorValues` ADD `ArmorPenetration` = `30.0`. (It also adds keywords, including `HasLegendary_Weapon_ArmorPenetrating` `001F4424`, and a value multiplier.)
- `ENCH 001F4425`: Constant Effect, target Self, one effect -> `MGEF 001F4423` (`ModArmorPenetrationAddPerkEffect`: constant, self, hidden in the UI) -> `PERK 001F4166` (`ModArmorPenetrationPerk`: hidden, non-playable, one rank).
- That perk has **one entry point: Mod Target Damage Resistance, function "Multiply 1 + Actor Value Mult", actor value `ArmorPenetration`, float `-0.01`** (Verified, 2026-11-23). So the target's resistance is multiplied by `1 + (ArmorPenetration x -0.01)`: with the weapon's stat at 30 that is x0.70, i.e. 30% ignored, matching the OMOD's description. The strength therefore comes from the weapon's `ArmorPenetration` value, not from a number in the perk; the 100% case is a stat of 100 (x0).
- `AVIF 00097341` `ArmorPenetration`: default 0, "treat as % armor ignored".

**Approach (revised 2026-11-23): reuse the whole vanilla chain, add no new ENCH/MGEF/PERK for 0.1. DOES NOT WORK AS BUILT: see the findings section below.**
1. Weapon `EITM` (base enchantment) = the vanilla `enchModArmorPenetration` (`ENCH 001F4425`).
2. Give the Blade a weapon-level actor-value property `ArmorPenetration` = 30, as the vanilla OMOD does, but on the weapon's own object template (the template combination's `Properties`, which are empty on the sword) instead of in an OMOD. *To verify:* that template-level `ActorValues` properties apply to the item. Fallback: our own OMOD included in the template; it must not use `ap_melee_MeleeMod` (that is the sword's blade-mod slot) or `ap_Legendary`, so it would need a new attach point.
3. Eye of Ra (later): the stat rises to 100 while the Eye is worn, or a second perk; decide when that item is specced.

**Replaces the earlier plan** (new ENCH/MGEF/PERK with a fixed `-0.30`): with the vanilla function a fixed `-0.30` would not mean 30%, and reusing the vanilla chain needs fewer records. Why not copy the OMOD: it would occupy `ap_Legendary`, which would stop players adding a legendary effect; a weapon's own `EITM` does not use that slot.

**To verify (in-game):**
- That the weapon's `EITM` enchantment applies the perk while equipped and stops when not.
- That the `ArmorPenetration` stat on the weapon is what the perk reads (compare damage against an armored enemy with and without; the vanilla Penetrating legendary is the control).
- Fallback if it fails: the OMOD route exactly as vanilla, accepting that it uses the legendary slot or needs a new attach point.


## Armor penetration: in-game findings (2026-11-23)

**A working control (Verified).** A vanilla legendary Penetrating weapon, the Sword of Wonders (a legendary Chinese Officer Sword from Nuka-World, per the wiki), reads `player.getav ArmorPenetration` = **30.00** and `player.hasperk 001F4166` = **Rank 1** when equipped. On the SKK workshop target dummy (Normal difficulty) it did 37 to 41 damage unarmored and 23 to 29 against the heavy combat armor chest, where a plain Chinese Officer Sword did 32 and 15. So the chain in "How vanilla does it" is real and the two console commands are a valid check.

**What failed (Verified in game, same checks):**
1. Weapon `EITM` plus template-level `ArmorPenetration` (the as-built plugin, also a stat-100 test): stat 0, no perk; the dummy showed 15 for every sword.
2. A weapon whose Default template combination includes a copy of the vanilla legendary Penetrating mod (`001F4426`), with `Attach Point Index` 1 and then 0: the crafted item did not show as legendary; stat 0, no perk.
3. **Not a valid test:** an Upgrade-slot mod carrying the stat and enchantment. A bug in the build script (it looked up the mod's `DATA - Data` block by the wrong name) meant the properties were never added, so that approach is **still untested**. Fixed in `BuildBladePerk.pas`.

**How vanilla attaches penetration (Verified in xEdit, `Fallout4.esm` and `DLCRobot.esm`):**
- **Mundane melee mods** (Puncturing and Spiked knuckles and power fist) carry only the keyword `ap_melee_ArmorPenetrate` (`KYWD 00097342`). The base `PlayerPerk` (`PERK 00056DD7`) has an entry, Mod Target Damage Resistance / Multiply Value **0.85**, whose weapon-tab condition is `HasKeyword ap_melee_ArmorPenetrate`. So non-legendary melee is a flat **15%**, set in that one entry; the weapon carries only the tag. Perk entries have condition tabs (0 attacker, 1 weapon, 2 target).
- **Mundane gun mods** (Armor Piercing receivers) use the full trio: a `dn_HasReceiver_ArmorPiercing1`-type keyword, `Enchantments` `enchModArmorPenetration`, and `ActorValues` `ArmorPenetration` 40.
- **Legendary Penetrating** (`OMOD 001F4426`, attach point `ap_Legendary`, Legendary Mod flag): marker keywords, the enchantment, and `ArmorPenetration` 30.
- Only four vanilla weapon records ship with a legendary mod in their template (the Tesla Rifle, the two Sentry Bot miniguns, the Salvaged Assaultron Head, all `DLCRobot.esm`): it is an include in the **Default** combination, `Attach Point Index` 0, `Optional` False, `Don't Use All` True. We copied that and the game still did not apply it to a crafted item; reason unknown.
- The cheat terminal's legendary menu calls `ObjectReference.AttachMod` on the object the player is holding (`Game.GetPlayerGrabbedRef`), i.e. a legendary effect is attached to an item instance at runtime.

**Round 2 results (BuildBladePerk.pas, 2026-11-24, `RegaliaPerkTest2`; Verified in game, SKK dummy, Normal, Strength 10):**
- **Mod B (vanilla trio on an Upgrade-slot mod) works:** `getav ArmorPenetration` 30, `hasperk 001F4166` 1. Heavy chest: plain sword 15, mod B 18 (unarmored 32 for both). So the Upgrade-slot mechanism is real, but we do not control its strength directly.
- **Mod A (our keyword plus our perk, added with `player.addperk`, multiplier 0.0) works:** the sword (Electrified Serrated, so about 56 plus electric, 63 to 75 per swing) did the same damage unarmored, in the heavy chest and in full combat armor: all armor ignored. The weapon-tab `HasKeyword` perk entry is confirmed.

**Round 3 results (`BuildBladePerk2.pas`, plugin `RegaliaPerkTest3`; Verified in game, same conditions):**
- **Delivery needs no console, script or holotape.** Mod A also carries our own `ENCH` (a copy of `001F4425`) -> our `MGEF` (a copy of `001F4423`, archetype Add Perk, `Perk to Apply` = our perk) -> our perk. Equipping the sword gives `hasperk` 1; unequipping gives 0. The chain is copied from vanilla and re-pointed, with no new mechanism.
- **Real strength:** Blade perk entry multiplier 0.70. Heavy chest 40s to 50s against 60s to 70s unarmored (the Electrified Serrated base), roughly 0.7 to 0.75, consistent with 30% ignored.
- **Eye of Ra works as a keyword.** A second perk entry (multiplier 0.0) with two conditions: weapon-tab `HasKeyword MoM_Blade_KW` and attacker-tab `WornHasKeyword MoM_EyeOfRa_KW`. Multipliers stack, so Blade alone is 0.70, Blade plus Eye is 0.70 x 0.0 = 100% ignored, Eye alone does nothing. Measured: Blade plus Eye in the heavy chest 60s to 70s (the unarmored number); Eye with a plain sword 15. The Eye was a copy of the Eyeglasses (`001C4BE8`, Eyes slot 47) with our keyword; no enchantment, no script.
- **Therefore the mechanism is settled:** an Upgrade-slot mod (our keyword plus our enchantment) and our own perk. The mundane-Blade and Cryptos-holotape ideas are no longer needed for delivery.
- **Not tested:** the Eye on an unarmored target (expected no change); the Eye through a non-Hair-Top slot; the recipe gate and cost for the new mod; whether the mod can be crafted at the weapon workbench with conditions; the gold-tinted model.


**Round 4 results (`BuildBladeStats.pas`, plugin `RegaliaStats1`; Verified in game 2026-11-24, Normal, dummy, Strength 10):** a Serrated-only mod (`OMOD 00176DF9`, bleed, no shock) with `AttackDamage` 0.75 -> 1.2, `AttackActionPointCost` -0.43, `Weight` -0.33, plus our keyword and enchantment chain, built as one Upgrade mod and one with `Speed` +0.45.
- **Works:** damage 32 -> 70 unarmored (x2.2); heavy chest 51 to 61 (30% ignored, variance); weight 3 -> 2; VATS swings 2 -> 5 on the same AP (cheaper; exact cost not read); `hasperk` 1; the Eye brings the chest back to 70s to 80s.
- **Does not work:** the `Speed` property has no visible effect on a melee swing (the speed-test variant felt the same). Real swing speed is a weapon-record field: Disciples Blade is fast through `MASE - Melee Speed = Fast`, `Animation Attack Seconds` 0.77 (sword 1.12), AP 20, and the keyword `Anims1hmShortWeapon`. Chris does not want the short-blade keyword (the long sword's stab animations would not suit it).
- **Name:** the Pip-Boy shows "Serrated", as predicted: `dn_CommonMelee` (`INNR 000B9738`) maps keyword `dn_HasMeleeMod_Serrated` to "Serrated"; rules are text + keywords + index and the last rule `*` is the base name at the same index (10000), so a rule can only add words around the base name, not replace it.
- **Reference weapons (vanilla, xEdit):** Disciples Blade 20 damage, weight 1.5, AP 20, swing 0.77s; its Cutlass mod is +75% damage and bleed (so 35 base); Knife +25%; Hatchet +25%; Serrated Hatchet +75%. The Steel Sword (CC "Fantasy Hero Set", `ccBGSF04048_Sword`) is not installed here; wiki only: damage 25, medium speed, weight 4, mods add +16 (Sharp), +30, +44, units unknown.
- **Decision (Chris):** keep medium swing speed with cheaper VATS and lower weight (stays between Throatslicer, a Wounding Disciples Blade, and the Steel Sword). The next test was the name.

**Round 5 result (`BuildBladeName.pas`, `RegaliaName1`; Verified in game 2026-11-24):** the Upgrade mod without `dn_HasMeleeMod_Serrated` plus an override of `dn_CommonMelee` with a rule (our keyword -> "of Bastet", index 10001) shows **"of Bastet Chinese Officer Sword"**: the rule text goes in **front** of the base name regardless of index 10001 (so a suffix was not achieved, and rule order is not simply by index). Abandoned: a rule can only add words in front, and the override of a shared record has a compatibility cost.

**Round 6 result (`BuildBladeWeapon.pas`, `RegaliaWeapon1`; Verified in game 2026-11-24): the Blade as its own weapon works.** `MoM_WEAP_BladeOfBastet` is a copy of the sword (`00147BE4`), named "Blade of Bastet", whose template includes (Default, Standard, Simple) point at our mod (the Serrated-only mod with the round 4 stats, our keyword and enchantment chain, without the Serrated naming keyword) instead of "No Upgrade". Crafted at the Chemistry Station (the round 1 recipe: sword + Steel 4, Silver 3, Gold 2, Crystal 2, Adhesive 3, ungated):
- **Name:** exactly "Blade of Bastet" (no naming rule fires, no override of the shared record needed).
- **Stats:** damage 70 unarmored (Strength 10), weight 2, VATS 5 swings on the AP the plain sword spent on 2; the dummy and the perk behave as in rounds 3 and 4; the Eye works. Bleed not checked (the Blade carries the vanilla bleed enchantment `EnchWeapModBleed`).
- **So a default template include of a plain Upgrade-slot mod attaches on a crafted weapon** (the earlier failure was with a legendary mod).
- **Open (resolved in round 7 below): the weapon workbench still offered the vanilla Serrated, Electrified and other sword mods on the Blade,** in the same slot as ours, so swapping one in would drop our mod (the penetration, stats and bleed) while the item stayed named "Blade of Bastet".

**Round 7 result (`BuildBladeLock.pas`, `RegaliaLock1`; Verified in game 2026-11-24): the blade-mod slot is locked.** The Blade carries a new keyword `MoM_ma_Blade` **in place of** `ma_ChineseOfficerSword` (`KYWD 0018782C`) on the weapon, and our mod's target keyword list (`MNAM`) is `MoM_ma_Blade` too. Result: the name stays "Blade of Bastet", the stats and perk are as before, and the Blade **does not appear at the weapon workbench at all** (it has no mods compatible with it, like glasses at the armor station). A plain Chinese Officer Sword still lists all its mods. So workbench mod lists are filtered by the weapon's `ma_` keyword matched to the mods' target keywords.
- **Unconfirmed side effects:** a player cannot rename the Blade at the workbench if renaming lives there (not checked); the Blade's model is the Serrated blade because our mod is a copy of Serrated (Chris: fine, to be changed with the gold tint).
**Round 8 result (`BuildBladeEye.pas`, `RegaliaEye1`; Verified in game 2026-11-24): the Eye as a worn Neck item.** The Eye was re-slotted from Eyes (47) to Neck (50), its Perception enchantment (`EnchClothingPerception`, inherited from the Eyeglasses copy; the earlier test Eye had silently given a Perception bonus) removed, its world model set to `Props\LocketSilver.nif` (every locket in the game uses it) and its armature list removed. In game: it **shows as a locket when inspected** (the world-model route works for the inventory look); it equips. Neck conflict: it shares the slot with other neck items (equipping the Eye while wearing a Shock Collar removed the collar; the reverse did not remove the Eye, cause unknown; the collar is a quest item and may be script-forced). Not recorded: how it looks on the character with no armature, and the Pip-Boy preview framing (`PTRN` is still the glasses' `ArmorHead`).
- **Lore (Chris, 2026-11-24):** the Eye of Ra was a gem or necklace, not an eye; a neck item fits. Cryptos is a terminal under Riverside Manor.
- **Decision (Chris, 2026-11-24): for now the Eye is a "Jury-Rigged Eye of Ra" built on the Nuka-World Shock Collar (`DLC04_ShockCollar`, `06029AFA`) and its look**, the idea being that the Eye is being rebuilt from schematics. This makes the plugin **require `DLCNukaWorld.esm`** as a master (Chris accepts that). The final Eye can be the invisible locket later. Name candidates: "Jury-Rigged Eye of Ra" (preferred), "Rebuilt", "Salvaged". The collar record must be read first: it is a quest item and may carry a script, an effect or odd keywords that a copy would inherit.
- **Gold tint:** no vanilla gold weapon material exists (checked 2026-11-24: material swaps and weapon mods; the sword has no `ap_WeaponMaterial` slot), so it needs new art (a tinted texture, a new `.BGSM`, a material swap) and tools not installed on the Deck. Deferred to after the real plugin; a research-only session is looking into it.
- **Next:** read the Shock Collar record, build the Jury-Rigged Eye on it, then the real plugin with gates, description and the ESL flag.

## Recipe and cost

**Recipe (`COBJ`), proposed:** consume the sword, plus materials; create `MoM_WEAP_BladeOfBastet`.

| Ingredient | Amount | Why |
|---|---|---|
| Chinese Officer Sword (`00147BE4`) | 1 | the conversion base (vanilla recipes already use items as ingredients: the Baseball grenade uses a `Baseball`, the Bottlecap mine a `LunchBoxKids01`) |
| Steel (`c_Steel`, `CMPO 0001FABD`) | 4 | the blade work |
| Silver (`c_Silver`, `CMPO 0001FABB`) | 3 | the ceremonial theme |
| Gold (`c_Gold`, `CMPO 0001FAA6`) | 2 | scarcer on purpose: it should not be too easy |
| Crystal (`c_Crystal`, `CMPO 0001FA9F`) | 2 | a gem inlay in the hilt; fits the Eye of Ra and the regalia theme, and is plentiful early |
| Adhesive (`c_Adhesive`, `CMPO 0001FAA5`) | 3 | common, matches other melee recipes |

About 14 components plus the sword, in line with vanilla sword mods (the Shock mod costs 18 components; Shock+Serrated 26). Gold is the deliberate friction. No fiber optics, circuitry or nuclear material.

**UPDATE 2026-11-24 (Verified in game): the gate is `HasPerk` Cryptos Notes (the book) AND Blacksmith rank 3 (`000264D8`) AND Science rank 1 (`000264D9`), the same as Electrified Serrated; recipes appear greyed until met.** Old text: **Perk gate: Blacksmith rank 2 only** (`Blacksmith02`, via the `HasPerk` condition, function index `448`). The sword's own Serrated and Shock mods use the same rank (Verified), and the story gate already limits who sees it, so a second perk gate (Science) would be ceremony.

*Component FormIDs above are Verified (read in xEdit from `Fallout4.esm`, 2026-11-23; the game has 31 components). The perk is `Blacksmith02`, `PERK 0004B26A` (Verified; "You gain access to Rank 2 melee weapon mods"; its own prerequisite is a Strength check, which does not affect a `HasPerk` condition).* *To verify in-game:* whether a sword that already has mods installed counts as the ingredient, and what the player gets back (the Blade comes unmodded).


*Workbench, category, discovery gate and instructions are set-wide: see `spec-regalia.md`.*

## Test plan (Blade, for the Steam Deck in the separate MO2 instance)

1. Crafting consumes the sword and produces the Blade; vanilla sword mods still attach.
2. Damage against a heavily armored enemy is higher than the plain sword; against an unarmored enemy it is the same.
3. Removing the Blade removes the effect; a legendary effect can still be added.
4. A sword that already has mods installed: does it count as the ingredient, and what comes back.

## Open items (Blade)

- **Mechanism resolved (2026-11-24):** an Upgrade-slot mod plus our own ENCH/MGEF/PERK; see the findings section. **Open design choice:** the test mod is a copy of Electrified Serrated, so it takes the blade-mod slot and inflates damage; the real Blade must pick between a mundane base (damage tuned in an OMOD property; gold tint) and keeping serrated/shock, and move the recipe to the weapon workbench with the story and perk gates.
- Read in xEdit and done (2026-11-23): component and perk FormIDs, the sword's base damage (16), the penetration chain's strength.
