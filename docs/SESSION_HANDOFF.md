# Session handoff — 15 November 2026

Read AGENTS.md, PROGRESS.md, ARCHITECTURE.md, and the relevant guide sections before gameplay changes. PROGRESS.md preserves the dated history.

## Current milestone

- Workspace: `/home/aurelius/Projects/blood-powder`.
- Branch: `feature/m2-captain-kegs`, based on `m1-approved`.
- M0/M1 accepted. M2 implementation is at final inspection; no full M2 approval, merge, or tag has been recorded. M3 must wait for explicit approval.
- User wants autonomous milestone work and milestone inspection handoffs, not per-feature progress reports. Ask only for actual blockers/design decisions.
- Q/E functional playtest passed; polish deferred. W activation and Searing Edge were confirmed. Denser Broadside visuals received “Much better.” Final manual combo acceptance remains unreported.
- Final inspection guide: `docs/M2_PLAYTEST.md`. Implementation/automated gate mapping: `docs/M2_ACCEPTANCE.md`.

## Implemented Captain

- Q Flintlock: targeted 15-tick cast, 270-tick cooldown, 26 m/s homing shot; physical crit-capable damage; owned keg hit removes one pip. Removed targets fizzle.
- E: 15-tick pending placement, 30-tick recast lock, 3/4/5 charges, serial 780-tick recharge. Placement wall/spacing/range checks and approach-to-cast. Tier locks on materialization; default 60-tick decay to one pip; lifetime 1500 ticks. Graph distance 6.9 m, 20-tick propagation, pending-node combos, snapshot payload and hit-once set. Scheduled-node safety and reset cleanup tested.
- Passive Searing Edge: melee enemy hit burns 5 × 24 true damage at 30-tick intervals; 25% speed for 120 ticks; 900-tick cooldown. First explosion of a chain resets readiness/grants speed once. Q/keg damage does not apply burn. P cooldown and ready blade glow included.
- W Ration: 15-tick cast, 1080-tick cooldown, 100 + 13% missing HP healing, capped; cleanse slow/root/stun, preserve burn. **User approved the Ration-only stun exception:** W starts/completes through stun, then cleanses it. New stun does not interrupt W; death does. Other casts remain blocked/interrupted. The guide amendment was written before implementation. Physical W, buffered order, and exact timing have coverage.
- R Broadside: 15-tick cast/1800-tick cooldown, ground target anywhere inside arena. A fixed 5.8 m area lasts 480 ticks after completion. Twelve 40-magic waves with 30% slow for 30 ticks, completion offsets 30/45/60, 150/165/180, 270/285/300, 390/405/420. Area damage snapshots; no keg/ally damage or passive burn. Ring lasts full duration. Default 16 cosmetic balls per wave (192 per cast), F1 density 1–32, seeded staggered impacts. Cosmetic density does not change simulation RNG consumption.

## Training and debug

- F1 resource-backed settings: count 1–5, armor 0/50/100, HP 2000/10000, Infinite HP default On, Counts as Elite.
- Behavior: stationary, three-meter strafe at 3.45 m/s, or slow chase at 1.5 m/s with 2 m stopping distance. Numeric parameters tunable. Driver uses normal tick orders/navigation/statuses and waits for pending commands; F5/settings changes reset patrol direction.
- Enemy keg-attacking default Off; On makes dummies attack only live in-range kegs using normal melee timing. One pip per hit; enemy destruction removes without explosion/passive reset. No player attacks or keg chase; no M4 challenge AI.
- LMB dummy: total resolved damage and encounter-average DPS since first hit, including idle time. Finite totals follow combat-log overkill semantics. Reset damage / DPS and Restore player health are queued for next tick.
- Settings export through DebugConfig, apply next tick, reset/recenter targets when changed, persist through F5, restore with Reset tuning to file. Source resources remain unchanged. Arrays mutate in place for active kegs/Broadside. Removed targets are invalidated and selection cleared safely.
- F2 radii, F3 state, F4 events; F7/F8 pacing, F9 pause/F10 tick step. F5 clears casts, statuses, kegs, shots, zones, charges, and damage counters. Explicit combat CSV/tuning exports remain available.
- Actual main scene enables training. Legacy M1/Captain finite-health regression fixtures explicitly opt out; dedicated training tests use actual defaults.

## Verification and limitations

Final run details are appended to PROGRESS.md and below. `python tools/verify.py` runs import, all-script parsing, stock imports, full GUT, and 600-tick smoke. The known restricted-session editor debugger socket error must remain reported; never claim strict overall success here. No extra rerun is needed after documentation-only changes.

- Accepted movement, attack defaults, red stock character appearance, and deferred provisional animation markers are preserved.
- Full art/VFX/audio/props remain M5/deferred polish. Raw packs stay outside repo; verify licenses and record used assets in CREDITS.md.
- Keep work local. Prior GitHub pushes failed on DNS; user requested no repeated attempts. Do not add AI authorship/coauthor trailers.
- Pre-existing `project.godot` editor serialization is uncommitted and must be preserved/excluded from the implementation commit.
- No system/shell/desktop/other-app configuration changes without explicit approval.

## Next gate

User inspection of final M2 build, including five consecutive three-keg chains on three dummies and Ration during stun. Address reported defects. Only after explicit M2 approval may M2 merge/tag or M3 Hunter work begin.

Final verification: 93/93 tests passed (2,652 assertions), all 136 scripts loaded, 8 stock scenes imported, and main scene ran 600 ticks. `python tools/verify.py` fails only the known restricted-session editor debugger TCP-socket errors. `git diff --check` is clean.

M2 inspection feedback: barrel links were too faint. Now amber ground ribbons with dark borders (link_width=0.16 m, link_border=0.06 m per side, F1 tunable), bright pale gold while scheduled. Visual-only change; graph/combat behavior unchanged. Restart for desktop inspection; M2 still awaiting approval.

Link-visibility verification: 93 tests / 2,652 assertions passed, 136 scripts loaded, 8 asset scenes imported, and 600 runtime ticks passed. Strict verification retains only the known sandbox editor-import socket error. `git diff --check` passed; desktop visibility awaits inspection.
