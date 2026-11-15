# M3 implementation inspection

All Hunter implementation gates are covered: 113 tests passed in the full suite, plus an 18-test Hunter follow-up; 143 scripts, 8 stock scenes, and both 600-tick smoke runs passed. User feel/appearance approval remains pending. See M3_PLAYTEST.md for the inspection sequence. No M4 work is authorized before approval.

| Guide section 9 gate | Coverage |
| --- | --- |
| 7.4 m edge range leaps; 7.6 m does not | `test_hunter.test_brush_range_edge_boundary_and_exact_landing_ticks` |
| Brush linger at +20, expired at +22 | `test_hunter.test_linger_twenty_ticks_then_expires_at_twenty_two` |
| Landing at round(actual travel / 14.5 × 60) | Exact landing test, with pre-impact no-damage assertion |
| Midair Bola fires that tick without cast delay | `test_hunter.test_midair_bola_immediate_and_move_buffered_until_landing` |
| Rend resets readiness and starts next attack | Rend reset/protected windup integration test |
| Howl/Bola/Rend/leap → 4; empowered consumes to zero | Full leap combo plus empowered Bola cooldown-bypass/root test |
| Ferocity decay at 600 ticks | `test_ferocity.test_decay_exact_600_ticks_and_howl_lockout` |
| Howl heals exactly half of last 90-tick damage | Grey-health window plus empowered cleanse integration test |

Additional tests exercise leap interruption/root/cooldown/walls/dead or moving targets, Bola first-hit/width/walls/aim-origin rules, brush/camouflage vision, Stalk mark/bonus/armor-shred deadline, rolling grey health/burn exclusion, empowered-AS persistence, class switching, resets, visual RNG isolation, and prior Captain regressions.

Both classes receive 600-tick smoke checks. Strict editor import in the restricted session still reports the previously documented debugger-socket restriction; test/parse/asset/runtime results are reported separately in PROGRESS.md.

Known presentation limits: stock human Hunter outfit with green cloth is provisional, Howl uses a stock cast-pose substitute, and final audio/VFX/environment dressing remain M5. Accepted animation fine-tuning remains deferred. Headless verification does not prove desktop feel or manual combo reliability.
