# Architecture

Read this file and `PROGRESS.md` at the beginning of a working session. The development guide defines the eventual MVP; this document describes what actually exists.

## Implemented in M0

- `world/setup_room.tscn` preserves the accepted M0 reference scene; M1 uses `world/arena.tscn` as the main scene. Its script builds a 36×28 m grey floor, four outer walls, light, perspective camera, and static 1.8 m capsule marker. It has no player controller, navigation, combat, brush, pillars, or enemy AI.
- The renderer is Forward+, physics is Jolt at 60 Hz, maximum physics steps per frame is 8, and physics interpolation is enabled. Default viewport is 1920×1080, resizable, V-Sync on.
- `SimClock` advances `TickState` from `_physics_process` and synchronously emits `tick_advanced(tick)`. Future gameplay updates must subscribe to this signal so pause and slowed pacing affect every gameplay timer uniformly. Each admitted tick is always 1/60 simulated second. `_process` is presentation only.
- `TickState` stores integer tick count, integer speed in tenths, pause/single-step flags, and the sole seeded gameplay RNG. Integer accumulation admits fewer ticks at lower speed; `Engine.time_scale` is not modified. Pacing is for command-driven simulation. Future CharacterBody movement must use a fixed 1/60 step on each admitted tick; dynamic rigid-body gameplay would need an explicit pacing design before use.
- `EventBus.publish` emits a tick-stamped notification and a deep-copied payload. Presentation and logs may listen; gameplay must never require those listeners.
- `DebugConfig` provides in-memory per-resource overrides with fallback and reset. It has a live tuning UI and explicit snapshot export, but no automatic disk persistence.
- `InputRouter` handles setup reset, pause, single-step, speed, and menu signals. It ignores keyboard auto-repeat. Input map includes all later gameplay bindings, but Commands and world picking are M1 work.
- `tools/verify.py` imports the project, loads every script, runs GUT, and runs the main scene for 600 consecutive simulation ticks. It pins the official engine version and redirects XDG paths inside ignored `.local/` for verification only.

## Dependencies and assets

GUT 9.7.1 is vendored under `addons/gut/` and enabled in project-local settings. One local patch in `gut_plugin.gd` replaces its automatic startup network update check with the bundled/cached version check, avoiding offline startup errors. Explicit manual update checks remain available. GUT itself includes font and GUI assets with upstream licenses. Only the addon subtree was extracted; its original license is retained.

The original guide and approved concept sheet live under `docs/`. Raw external character packs stay outside the repo. Empty asset/system directories reserve the guide's structure; `.gitkeep` files are placeholders, not implementations.

Eight stock character/animation candidates are prepared under `assets/`. The original M0 setup scene does not instantiate them; the M1 arena now uses the male ranger outfit, male base body/head, and both animation libraries. See `docs/asset_audit.md` and the manifest for compatibility limits. Rigs share a 65-bone hierarchy but not all bind poses. `tools/prepare_assets.py` packages glTF dependencies; `tools/check_assets.gd` checks imported scenes, bone counts, and animation names during verification.

## M1 implementation — first foundation slice

M0 was explicitly approved by Ishak; local tag `m0-approved` records its accepted code. M1 was accepted with finer animation calibration deferred; local tag `m1-approved` records it. M2 is active on `feature/m2-captain-kegs`.

