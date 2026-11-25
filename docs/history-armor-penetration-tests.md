# History: first armor-penetration tests (2026-11-23)

Moved from Alexandria. Superseded by the in-game findings in `spec-blade-of-bastet.md`; where this disagrees with `build-spec.md`, the build spec wins.

## Blade of Bastet armor-penetration test results (Chris, Test profile, 2026-11-23)

Spawned `player.placeatme 00106B07` (a Protectron), Strength 10 so both swords show 32 damage, hits to kill, plain swings, single runs:

| Weapon | `ArmorPenetration` stat | Hits to kill |
|---|---|---|
| Plain Chinese Officer Sword | 0 | 22 to 23 |
| Blade of Bastet (spec build) | 30 | 22 |
| Blade of Bastet TEST100 | 100 | 18 |

- Expected ratios if the chain applied fully: about 1.14 (stat 30) and about 2.15 (stat 100). Observed about 1.0 and 1.2: **an effect smaller than predicted, or noise.** Early impression was a faster-draining health bar. Single runs and random criticals (which ignore armor) make this inconclusive; repeated counts (3 each) and a more heavily armored target are the next steps.
- Chris's check: 18 swings x 32 damage is about 570, far more than a 100-health target. **Alternative reading (2026-11-23):** if the stat-100 build sits at the 0.99 cap and the target has about 570 HP, the plain sword's coefficient was about 0.79 (effective DR about 9, not 40), so full penetration could gain at most 0.99/0.79 = 1.25x, and 22.5/1.25 = 18, matching the result. The penetration may already be working on a soft target. HP is inferred, not measured, so this is not proof. **Those runs were on Very Hard** (difficulty scales player damage), so the 570 HP and effective-DR-of-9 figures are unreliable; only the ratios between weapons hold. Decisive test: a heavily armored target (Mirelurk Hunter `00064C5E`, DR 85, about 2.8x at the cap).
- **Record stats did not predict the spawned actor.** The three Protectron records (`00106B07` LvlProtectron, `00106B09` EncProtectron01Template, `00186E01` LvlProtectron_Hostile) all read health 100, DR 40, level 5, yet the spawned one took about 22 swings (about 7 expected). Templates and level scaling are involved. `00106B09` was suggested as a fixed-stat spawn; not yet tried.
- Reading `getav health` in the console was unreliable on the Deck; screenshots attached to chat are readable. Counting hits to kill is the practical measure.
