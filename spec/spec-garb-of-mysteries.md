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

## To do

1. See the recoloured dress in game (centre, size and height of the chevrons; the cowl; the shoes staying dark); adjust the script parameters.
2. The real Garb: armor ratings and resistances (clothing is armor 0), a sneak bonus, how the Eye amplifies it (a worn-keyword perk entry, as for the Blade), the name and description.
3. The **Tattered Dress** (broken form: a plain Misc item or a wearable, to decide; not scrappable), the repair recipe (Chemistry Station, Cryptos + Armorer 3), the placement.
4. Ship the art in a `.ba2` named after the plugin (see the release checklist in `spec-regalia.md`).
5. Optional: a gold-tinted version of the look, a skin tone match, a longer tunic-and-leggings silhouette (the Fallout 76 outfit is a short pointed tunic over leggings; ours is a long hugging dress).
