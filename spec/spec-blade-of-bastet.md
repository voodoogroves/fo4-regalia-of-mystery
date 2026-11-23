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

**Approach (revised 2026-11-23): reuse the whole vanilla chain, add no new ENCH/MGEF/PERK for 0.1.**
1. Weapon `EITM` (base enchantment) = the vanilla `enchModArmorPenetration` (`ENCH 001F4425`).
2. Give the Blade a weapon-level actor-value property `ArmorPenetration` = 30, as the vanilla OMOD does, but on the weapon's own object template (the template combination's `Properties`, which are empty on the sword) instead of in an OMOD. *To verify:* that template-level `ActorValues` properties apply to the item. Fallback: our own OMOD included in the template; it must not use `ap_melee_MeleeMod` (that is the sword's blade-mod slot) or `ap_Legendary`, so it would need a new attach point.
3. Eye of Ra (later): the stat rises to 100 while the Eye is worn, or a second perk; decide when that item is specced.

**Replaces the earlier plan** (new ENCH/MGEF/PERK with a fixed `-0.30`): with the vanilla function a fixed `-0.30` would not mean 30%, and reusing the vanilla chain needs fewer records. Why not copy the OMOD: it would occupy `ap_Legendary`, which would stop players adding a legendary effect; a weapon's own `EITM` does not use that slot.

**To verify (in-game):**
- That the weapon's `EITM` enchantment applies the perk while equipped and stops when not.
- That the `ArmorPenetration` stat on the weapon is what the perk reads (compare damage against an armored enemy with and without; the vanilla Penetrating legendary is the control).
- Fallback if it fails: the OMOD route exactly as vanilla, accepting that it uses the legendary slot or needs a new attach point.


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

**Perk gate: Blacksmith rank 2 only** (`Blacksmith02`, via the `HasPerk` condition, function index `448`). The sword's own Serrated and Shock mods use the same rank (Verified), and the story gate already limits who sees it, so a second perk gate (Science) would be ceremony.

*Component FormIDs above are Verified (read in xEdit from `Fallout4.esm`, 2026-11-23; the game has 31 components). The perk is `Blacksmith02`, `PERK 0004B26A` (Verified; "You gain access to Rank 2 melee weapon mods"; its own prerequisite is a Strength check, which does not affect a `HasPerk` condition).* *To verify in-game:* whether a sword that already has mods installed counts as the ingredient, and what the player gets back (the Blade comes unmodded).


*Workbench, category, discovery gate and instructions are set-wide: see `spec-regalia.md`.*

## Test plan (Blade, for the Steam Deck in the separate MO2 instance)

1. Crafting consumes the sword and produces the Blade; vanilla sword mods still attach.
2. Damage against a heavily armored enemy is higher than the plain sword; against an unarmored enemy it is the same.
3. Removing the Blade removes the effect; a legendary effect can still be added.
4. A sword that already has mods installed: does it count as the ingredient, and what comes back.

## Open items (Blade)

- Whether the copy's default mod list reuses the vanilla "No Upgrade" mod (`00176DF8`); whether template-level `ArmorPenetration` properties apply; the armor-penetration mechanism (`EITM` + weapon stat) proven in-game.
- Read in xEdit and done (2026-11-23): component and perk FormIDs, the sword's base damage (16), the penetration chain's strength.
