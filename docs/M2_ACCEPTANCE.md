# M2 implementation inspection

Milestone: Powder Captain keg-combo training arena. Implementation checkpoint ready for user inspection: 93 tests / 2,652 assertions passed, 136 scripts loaded, 8 asset scenes imported, and 600 runtime ticks completed. Strict editor import still reports the known sandbox socket error. This document does not grant milestone approval.

## Guide section 8 automated gates

| Requirement | Coverage |
| --- | --- |
| 3→2→1 pips at placement/+60/+120 | `test_keg_graph.test_decay_is_exact_and_stops_at_one`, Captain placement integration |
| Expiry +1500 without explosion | `test_keg_graph.test_lifetime_expiry_never_explodes` |
| Three-node line at t/t+20/t+40 | `test_keg_graph.test_three_keg_line_propagates_at_exact_twenty_tick_intervals` |
| Overlap damages each unit once | `test_keg_graph.test_overlapping_explosions_damage_each_unit_once_per_chain` |
| 6.9 m connects; 7.0 m does not | `test_keg_graph.test_graph_boundary_includes_six_point_nine_but_not_seven` |
| Scheduled node cannot explode twice | `test_keg_graph.test_destroying_scheduled_keg_does_not_double_explode` |
| Pending node waits for materialization | Graph pending test plus Captain one-part combo at exact ticks |
| Keg resets passive and grants speed | Captain `test_searing_edge_resets_once_per_chain_and_not_on_child` |
| Charges exhaust; return after 780 ticks | Graph serial recharge test plus Captain empty-charge cast failure |

Further integration checks cover melee/Q keg detonation, projectile arrival/fizzle, placement validation, chain extension/snapshots, cast interruption, reset cleanup, five true-damage burn pulses, Ration healing/cleanse, physical W/R input routing, all twelve Broadside wave ticks, area boundaries, and visual density/RNG isolation.

## Completed training controls

- Stationary/Strafe/slow Chase, count 1–5, armor 0/50/100, health 2000/10000/Infinite, Elite flag.
- Infinite-health defaults, selected-target damage and encounter-average DPS, reset readouts/restore living player health.
- Keg decay tiers 2/1/0.5 seconds, 3/4/5 charges, enemy keg-attacking toggle (default Off).
- Tick-owned settings/motion/status behavior, export/reset, pause/step, and F5 cleanup.
- Enemy training attacks remove one pip in melee range; destruction never triggers a Captain explosion or passive reset.

## Approved changes and deferred work

- Ration can cast through stun and cleanse it on completion: explicitly approved November 15 and recorded as a guide amendment. Other abilities retain normal stun restrictions.
- Animation fine-tuning and Q/E polish were explicitly deferred. Broadside visual density feedback was accepted.
- Final map dressing, full VFX/audio, and export polish remain M5. M4 enemy classes/challenge behavior are not implemented here.
- Strict editor import in this sandbox still reports the known debugger TCP-listener restriction. The remaining automated checks run independently and are reported honestly.

## User inspection gate

Follow [M2_PLAYTEST.md](M2_PLAYTEST.md), particularly the three-keg chain on three dummies five consecutive times, moving-target training, enemy keg toggle, Ration during stun, and reset during active effects. User approval is required before merging/tagging M2 or beginning M3. No automatic inspection or headless test proves desktop feel or manual combo reliability.
