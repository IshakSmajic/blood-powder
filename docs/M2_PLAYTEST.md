# M2 final playtest

Restart the running game after updating. F1 contains dummy settings, keg tuning, and player status controls. Dummy defaults are three stationary targets with infinite HP and 50 armor. LMB a dummy for damage/DPS; F1 → Reset damage / DPS clears those measurements. Settings persist through F5 for this session; Reset tuning to file restores defaults. Changing dummy settings resets/repositions all dummies on the next simulation tick. Paused settings wait for F10/resume.

## Captain regression

1. RMB movement/chase/basic attacks, A+click, S/H, camera and pause/step should retain the accepted feel.
2. E: three pips, then two and one. Try each F1 decay tier (2/1/0.5 seconds); existing kegs retain their placement tier. Charges cap at 3/4/5 as tuned and recharge serially. Invalid/wall/too-close placement should not consume a charge.
3. Q: dummy damage and homing; one pip removed on a keg. Removing the target before projectile arrival should fizzle safely.
4. Passive: melee once then S. Five burn pulses, speed buff and P cooldown. Keg explosion resets P once per chain; Q/keg damage does not apply passive burn.
5. W: use F1 Burn to lose HP, then W to heal. Root/slow are cleansed, burn remains. Current shared stun rule blocks/interrupts W; the guide conflict is recorded in PROGRESS.md.
6. R: fixed area for eight seconds; four clusters of three waves, dense cannonball visuals, magic damage/slow and cooldown. Walk away, pause/step, and F5 during the barrage.

## Keg combos

Use F2 for links/radii and F4 for tick events. F5 gives a fresh attempt with full charges. Wait for the first keg to reach one pip before triggering it with Q or RMB.

- Single: detonate one keg next to a dummy.
- Two-part: place a second linked keg, then trigger the first.
- Three-keg: place a linked line; the events should be 20 ticks apart.
- Overlap: multiple blasts from one chain around the same dummy apply damage once; Reset damage / DPS helps compare.
- Extension: trigger A linked to B, then place C near B before B explodes.
- One-part: Q a one-pip keg from range, immediately E a linked keg while Q travels. The pending placement should join the chain.
- Final manual gate: perform a three-keg chain on three dummies five times in a row. Report success or the combo/input that failed.

## Training controls

- Count 1–5: targets stay in a centered line, three meters apart; selection is safe when removing a selected dummy.
- Armor 0/50/100 and finite health 2000/10000; infinite HP allows lethal-sized hits without death.
- Counts as Elite: compare keg damage with Off/On; only the Elite bonus should change.
- LMB a dummy: total resolved damage and average DPS since the first hit, measured in simulation ticks. The average includes idle time until reset; finite-target totals follow combat-log damage (including overkill).
- F1 → Restore player health heals a living player on the next tick.

Stationary dummies are implemented; strafe/chase behavior and enemy keg-attacking toggle remain later training/PvE work. Final map assets, audio, and full VFX remain M5/deferred polish. M3 must wait for explicit M2 approval; this checklist does not record approval automatically.
