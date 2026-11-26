# Build spec: Regalia of Mystery

**Read this first.** It is the current state of the mod and every decision behind it, written so that someone new can build it. State as of **2026-11-26** (release plugin `RegaliaOfMystery.esp`, version 0.9.0). Open work is in [`next-steps.md`](next-steps.md). The other files in this folder are the history (how each answer was found, including dead ends); where they disagree with this file, this file wins.

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
| Scripts | No Papyrus. Everything is records plus art, packed into two `.ba2` archives for release. |
| Vanilla records | No vanilla item, perk or effect is changed. Placement **does** override map cells (and the Commonwealth worldspace record) to add our references; see 3.2. |
| Editor ID prefix | `MoM_` |
| Masters | `Fallout4.esm` and `DLCNukaWorld.esm` (the Eye is a Shock Collar copy). No Creation Club master. |
| Names | Found items: "Mystery: ..."; repaired pieces: their own names, no prefix. |
| Assets | Never committed. Commit the script that makes an asset. |
| Balance | Pieces stay in line with vanilla gear; the Eye is where the extra power is. |

## 3. The mod as built

### 3.1 Recipes (greyed before reading the Cryptos and all five crafted, seen in game 2026-11-26)

| Result | Found item (editor ID) | Other ingredients | Skill perk |
|---|---|---|---|
| Blade of Bastet | Mystery: Broken Sword (`MoM_MISC_BrokenBladeOfBastet`) | Steel 4, Silver 3, Gold 2, Crystal 2, Adhesive 3 | Blacksmith 3 (`000264D8`) |
| Eye of Ra | Mystery: Broken Necklace (`MoM_MISC_BrokenEyeOfRa`) | Crystal 2, Silver 2, Adhesive 2 | Science 3 (`000264DB`) |
| Garb of Mysteries | Mystery: Tattered Dress (`MoM_MISC_TatteredDress`) | Cloth 6, Adhesive 2, Silver 1 | Armorer 3 (`0004B256`) |
| Veil of Secrets | Mystery: Worn Veil (`MoM_MISC_TatteredVeil`) | Cloth 3, Adhesive 2, Silver 2 | Chemist 3 (`000E3701`) |
| Voice of Set | Mystery: Broken Revolver (`MoM_MISC_BrokenVoice`) | Steel 4, Screws 2, Silver 2, Adhesive 3 | Gun Nut 3 (`0004A0DC`) |

Component IDs: Steel `0001FABD`, Silver `0001FABB`, Gold `0001FAA6`, Crystal `0001FA9F`, Adhesive `0001FAA5`, Cloth `001223C7`, Screws `0003D294`. Amounts for the last three recipes were chosen by the assistant and accepted without tuning. Where this file or the scripts say Broken Blade, Eye or Voice, they mean these records.

- The Sword, Necklace and Revolver are `MISC` copies of the Silver Locket (`00059B34`), scrap components removed, `UnscrappableObject` (`001CC46A`). Models: the sword mesh, the locket, `Weapons\44\44.nif`.
- The Dress and Veil are made the same way, with world models `Clothes\SlinkyDress\GO_SequinDress.nif` and `Armor\Raider02\Mask_GO.nif`. The only wearable tattered dress left is the Traveler's (`MoM_ARMO_SeekerDress`).
- Why plain items: crafting the Veil from a wearable broken Veil crashed the game in a test round (**cause not proven**), and crafting the Garb while wearing the Tattered Dress left its look stuck on the player.

### 3.2 The world (placements seen and accepted, also in the release plugin)

