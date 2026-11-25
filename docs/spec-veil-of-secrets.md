# Spec: Veil of Secrets (the face piece)

> **History file.** The current state is in [`build-spec.md`](build-spec.md), open work in [`next-steps.md`](next-steps.md). Where they differ, those win.

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

## Calibration and updated decisions (Chris, 2026-11-24, after the second lookup)

- **Radiation resistance is dropped** (Chris: disease alone is more fitting). The Veil is now **persuade plus disease**, with no armor rating.
- **Persuade (proven):** vanilla `Mod Charisma Challenge Chance`, `Add Value`: Black Widow and Lady Killer **+10, +20, +30** over their three ranks ("easier to persuade"; they also condition on the target's sex), and a plain unconditioned magazine perk (`DLC04_PerkMagPerkScav01`) uses the same entry. Proposed: **+5 base, +10 more with the Eye (15 total)**.
- **Intimidate: no vanilla anchor.** The entry point `Mod Player Intimidation` exists in the definitions but **no vanilla perk uses it** (zero found), so it cannot be calibrated or checked: left out of the first build unless Chris wants to experiment.
- **Disease: there is no vanilla resistance stat.** The actor-value records are damage, energy, electricity, fire, cold, poison, magic, and radiation exposure and ingestion; `Resist Disease` appears in the engine's definitions but has no record. The vanilla disease effects are Survival-mode sickness effects (insomnia, fatigue, infection, `HC_` effects) triggered by risk events. Options: **(A) poison resistance** (`AbFortifyResistPoison`, `MGEF 0004D86B`, simple and exact), or **(B) the real disease-risk reduction** copied from the Lead Belly perk (lookup queued: that perk and the `HC_Disease` spells). Plan: try B, fall back to A.
- Useful resist effects found (for any resistance bonus): `AbFortifyResistPoison` `0004D86B`, `AbFortifyResistEnergy` `000559A4`, `AbFortifyResistRadiationExpose` `0004C47D`, `AbFortifyResistRadiationIngest` `0004A0C2`, `AbFortifyResistDamage` `0004A0AC`, `AbFortifyResistFire` `0004D86E`, `AbFortifyResistCryo` `0004D86D`, `AbFortifyResistElectricity` `0004D86F`; damage types `dtRadiationExposure` `00060A85`, `dtPoison` `00060A84`, `dtEnergy` `00060A81`.

## Gas immunity (added 2026-11-24; research hand-off from a read-only session, then verified in xEdit)

Chris likes it ("fitting, given the HalluciGen gas interaction with the Stealth Boy and Phantom Device") and wants it if it can be done. The Hazmat Suit blocks the two vanilla poison gases through a perk, not through poison resistance:
- `ARMO Armor_HazmatSuit` `000CEAC4` has `EITM` `ENCH EnchPA_HazmatRadReduction` `0014EF47` (constant effect) -> `MGEF HazmatSuitPerkEffect` `0014EF48` (archetype Value Modifier on `RadResistExposure`, magnitude 0, with a **Perk to Apply**) -> `PERK HazmatSuitRadResistancePerk` `0014EF46` (hidden, one rank).
- The perk has three entries: (1) **`Mod Incoming Spell Magnitude`, `Set Value` 0.0, with the perk condition `EPMagic_SpellHasKeyword DN102_PoisonGasEffectKeyword` (`KYWD 000449B9`) == 1** (tab 1): this blocks the gas; (2) `Mod Incoming Spell Magnitude`, `Multiply Value` 0.02 on spells with `DamageTypeRadiation` (`0004B25C`); (3) `Mod Typed Incoming Spell Magnitude`, `Multiply Value` 0.02 for `dtRadiationExposure`. Entries 2 and 3 are the radiation reduction.
- **Exactly three effects carry the gas keyword** in the whole game (all DLC included, no Creation Club): `DN102_GasHazardEffect` "HalluciGen Gas" `000E6203`, and the Nuka-World `DLC04Gauntlet_GasHazardInitialEffect` `0602D828` and `DLC04Gauntlet_GasHazardSubsequentEffect` `0603DB50` (they use `PoisonResist` and hit `Health`). So the perk blocks those and nothing else.
- Poison resistance only softens the gas; it does not zero it. Power armor and gas masks lack this perk (matching reports that they do not block it).
- **For the Veil:** the Veil's perk gets a copy of entry (1) only (no radiation entries: Chris dropped radiation). Always on while the Veil is worn (the Veil's identity); a constant (`GAS_NEEDS_EYE`) is False in `BuildVeil.pas` (gating it behind the Eye is not implemented). **To test in game:** the HalluciGen, Inc. basement (quest Hazardous Material) and the Nuka-World Gauntlet gas room (quest Taken for a Ride), with the Veil, without it, and with the Hazmat Suit as a control. Untested by the research and by us.

## Verified in game (Chris, 2026-11-24, `RegaliaVeil1`, `build/xedit/BuildVeil.pas`; needs `RegaliaGold1.esp` for the Eye keyword)

- **The look is good** (black fabric with the cream-gold diamond net; at face scale it reads as a fine black-and-cream lattice, a little like gingham). Locked.
- **The perk is delivered:** `hasperk` is 1 while the Veil is worn and 0 when it is off.
- **Poison resistance rises to 20 with the Eye** (10 base).
- **A hat works with it** (slots 48 and 49 only).
- **Not yet tested (later list):** the gas immunity. The gas rooms are far from the player's current save (Sanctuary): the HalluciGen, Inc. basement (quest Hazardous Material) and the Nuka-World Gauntlet gas room (quest Taken for a Ride); compare with the Veil off and with the vanilla Hazmat Suit as a control. Persuade cannot be measured directly (the `hasperk` check is the proof it is delivered).

## Mechanics (earlier note, superseded by the decisions above)

Hazard and disease protection: candidates are the enchantment effects and armor resistances for disease, radiation exposure and poison (a lookup is queued: the disease resist effects and the damage types). Social edge: a Charisma bonus (the vanilla `Fortify Charisma` effect, as the dresses carry) and perhaps speech. Small numbers: it is a cloth veil. The Eye: open.

## To do

1. Look: choose black, or black with the net; maybe a reference picture for a lace motif.
2. Mechanics: read the resist effects; decide numbers and whether the Eye amplifies the Veil.
3. The build: a plugin step like `BuildGarb.pas` (copy of the Surgical Mask with our addon swap and enchantment).
4. The broken form (a plain Misc item), the repair recipe (Cryptos plus one skill perk), the placement.
