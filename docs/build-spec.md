# Build spec: Regalia of Mystery

**Read this first.** It is the current state of the mod and every decision behind it, written so that someone new can build it. State as of **2026-11-26** (test plugin `RegaliaWorld10`). Open work is in [`next-steps.md`](next-steps.md). The other files in this folder are the history (how each answer was found, including dead ends); where they disagree with this file, this file wins.

Words used: **verified** or **seen** means the owner (Chris) saw it work in game. **Untested** or **not reported** means built or written but not seen. Section 3.6 lists everything not yet seen.

## 1. What the mod is

The Fallout 76 Order of Mysteries gear (the Mistress of Mystery's Regalia), rebuilt in Fallout 4. A dead woman from Appalachia lies on a Boston rooftop with her diary and a book of notes (the Cryptos). The diary leads the player to five broken items, each repaired at a Chemistry Station. Wearing the **Eye of Ra** makes every other piece stronger.

## 2. Rules for the whole set

| Rule | Decision |
|---|---|
| Broken items | Every piece is found broken and repaired, so copies are limited to the world's supply. Broken items are **plain, non-wearable** `MISC` records. No protection against selling, dropping or stashing. |
| Discovery | Reading **Mystery: Cryptos** grants the perk `MoM_PERK_Cryptos` ("Mystery: Cryptos Notes"), with no script. No quest-stage gate. |
| Recipe gate | `HasPerk` Cryptos Notes **plus exactly one** skill perk. The craft screen shows only two perk prerequisites. Locked recipes show greyed. |
| Station | Chemistry Station (`WorkbenchChemlab` `00102158`), category `RecipeUtility` (`0006980C`). |
| Scripts | No Papyrus. Everything is records plus loose art. |
| Vanilla records | No vanilla item, perk or effect is changed. Placement **does** override map cells (and the Commonwealth worldspace record) to add our references; see 3.2. |
| Editor ID prefix | `MoM_` |
| Masters | `Fallout4.esm` and `DLCNukaWorld.esm` (the Eye is a Shock Collar copy). No Creation Club master. |
| Names | Found items: "Mystery: ..."; repaired pieces: their own names, no prefix. |
| Assets | Never committed. Commit the script that makes an asset. |
| Balance | Pieces stay in line with vanilla gear; the Eye is where the extra power is. |

## 3. The mod as built

### 3.1 Recipes (all repairs crafted in game 2026-11-26 with `RegaliaWorld6`, before the Eye's rename)

| Result | Found item (editor ID, plugin) | Other ingredients | Skill perk |
|---|---|---|---|
| Blade of Bastet | Mystery: Broken Sword (`MoM_MISC_BrokenBladeOfBastet`, Gold1) | Steel 4, Silver 3, Gold 2, Crystal 2, Adhesive 3 | Blacksmith 3 (`000264D8`) |
| Eye of Ra | Mystery: Broken Necklace (`MoM_MISC_BrokenEyeOfRa`, Gold1) | Crystal 2, Silver 2, Adhesive 2 | Science 3 (`000264DB`) |
| Garb of Mysteries | Mystery: Tattered Dress (`MoM_MISC_TatteredDress`, World) | Cloth 6, Adhesive 2, Silver 1 | Armorer 3 (`0004B256`) |
| Veil of Secrets | Mystery: Worn Veil (`MoM_MISC_TatteredVeil`, World) | Cloth 3, Adhesive 2, Silver 2 | Chemist 3 (`000E3701`) |
| Voice of Set | Mystery: Broken Revolver (`MoM_MISC_BrokenVoice`, Voice12) | Steel 4, Screws 2, Silver 2, Adhesive 3 | Gun Nut 3 (`0004A0DC`) |

Component IDs: Steel `0001FABD`, Silver `0001FABB`, Gold `0001FAA6`, Crystal `0001FA9F`, Adhesive `0001FAA5`, Cloth `001223C7`, Screws `0003D294`. Amounts for the last three recipes were chosen by the assistant and accepted without tuning. Where this file or the scripts say Broken Blade, Eye or Voice, they mean these records.

- The Sword, Necklace and Revolver are `MISC` copies of the Silver Locket (`00059B34`), scrap components removed, `UnscrappableObject` (`001CC46A`). Models: the sword mesh, the locket, `Weapons\44\44.nif`.
- The Dress and Veil are made the same way, with world models `Clothes\SlinkyDress\GO_SequinDress.nif` and `Armor\Raider02\Mask_GO.nif`. `BuildWorld.pas` overrides the two recipes in `RegaliaBroken2` to take them. The wearable broken records in Broken2 (`MoM_ARMO_TatteredDress`, `MoM_ARMO_BrokenVeil`) are no longer obtainable; the dress is still used as the model for the Traveler's outfit.
- Why plain items: crafting the Veil from the wearable broken Veil crashed the game with `RegaliaWorld5` ticked (**cause not proven**), and crafting the Garb while wearing the Tattered Dress left its look stuck on the player.

### 3.2 The world (placed by `BuildWorld.pas`; placements seen and accepted)

| What | Cell | Position x, y, z, heading | Our record (vanilla base) |
|---|---|---|---|
| The Mysterious Traveler | `0000E0BA` | 5514.07, -18598.39, 1820 | see 3.3 |
| Diary, loose beside her, No Respawn | `0000E0BA` | 5556, -18622, 1806, 80 | `MoM_BOOK_Diary` (note `001D5CDC`) |
| Cryptos, loose beside her, No Respawn | `0000E0BA` | 5560, -18578, 1806, 110 | override of `MoM_BOOK_Cryptos` |
| Suitcase: Broken Sword | `0000E0BA` (rooftops by Hubris) | 7408.37, -18588.25, 1856.75, 68 | `MoM_CONT_Blade` (`001002A4`) |
| Duffle bag: Broken Revolver | `0000E0B9` (Swan's pond) | 11993.90, -20086.55, 596.4, 35 | `MoM_CONT_Voice` (`0008E59E`) |
| First aid kit: Worn Veil | `0000E0D9` (near the cafe) | 7267.84, -20585.32, 1117.2, 180 | `MoM_CONT_Veil` (`0020A6FD`) |
| Tool case: Broken Necklace | `0004542D` (Hubris interior), on file cabinet `00066AC5` | 2818.3, -245.5, 839.5, 135 | `MoM_CONT_Eye` (`001103E3`) |

- Containers: our copies with the Respawns flag (`DATA` bit `0x02`) cleared, scripts and vanilla contents removed, one item each.
- Skins (`make_containers.py`): charcoal with emerald chevrons or stripes, one material swap each. The suitcase uses `SetDressing\Suitcase\Suitcase_prewar.nif`, because `Suitcase01.nif` names no material to swap.
- The books lie loose because taking an item from a container or body does not open it for reading.
- Cell overrides: the cells' scenery (previs) data matches vanilla in the saved plugin, and the scenery looked normal. xEdit's copy of the worldspace record drops `OFST`, `RNAM` and `CLSZ`; no problem seen.
- An unmanaged plugin in this install, `atomic_age (8).esp`, overrides some of the same cells: keep it unticked.

### 3.3 The Mysterious Traveler

- `MoM_NPC_Seeker`: copy of `Loot_CorpseSettlerFemale_Empty` (`0020A578`, no respawn). Thin (weight 1,0,0), jet black hair (`0019EE60`), "No Apologies" hairstyle (`0016CA35`). "Use template: base data" cleared, or she is named "Settler".
- Outfit `MoM_OTFT_Seeker`: `MoM_ARMO_SeekerDress`, a copy of the Tattered Dress flagged **Non-Playable** (record flag `0x4`). Inventory: the plain Mystery: Tattered Dress only.
- One `ACHR` with **Starts Dead** (`0x200`). Pose: `XRGD` and `XRGB` copied from vanilla `ACHR 001289CF`; without a saved pose she stood upright in a T-pose.

### 3.4 The two books

- **Mystery: Cryptos**: copy of the Silver Shroud Photo (`0018AC1E`), flag **Add Perk**, **Teaches** the Cryptos perk (a copy of the Barbarian magazine perk `0008E3A6`, no effects, one rank). The perk stays after the book is stashed. Text: [`cryptos-text.md`](cryptos-text.md).
- **Mystery: Traveler's Diary**: text [`diary-text.md`](diary-text.md).
- A book shows its text on the page of its **preview model** (`INAM`). Both use the standard note page (`STAT 001B5EF1`, `Interface\Newspaper\Note.nif`); Cryptos uses our copy `MoM_STAT_CryptosSketch` with the sketch faded into the paper. The small photo model showed no text, the large photo page cut it off, the torn note showed half a page.
- The world card shows our pencil sketch (material swap on the photo model). Source images are outside the repos in `~/Games/mo2-lint/tools/our-assets/photo-candidates/` (use `candidate-03-line-art-pencil.png`).
- The script reads both text files at build time and fails unless the diary contains "Someone should." and the Cryptos text "THE VOICE OF SET". Plain text with straight quotes.

### 3.5 The Eye of Ra

- Copy of the Nuka-World Shock Collar (`DLC04_ShockCollar` `06029AFA`), neck slot, keyword `MoM_EyeOfRa_KW`. No enchantment: each other piece checks for the keyword. Named "Eye of Ra" by an override (Gold1 calls it "Jury-Rigged Eye of Ra").

| Piece | Without the Eye | With the Eye |
|---|---|---|
| Blade | 30% armor penetration | 100% |
| Garb | resistance 30 damage / 30 energy; harder to detect +5; sneak attack +0.2 (one-hand melee) / +0.1 (not melee) | resistance 70 / 70; harder to detect +25; sneak attack +0.6 / +0.3 |
| Veil | persuade +5, poison resistance 10 | persuade +15, poison resistance 20 |
| Voice | 30% stagger on a direct hit; the burst affects nobody | the burst also staggers those it catches, 50% (never the player) |

The only damage or energy resistance the Eye adds is on the Garb.

### 3.6 Not yet seen in game

- Round 10: no ballistic weave at the armor workbench on a freshly repaired Garb; the new sneak attack values; the "Mystery: Worn Veil" repair.
- The Eye repair giving "Eye of Ra", and recipes still unlocking after the perk's rename.
- Reading both books on the full note page (text fit; Cryptos over the faded sketch); the current diary wording in game.
- Whether the burst stagger can catch the player (it should not).
- After an area reset: the Traveler, loose books and containers stay put and taken items stay gone. Blast resistance of the loose books.
- Veil poison gas immunity; Veil poison boost with the Eye (the Veil's history file says seen, an older to-do says not); Garb detection effect; Blade bleed.

## The pieces in detail

### Blade of Bastet

- Own weapon record, a copy of the Chinese Officer Sword (`00147BE4`), name exactly "Blade of Bastet". Own `MoM_ma_Blade` keyword, so the workbench offers no vanilla mods.
- Its default mod `MoM_OMOD_Blade` is a copy of the Serrated mod (`00176DF9`): adds `MoM_Blade_KW` and our enchantment; `AttackDamage` +0.45 over the serrated base (to 1.2), AP cost -0.43, weight -0.33; the serrated naming keyword removed.
- **Look:** the plain model `Weapons\ChineseOfficerSword\Blade.nif` with a material swap to our gold material.
- **Numbers seen:** damage 70 at Strength 10, weight 2, VATS cost about 20, medium swing speed (the `Speed` property does nothing for melee).
- **Armor penetration:** 30% from our perk (a `PlayerPerk` melee entry, weapon tab `HasKeyword`, multiplier 0.70). With the Eye, 100% (a second entry, multiplier 0.0, attacker tab `WornHasKeyword`).
- Bleed comes from the serrated base (not separately confirmed).

### Garb of Mysteries

- Copy of the Sequin Dress (`0011A27B`, addon `0011A27A`). Value 50, weight 1.0, +1 Perception, +5 speed while sneaking, plus the sneak effects (our hidden perk delivered by the enchantment).
- Underarmor slots: `First Person Flags` = 1992 (33, 36 to 40), so armor goes over it. No upgrade levels. **No ballistic weave.**
- **Final values** (Garb2 as overridden by `BuildWorld.pas`): armor rating and energy resistance 30 (Garb2: 20); `MoM_ENCH_Garb` gains `AbFortifyResistDamage` (`0004A0AC`) and `AbFortifyResistEnergy` (`000559A4`) +40, each conditioned on `WornHasKeyword` Eye; the weave attach point (`APPR`) and keyword `ma_Railroad_ClothingArmor` removed; sneak attack perk entries 0.2 and 0.1, plus 0.4 and 0.2 with the Eye (they add); description rewritten (`GARB_DESC`).
- **Look:** charcoal body, emerald chevrons, cream-gold shoulder cowl, sequins kept.

### Veil of Secrets

- Copy of the Surgical Mask (`000787DA`, addon `000787D0`; slots 48 and 49, so hats work). Value 40, weight 0.2, no armor rating.
- Perk-delivered, persuade +5 (+10 more with the Eye) through `Mod Charisma Challenge Chance`; poison resistance 10 (+10 with the Eye). **Poison resistance stands in for disease** (the game has no disease resistance stat). No radiation, no intimidate (no vanilla anchor).
- **Poison gas immunity**, copied from the Hazmat Suit perk (`Set Value` 0.0 on spells with `DN102_PoisonGasEffectKeyword` `000449B9`). Built; **untested**.
- **Look:** black fabric with a cream-gold diamond net.

### Voice of Set

- A **.44** (lore), copy of `000CE97D`, name exactly "Voice of Set" (instance naming removed). Damage 48, the same as the .44; the Western Revolver is 60. Random receivers and barrels are **intended** (Chris: fine as a leveled spread).
- **Silenced:** Sound Level Silent, keyword `s_20_Silenced`, and our own sound keyword mapping (`KSSM`), a copy of the silenced Pipe Revolver mapping (`0002B941`) re-keyed to the .44 sound keyword. No visual suppressor.
- **Sonic burst at every impact:** our projectile is a copy of `MS09PushProjectile` (`00199046`, Missile type with the `Explosion` flag; speed 10000, no gravity, suppressed muzzle flash). Our explosion is a copy of `MS09PushExplosion` (`000E5786`): force 250, damage 0, radius 32/128, stagger Medium, Mirelurk King sonic sound.
- **Stagger:** `MoM_OMOD_Voice`, our copy of the legendary Staggering mod (`001E81AB`), included in every template combination. The "legendary item" pickup screen is kept.
- **Eye boost (`BuildWorld.pas`, overrides records of Voice12):** the sonic burst carries `MoM_ENCH_BurstStagger`, a copy of the legendary stagger enchantment (`0023AD16`) cut to one effect (`001E81A8`, magnitude 4) with three conditions: `GetIsID` Player (`00000007`) = 0, `WornHasKeyword` Eye = 1 run on PlayerRef (`00000014`), `GetRandomPercent` <= 50. The burst does 0 damage. Seen in game at an every-time chance (round 8): both bystanders staggered with the Eye, neither without. 50% (round 9) accepted by the owner as fair for a slow .44.
- **Replaced:** the earlier Eye boost (a hidden perk from that mod casting a second 30% stagger spell on a hit) is switched off by setting its `GetRandomPercent` to -1.
- At 0 damage with only its own stagger setting, the burst affected nobody who was not hit; at 1 damage it hurt bystanders and the player without staggering.
- **Look:** gold metal with black shadows, charcoal grips, gold medallions and diamond screw plates. Same gold tint and bronze reflection as the Blade, with darker mid-tones. Scopes, sights glass and rubber grips stay vanilla.

## 4. How to build

### Current layout: a chain of test plugins

There is no single plugin yet. **In dependency order:**

| Order | Script (`build/xedit/`) | Plugin | Contents | Needs ticked |
|---|---|---|---|---|
| 1 | `BuildBladeGold.pas` | `RegaliaGold1` | Blade, Eye, Cryptos book and perk, Broken Blade and Eye, their recipes | game + DLC |
| 2 | `BuildGarb.pas` | `RegaliaGarb2` | Garb | + Gold1 |
| 3 | `BuildVeil.pas` | `RegaliaVeil1` | Veil | + Gold1 |
| 4 | `BuildBroken2.pas` | `RegaliaBroken2` | Wearable broken dress and veil, two repair recipes | + Gold1, Garb2, Veil1 |
| 5 | `BuildVoice3.pas` | `RegaliaVoice12` | Voice, Broken Voice, its recipe | + Gold1 |
| 6 | `BuildWorld.pas` | `RegaliaWorld10` | Everything in 3.2 to 3.4, renames, plain dress and veil and recipe overrides, the Voice and Garb Eye changes | game + DLC + Gold1, Garb2, Veil1, Broken2, Voice12 |

Every other script in that folder is an earlier round or a diagnostic, kept for reference. The constant `PLUGIN_HINT` only changes the on-screen hint; the name typed in the box is what is created. Later scripts look up the earlier plugins by exactly these names. Tick only these six when playing.

### What a merged plugin must do (not started)

- Create each record once **with its final values**: no renames, no overrides of our own records, no override-only workarounds.
- Dress and veil: plain broken items from the start; drop the wearable broken records; keep one non-playable dress (and its addon and tattered material swap) for the Traveler.
- Voice: the burst carries the stagger enchantment; do not create the second-roll stagger spell and perk effect (check what else that perk and its enchantment do before removing them).
- Garb: final resistances and perk values, no weave.
- Overrides left should be only the map cells and worldspace.
- FormIDs will change, so saves made with the test chain will not carry over.

### Art (run before testing looks)

All need `baunpack` (Alexandria `memory/fo4-mod/fo4-archives.md`). Run with `python3 -B <script> OUTDIR`, then copy `Textures/` and `Materials/` into the MO2 mod folder.

| Command | MO2 mod |
|---|---|
| `make_gold.py OUT` | Blade of Bastet Art |
| `make_gold44.py OUT` | Blade of Bastet Art |
| `make_dress.py OUT` | Garb of Mysteries Art |
| `make_dress.py OUT --tattered --name TatteredDress` | Garb of Mysteries Art |
| `make_veil.py OUT --lace` | Veil of Secrets Art |
| `make_photo.py PICTURE OUT [--dim 0.86] [--fade 0.35]` (also needs `ffmpeg`) | Blade of Bastet Art |
| `make_containers.py OUT` | Blade of Bastet Art |

Loose files need `bInvalidateOlderFiles=1` and an empty `sResourceDataDirsFinal=` under `[Archive]` in the MO2 profile's `fallout4custom.ini`. Texture-only changes need a game restart, not a rebuild.

### Running a script

Environment: Steam Deck, a separate MO2 instance for Fallout 4, profile **Test**, FO4Edit 4.1.5f under Proton. Setup and the working loop are in Alexandria `memory/fo4-mod/` (`fo4-deck-mo2-setup`, `fo4-deck-workflow`).

1. To point the BUILD entry (`5\arguments=` in `ModOrganizer.ini`) at a different script, the person closes MO2 completely and says so; the assistant backs the file up and edits it. **If MO2 is open, it writes the old value back.** Rebuilding the same script file needs no edit and no restart; BUILD currently points at `BuildWorld.pas`.
2. The person runs BUILD, checks **Applying script "<name>"**, ticks the modules, types a **new** plugin name, **closes the xEdit window and accepts the save** (nothing is written until then).
3. Before any in-game test the assistant checks `~/Games/mo2-lint/tools/our-scripts/build.log` for `FAIL` or exceptions and reads the saved `.esp` back (record names, values, references).
4. When swapping plugin versions, test on a save made before the items were picked up.

### xEdit and engine facts

General ones live in Alexandria `memory/fo4-mod/` (context prep lists them). Learned while building the world and **not yet written there**: placing a dead actor and borrowing a pose (3.3), adding references to exterior and interior cells (3.2), container respawn flags, book reading pages (3.4), explosion enchantments with conditions (Voice), and crafting from a worn ingredient (3.1).

## 5. Console, for testing

`player.getav DamageResist` / `EnergyResist`; `help "<name>" 4` finds an ID; `player.additem <ID> 1`; `.44` ammo `0009221C`; `player.addperk` / `player.hasperk <ID>`; `amod <modID>` on a clicked dropped item. Targets: `player.placeatme 00106B07` (Protectron), `0005A9C1` (Mirelurk). The practice dummy cannot show a stagger.

## 6. Licence

Creation Kit EULA (<https://store.steampowered.com/eula/1946160_eula_1>), read by a helper agent, not legal advice: non-commercial, and the release must carry "THIS MATERIAL IS NOT MADE, GUARANTEED OR SUPPORTED BY ZENIMAX OR ITS AFFILIATES." (accepted). Our own licence is undecided.