- `world/arena.gd` builds the separate sandbox and runs units in stable array order on `SimClock.tick_advanced`. It owns cursor-to-ground projection, selection, held movement, attack-move arming, debug toggles, and reset/menu handling. No runtime network is used.
- `world/arena_geometry.gd` creates the 36×28 m floor, four pillars, central low wall, outer walls, and visual-only brush patches. Static collider geometry is parsed/baked into one NavigationRegion3D synchronously at startup. The region becomes usable after navigation-server synchronization; commands wait for readiness.
- `UnitCommand` represents move, attack, attack-move, stop, and hold. Each unit has one pending command slot: last input wins; orders apply on the next simulation tick. Raw mouse input is never smoothed.
- `CombatUnit` is a reusable CharacterBody3D with an unchanged capsule collider and a stock CharacterAvatar visual, with UnitStats resources and separate MovementComponent and AttackCycle. It currently owns health, action state, target selection, basic melee hit resolution, and respawn inline. StatusEffects and AbilityRunner are now separate state helpers; class-specific mechanics are not implemented.
- MovementComponent uses NavigationAgent3D and fixed `speed / 60` collision motion on admitted simulation ticks. Recast path-height quantization is compensated with the agent's path height offset; visual interpolation never determines gameplay positions. Chase repaths every 6 ticks. Physical radius is fixed at 0.65 m; bake clearance is 0.75 m. No dynamic-unit avoidance is needed for the stationary dummy slice.
- AttackCycle uses absolute integer hit/ready deadlines. Captain defaults give 15-tick windup and 91-tick period. Windup cancellation before the hit refunds readiness; commands on the hit tick commit the hit first. Movement during backswing retains the original readiness deadline. Retargeting cancels the old windup and starts a new one if in range.
- DamageResolver applies positive/negative resistance and percent penetration. Basic attacks roll crit from SimClock's seeded RNG, then resolve physical damage against armor. The temporary Training Pulse resolves magic damage against MR, and burn applies true damage directly. Target validity/range is rechecked at impact. Dummies have 2000 HP/50 armor and respawn after 120 ticks. Player respawn is 180 ticks; no attacking enemy AI exists yet.
- ArenaCamera follows an interpolated target in render processing and disables interpolation on its own transform. It implements 56° pitch, 40° FOV, approximately 22 m default visible width, lock toggle, Space center, bounded zoom, and edge pan. Camera behavior cannot alter simulation results.
- SandboxHUD provides prototype health/status text, selection stats, ability slots with a working temporary Q cooldown, live numeric player-stat/ability overrides, ranges/path overlay, state timers, last 200 combat events, and pause/restart/quit. Gameplay radius is excluded from live tuning because changing collider and baked navigation clearance must be coordinated. Explicit tuning snapshots and whole-run CSV export are available; replay persistence is not implemented yet.
- Basic hit flash and floating damage numbers are presentation only. All temporary effects are grouped and removed on reset. Brush has no vision/leap behavior in M1.

Status/cooldown slice:

- `StatusEffects` stores integer expiry deadlines. It resolves strongest slow, additive speed buffs, longest root/stun, and 30-tick burn pulses. Cleanse removes slow/root/stun; burn and buffs remain. Root prevents motion but permits attacks and self-casts. Stun interrupts uncommitted windups/casts and movement. These checks are integrated without changing accepted movement/attack timing defaults.
- `AbilityData` is a tunable resource and `AbilityRunner` owns cast/cooldown deadlines. Q uses a temporary self-centered Training Pulse; it is not a Captain class ability. Cast locks buffer one command until unlock, last wins, with 30-tick expiry. A cast preserves the prior order and resumes it after completion. Interrupted casts retain their cooldown. Death/reset clears cast state, cooldowns, and statuses.
- Arena queues F1 debug status buttons for the next tick rather than modifying gameplay from GUI callbacks. HUD draws a radial Q cooldown, remaining seconds, failure feedback, and status text; pulse effects are visual only. Other class slots stay inactive.

Ishak accepts the current animations and has explicitly deferred finer manual hit-frame calibration unless a later issue requires it. Profile markers remain provisional; this is an accepted deferral, not a claim of completed calibration. Ishak subsequently instructed continued work and accepted the M1 checkpoint; the first M2 Q/E slice is now active.


Stock-character visual slice:

