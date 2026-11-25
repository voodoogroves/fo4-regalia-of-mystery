# Spec: Veil of Secrets (the face piece)

Status: DESIGN and art tooling (2026-11-24); nothing built in the plugin yet. Part of the Regalia of Mystery set; see `spec-regalia.md` (release checklist), `spec-eye-of-ra.md` (broken items, gate rule), `spec-garb-of-mysteries.md` (the pattern: perk chain, conditions, recolour). Art outputs are derived from Bethesda's texture and are NOT committed (public repo).

## Intent (`concept-spec.md`)

A face piece with **hazard and disease protection and a social edge**. Found broken and repaired like the others (the Cryptos book plus one skill perk). In Fallout 76 the Veil looks **"sort of lacey"** (Chris); the Fallout 76 Eye table does not list the Veil, so whether the Eye amplifies it is open (Chris to say).

## Base: the Surgical Mask (verified records)

`Clothes_Raider_SurgicalMask` `ARMO 000787DA` (base game): slots **48 (Beard) and 49 (Mouth)** only, so it never clashes with hats or helmets; keywords `ArmorBodyPartHead` and `AnimHelmetCoversMouth`, no `ma_` keyword (so no mod slots: nothing to lock or inherit); armor rating 0, value 5, weight 0.2; addon `AA_Raider_02_Helmet_Mask` (`ARMA 000787D0`: slots 48/49, male mesh `Armor\\Raider02\\Raider02MaskM.nif`, female `...F.nif`). One material, `Armor\\Raider02\\Raider02Mask.bgsm`, and one texture set `RaiderMask_d/n/s.dds`. The diffuse is **BC3 (DXGI 77), 1024 x 1024, 11 mips**: the mask cloth (a dirty-beige patch at the bottom), the ear straps (beige strips at the top), and other Raider parts (dark) the mask does not use; the alpha is solid except for cut-outs on the strap edges and loops. Other face candidates read and set aside: helmets, hoods and full masks (the neck and mouth slot searches), the Pack and Disciples masks (ornate, Nuka-World).

## The look (first pass; Chris: black fabric, possibly with the cream-gold of the Garb's cowl)

`build/art/make_veil.py OUTDIR [--lace]` (needs `baunpack`; BC3 handling: the colour half of each block is recoloured and re-encoded, the alpha half is kept as is):
- **Plain black fabric:** every pixel goes through a darkening ramp (a very slightly cool black); the folds and stains stay as faint shading.
- **Black with a cream-gold net:** a fine diamond lattice with a bead at every crossing (cream-gold 198, 181, 150, as the cowl), painted anti-aliased on the cloth at every mip level; the cloth is found by geometry (u below 0.82, v above 0.53) plus anything beige, because a colour test alone broke on the stained patch. The first try (period 0.045) looked like chain-link; the second (period 0.052, line 0.0022, no centre dots) reads as a delicate net. It is a net, not flowing lace: a real lace motif (scallops, florals) needs a reference picture.
- Outputs: `Textures\\Armor\\VeilOfSecrets\\VeilOfSecrets_d.dds`, `Materials\\Armor\\VeilOfSecrets\\VeilOfSecrets.BGSM` (the mask material with the diffuse path changed), delivered like the Garb's art (an MO2 mod, a material swap on a copy of the addon).

## Decisions (Chris, 2026-11-24)

1. **Look: the black fabric with the cream-gold diamond net** (the second preview: a fine lattice with a bead at each crossing).
2. **The Eye amplifies the Veil.**
3. **Effects: small radiation and disease resistance, and a persuade and intimidate chance bonus instead of Charisma. The Eye increases the disease resistance and the persuade and intimidate bonus** (not the radiation resistance).
- **Mechanisms found in the game's definitions (names only so far, values not yet read):** actor value `Resist Disease` (disease); perk entry points `Mod Charisma Challenge Chance` (persuade) and `Mod Player Intimidation` (intimidate), also `Mod Bribe Amount`; damage types for armor resistances `dtRadiationExposure` (`DMGT 00060A85`), `dtPoison` (`00060A84`), `dtRadiationIngestion` (`00060A86`). The vanilla "disease" effects in the data are Survival-mode sickness effects (insomnia, fatigue, infection), not resistances.
- **Lookup queued:** the vanilla perks that use the two speech entry points, the `Resist` actor values, and effects that fortify them, to copy structure and calibrate numbers.

## Mechanics (earlier note, superseded by the decisions above)

Hazard and disease protection: candidates are the enchantment effects and armor resistances for disease, radiation exposure and poison (a lookup is queued: the disease resist effects and the damage types). Social edge: a Charisma bonus (the vanilla `Fortify Charisma` effect, as the dresses carry) and perhaps speech. Small numbers: it is a cloth veil. The Eye: open.

## To do

1. Look: choose black, or black with the net; maybe a reference picture for a lace motif.
2. Mechanics: read the resist effects; decide numbers and whether the Eye amplifies the Veil.
3. The build: a plugin step like `BuildGarb.pas` (copy of the Surgical Mask with our addon swap and enchantment).
4. The broken form (a plain Misc item), the repair recipe (Cryptos plus one skill perk), the placement.
