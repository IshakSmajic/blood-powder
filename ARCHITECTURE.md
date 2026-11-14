# Architecture

Read this file and `PROGRESS.md` at the beginning of a working session. The development guide defines the eventual MVP; this document describes what actually exists.

## Implemented in M0

- `world/setup_room.tscn` preserves the accepted M0 reference scene; M1 uses `world/arena.tscn` as the main scene. Its script builds a 36×28 m grey floor, four outer walls, light, perspective camera, and static 1.8 m capsule marker. It has no player controller, navigation, combat, brush, pillars, or enemy AI.
- The renderer is Forward+, physics is Jolt at 60 Hz, maximum physics steps per frame is 8, and physics interpolation is enabled. Default viewport is 1920×1080, resizable, V-Sync on.
- `SimClock` advances `TickState` from `_physics_process` and synchronously emits `tick_advanced(tick)`. Future gameplay updates must subscribe to this signal so pause and slowed pacing affect every gameplay timer uniformly. Each admitted tick is always 1/60 simulated second. `_process` is presentation only.
- `TickState` stores integer tick count, integer speed in tenths, pause/single-step flags, and the sole seeded gameplay RNG. Integer accumulation admits fewer ticks at lower speed; `Engine.time_scale` is not modified. Pacing is for command-driven simulation. Future CharacterBody movement must use a fixed 1/60 step on each admitted tick; dynamic rigid-body gameplay would need an explicit pacing design before use.
- `EventBus.publish` emits a tick-stamped notification and a deep-copied payload. Presentation and logs may listen; gameplay must never require those listeners.
- `DebugConfig` provides in-memory per-resource overrides with fallback and reset. It has no disk persistence or tuning UI yet.
- `InputRouter` handles setup reset, pause, single-step, speed, and menu signals. It ignores keyboard auto-repeat. Input map includes all later gameplay bindings, but Commands and world picking are M1 work.
- `tools/verify.py` imports the project, loads every script, runs GUT, and runs the main scene for 600 consecutive simulation ticks. It pins the official engine version and redirects XDG paths inside ignored `.local/` for verification only.

## Dependencies and assets

GUT 9.7.1 is vendored under `addons/gut/` and enabled in project-local settings. One local patch in `gut_plugin.gd` replaces its automatic startup network update check with the bundled/cached version check, avoiding offline startup errors. Explicit manual update checks remain available. GUT itself includes font and GUI assets with upstream licenses. Only the addon subtree was extracted; its original license is retained.

The original guide and approved concept sheet live under `docs/`. Raw external character packs stay outside the repo. Empty asset/system directories reserve the guide's structure; `.gitkeep` files are placeholders, not implementations.

Eight stock character/animation candidates are prepared under `assets/`; the setup scene does not instantiate them. See `docs/asset_audit.md` and the manifest for compatibility limits. Rigs share a 65-bone hierarchy but not all bind poses. `tools/prepare_assets.py` packages glTF dependencies; `tools/check_assets.gd` checks imported scenes, bone counts, and animation names during verification.

## M1 implementation — first foundation slice

M0 was explicitly approved by Ishak; local tag `m0-approved` records its accepted code. M1 is active on `feature/m1-foundation`.

- `world/arena.gd` builds the separate sandbox and runs units in stable array order on `SimClock.tick_advanced`. It owns cursor-to-ground projection, selection, held movement, attack-move arming, debug toggles, and reset/menu handling. No runtime network is used.
- `world/arena_geometry.gd` creates the 36×28 m floor, four pillars, central low wall, outer walls, and visual-only brush patches. Static collider geometry is parsed/baked into one NavigationRegion3D synchronously at startup. The region becomes usable after navigation-server synchronization; commands wait for readiness.
- `UnitCommand` represents move, attack, attack-move, stop, and hold. Each unit has one pending command slot: last input wins; orders apply on the next simulation tick. Raw mouse input is never smoothed.
- `CombatUnit` is a reusable capsule CharacterBody3D, with UnitStats resources and separate MovementComponent and AttackCycle. It currently owns health, action state, target selection, basic melee hit resolution, and respawn inline. Further status/ability components are not implemented.
- MovementComponent uses NavigationAgent3D and fixed `speed / 60` collision motion on admitted simulation ticks. Recast path-height quantization is compensated with the agent's path height offset; visual interpolation never determines gameplay positions. Chase repaths every 6 ticks. Physical radius is fixed at 0.65 m; bake clearance is 0.75 m. No dynamic-unit avoidance is needed for the stationary dummy slice.
- AttackCycle uses absolute integer hit/ready deadlines. Captain defaults give 15-tick windup and 91-tick period. Windup cancellation before the hit refunds readiness; commands on the hit tick commit the hit first. Movement during backswing retains the original readiness deadline. Retargeting cancels the old windup and starts a new one if in range.
- DamageResolver applies positive/negative resistance and percent penetration. Basic attacks roll crit from SimClock's seeded RNG, then resolve physical damage against armor. Target validity/range is rechecked at impact. Dummies have 2000 HP/50 armor and respawn after 120 ticks. Player respawn is 180 ticks; no attacking enemy AI exists yet.
- ArenaCamera follows an interpolated target in render processing and disables interpolation on its own transform. It implements 56° pitch, 40° FOV, approximately 22 m default visible width, lock toggle, Space center, bounded zoom, and edge pan. Camera behavior cannot alter simulation results.
- SandboxHUD provides prototype health/status text, selection stats, placeholder ability slots, live numeric player-stat overrides, ranges/path overlay, state timers, last 200 combat events, and pause/restart/quit. Gameplay radius is excluded from live tuning because changing collider and baked navigation clearance must be coordinated. No tuning-file export or replay persistence exists yet.
- Basic hit flash and floating damage numbers are presentation only. All temporary effects are grouped and removed on reset. Brush has no vision/leap behavior in M1.

M1 is not complete: stock-character animation integration/calibration, status components, test ability/cooldowns, fuller debug/export tooling, and feel approval remain. M2/class mechanics have not started.
