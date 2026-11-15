# M3 — Apex Hunter inspection

Restart the game. Open F1 and select **Apex Hunter** at the top, then close F1. Switching class resets the player and clears old class effects; Captain remains available in the same selector. F5 resets the current class. The Hunter uses a provisional green hooded human outfit from the existing stock assets; Captain retains the accepted red appearance.

## Main milestone combo

1. Move into either green brush patch near the north dummy line. P's claw indicator and the Leap READY text show eligibility. F2 displays the leap range and Bola aim line.
2. RMB a dummy beyond normal melee range but within leap range. The Hunter leaps toward the target's sampled position and attacks on landing.
3. Press E at the enemy during the leap. Bola should launch immediately without the grounded cast delay.
4. Press Q while airborne or immediately after landing to empower/reset attacks. W hits nearby targets and builds Ferocity.
5. At four pips, Q/W/E glow and the next available basic ability is empowered. Check the stronger damage, E root, or W cleanse/heal; pips should return to zero and speed should increase briefly.
6. Repeat until brush leap → midair Bola → Rend reset → empowered ability is reliable. Report the exact input/phase if something feels wrong.

## Abilities and resource

- Q Rend: resets readiness, buffs two attacks, first-hit bonus and uncancellable first windup. Try a move order during its first windup; it should execute after the hit. Empowered Q's five-second attack-speed buff survives a follow-up normal Q.
- W Howl: magic damage in 4.5 m and healing for 50% of post-mitigation damage from the prior 90 ticks. Use F1 Burn or damage/status buttons to inspect grey HP. Damage older than 1.5 seconds leaves the grey bar. Empowered W can be used while stunned and cleanses slow/root/stun; normal W cannot.
- E Bola: ground cast takes 15 ticks, direction is fixed by the original aim point, and the shot launches from the cast-completion position. It hits the first enemy, slows, and is stopped by walls. Empowered E roots. Try Q/W during the ground cast to check buffering.
- R Stalk: immediate speed, camouflage/leap eligibility after two seconds, nearest-enemy marker within 16 m. Model fades to 30% opacity. Attacking or casting W/E ends it; Q preserves it. A marked attack adds AD damage and reduces armor by 20 for four seconds.
- Ferocity: one leap-derived stack until stacks are consumed/decayed, W/E cast gains, first normal Rend hit gain, cap four. Empowered abilities ignore base cooldowns. Observe the brief same-ability lockouts. After ten seconds without non-burn combat damage, pips clear.

## Interruptions, geometry, and cleanup

- Leaving brush gives a 21-tick eligibility linger. Root prevents starting a leap; stun interrupts an airborne leap with no landing hit. Root applied midair does not cancel an existing leap.
- The landing destination is fixed when the leap starts. A moving target is still hit on landing. A dead target takes no damage but consumes Rend's first-hit opportunity. Walls stop displacement; landing attack still occurs at the original impact deadline.
- A move command during flight executes after landing. All four abilities can be used midair.
- F5 during leap/Bola/Stalk clears motion, projectiles, Ferocity, buffs, markers, and cooldowns. Switch Hunter↔Captain during active effects and ensure no prior class effects remain.
- Captain regression: Q/E chains, passive reset, W during stun, dense R, amber keg links, and training controls should retain the accepted behavior.
- Training chase uses brush/camouflage visibility. Full enemy classes and challenge AI remain M4; final environment/audio/VFX remain M5.

Approve M3 only after inspecting its feel. M4 does not begin until explicit approval. Animation/contact fine-tuning remains deferred unless a new defect warrants it.
