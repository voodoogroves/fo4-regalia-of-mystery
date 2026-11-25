# Voice of Set

> **History file.** The current state is in [`build-spec.md`](build-spec.md), open work in [`next-steps.md`](next-steps.md). Where they differ, those win.

The set's pistol: a .44 (Chris: lore says it is a .44) that is silenced at the muzzle and bursts with sound where it hits.

## Verified in game (2026-11-25, `RegaliaVoice8`, `build/xedit/BuildVoice3.pas`, master Fallout4.esm only)

- Named exactly "Voice of Set"; damage 48, the same as the .44 (the Western Revolver is 60).
- Silenced gunshot: our own sound keyword mapping (copy of the silenced Pipe Revolver mapping) for the .44 sound keyword + Silenced; the weapon has `s_20_Silenced` and Sound Level Silent. NPCs stay unaware.
- Sonic burst at every impact: a copy of `MS09PushProjectile` (Missile type with the `Explosion` flag) and of its explosion, toned down (force 250, damage 0, radius 32/128, stagger Medium), with the Mirelurk King sonic sound. It does not affect the player.
- Stagger: the vanilla legendary Staggering mod (`001E81AB`) built into every template combination. The game shows the "legendary item" pickup screen.

## What did not work

- An explosion on a copy of the normal bullet (Beam type, no `Explosion` flag): never seen.
- An enchantment on the weapon record (`EITM`): never applied, even at 100% chance.

## Later rounds, verified 2026-11-25

- `RegaliaVoice11`: the Eye of Ra's second stagger roll (perk, `Apply Combat Hit Spell`) and the Broken Voice of Set with its recipe (Cryptos Notes + Gun Nut 3). Dead ends: a spell effect copied from an enchantment came out empty; xEdit's perk entry order differs from the file's; a spell effect would not take a new condition list.
- `RegaliaVoice12`: gold plating by material swap (`build/art/make_gold44.py`): black shadows, charcoal grips, gilded inlays.
- Decided: random receivers stay; no visual suppressor; no Creation Club master (the Captain Cosmos "Pulse" barrel turned out to use the vanilla push projectile).
