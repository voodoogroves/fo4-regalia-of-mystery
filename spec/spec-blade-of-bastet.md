# Spec: Blade of Bastet (version 0.1)

*Status: DRAFT, plan not yet built or tested. Item-level mechanics for the Blade. Set-wide decisions (plugin name, discovery gate, workbench, instructions) are in `spec-regalia.md`; intent is in `concept-spec.md`. Each fact is marked **Verified** (read from the game files or the xEdit source on 2026-11-22) or **To verify** (needs xEdit or in-game testing).*

## Goal (from the concept-spec)

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

Base damage and speed are inherited unchanged. *Not yet read:* the sword's damage lives in a record or template I did not trace; compare in xEdit before final.


## The sword's vanilla mods (Verified from the game's OMOD records)

The sword has two attach points (`ap_melee_MeleeMod` and `ap_Legendary`) and four blade states:

| Mod | In-game name | Effect | Cost (perk gate) |
|---|---|---|---|
| `mod_melee_ChineseOfficerSword_Null` | No Upgrade | the base sword; changes nothing | free |
| `..._Serrated` | Serrated Blade | +75% damage; targets bleed (`EnchWeapModBleed`) | Steel 7, Oil 3, Fiberglass 4, Adhesive 3 (Blacksmith 2) |
| `..._Shock` | Electrified Blade | +5 electrical damage (`EnchWeapModShock`) | Rubber 3, Circuitry 3, Aluminum 8, Adhesive 4 (Blacksmith 2, Science 1) |
| `..._ShockAndSerrated` | Electrified Serrated Blade | both of the above | 26 components (Blacksmith 3, Science 1) |

No other mod slots exist besides the legendary slot. The copy should keep these so players can still stack bleed and shock on the Blade. *To verify:* that the copy's default mod list points at the vanilla "No Upgrade" mod and that all four attach. The base damage number is not in these mods (the standard state changes nothing); it comes from the weapon record or its template and is still untraced.


## Armor penetration (the one change)

**How vanilla does it (Verified):**
- Weapon stat `ArmorPenetration` (AVIF `00097341`): 0 to 100, a percentage of the target's armor ignored.
- Legendary "Penetrating": OMOD `001F4426` sets that property to `30.0` and attaches ENCH `001F4425` -> MGEF `001F4423` (Add Perk) -> PERK `001F4166`.
- That perk has one entry point, **Mod Target Damage Resistance** (entry point 37 in the xEdit definitions), with the AV `ArmorPenetration` and a small multiplier (about `-0.01`). *Inference, not confirmed:* it subtracts (weapon stat x 1%) from the target's damage resistance.

**Our approach (proposed), avoiding the legendary slot:**
1. Weapon `EITM` (base enchantment) = new `MoM_ENCH_BladeOfBastet`, constant effect on the wielder.
2. ENCH effect = new MGEF `MoM_MGEF_BladeOfBastetPerk`, a copy of `001F4423` (Add Perk).
3. MGEF adds new PERK `MoM_PERK_BladeOfBastet`: entry point **Mod Target Damage Resistance**, value **-0.30** (30% of the target's armor ignored). A second entry for the Eye of Ra (-1.00) comes later, conditioned on the Eye being worn.

Why this over copying the OMOD: the vanilla legendary OMOD occupies `ap_Legendary`, which would stop players adding a legendary effect. A weapon's own `EITM` does not use that slot.

**To verify:**
- That a constant-effect `EITM` on a melee weapon applies while it is equipped and stops when it is not.
- That the perk's armor reduction works as inferred (a 30% reduction of the target's resistance), by comparing damage against an armored enemy with and without.
- Fallback if it fails: the OMOD route (set `ArmorPenetration` = 30 as a property, as vanilla does), accepting that it uses the legendary slot or needs a new attach point.


## Recipe and cost

**Recipe (`COBJ`), proposed:** consume the sword, plus materials; create `MoM_WEAP_BladeOfBastet`.

| Ingredient | Amount | Why |
|---|---|---|
| Chinese Officer Sword (`00147BE4`) | 1 | the conversion base (vanilla recipes already use items as ingredients: the Baseball grenade uses a `Baseball`, the Bottlecap mine a `LunchBoxKids01`) |
| Steel (`c_Steel`) | 4 | the blade work |
| Silver (`c_Silver`) | 3 | the ceremonial theme |
| Gold (`c_Gold`) | 2 | scarcer on purpose: it should not be too easy |
| Crystal (`c_Crystal`) | 2 | a gem inlay in the hilt; fits the Eye of Ra and the regalia theme, and is plentiful early |
| Adhesive (`c_Adhesive`) | 3 | common, matches other melee recipes |

About 14 components plus the sword, in line with vanilla sword mods (the Shock mod costs 18 components; Shock+Serrated 26). Gold is the deliberate friction. No fiber optics, circuitry or nuclear material.

**Perk gate: Blacksmith rank 2 only** (`Blacksmith02`, via the `HasPerk` condition, function index `448`). The sword's own Serrated and Shock mods use the same rank (Verified), and the story gate already limits who sees it, so a second perk gate (Science) would be ceremony.

*Component names above are verified to exist in the game (31 components, including Silver, Steel, Circuitry, Adhesive). FormIDs still need reading in xEdit.* *To verify in-game:* whether a sword that already has mods installed counts as the ingredient, and what the player gets back (the Blade comes unmodded).


*Workbench, category, discovery gate and instructions are set-wide: see `spec-regalia.md`.*

## Test plan (Blade, for the Steam Deck in the separate MO2 instance)

1. Crafting consumes the sword and produces the Blade; vanilla sword mods still attach.
2. Damage against a heavily armored enemy is higher than the plain sword; against an unarmored enemy it is the same.
3. Removing the Blade removes the effect; a legendary effect can still be added.
4. A sword that already has mods installed: does it count as the ingredient, and what comes back.

## Open items (Blade)

- Component and perk FormIDs (read in xEdit); tracing the sword's base damage; whether the copy's default mod list reuses the vanilla "No Upgrade" mod; the armor-penetration mechanism (`EITM` route) proven in-game.
