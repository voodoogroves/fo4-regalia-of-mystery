# Concept spec: Order of Mysteries Regalia & Arsenal

*Status: agreed (draft). Intent only. No FormIDs, condition numbers, record types or numbers; those belong in `spec-regalia.md` (set-wide) and `spec-blade-of-bastet.md` (per item).*

## What this is

A Fallout 4 mod that brings the Fallout 76 **Order of Mysteries** set into the Commonwealth as a small espionage/assassin loadout, tuned for Survival Mode.

## Intent

- **A coherent set, not a bag of items.** Each piece is decent on its own; Eye of Ra makes the others stronger when worn.
- **Theme over raw power.** A run dressed as the Mistress of Mysteries should be viable and fun, and the gear shouldn't feel like a mistake next to Throatslicer, The Deliverer, the Problem Solver, Splattercannon, Pickman's Blade, a wounding minigun or Spray and Pray. It doesn't need to match them; being thematically strong is the point.
- **A stealth-and-control fantasy.** Quiet approach, hazard and disease resilience, talking your way past trouble, disrupting a fight rather than winning it by damage.
- **Earned, not handed over.** The set is discovered through the Silver Shroud storyline and built by converting ordinary items the player already carries.
- **Fits the vanilla game.** It should feel like it was always in FO4: same workbenches, same upgrade habits, vanilla look.

## The set (what, not how)

| Piece | Role | Fantasy |
|---|---|---|
| Garb of Mysteries | Outfit | Armored, discreet; a sneaking outfit |
| Veil of Secrets | Face piece | Hazard and disease protection; social edge |
| Eye of Ra | Amulet / catalyst | The piece that makes the others stronger |
| Blade of Bastet | Melee | A ceremonial blade that ignores armor |
| Voice of Set | Sidearm | A revolver that disrupts groups instead of killing them |

## Staging

- **0.1:** one item, end to end, to prove the pipeline.
- **0.2:** the Veil plus one more item.
- Later 0.x versions add the rest.
- **1.0 is the release**, and the point where it may be shared (for example on Nexus Mods). Everything before 1.0 is for ourselves.

Each stage must be useful and installable on its own.

## Constraints (these are intent, not detail)

1. **Vanilla assets only.** No new meshes, textures or materials.
2. **Light and simple to install.** A single light plugin, no scripts, no archives.
3. **Doesn't touch vanilla.** No changes to existing records; coexists with major gameplay overhauls.
4. **Works on Steam Deck** through Mod Organizer 2 and xEdit.
5. **Baseline is Anniversary Edition plus all DLC.** Using DLC or Creation Club assets is fine, but each use is called out in `spec-regalia.md` (it makes that DLC a hard requirement).

## Decided

- Each piece is decent standalone; Eye of Ra amplifies the others (replaces former Q1).
- Power level: viable, not competitive with top legendaries; theme is the priority (replaces former Q4).
- **0.1 is the Blade of Bastet**, made by converting a Chinese Officer Sword the player already has, with vanilla stats inherited.
- Male characters can wear the dress (the Fallout wiki shows men in the vanilla dresses on the same rig), so no separate male outfit is planned; confirm in-game.
- The look is the **Mistress** of Mysteries (there is no male counterpart in the lore). The green accent was for a visible Eye of Ra; it returns only if visible jewelry is added after 1.0.
- **Discovery gate: the Silver Shroud quest, once the player has answered Kent either way** (refuse, "I am the Mistress", or accept and wear the mask). It needs no vanilla edits. Players who have not reached that point in the quest won't see the recipes; accepted.
- **Eye of Ra before 1.0 is non-visible**: a worn item on the neck slot that only carries the catalyst effect, shown as the Silver Locket in the inventory (like a ring, but on the neck). Visible jewelry (cape or other) is considered after that, not before.
- Phantom Device is cut. Staging: 0.1 = one item, 0.2 = Veil plus one more, 1.0 = release.

## 0.1: Blade of Bastet

- **Base:** the player converts a Chinese Officer Sword they already have (plus materials). It inherits the sword's vanilla stats: damage, speed and mods.
- **The one change:** built-in armor penetration of **30%** (the vanilla legendary "Penetrating" level; target's armor ignored). Decided.
- Keeps the sword's workbench mods and the open legendary slot.
- **Instructions:** a short in-game explanation of how the conversion works (a holotape or similar), available once the recipes are discovered. How it reaches the player without editing vanilla records is settled in `spec-regalia.md`.
- The converted weapon is renamed Blade of Bastet.
- **With Eye of Ra worn (0.2 or later): ignores ALL armor (100%).** This matches the Fallout 76 original, which also goes to full armor-ignore. Accepted as fine because the base weapon is a low-tier melee sword. The Blade is not meant to outclass guaranteed legendaries such as Throatslicer, a Furious power fist or a Staggering Ripper; theme comes first (see Intent).

## References (not decisions)

- **Cape body colour:** the Institute division-head uniform green (`Materials\Clothes\InstituteUniform\InstUniformMDH_green.BGSM` / `FDH`), a medium leaf green (about rgb 83,132,88 where green). Reference only. A material swap replaces the whole texture, and the cape's texture layout (UVs) differs from the uniform's, so the real result must be checked in-game before we commit to it.
- **Cape and brooch:** the Maxson cape (`FCapeMaxon.nif` / `MCapeMaxon.nif`) uses one material and one texture holding the red cloth and the dark metal clasp plates together. A swap cannot change the clasp or symbol on its own.

- **UCO (Unified Clothing Overhaul), checked against its plugin:** `ClothesUCOCape` makes the vanilla Maxson cape a standalone wearable on slot 54, using the same vanilla meshes (`FCapeMaxon` / `MCapeMaxon`) and the same single texture; it adds no cape art. `ClothesUCOScarf` sits on the neck slot (50) and uses the vanilla `Armor\Metal\MScarf.nif`; UCO ships no scarf or cape textures. So a standalone cape is proven workable, and slot choice for Eye of Ra matters for UCO users (50 and 54 are both taken by UCO items).
- **Round symbol:** the round disc on the cape's texture, lower right, in the same image as the cloth. Cannot be replaced on its own by a swap.

## Open questions

None for now. To verify in the specs: that a worn item with no mesh behaves well on the neck slot.

## Out of scope (for now)

Phantom Device (cut), visible Eye of Ra jewelry (after 1.0 planning), custom art, new quests or voice, FO76 upgrade tiers, scripted effects, compatibility patches for specific overhauls.

## Next

This file is agreed. Mechanics live in `spec-regalia.md` and one `spec-<item>.md` per item (`spec-blade-of-bastet.md` first), verified against the xEdit definitions in Alexandria.
