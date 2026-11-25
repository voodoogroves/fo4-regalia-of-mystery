# Voice of Set

The set's pistol: a .44 (Chris: lore says it is a .44) that is silenced at the muzzle and bursts with sound where it hits.

## Verified in game (2026-11-25, `RegaliaVoice8`, `build/xedit/BuildVoice3.pas`, master Fallout4.esm only)

- Named exactly "Voice of Set"; damage 48, the same as the .44 (the Western Revolver is 60).
- Silenced gunshot: our own sound keyword mapping (copy of the silenced Pipe Revolver mapping) for the .44 sound keyword + Silenced; the weapon has `s_20_Silenced` and Sound Level Silent. NPCs stay unaware.
- Sonic burst at every impact: a copy of `MS09PushProjectile` (Missile type with the `Explosion` flag) and of its explosion, toned down (force 250, damage 0, radius 32/128, stagger Medium), with the Mirelurk King sonic sound. It does not affect the player.
- Stagger: the vanilla legendary Staggering mod (`001E81AB`) built into every template combination. The game shows the "legendary item" pickup screen.

## What did not work

- An explosion on a copy of the normal bullet (Beam type, no `Explosion` flag): never seen.
- An enchantment on the weapon record (`EITM`): never applied, even at 100% chance.

## Open

- Fixed configuration (it still spawns with random receivers and the vanilla .44 mods apply).
- The Eye of Ra boost.
- The broken form and its repair recipe.
- Range: the dummy registers the burst (zero damage) out to about 300, which may feel large.
- Whether the explosion alone staggers anything (not separated from the legendary effect).