- `CharacterAvatar` replaces the capsule mesh with the stock male ranger outfit for the player and flat-grey superhero male bodies for dummies. The red ranger is provisional; no pirate coat/hat is in the free archive. A simple code-built sword attaches to `hand_r`, as allowed by the guide's primitive weapon fallback.
- Only head/neck-weighted triangles above the neck cutoff are retained from the base body under the outfit. Skin binds and custom mesh attribute encodings are preserved. Tests verify no torso triangles remain and the head's weighted rest position matches the outfit rig. Original source GLBs are not modified.
- `AvatarLibrary` loads stock animation data once and caches an adapted library per target rig. Global-rest rotation compensation and target-rest translations preserve body proportions despite the mannequin's different bind pose. Matching strike/recovery clips are joined for alternating melee. Rest-pose and finite/bounded-pose tests cover the resulting libraries.
- `CharacterAvatar` manually samples seven animation roles: idle, run, attack_a/b, cast, death, and rest. It uses simulation ticks for presentation pacing, supports short pose blends, freezes on stun, and sinks the visual during the end of a death. Actor transforms, navigation, RNG, damage, and attack deadlines remain simulation-owned.
- Attack animation sampling is piecewise: the source hit marker aligns with the actual hit tick, then the remainder fills the backswing. Source markers in `data/anim_profiles/attack_a.tres` and `attack_b.tres` are provisional until Ishak visually marks them.
- `debug/anim_lab.tscn` is reachable through F1. It supports character/role selection, play/pause, 60 fps frame steps, and explicit hit marking through M/button. ResourceSaver writes only the selected project animation profile; failed saves restore the in-memory marker. Returning to the arena resets the sandbox. The lab pauses SimClock and never changes combat timing.


Debug export slice:

- `CombatLog` records full-run tick-stamped event payloads independently of the 200-row HUD display buffer. Arena's event handler owns recording, so leaving the scene disconnects collection automatically. Reset clears both logs. CSV export uses FileAccess CSV quoting with the guide's six columns.
- `DebugConfig.export_overrides` writes an explicit TuningSnapshot resource containing only live overrides plus schema/engine/date metadata. It never mutates source resources or auto-loads snapshots on startup. `clear_overrides` restores defaults; the HUD synchronizes its SpinBoxes with signals blocked.
- F1 export buttons write unique files under project-local `debug_exports/`, excluded from Git and game import. Both exporters reject existing targets. Tests use isolated `.local/test_exports/` paths and remove their outputs. No app/system configuration is edited.


## M2 first slice — Q/E and keg combos

- Arena enables a CaptainController by default. The legacy M1 Training Pulse fixture explicitly disables it to preserve previous regression coverage. Movement, physics radii, basic attack deadlines, and character appearance are unchanged.
- CombatUnit now accepts generic Node3D targets implementing `alive/stat/unit_id` (units or owned kegs), tracks the active cast runner separately from Q's runner, and preserves an out-of-range cast intent while approaching. A new move/attack cancels that pending approach. Cast locks still use one last-wins 30-tick buffer. Successful Q/E casts face their target point.
- CaptainController owns Q/E runners, serial ChargePool, homing projectiles, and KegManager. It validates Q targets and E wall/spacing constraints before consuming cooldown/charges. Existing cast and stun semantics are retained. Stun cancels the pending ghost but does not refund an already committed charge. Reset/respawn clears the controller, kegs, schedules, and projectiles.
- KegState/KegGraph represent both pending and live kegs; neighbors are sorted by id and connect at <=6.9 m. Pending materialization time participates in chain deadlines. Only successful E completion materializes the node. Views are nonblocking targetable prototype barrels with health pips/countdown rings; graph links brighten for scheduled nodes.
- Simulation order is: queued debug actions, Captain pre-tick (charges, live decay/expiry, due chains), unit ticks/cast completion, projectile movement/impact, and a final due-chain pass. This makes decay apply before same-tick hits and permits a scheduled pending keg to explode on its materialization tick without recursion.
- Each chain snapshots triggering raw damage, crit flag/extra multiplier, armor penetration, elite bonus, and slow parameters. It owns a hit-unit set so overlapping blasts apply once per chain. A crit payload gets an additional 1.05 multiplier by default, then an elite-only flat bonus; penetration is 40%. Those formula choices are explicit resource fields. Later child explosions do not resnapshot current attack damage or live damage modifiers.
- A scheduled keg destroyed early uses its existing chain payload; stale queue entries are ignored. Removed/expired/reset nodes cannot explode again. Chain payloads are released when no chain nodes remain.
- Q starts a 15-tick cast and 270-tick cooldown; its projectile advances at 26 m/s starting the tick after launch. It re-aims at the valid target each tick. Removed/dead targets fizzle; kegs take exactly one health damage. E has a 15-tick cast, 30-tick recast lock, three charges and serial 780-tick recharge. Decay interval locks when materialized; lifetime defaults to 1500 ticks.
- The HUD supports Q/E cooldowns, charge pips/recharge progress, selection of owned kegs, correct-slot failure flashes, and Q/E tuning. Stock pistol-shot/throw animations and a procedural pistol support the new casts; all visuals remain simulation-independent.

