# Build spec: Regalia of Mystery

**Read this first.** It is the current state of the mod and every decision behind it, written so that someone new can build it. State as of **2026-11-25**. Open work is in [`next-steps.md`](next-steps.md). The other files in this folder are the history (how each answer was found, including dead ends); where they disagree with this file, this file wins.

Words used: **verified** means the owner (Chris) saw it work in game. **Untested** means built or written but not seen.

## 1. What the mod is

The Fallout 76 Order of Mysteries gear (the Mistress of Mystery's Regalia), rebuilt in Fallout 4. The player finds a book of notes and five broken items, and repairs each at a Chemistry Station. Wearing the **Eye of Ra** makes every other piece stronger.

## 2. Rules for the whole set

| Rule | Decision |
|---|---|
| Broken items | Every piece is found broken and repaired, so copies are limited to the world's supply. No protection against selling, dropping or stashing. |
| Discovery | Reading the **Cryptos** book grants the perk `MoM_PERK_Cryptos` ("Cryptos Notes"), with no script. No quest-stage gate. |
| Recipe gate | `HasPerk` Cryptos Notes **plus exactly one** skill perk. The craft screen shows only two perk prerequisites. Locked recipes show greyed. |
| Station | Chemistry Station (`WorkbenchChemlab` `00102158`), category `RecipeUtility` (`0006980C`). |
| Scripts | No Papyrus. Everything is records plus loose art. |
| Vanilla records | None are overridden; everything is a copy or a new record. |
| Editor ID prefix | `MoM_` |
| Masters | `Fallout4.esm` and `DLCNukaWorld.esm` (the Eye is a Shock Collar copy). No Creation Club master. |
| Assets | Never committed. Commit the script that makes an asset. |
| Balance | Pieces stay in line with vanilla gear; the Eye is where the extra power is. |

## 3. The pieces (all verified in game unless noted)

### Recipes

| Result | Broken item (record) | Other ingredients | Skill perk |
|---|---|---|---|
| Blade of Bastet | Broken Blade of Bastet (`MISC`) | Steel 4, Silver 3, Gold 2, Crystal 2, Adhesive 3 | Blacksmith 3 (`Blacksmith03` `000264D8`) |
| Jury-Rigged Eye of Ra | Broken Eye of Ra (`MISC`) | Crystal 2, Silver 2, Adhesive 2 | Science 3 (`Science03` `000264DB`) |
| Garb of Mysteries | Tattered Dress (`ARMO`, wearable) | Cloth 6, Adhesive 2, Silver 1 | Armorer 3 (`Armorer03` `0004B256`) |
| Veil of Secrets | Broken Veil of Secrets (`ARMO`) | Cloth 3, Adhesive 2, Silver 2 | Chemist 3 (`Chemist03` `000E3701`) |
| Voice of Set | Broken Voice of Set (`MISC`) | Steel 4, Screws 2, Silver 2, Adhesive 3 | Gun Nut 3 (`GunNut03` `0004A0DC`) |

Component IDs: Steel `0001FABD`, Silver `0001FABB`, Gold `0001FAA6`, Crystal `0001FA9F`, Adhesive `0001FAA5`, Cloth `001223C7`, Screws `0003D294`. Ingredient amounts for the last three recipes were chosen by the assistant and accepted without tuning.

### Cryptos book and broken items

- `MoM_BOOK_Cryptos` "Cryptos: Regalia of Mystery": copy of the Silver Shroud Photo (`0018AC1E`), flag **Add Perk**, **Teaches** the Cryptos perk. The perk is a copy of the Barbarian magazine perk (`0008E3A6`) with no effects and one rank. It stays after the book is stashed.
- Broken Eye, Broken Blade, Broken Voice: `MISC` copies of the Silver Locket (`00059B34`), scrap components removed, `UnscrappableObject` (`001CC46A`). The Blade uses the sword mesh, the Voice `Weapons\44\44.nif`.
- Tattered Dress: the Sequin Dress with the faded art, underarmor slots, no enchantment, armor rating 0, value 5.
- Broken Veil: plain copy of the Surgical Mask, armor rating 0, value 5.

### Blade of Bastet

- Own weapon record, a copy of the Chinese Officer Sword (`00147BE4`), name exactly "Blade of Bastet". Own `MoM_ma_Blade` keyword, so the workbench offers no vanilla mods.
- Its default mod `MoM_OMOD_Blade` is a copy of the Serrated mod (`00176DF9`): adds `MoM_Blade_KW` and our enchantment; `AttackDamage` +0.45 over the serrated base (to 1.2), AP cost -0.43, weight -0.33; the serrated naming keyword removed.
- **Look:** the plain model `Weapons\ChineseOfficerSword\Blade.nif` with a material swap to our gold material.
- **Numbers seen:** damage 70 at Strength 10, weight 2, VATS cost about 20, medium swing speed (the `Speed` property does nothing for melee).
- **Armor penetration:** 30% from our perk (a `PlayerPerk` melee entry, weapon tab `HasKeyword`, multiplier 0.70). With the Eye, 100% (a second entry, multiplier 0.0, attacker tab `WornHasKeyword`).
- Bleed comes from the serrated base (not separately confirmed).

### Jury-Rigged Eye of Ra

- Copy of the Nuka-World Shock Collar (`DLC04_ShockCollar` `06029AFA`), neck slot, keyword `MoM_EyeOfRa_KW`. No enchantment: each other piece checks for the keyword.

| Piece | Without the Eye | With the Eye |
|---|---|---|
| Blade | 30% armor penetration | 100% |
| Garb | sneak +5, sneak attack +0.25 (one-hand melee) / +0.125 (other) | sneak +25, sneak attack +1.0 / +0.5 |
| Veil | persuade +5, poison resistance 10 | persuade +15, poison resistance 20 |
| Voice | 30% stagger on hit | a second independent 30% roll (about 51%) |

The Eye adds **no** damage or energy resistance to anything.

### Garb of Mysteries

- Copy of the Sequin Dress (`0011A27B`, addon `0011A27A`). Damage resistance 20, energy resistance 20, value 50, weight 1.0, +1 Perception, +5 speed while sneaking, plus the sneak effects above (our hidden perk delivered by the enchantment).
- Underarmor slots: `First Person Flags` = 1992 (33, 36 to 40), so armor goes over it. Ballistic weave is offered. Light armor by design: if weave ever stopped being offered, the resistances would need raising. No upgrade levels.
- **Look:** charcoal body, emerald chevrons, cream-gold shoulder cowl, sequins kept.

### Veil of Secrets

- Copy of the Surgical Mask (`000787DA`, addon `000787D0`; slots 48 and 49, so hats work). Value 40, weight 0.2, no armor rating.
- **Persuade** through `Mod Charisma Challenge Chance`. **Poison resistance stands in for disease** (the game has no disease resistance stat). No radiation, no intimidate (no vanilla anchor).
- **Poison gas immunity**, copied from the Hazmat Suit perk (`Set Value` 0.0 on spells with `DN102_PoisonGasEffectKeyword` `000449B9`). Built; **untested**.
- **Look:** black fabric with a cream-gold diamond net.

### Voice of Set

- A **.44** (lore), copy of `000CE97D`, name exactly "Voice of Set" (instance naming removed). Damage 48, the same as the .44; the Western Revolver is 60. Random receivers and barrels are **intended** (Chris: fine as a leveled spread).
- **Silenced:** Sound Level Silent, keyword `s_20_Silenced`, and our own sound keyword mapping (`KSSM`), a copy of the silenced Pipe Revolver mapping (`0002B941`) re-keyed to the .44 sound keyword. No visual suppressor.
- **Sonic burst at every impact:** our projectile is a copy of `MS09PushProjectile` (`00199046`, Missile type with the `Explosion` flag; speed 10000, no gravity, suppressed muzzle flash). Our explosion is a copy of `MS09PushExplosion` (`000E5786`): force 250, damage 0, radius 32/128, stagger Medium, Mirelurk King sonic sound.
- **Stagger:** `MoM_OMOD_Voice`, our copy of the legendary Staggering mod (`001E81AB`), included in every template combination. The "legendary item" pickup screen is kept.
- **Eye boost:** that mod also grants a hidden perk: an `Apply Combat Hit Spell` entry (from `BigLeagues02`) casting our stagger spell when the Eye is worn, a 30% roll passes and the weapon has `MoM_Voice_KW`.
- **Look:** gold metal with black shadows, charcoal grips, gold medallions and diamond screw plates. Same gold tint and bronze reflection as the Blade, with darker mid-tones. Scopes, sights glass and rubber grips stay vanilla.

## 4. How to build

### Current layout: a chain of test plugins

There is no single plugin yet. These are the verified builds, **in dependency order**:

| Order | Script (`build/xedit/`) | Plugin | Contents | Needs ticked |
|---|---|---|---|---|
| 1 | `BuildBladeGold.pas` | `RegaliaGold1` | Blade, Eye, book, Broken Blade, Broken Eye, their recipes | game + DLC |
| 2 | `BuildGarb.pas` | `RegaliaGarb2` | Garb | + Gold1 |
| 3 | `BuildVeil.pas` | `RegaliaVeil1` | Veil | + Gold1 |
| 4 | `BuildBroken2.pas` | `RegaliaBroken2` | Tattered Dress, Broken Veil, two recipes | + Gold1, Garb2, Veil1 |
| 5 | `BuildVoice3.pas` | `RegaliaVoice12` | Voice, Broken Voice, its recipe | + Gold1 |

Every other script in that folder is an earlier round or a diagnostic, kept for reference. The constant `PLUGIN_HINT` only changes the on-screen hint; the name typed in the box is what is created, and later scripts look up `RegaliaGold1.esp`, `RegaliaGarb2.esp` and `RegaliaVeil1.esp` by exactly those names.

### Art (run before testing looks)

All need `baunpack` (Alexandria `memory/fo4-mod/fo4-archives.md`). Run with `python3 -B <script> OUTDIR`, then copy `Textures/` and `Materials/` into the MO2 mod folder.

| Command | MO2 mod |
|---|---|
| `make_gold.py OUT` | Blade of Bastet Art |
| `make_gold44.py OUT` | Blade of Bastet Art |
| `make_dress.py OUT` | Garb of Mysteries Art |
| `make_dress.py OUT --tattered --name TatteredDress` | Garb of Mysteries Art |
| `make_veil.py OUT --lace` | Veil of Secrets Art |

Loose files need `bInvalidateOlderFiles=1` and an empty `sResourceDataDirsFinal=` under `[Archive]` in the MO2 profile's `fallout4custom.ini`. Texture-only changes need a game restart, not a rebuild.

### Running a script

Environment: Steam Deck, a separate MO2 instance for Fallout 4, profile **Test**, FO4Edit 4.1.5f under Proton. Setup and the working loop are in Alexandria `memory/fo4-mod/` (`fo4-deck-mo2-setup`, `fo4-deck-workflow`).

1. The person closes MO2 completely and says so. The assistant backs up `ModOrganizer.ini` and points the BUILD entry (`5\arguments=`) at the script. **If MO2 is open, it overwrites the edit with the old value**, and the assistant cannot detect MO2's process. No edit is needed to rerun the same script file.
2. The person opens MO2, runs BUILD, checks the window says **Applying script "<name>"**, ticks the modules, types a **new** plugin name, closes xEdit and accepts the save.
3. The assistant checks `~/Games/mo2-lint/tools/our-scripts/build.log` (no `FAIL` or exception lines; the logged values read back right) and the plugin's date and size, before any in-game test.

### xEdit and engine facts that cost us time

- `wbCopyElementToFile(src, file, True, True)` copies as a new record. Add masters yourself.
- `FormID(rec)` is numbered for the record's own file. For another plugin's record use `LoadOrderFormIDtoFileFormID(f, GetLoadOrderFormID(rec))` (the `Ref` helper in `BuildVoice3.pas`).
- xEdit's order of list entries can differ from the file's; pick entries by name, never by index.
- A condition list cannot be created on a spell effect with `Add`; put the condition on the perk entry.
- Log every written value and stop with `FAIL` when one is wrong.
- Perks with no script: constant enchantment, to an Add Perk magic effect, to the perk; attach by a weapon mod or armor `EITM`. A weapon record's `EITM` on our .44 never applied.
- An explosion fires only from a projectile with the `Explosion` flag (Missile type here); ordinary bullets are Beam type without it.
- Gunshot sounds are chosen by `KSSM` records matched on the weapon's `s_` keywords.
- Fields under `FNAM` (for example `Override Projectile`) are not under `DNAM`.
- Creation Club files downloaded through MO2 land in its `overwrite` folder, and xEdit did not load them. Rhodes `scripts/esp/esp.py` reads any plugin directly.

More detail: Alexandria `memory/fo4-mod/` (context prep lists it).

## 5. Console, for testing

`help "<name>" 4` finds an ID; `player.additem <ID> 1`; `.44` ammo `0009221C`; `player.addperk` / `player.hasperk <ID>`; `amod <modID>` on a clicked dropped item. Targets: `player.placeatme 00106B07` (Protectron), `0005A9C1` (Mirelurk). The practice dummy cannot show a stagger.

## 6. Licence

Creation Kit EULA (<https://store.steampowered.com/eula/1946160_eula_1>), read by a helper agent, not legal advice: non-commercial, and the release must carry "THIS MATERIAL IS NOT MADE, GUARANTEED OR SUPPORTED BY ZENIMAX OR ITS AFFILIATES." (accepted). Our own licence is undecided.
