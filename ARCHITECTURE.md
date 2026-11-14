# Architecture

Read this file and `PROGRESS.md` at the beginning of a working session. The development guide defines the eventual MVP; this document describes what actually exists.

## Implemented in M0

- `world/setup_room.tscn` is the main scene. Its script builds a 36×28 m grey floor, four outer walls, light, perspective camera, and static 1.8 m capsule marker. It has no player controller, navigation, combat, brush, pillars, or enemy AI.
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

## Next milestone, after M0 approval

M1 introduces Commands, unit components, navigation, basic attacks, damage, camera controls, debug interfaces, and animation calibration. It must not silently replace setup architecture or alter guide rules. Stock model rig and animation compatibility must be validated with actual files before choosing character recipes.
