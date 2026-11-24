# Spec: Garb of Mysteries (the dress)

Status: LOOK TEST in progress (2026-11-24). Part of the Regalia of Mystery set; set-wide rules are in `spec-regalia.md`, the broken-item pattern and gate rule in `spec-eye-of-ra.md`. Art outputs are derived from Bethesda's texture and are NOT committed (public repo; see Rhodes `decisions.md`, 2026-11-24).

## Intent (from `concept-spec.md`)

An armored, discreet sneaking outfit; the Eye of Ra amplifies it. Found as a **Tattered Dress** (the broken form; Fallout 76 lists a separate Tattered Dress among the Regalia pieces) and repaired at the Chemistry Station, gated by the Cryptos book plus **one** skill perk, **Armorer 3** (Chris; the craft screen shows only two perk prerequisites).

## Base: the Sequin Dress (Chris, 2026-11-24)

`ClothesSequinDress` `0011A27B` (Agatha's Dress `000F15CF` shares its addon). Chosen because it is **body hugging** (the Mistress art is) and its texture is already a dark sequin dress. Other candidates read and set aside: the pre-war dress family (Laundered Rose, Denim and Green share one mesh, `Clothes\PrewarDress\DressGO.nif`, with three small materials; the green is very light), the Red (slinky) Dress, Ratty Skirt, Feathered Dress. The vanilla dresses carry the enchantment `EnchClothingCharisma2` ("Fortify Charisma"), armor rating 0. The worn meshes are `Clothes\SlinkyDress\DressFSequin.nif` and `DressMSequin.nif`; the armor addon `AAClothesSequinDress` (`ARMA 0011A27A`) has Male Biped Model, Female Biped Model, and no material swaps; the mesh has two materials, the dress (`Clothes\SlinkyDress\SequinDress.BGSM`) and the body skin. The dress is one **2048 x 2048 BC1 texture** (`SlinkySequinDress_d.dds`, 12 mips).

## The look (colours measured from an in-game picture of the Fallout 76 outfit, median RGB)

- **Chevrons:** three nested V bands on the upper torso, chest to waist, points down at the front centre: green **(65, 137, 80)**, a mid emerald with a cool cast. (The concept art Chris first saved has darker greens, median 36, 68, 38; it is a painting.)
- **Body:** neutral **charcoal (53, 56, 57)** (gloves and leggings 39, 41, 41): not pure black, and not the sequin dress's navy.
- **Top band (the shoulder cowl):** pale **cream-gold (198, 181, 150)**, like the reference's ruffled collar. Our dress has no ruffle mesh; the band is the drape across the shoulders and chest.
- The sequin sparkle is kept under every recolour (the stripes glitter green).

## How the texture wraps (Verified in game 2026-11-24 with the UV test texture on mannequins)

`make_dress.py --debug-uv` paints each tenth of the texture's width a distinct hue (red, orange, yellow, lime, green, cyan, blue, violet, magenta, white) and fades each tenth of the height from light to dark.
- **Front centre is at u about 0.45** (the green/cyan boundary); yellow (u 0.2) is the wearer's **right** side and blue (0.65) the **left**. The **back centre is the texture's seam** (magenta u 0.83 meets red u 0.0); u runs 0 to 0.83 around the whole body.
- **v runs down the body:** the neckline at the top (about 0.23), the hem at the bottom (1.0). The vertical shading darkens toward the hem.
- **The top band (v below 0.225) is the shoulder cowl,** with its own seam at the **front** of the chest (a white and red spot).
- **The shoes reuse the right-hand part of the top band (u above about 0.8)**: they showed white and magenta. So that part must not be tinted cream (it is left alone).
- The strip on the right of the texture (u above 0.83, below the band) holds small parts (a zip, shoe shapes) and is untouched.

## Pipeline (all verified except the last step)

`build/art/make_dress.py OUTDIR` (needs `baunpack`): extracts the sequin texture, recolours it zone by zone by block (BC1 blocks are 4 x 4 pixels with two RGB565 endpoints; recolouring the endpoints, at every mip level, keeps the sparkle), writes **our own** files `Textures\Clothes\GarbOfMysteries\GarbOfMysteries_d.dds` and `Materials\Clothes\GarbOfMysteries\GarbOfMysteries.BGSM` (a copy of `SequinDress.BGSM` with the diffuse path changed), and previews. Parameters: `--uc --uspan --y0 --pitch --bands --thick --slope --tint --gain --cap --debug-uv`. The plugin side is `build/xedit/BuildGarbTest.pas` (plugin `RegaliaGarb1`, **Fallout4.esm only**): a material swap `SequinDress.BGSM` -> ours, a copy of the addon with `MO2S` (male) and `MO3S` (female) set, and a copy of the dress pointing at our addon. Loose files live in the MO2 mod `Garb of Mysteries Art`; replacing the texture needs only a relaunch, not a rebuild. **Verified:** the UV test texture showed on the dress (swap, loose files and addon all work). **Not yet seen:** the recoloured texture in game.

## Fallout 76 stats (from wiki screenshots Chris supplied, 2026-11-24; fan-wiki level, not checked in game)

**Garb of Mysteries (item card):** levels 25 / 30 / 35 / 40 / 45 / 50 (an upgrade ladder); **40 damage resistance, 40 energy resistance** (the card shows one pair; read as the top level); **value 50, weight 1.0**; effects: **+1 Perception** and **5% harder to detect while sneaking**. The render: a short pointed tunic with a cream-gold ruffled collar, a charcoal body with **thin, dark green chevrons**, black leggings, long gloves and boots.

**The Eye of Ra's bonus table ("while wearing the Eye"):**

| Item | Bonus while wearing the Eye |
|---|---|
| Garb of Mysteries | +20 DR, ER and Sneak |
| Voice of Set | against robots, deal +70 energy damage and a 25% chance to stun for 1 second |
| Blade of Bastet | 100% armor penetration (built) |
| Phantom Device | invisibility lasts 60 seconds, frenzy lasts 30 seconds (the cut item) |

**What Chris said:** "we don't need to be exact"; not too heavy on DR and ER, mostly sneak and utility.

**Proposed Fallout 4 translation (to confirm):** about **half the 76 protection**: **20 DR and 20 ER**, rising to **30 and 30 with the Eye** (the Eye's +20 halved to +10, applied through a worn-keyword condition); **+1 Perception** (the vanilla `Fortify Perception` effect, as on the Eyeglasses); keep the dress's vanilla Charisma bonus if wanted; **harder to detect while sneaking**, small at base and clearly stronger with the Eye (our own perk using the detection entry points, to be tuned once the vanilla Sneak perks are read). Value 50, weight 1.0 as in 76. The Voice of Set's 76 role is a **robot-hunting, stunning sidearm** (energy damage and a short stun against robots), close to the concept's "disrupts instead of kills"; keep that in mind when we reach it.

## Fallout 76 stats: earlier check (superseded by the above)

- The Fextralife stubs showed no stats. We had **no verified Fallout 76 stats** for the Garb. The Fextralife wiki pages for the [Garb of Mysteries](https://fallout76.wiki.fextralife.com/Garb+of+Mysteries) and the [Tattered Dress](https://fallout76.wiki.fextralife.com/Tattered+Dress) (last edited 9 April 2026) are thin stubs, read by a helper agent: weight and value are unfilled template placeholders, there are no resistances, no perks, no sneak effect; the Garb's source reads "??"; both are classed as **Outfits, which are cosmetic and worn "on top" of armor** in Fallout 76. (Chris's screenshots, above, show the real 76 numbers.) The Fandom page (the one with more detail) is blocked to our fetches (HTTP 402). If Chris has the in-game numbers, add them here.
- **The Tattered Dress is a corpse-loot item in Fallout 76** ("found on various corpses throughout Appalachia", one in Camden Park, one on a corpse named Natasha Hunt at Lewisburg; fan-wiki level). The wiki does not say whether it feeds the Garb. This fits Chris's body idea.
- The archived Gemini brainstorm (`Alexandria/historical/regalia/gemini-brainstorming.md`, marked historical and unverified) proposes `30 DR / 30 ER`, `+15% Sneak` rising to `+30%` with the Eye, a charcoal Tuxedo material, and an Armorer rank 1 recipe. These are its own design numbers, not Fallout 76 facts, and its mechanics (`FortifySneak`) are not checked against Fallout 4 (the game's definitions have an actor value `Sneak` and the entry points below).

## Design direction (Chris, 2026-11-24)

- **Light armor, weighted to sneak and utility.** The dress can take ballistic weave, so modest DR and ER only; the Garb's value is in sneaking and utility.
- **Candidate mechanics (names read from the game's definitions; the values and effects are not yet seen):** actor values `Movement Noise Mult` (quiet steps), `Sneak`, `Sneaking Modifier`, `Detect Life Range`; perk entry points `Mod Detection Light`, `Mod Detection Movement`, `Mod Detection Sneak Skill`, `Mod Sneak Attack Mult`, `Ignore Running During Detection`; condition `IsSneaking`. Too strong, leave alone: `Invisibility`, `Set Undetectable`. Proposal: quiet steps, harder to spot while sneaking (our own perk, conditioned on sneaking), and a sneak attack bonus (pairs with the Blade); the Eye of Ra amplifies them through a worn-keyword condition. The dress already carries the vanilla `Fortify Charisma`.
- Lookup queued to read the vanilla stealth enchantments, the Sneak perks, the clothed skeleton and the movement-noise effects.

## Decisions and calibration (Chris, 2026-11-24)

- **No leveling upgrades** (a Fallout 76 thing): the Garb is one item. **The Voice of Set will be a general sonic weapon**, not robot-specific (the lore is not specific about robots; checked in earlier sessions).
- **Vanilla anchors (read from the records, 2026-11-24):** the Sneak perk rank 1 uses `Mod Detection Sneak Skill` Add **+20** and `Mod Detection Movement` Multiply **0.9** ("20% harder to detect while sneaking": the Sneak Skill value is the percentage); Stealth Boy +50 and x0.5; the Sneak bobblehead `Mod Detection Light` x0.9 and `Mod Detection Movement` x0.9; the Creation Club X-02 camo perk matches Sneak rank 1; Ninja uses `Mod Sneak Attack Mult` Add (rank 1: +1 ranged, +0.5 melee). The armor mod "Stealth Move" (`enchArmorStealthMoveMod` `00245BDE`) is a constant-effect enchantment, `Fortify Actor Speed Mult` 5, **with per-effect conditions** (`IsSneaking`); the Shadowed lining (`enchArmorShadowMod` `00183313`) uses `ArmorShadowEffect` (`MGEF 00183311`) magnitude 15; the legendary Chameleon (`ench_mod_LegendaryArmor_Chameleon` `001F4D16`) uses `Stealth Field` (`MGEF 000976E0`) magnitude 20 with `IsMoving` and `IsSneaking` conditions. Useful: an enchantment's effects can carry conditions, so the Eye can amplify through a `WornHasKeyword` condition on an effect.
- **Numbers (Chris, 2026-11-24: include the sneak attack and the sneak speed; the Eye gives NO DR/ER boost at all):** harder to detect while sneaking **+5** base (as in 76), **+25** with the Eye; DR and ER **20**, fixed (the Eye does not touch them; this drops the Eye-conditioned resist effects entirely); **+1 Perception**; **sneaking speed +5** (the vanilla Stealth Move effect); a **sneak attack bonus**, small at base (about a quarter of Ninja rank 1) and larger with the Eye (up to about Ninja rank 1), exact figures to tune in game.
- **Still to read:** the effects behind these enchantments and the vanilla damage and energy resist effects (lookup queued). The clothed-skeleton search by the name `SkeletonClothed` found nothing; searching `Skeleton` next.

## Dependency: ballistic weave (Chris, 2026-11-24)

The light DR and ER (20 and 20, no Eye boost) are **predicated on being able to add ballistic weave** to the Garb at the armor workbench. In vanilla it is an armor mod for clothing, offered by keywords and attach points on the item (as the sword mods were on the Blade, until its `ma_` keyword was swapped); our dress is a copy of the Sequin Dress and should inherit those, **but this is not verified**.
- **First in-game check for the Garb build:** at an armor workbench, is ballistic weave offered on the Garb?
- **If it is not:** put DR and ER back and raise them (a starting point of about 35 and 35; the Eye still does not touch them), and tune in play.
- **To read (lookup after the current one):** the vanilla ballistic weave mods, for what each tier adds, so the two cases can be compared with real numbers.

## Placement ideas (parked; Chris, 2026-11-24)

- **The Tattered Dress on a body:** a body wearing the Tattered Dress, with the broken items in its inventory and a note (the Cryptos book is already that note; the text is for later).
  - **Option A (low risk): a vanilla clothed skeleton plus our own container beside it.** The game has clothed-skeleton set-dressing models (a material swap `SkeletonClothedFGreen` points at `SetDressing\Skeletons\SkeletonDress04.BGSM`). They are static, not lootable, so the loot sits in a container next to it. No new actor records.
  - **Option B (richer, riskier): a lootable corpse:** a new NPC wearing the Tattered Dress, placed dead. A new actor with no face data can show a broken head, so the way is to copy a known-good vanilla corpse; read a vanilla example first.
  - Chris wants the skeleton option kept in view. Start with A; B later if wanted.
- **Scattered broken pieces:** other broken items could be placed elsewhere in the world, with a story: someone trying to get somewhere, found dead, who lost their broken pieces along the way and never arrived. Not worked out; the supply of each piece is the world's supply (see the broken-items rule).

## To do

1. See the recoloured dress in game (centre, size and height of the chevrons; the cowl; the shoes staying dark); adjust the script parameters.
2. The real Garb: armor ratings and resistances (clothing is armor 0), a sneak bonus, how the Eye amplifies it (a worn-keyword perk entry, as for the Blade), the name and description.
3. The **Tattered Dress** (broken form: a plain Misc item or a wearable, to decide; not scrappable), the repair recipe (Chemistry Station, Cryptos + Armorer 3), the placement.
4. Ship the art in a `.ba2` named after the plugin (see the release checklist in `spec-regalia.md`).
5. Optional: a gold-tinted version of the look, a skin tone match, a longer tunic-and-leggings silhouette (the Fallout 76 outfit is a short pointed tunic over leggings; ours is a long hugging dress).