## M2 Ration slice

- CaptainController owns W Ration alongside Q/E. `data/abilities/ration.tres` defines a 15-tick cast, 1080-tick cooldown, and healing of 100 + 13% missing health, calculated on completion and capped at maximum health. W is self-cast and requires no cursor target.
- Successful completion heals and invokes the shared cleanse (slow/root/stun removed; burn and buffs retained). Ishak approved a Ration-specific stun exception on November 15: W can start and complete during stun, then cleanse it. New stuns do not interrupt W; death still cancels it. Other casts retain the global stun prohibition. The user amendment is recorded in the guide.
- InputRouter forwards physical W through `ability_w` to the arena; casting at full health is allowed and consumes cooldown. A physical-key regression covers the router-to-arena path.
- W uses the existing cast buffer, resumes previous intent, and clears on death/reset/respawn. The HUD exposes W cooldown/failure feedback and live tuning. Healing emits a tick-stamped log event, green number, and prototype green ring, with no simulation dependency on presentation.

## M2 Searing Edge slice

- CaptainController owns a passive AbilityRunner used only for cooldown display/deadlines, never an active cast. A landed basic attack against an enemy CombatUnit consumes readiness and starts a 900-tick cooldown; cancelled/missed attacks, Flintlock, and attacks against kegs do not consume it. Lethal melee still consumes readiness and grants speed; dead targets cannot receive new statuses.
- `data/abilities/searing_edge.tres` defines 24 true damage per half-second burn pulse for 150 ticks (five pulses, 120 total), plus a 25% speed buff for 120 ticks. The shared burn and buff helpers handle expiry/cleanse; repeating the same speed source refreshes rather than stacks it. Basic attack timing is unchanged.
- KegManager emits a direct simulation signal at the first explosion of each chain, guarded by a flag in that chain's existing state. Captain resets readiness and grants the speed buff once. Child explosions cannot reset a passive consumed between chain nodes. This logic does not depend on EventBus listeners; EventBus only records passive hit/reset notifications.
- P shows passive cooldown/readiness; F1 exposes passive resource fields (damage is per pulse). CharacterAvatar adds an orange blade emission while ready; it reads state and never mutates simulation. Full flame/VFX/audio polish remains later work.

## M2 Broadside slice

- CaptainController owns R plus active BroadsideZone nodes. Physical R is forwarded by InputRouter and quick-casts at the cursor ground point anywhere inside the 36×28 m arena, without approaching or wall-placement restrictions. Invalid/outside points fail before cooldown. The cast is 15 ticks; its 1800-tick cooldown starts on cast start. Shared buffering, interruption, and previous-intent rules apply.
- `BroadsideData` extends AbilityData with timing/count fields. On successful completion a fixed zone snapshots radius (5.8 m), damage (40 magic per wave), slow (30% for 30 ticks), duration (480 ticks), and schedule. First cluster is measured from cast completion: waves at +30/+45/+60, +150/+165/+180, +270/+285/+300, +390/+405/+420. The ring remains through +479 and the zone is removed at +480. Live tuning affects subsequent zones. Custom waves at/after expiry are excluded; counts are bounded to 1–32 each.
- Zones simulate after unit ticks and before Flintlock projectile updates in Captain post-tick. Each wave damages every living opposing unit whose gameplay radius intersects the area, once per wave, and refreshes the shared slow. Kegs and allies are excluded; this damage does not apply Searing Edge. Damage is area-wide and independent of cannonball impact positions.
- Twelve uniform-area wave anchors are generated using the shared seeded simulation RNG on zone creation. Each anchor seeds a local cosmetic RNG to generate 16 cannonballs per wave (192 per cast), spread across the circle with ±5-tick impact staggering. F1 exposes `cannonballs_per_wave` (1–32, max 2048 visuals per zone). Changing density does not consume additional simulation RNG or alter damage, slows, or wave timing. Meshes/materials are shared and use low segment counts. Rendering consumes no RNG: a persistent ring, falling streaks for the 15 ticks before impact, and brief impact flashes read simulation ticks. These are procedural prototypes; final VFX/audio remain deferred.
- F5/controller reset and respawn clear all zones and R cooldown. Stun/death interrupts an unfinished cast without refund; completed zones continue until expiry or controller reset, consistent with already launched class effects. R HUD/failure feedback and F1 tuning are available.