| What | Cell | Position x, y, z, heading | Our record (vanilla base) |
|---|---|---|---|
| The Mysterious Traveler | `0000E0BA` | 5514.07, -18598.39, 1820 | see 3.3 |
| Diary, loose beside her, No Respawn | `0000E0BA` | 5556, -18622, 1806, 80 | `MoM_BOOK_Diary` (note `001D5CDC`) |
| Cryptos, loose beside her, No Respawn | `0000E0BA` | 5560, -18578, 1806, 110 | `MoM_BOOK_Cryptos` |
| Suitcase: Broken Sword | `0000E0BA` (rooftops by Hubris) | 7408.37, -18588.25, 1856.75, 68 | `MoM_CONT_Blade` (`001002A4`) |
| Duffle bag: Broken Revolver | `0000E0B9` (Swan's pond) | 11993.90, -20086.55, 596.4, 35 | `MoM_CONT_Voice` (`0008E59E`) |
| First aid kit: Worn Veil | `0000E0D9` (near the cafe) | 7267.84, -20585.32, 1117.2, 180 | `MoM_CONT_Veil` (`0020A6FD`) |
| Tool case: Broken Necklace | `0004542D` (Hubris interior), on file cabinet `00066AC5` | 2818.3, -245.5, 839.5, 135 | `MoM_CONT_Eye` (`001103E3`) |

- Containers: our copies with the Respawns flag (`DATA` bit `0x02`) cleared, scripts and vanilla contents removed, one item each.
- Skins (`make_containers.py`): charcoal with emerald chevrons or stripes, one material swap each. The suitcase uses `SetDressing\Suitcase\Suitcase_prewar.nif`, because `Suitcase01.nif` names no material to swap.
- The books lie loose because taking an item from a container or body does not open it for reading.
- After passing time (`set gamedayspassed to 200`) taken items and books stayed gone and what was left stayed (seen 2026-11-26). The Voice's burst moves the loose diary only very little.
- The only overrides in the plugin are the four cells and the worldspace record. The worldspace override is the `Fallout4.esm` version; the DLC and Creation Club versions differ from it only in the dropped blocks and an icon path, and none of them overrides our cells.
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
- The world card shows our pencil sketch (material swap on the photo model): the owner's own Fallout 4 screenshot (vanilla assets and our gear) run through ordinary ffmpeg filters by `make_sketch.py`, no generative AI. It replaced an earlier AI-generated sketch on 2026-11-26; card and reading page seen in game. Source images are outside the repos in `~/Games/mo2-lint/tools/our-assets/photo-candidates/`: screenshot `candidate-04`, sketch `candidate-06`.
- The script reads both text files at build time and fails unless the diary contains "Someone should." and the Cryptos text "THE VOICE OF SET". Plain text with straight quotes.

### 3.5 The Eye of Ra

- Copy of the Nuka-World Shock Collar (`DLC04_ShockCollar` `06029AFA`), neck slot, keyword `MoM_EyeOfRa_KW`. No enchantment: each other piece checks for the keyword. Named "Eye of Ra".

| Piece | Without the Eye | With the Eye |
|---|---|---|
| Blade | 30% armor penetration | 100% |
| Garb | resistance 30 damage / 30 energy; harder to detect +5; sneak attack +0.2 (one-hand melee) / +0.1 (not melee) | resistance 70 / 70; harder to detect +25; sneak attack +0.6 / +0.3 |
| Veil | persuade +5, poison resistance 10 | persuade +15, poison resistance 20 |
| Voice | 30% stagger on a direct hit; the burst affects nobody | the burst also staggers those it catches, 50% (never the player) |

The only damage or energy resistance the Eye adds is on the Garb.

### 3.6 What has and has not been seen in game (release plugin, 2026-11-26)

Seen and reported good: the Traveler, both books and their pages, all containers and their skins, locked then crafted recipes, resistances 30 / 30 / 10 and 70 / 70 / 20 with the Eye, sneak attack steps, Blade bleed, the Voice's burst stagger with and without the Eye (never the player), the blast beside the diary, the area reset, the new Cryptos picture, no ballistic weave on the Garb, the Voice's own stagger on a direct hit without the Eye. **The packed release** (the 0.9.0 zip installed as one MO2 mod, loose art mods off): everything in its places, all five crafted, colors good.

The silenced Voice is tested (owner, 2026-11-26). So is play on mid-game saves, including a character fresh out of the vault (owner, 2026-11-26). Adding the mod to a save made after visiting the four cells still spawned the traveler, both books, the items and the containers, and the scenery looked normal (owner, 2026-11-26). Crafting without cheats and the Voice grips are checked (owner, 2026-11-26).

Not yet seen or not specifically reported:

- **Veil persuade bonus: untested** (persuade cannot be measured directly; the release page says it is unconfirmed).
- **Veil poison gas immunity: untested** (spawned gas, a console cast and the HalluciGen placements did no damage even without the Veil). Neither the Cryptos nor the Veil's descriptions mention gas.

## The pieces in detail

### Blade of Bastet

- Own weapon record, a copy of the Chinese Officer Sword (`00147BE4`), name exactly "Blade of Bastet". Own `MoM_ma_Blade` keyword, so the workbench offers no vanilla mods.
- Its default mod `MoM_OMOD_Blade` is a copy of the Serrated mod (`00176DF9`): adds `MoM_Blade_KW` and our enchantment; `AttackDamage` +0.45 over the serrated base (to 1.2), AP cost -0.43, weight -0.33; the serrated naming keyword removed.
- **Look:** the plain model `Weapons\ChineseOfficerSword\Blade.nif` with a material swap to our gold material.
- **Numbers seen:** damage 70 at Strength 10, weight 2, VATS cost about 20, medium swing speed (the `Speed` property does nothing for melee).
- **Armor penetration:** 30% from our perk (a `PlayerPerk` melee entry, weapon tab `HasKeyword`, multiplier 0.70). With the Eye, 100% (a second entry, multiplier 0.0, attacker tab `WornHasKeyword`).
- Bleed comes from the serrated base (seen in game).

### Garb of Mysteries

- Copy of the Sequin Dress (`0011A27B`, addon `0011A27A`). Value 50, weight 1.0, +1 Perception, +5 speed while sneaking, plus the sneak effects (our hidden perk delivered by the enchantment).
- Underarmor slots: `First Person Flags` = 1992 (33, 36 to 40), so armor goes over it. No upgrade levels. **No ballistic weave.**
- **Values:** armor rating and energy resistance 30; `MoM_ENCH_Garb` gains `AbFortifyResistDamage` (`0004A0AC`) and `AbFortifyResistEnergy` (`000559A4`) +40, each conditioned on `WornHasKeyword` Eye; the weave attach point (`APPR`) and keyword `ma_Railroad_ClothingArmor` removed; sneak attack perk entries 0.2 and 0.1, plus 0.4 and 0.2 with the Eye (they add).
- **Look:** charcoal body, emerald chevrons, cream-gold shoulder cowl, sequins kept.

### Veil of Secrets

- Copy of the Surgical Mask (`000787DA`, addon `000787D0`; slots 48 and 49, so hats work). Value 40, weight 0.2, no armor rating.
- Perk-delivered, persuade +5 (+10 more with the Eye) through `Mod Charisma Challenge Chance`; poison resistance 10 (+10 with the Eye). **Poison resistance stands in for disease** (the game has no disease resistance stat). No radiation, no intimidate (no vanilla anchor).
- **Poison gas immunity**, copied from the Hazmat Suit perk (`Set Value` 0.0 on spells with `DN102_PoisonGasEffectKeyword` `000449B9`). Built; **untested** and not advertised (see 3.6).
- **Look:** black fabric with a cream-gold diamond net.

### Voice of Set

- A **.44** (lore), copy of `000CE97D`, name exactly "Voice of Set" (instance naming removed). Damage 48, the same as the .44; the Western Revolver is 60. Random receivers and barrels are **intended** (Chris: fine as a leveled spread).
- **Silenced:** Sound Level Silent, keyword `s_20_Silenced`, and our own sound keyword mapping (`KSSM`), a copy of the silenced Pipe Revolver mapping (`0002B941`) re-keyed to the .44 sound keyword. No visual suppressor.
- **Sonic burst at every impact:** our projectile is a copy of `MS09PushProjectile` (`00199046`, Missile type with the `Explosion` flag; speed 10000, no gravity, suppressed muzzle flash). Our explosion is a copy of `MS09PushExplosion` (`000E5786`): force 250, damage 0, radius 32/128, stagger Medium, Mirelurk King sonic sound.
- **Stagger:** `MoM_OMOD_Voice`, our copy of the legendary Staggering mod (`001E81AB`), included in every template combination. Our copy has the `FeaturedItem` keyword (`001B3FAC`, which every legendary weapon mod adds) **removed**: its pop-up opened over the craft menu and the game crashed on Take (three crashes, one slow success; fixed and seen twice). So there is no "legendary item" screen.
- **Eye boost:** the sonic burst carries `MoM_ENCH_BurstStagger`, a copy of the legendary stagger enchantment (`0023AD16`) cut to one effect (`001E81A8`, magnitude 4) with three conditions: `GetIsID` Player (`00000007`) = 0, `WornHasKeyword` Eye = 1 run on PlayerRef (`00000014`), `GetRandomPercent` <= 50. The burst does 0 damage. Seen in game at an every-time chance (round 8): both bystanders staggered with the Eye, neither without. 50% (round 9) accepted by the owner as fair for a slow .44.
- At 0 damage with only its own stagger setting, the burst affected nobody who was not hit; at 1 damage it hurt bystanders and the player without staggering.
- **Look:** gold metal with black shadows, charcoal grips, gold medallions and diamond screw plates. Same gold tint and bronze reflection as the Blade, with darker mid-tones. Scopes, sights glass and rubber grips stay vanilla.

## 4. How to build

### The plugin

One script, `build/xedit/BuildRegalia.pas`, makes `RegaliaOfMystery.esp`: 64 records of our own with final values, masters `Fallout4.esm` and `DLCNukaWorld.esm`, object IDs from `000800`, the light (ESL) flag set by the script, and the disclaimer as the description. In xEdit tick the game and the six DLC only. The name typed in the box must be exactly `RegaliaOfMystery`, so an older file of that name is first moved out of the game's `Data` folder. The filename must not change once saves exist. Do not reorder the record creation without reason: FormIDs follow it.

Check the saved file with `python3 -B build/check/compare_chain.py`. It compares it record by record with the six old test plugins (which must stay in `Data` for this). Expected differences: seven dropped records (the wearable broken dress and veil, and the Voice's old second-roll spell, perk, effect, enchantment and keyword), the Voice's weapon and mod without them and without `FeaturedItem`, and the rewritten text (Blade, Eye, Veil, Cryptos, perk and effect names).

The older `.pas` scripts, including the six that built the test chain, are history.

### The release package

`python3 -B build/package.py VERSION [--plugin PATH]` takes the built plugin (the game's `Data` folder unless `--plugin` names a kept copy, such as `release/0.9.0/package/`) and the three MO2 art mods, packs `RegaliaOfMystery - Main.ba2` (materials) and `- Textures.ba2` with xEdit's `BSArch` through Proton's Wine (no MO2 needed), verifies both by unpacking, and writes `RegaliaOfMystery-VERSION.zip` with the readme from [`release-readme.txt`](release-readme.txt) under `~/Games/mo2-lint/tools/our-assets/release/` (outside the repo).

### Art (run before testing looks or packaging)

All need `baunpack` (Alexandria `memory/fo4-mod/fo4-archives.md`). Run with `python3 -B <script> OUTDIR`, then copy `Textures/` and `Materials/` into the MO2 mod folder.

| Command | MO2 mod |
|---|---|
| `make_gold.py OUT` | Blade of Bastet Art |
| `make_gold44.py OUT` | Blade of Bastet Art |
| `make_dress.py OUT` | Garb of Mysteries Art |
| `make_dress.py OUT --tattered --name TatteredDress` | Garb of Mysteries Art |
| `make_veil.py OUT --lace` | Veil of Secrets Art |
| `make_sketch.py candidate-04-source-screenshot.png candidate-06-screenshot-pencil-clean.png` (needs `ffmpeg` only; reproduces the picture exactly) | none (input for the next row) |
| `make_photo.py candidate-06-screenshot-pencil-clean.png OUT [--dim 0.86] [--fade 0.35]` (also needs `ffmpeg`) | Blade of Bastet Art |
| `make_containers.py OUT` | Blade of Bastet Art |

Loose files need `bInvalidateOlderFiles=1` and an empty `sResourceDataDirsFinal=` under `[Archive]` in the MO2 profile's `fallout4custom.ini`. Texture-only changes need a game restart, not a rebuild.

### Running a script

Environment: Steam Deck, a separate MO2 instance for Fallout 4, profile **Test**, FO4Edit 4.1.5f under Proton. Setup and the working loop are in Alexandria `memory/fo4-mod/` (`fo4-deck-mo2-setup`, `fo4-deck-workflow`).

1. To point the BUILD entry (`5\arguments=` in `ModOrganizer.ini`) at a different script, the person closes MO2 completely and says so; the assistant backs the file up and edits it. **If MO2 is open, it writes the old value back.** Rebuilding the same script file needs no edit and no restart; BUILD currently points at `BuildRegalia.pas`.
2. The person runs BUILD, checks **Applying script "<name>"**, ticks the modules, types the plugin name, **closes the xEdit window and accepts the save** (nothing is written until then).
3. Before any in-game test the assistant checks `~/Games/mo2-lint/tools/our-scripts/build.log` for `FAIL` or exceptions and reads the saved `.esp` back (record names, values, references).
4. Test from a fresh character (`coc HubrisComicsExt` at the main menu).

### xEdit and engine facts

They live in Alexandria `memory/fo4-mod/` (context prep lists them).

## 5. Console, for testing

Batch files in the game folder (`bat <name>`) save typing: `rom1` (god mode, skill perks, components, ammo), `romchem` and `romarmor` (spawn a station), `romroof`, `romsuit`, `romduffle`, `romcafe`, `romhal` (move there), `romres` (print resistances). `coc HubrisComics01` then `player.moveto 00066AC5` reaches the tool case. `tdetect` stops enemies noticing you.

`player.getav DamageResist` / `EnergyResist`; `help "<name>" 4` finds an ID; `player.additem <ID> 1`; `.44` ammo `0009221C`; `player.addperk` / `player.hasperk <ID>`; `amod <modID>` on a clicked dropped item. Targets: `player.placeatme 00106B07` (Protectron), `0005A9C1` (Mirelurk). The practice dummy cannot show a stagger.

## 6. Licence

Creation Kit EULA (<https://store.steampowered.com/eula/1946160_eula_1>), read whole as raw text on 2026-11-26, not legal advice: non-commercial, and the release must carry "THIS MATERIAL IS NOT MADE, GUARANTEED OR SUPPORTED BY ZENIMAX OR ITS AFFILIATES." (accepted).

Decided 2026-11-26: scripts in `build/` are MIT; the mod, its text and art have plain permissions (free to use, patches welcome, ask before re-uploading or reusing, never sold). Recolored Fallout 4 textures and the screenshot sketch ship as an **accepted risk**: the Nexus rules prohibit copyrighted game files without the owner's permission, and no explicit grant was found in the Creation Kit EULA text. Nexus tags: AI-Generated Content and AI Media; no Donation Points. Public version 0.9.1; 1.0 waits for the invisible locket and the lore check. Details: [`release-page.md`](release-page.md).