Still pending in M2: Broadside user playtest, final combo/manual milestone acceptance, and any remaining training controls. Polished VFX/audio/props remain deferred. No Hunter/M3 work is authorized yet.


## M2 training controls

- Main arena enables resource-backed TrainingSettings (`data/training/defaults.tres`): three stationary infinite-HP dummies by default, with F1 count 1–5, armor 0/50/100, finite HP 2000/10000, infinite toggle, and Counts as Elite. Settings use DebugConfig overrides, are exportable, and apply on the next admitted simulation tick. Changing them resets and recenters all targets at three-meter spacing without altering source UnitStats. Per-unit stat adjustments hold HP/armor; MR is unchanged.
- The existing units array is mutated in place so KegManager and active Broadside zones see count changes. Removed targets are marked dead before deferred freeing and selection falls back to player. New units have unique active ids; old targets are safely invalid for projectiles/orders.
- Infinite training targets keep their HP while normal damage/status events still fire. Each dummy records resolved incoming damage and first-hit tick; selected-unit UI shows total damage and encounter-average DPS (includes idle time since first hit, minimum one tick). Finite totals include overkill, matching damage log amounts. Reset/respawn and F1 Reset damage / DPS clear counters. F1 Restore player health is queued and heals only living players.
- F5 retains session settings and resets damage/status state. Reset tuning to file restores resource defaults and selector values, with changes applied next tick. The Captain/M1 combat regression fixtures explicitly disable training defaults to retain finite-target assertions; a dedicated training suite exercises actual infinite defaults and options.
- F1 offers explicit 2/1/0.5-second keg tiers alongside numeric tuning; materialized keg tiers remain locked. Stationary, Strafe, and slow Chase behavior plus enemy keg-attacking controls are now implemented for training (details below); no M3 AI/class work was started. `docs/M2_PLAYTEST.md` records the remaining manual gate, including five successful three-keg attempts.


## M2 final implementation audit

- Training behavior selects stationary, a three-meter side-to-side patrol at 3.45 m/s, or slow player chase (resource default 1.5 m/s, stopping within 2 m). Span/speeds/stop distance are exposed in F1 and exportable. Commands use the same tick-based navigation/movement/status rules as combat units; the driver waits for pending commands and does not overwrite them every tick. F5/settings changes reset patrol direction. This is training behavior only, not M4 enemy classes or challenge waves.
- Enemies attack kegs defaults Off. When enabled, training dummies prioritize the nearest live keg already within their melee range, using normal windup/cancellation timing. They do not chase kegs or attack the player. Enemy hits remove one pip; enemy destruction removes a keg without explosion or Searing Edge reset. A removed scheduled node is safely ignored by the chain queue.
- All Captain ability implementations, training settings, and section-8 acceptance tests are available for milestone inspection. M2 approval is not recorded automatically. Manual combo acceptance remains the user's gate. The W stun-cleanse conflict was resolved with Ishak’s explicit approval: W alone can cast through stun and cleanses it on completion. Final art/VFX/audio and prior Q/E polish remain deferred.
