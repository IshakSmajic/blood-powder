# Progress

## Active milestone: M4 — PvE validation

**Restart note:** read [docs/SESSION_HANDOFF.md](docs/SESSION_HANDOFF.md). Current branch: `feature/m4-pve`. M0–M3 are approved. M4 implements real enemy AI, telegraphed Elite slam, shared vision, three-wave Challenge, results/reset and binary command replay. M4 is ready for inspection: 134/134 tests and 2,863 assertions passed, 155 scripts loaded, 8 stock scenes imported, and Captain/Hunter/Challenge each passed 600-tick smoke checks. Strict editor import retains the known sandbox TCP restriction; M5 remains gated on explicit approval. See [M4 playtest](docs/M4_PLAYTEST.md) and [gate mapping](docs/M4_ACCEPTANCE.md).

Ishak explicitly approved M0 and proceeding to M1. M0 setup is accepted; remote synchronization remains pending because this session cannot resolve GitHub.

## Current M1 status

- [x] Navigation, movement, attack-move, stop/hold, camera, basic combat, statuses, and test ability/cooldown pipeline.
- [x] Stock character visuals, animation adapter, and Animation Lab.
- [x] Explicit combat CSV and tuning .tres exports; reset tuning to resource defaults.
- [x] Latest checks: 123 scripts, 8 stock asset imports, 47 tests / 2,131 assertions, 600-tick main-scene smoke.
- [x] Ishak likes movement feel and character visuals.
- [x] Current animations accepted; finer attack_a/attack_b calibration explicitly deferred by Ishak unless later playtesting reveals a need. Marker flags remain provisional, not falsely marked calibrated.
- [x] Ishak accepted the current foundation and instructed continued work; M1 accepted with animation fine-tuning deferred. Individual manual checks not separately reported remain documented limitations.

System/application configs remain untouched. The only strict verification error in this session is the previously confirmed sandbox debugger-socket restriction. GitHub pushes are still blocked by session DNS. See the dated work history below for each completed slice.

## M0 setup record


- [x] Private repository created and cloned at `~/Projects/blood-powder`.
- [x] Standalone Godot 4.7.2 installed; Ishak confirmed the editor opens.
- [x] Original guide and approved visual concept preserved in `docs/`.
- [x] Project structure, scene, input map, core autoloads, and session docs created.
- [x] GUT 9.7.1 addon vendored with license and enabled locally in this project.
- [x] All 97 GDScripts load; all 9 GUT tests pass; main scene runs for 600 ticks; all 8 prepared stock scenes import successfully.
- [x] Ishak ran `python tools/verify.py` in the normal terminal and supplied complete `VERIFICATION PASSED` output: clean editor import, 97 scripts, 8 asset scenes, 9 tests/729 assertions, 600 simulation ticks.
- [x] Ishak confirms the project works after the GUT startup fix ("Works fine").
- [x] Matching 4.7.2 Linux/Windows x86_64 debug/release export templates and console wrappers installed and byte-verified against the supplied TPZ. Both Linux templates report the pinned official version.
- [x] Four character/animation packs inspected, licenses checked, raw files extracted externally, and candidate assets prepared. See `docs/asset_audit.md` for rig/outfit limitations.
- [ ] Branch pushed for review; milestone merged/tagged after approval.

M0 branch: `setup/m0-foundation`; current work branch: `feature/m1-foundation`. The setup slice is committed locally using Ishak's configured author and committer identity, with no co-author trailers. Push was attempted and failed because this session cannot resolve `github.com`; there is no remote branch/PR yet. Working tree was clean after the setup commit. Local tag `m0-approved` was created after explicit approval. Remote synchronization/merge remains pending.

## Historical M0 verification

M0 follow-up: Ishak reported `[GUT] Could not get version info, response code: 0` while opening the editor. Inspection traced it to GUT's automatic GitHub update request. Patched only its startup call to use bundled/cached version information. Manual update requests remain available; existing system/application configuration and the editor's current `project.godot` serialization were preserved.

Ishak subsequently confirmed "Works fine" after reopening. This confirms the reported editor issue is resolved and the setup slice works on desktop. A normal-terminal strict verification log was subsequently supplied and all checks passed. Character packs and export templates are prepared. Detailed pause/step/resize results were not individually reported; Ishak subsequently gave explicit M0 approval.

Asset preparation follow-up: all 8 prepared GLBs import into Godot with 65-bone skeletons; UAL1 and UAL2 each expose 43 clips. Godot strips the standard `_Loop` suffix when importing animations; the check recognizes that exact rule. Both libraries contain usable melee/locomotion candidates, but visual playback/retargeting is not yet verified. Repeat packaging produced identical outputs. Actual archive contents differ from several guide assumptions; see `docs/asset_audit.md`. No gameplay or M1 visual integration was started.

Verified locally with Godot `4.7.2.stable.official.ed1daf0bf` and GUT 9.7.1:

- All-script loader: 97 scripts load successfully, exit 0, no script errors.
- Stock assets: all 8 scenes load with expected bones and animation clips, exit 0.
- GUT: 9/9 tests, 729 assertions, zero failures, exit 0.
- Main-scene smoke: 600 consecutive simulation ticks, exit 0, no runtime errors.
- Editor import completed and generated the project cache, but reported sandbox socket errors (`_inet_open` and `TCPServer.listen` / `ERR_CANT_CREATE`). These are not suppressed. Ishak subsequently verified the same project outside this restricted session: editor import and the full verification command passed without these errors.
- Desktop rendering, resizing, and physical keyboard interaction require Ishak's manual playtest; headless tests do not verify GPU/window behavior.

`python tools/verify.py` runs all stages even if one fails and saves logs in ignored `.local/`.

## Manual M0 playtest

1. Open this project's `project.godot` with the pinned editor; allow import to finish.
2. Press F5. Confirm the grey room, red capsule marker, setup instructions, and advancing tick counter appear. The capsule is static by design.
3. Focus the game window. Press F9: tick counter stops. Press and release F10: exactly one tick is added. Repeated taps each add one tick.
4. Press F9 to resume; F7 lowers speed and F8 raises it. F5 in the game resets the tick count and returns to 1.0× running.
5. Open Esc menu and Resume. Confirm a previously paused simulation stays paused after closing the menu. Quit closes the game.
6. Resize the window and confirm text remains readable. Check the Godot Debugger for errors.

Report: whether it launched, any errors, pause/step results, and whether you approve M0. No movement or combat playtest is expected yet.

## Constraints and known gaps

- Network/DNS from shell commands is blocked. Downloads currently require Ishak to place ZIPs in Downloads. Remote pushes cannot be assumed to work.
- No system, shell, desktop, or existing application config has been edited. New project settings are scoped to this repository. Godot may create its own editor state when Ishak opens the project.
- Git identity remains Ishak's configured identity; no AI author/co-author trailers are allowed.
- Source text in the original guide mentions another coding assistant; preserved as received. This does not change responsibilities or add attribution requirements.
- Guide proposes newest 4.7.x: installed and pinned 4.7.2. Guide text itself remains unchanged.
- Linux/Windows x86_64 export templates are installed in `~/.local/share/godot/export_templates/4.7.2.stable/`. Other platform/architecture templates remain in the original TPZ. No Windows executable has been run. Stock character/animation candidates are prepared but not instantiated in the test room. Final visuals and exports are not implemented.
- Generated concept HUD and arena proportions are illustrative; mechanics/layout must follow the guide.

## Open decisions

- Keep the concept's human hooded Hunter appearance unless Ishak requests a change; exact stock body/outfit selection remains pending asset inspection and approval in M1.
- Final code license has not been selected. No license for project-owned code is implied by vendored MIT dependencies.


## Work history

This is the project’s ongoing work log. Update it after each work session with completed changes, verification, limitations, and the next task. `ARCHITECTURE.md` describes the current implementation; the development guide defines the intended MVP.

### 2026-11-15 — Q/E playtested; polish deferred

Ishak tested Q and E and reported: “the functionality is there but needs polishing but we can do that at a later time.” Record the Q/E slice as user-playtested with polish deferred. No specific defects or individual scenario results were supplied; do not infer full milestone acceptance. Preserve current behavior until later feedback identifies the desired refinements.

No gameplay or configuration changes were made. Existing automated verification remains the 68-test / 2,231-assertion checkpoint; documentation-only updates do not require another run. Next implementation work is Searing Edge, W Ration, and R Broadside. M2 remains incomplete and M3 remains gated on explicit M2 approval.

### 2026-11-14 — M0 setup and asset preparation

1. Reviewed Ishak’s MVP development guide and preserved the original DOCX and searchable text in `docs/`.
2. Generated the visual concept sheet; Ishak approved its direction. Saved it under `docs/concepts/` and retained a copy in Downloads.
3. Confirmed the GitHub repository was cloned at `~/Projects/blood-powder`.
4. Installed standalone Godot 4.7.2 under `~/Applications/Godot-4.7.2/`, verified its exact version, and received confirmation that the editor launches.
5. Created the Godot project, grey test room, static scale marker, input bindings, SimClock, EventBus, DebugConfig, and InputRouter. Added setup pause, frame step, speed controls, reset, and menu.
6. Vendored GUT 9.7.1 with its license. Added 9 tests, all-script loading, a 600-tick main-scene smoke check, and `tools/verify.py` with isolated verification output.
7. Fixed GUT’s automatic startup update request after Ishak reported an offline version-check error. Ishak confirmed the project works after reopening.
8. Extracted the four downloaded Quaternius packs to `~/bp-assets-raw/`, verified CC0 notices, and prepared 8 self-contained GLBs. Added reproducible packaging, asset import checks, licenses, fingerprints, and the asset audit.
9. Found and documented mismatched bind poses, limited free outfits, body-clipping considerations, and missing explicitly named roar/stun clips. Fixed broken source texture references during packaging; no mesh or texture-pixel edits were made.
10. Verified 97 scripts load, all 8 asset scenes import, both 43-clip libraries are available, all 9 tests pass (729 assertions), and the main scene runs for 600 consecutive ticks. Strict editor-import verification still reports this session’s blocked debugger-socket errors.
11. Installed matching Linux/Windows x86_64 export templates, including debug/release binaries and Windows console wrappers. Checked extracted bytes against the TPZ; both Linux binaries report `4.7.2.stable.official.ed1daf0bf`.
12. Committed work locally on `setup/m0-foundation` using Ishak’s Git identity without AI/co-author trailers. GitHub push was attempted but failed because this session cannot resolve GitHub. The editor’s uncommitted `project.godot` serialization was preserved.

Next: begin the M1 movement/basic-attack sandbox. Character appearance/animation integration remains a later M1 slice; no movement, combat, enemy AI, class mechanics, or final art is implemented yet. Environment/VFX/audio sourcing remains later work. M0 sign-off was subsequently received.


### 2026-11-14 — normal-terminal verification confirmed

Ishak supplied the complete output of `python tools/verify.py`, ending in `VERIFICATION PASSED`. Editor import was clean, all 97 scripts loaded, all 8 stock scenes imported with the expected skeletons/clips, all 9 GUT tests passed (729 assertions), and the main scene completed 600 consecutive ticks. This resolves the outstanding verification gate; prior debugger-socket failures were restricted-session environment errors. No implementation changes were made in this follow-up, so no duplicate verification run was needed. M0 was subsequently explicitly approved; GitHub synchronization remains blocked from this session.


### 2026-11-14 — M0 approved; M1 started

Ishak explicitly approved M0 and proceeding to M1. Preserve the accepted setup scene as a standalone reference while adding the movement/basic-attack sandbox. Start with capsule visuals; character integration remains the last M1 slice. Existing uncommitted editor serialization in `project.godot` must be preserved.


### 2026-11-14 — M1 capsule movement/basic-attack slice

Implemented a separate arena scene; kept the accepted M0 reference unchanged. Added runtime-baked navigation around pillars/low wall, capsule player, three stationary dummies, next-tick command processing, held right-click movement, attack-move, stop/hold, chase/repath, integer attack deadlines, cancellation/retargeting, physical damage/armor/crits, health bars and labels, respawn, camera lock/pan/zoom, selection, live stat tuning, and range/state/log debug views. The new arena is now the main scene. No system or application config was edited; only the project main-scene line changes, preserving existing editor serialization.

Added pure combat timing/damage checks and scene-level tests for exact hit ticks, windup refund, retargeting, backswing movement, obstacle routing without penetration, hold behavior, exact respawn, and attack-move resumption. Early tests found and fixed a quantized navigation-surface height mismatch and attack-move destination restoration. Camera interpolation is disabled on the render-updated camera to avoid double interpolation.

Final slice verification: 109 scripts load, all 8 stock assets import, all 21 GUT tests pass (1,976 assertions, including 8 scene simulation tests), and the new main scene runs for 600 consecutive ticks without runtime errors. The strict command still fails only at editor import because this session blocks Godot’s debugger TCP listener; that environment limitation was independently confirmed during M0. M1 desktop feel/rendering verification remains pending.

Manual slice check: restart the project, move around the pillars and central wall, approach dummies in the northern half, right-click one to attack, cancel a windup with S or movement, move immediately after a hit, retarget another dummy, try A+click and H, inspect with LMB, test Y/Space/wheel, F1–F4, pause/step, Esc, and reset. Report movement feel and any errors.

Remaining M1: status components, working test ability/cooldowns, stock character/animation integration and hit-frame calibration, fuller tuning/log export, and full milestone playtest. Dummies currently have finite HP and reset after death; infinite-health/DPS configuration is a later training slice. Brush is visual only. No class abilities or enemy AI are present. No GUI/GPU verification is possible in this restricted session; desktop playtesting remains required. M1 is not approved/completed and M2 has not started.


### 2026-11-14 — movement feel accepted; status/cooldown foundation

Ishak reported the capsule sandbox feels surprisingly good. Preserve the current movement speed and basic-attack timing; no tuning defaults changed. Ishak also asked about the red capsule: clarified that downloaded assets are imported and verified, but visual character integration remains the final M1 step as specified by the guide. This is positive slice feedback, not approval of the entire unfinished M1 milestone.

Added StatusEffects with strongest-slow selection, additive speed buffs, longest-duration root/stun, cleanse rules, and half-second true-damage burn pulses including the final expiry tick. Root blocks movement while preserving attacks/self-casts; stun cancels windups/casts and allows prior intent to resume when it expires. Death/reset clears effects.

Added a temporary self-centered Q Training Pulse resource and AbilityRunner to exercise the M1 cast/cooldown pipeline: 0.25 s cast, 3 s cooldown, 3.5 m radius, 60 magic damage, 40% slow for 2 s. These are prototype test values, not the Powder Captain's future Flintlock implementation. Cooldowns begin on cast start; successful casting cancels an attack windup with refund, preserves prior movement/attack intent, and buffers one last-wins input for up to 30 ticks. Stun interruption retains the cooldown. Failed casts show a reason near the cursor and flash the Q slot.

HUD now has code-drawn ability slots with radial cooldown/seconds, active status timers, blue magic/orange true-damage numbers, and pulse range/visual feedback. F1 adds live test-ability tuning and next-tick player status/cleanse buttons. No external/system configuration changes were made. Class abilities and stock character visuals are still pending.

Verification: all 115 scripts load, all 8 stock assets import, all 36 GUT tests pass (2,054 assertions, including the prior movement/attack regression suite), and the main scene runs for 600 consecutive ticks. Strict editor-import verification continues to report this restricted session's blocked debugger socket; no gameplay/script errors were found. GUI rendering and new interactions need desktop playtesting.

Manual check: restart the project, approach a dummy and press Q. Confirm a short cast, blue pulse/damage, visible Q cooldown, and “On cooldown” feedback when repeated. Inspect the dummy to see its slow. In F1, apply root/stun/burn to the player and use Cleanse; roots should allow Q and attacks, stuns should block/interrupt them, and burn should survive cleanse. F5 resets cooldowns/statuses. Movement/basic attack feel should match the accepted prior slice.

Next: stock-character/animation integration and calibration. Remaining M1 tooling includes tuning/log exports and animation lab. Do not begin M2 before full M1 sign-off.


### 2026-11-14 — stock characters and animation integration

Ishak authorized proceeding with the character swap. Replaced the red capsule mesh with the downloaded male ranger outfit in a provisional red palette, using only a cropped base head beneath it. Training dummies now use the stock male body with flat grey materials. The free pack still lacks the final Captain coat/hat; no bespoke clothing or purchase was introduced. A simple procedural sword attaches to the right-hand bone.

Added cached model scenes and shared stock animation data, per-rig rest compensation, joined strike/recovery animations, idle/run, alternating melee, cast, death, brief pose blends, hit flash, and visual death sinking. The original mesh-array attribute format is retained when cropping the head. Movement speed, capsule collision, navigation, RNG consumption, damage, and attack deadlines remain unchanged.

Added F1 → Animation Lab with character/clip selection, play/pause, 60 fps frame stepping, and explicit hit marking/saving to `data/anim_profiles/`. The initial hit-time values are provisional (`calibrated=false`); user marking is required before claiming final visual calibration. Save actions affect project animation data only, never application/system settings or combat timing.

Added seven meaningful avatar checks: stock mesh/rig/role presence, target rest-pose preservation, cropped head skin fit/no torso triangles, shared libraries and recovery segments, finite bounded animated poses, visual sampling isolation from gameplay state, and lab stepping/character switching without simulation ticks. Final verification: all 120 scripts load, all 8 stock asset scenes import, all 43 GUT tests pass (2,105 assertions), and the main scene runs for 600 consecutive ticks without runtime errors. All earlier movement/status/cooldown regression tests remain included. Strict editor import still reports only the known restricted-session debugger-socket errors. Desktop rendering and manual visual calibration remain pending.

Manual check: restart the project and F5. Confirm the player is a red-clothed humanoid with a sword and the dummies are grey humanoids. Check idle, running around obstacles, alternating attacks, cancellation/retargeting, Q, and dummy death/respawn. Check that heads/hoods/arms remain coherent. Open F1 → Animation Lab; inspect both attack roles and mark the contact frames with M, then Esc back to the arena. Report visual defects or send a screenshot/clip if any occur. Headless geometry/pose checks do not prove desktop rendering quality.

Remaining M1: user visual calibration/approval, tuning/log export tooling, and full milestone regression. M1 is not marked complete and M2 has not started. Remote pushes remain blocked by this session's DNS restriction.


### 2026-11-14 — visuals accepted; debug exports completed

Ishak reported “Looks very nice. I like it.” Record the character appearance as accepted and preserve its current look. This does not automatically mark the attack profiles as manually calibrated or approve the full M1 milestone.

Added F1 buttons for exporting all active tuning overrides as a standalone .tres snapshot, resetting tuning to resource defaults, and exporting the full current arena combat log as CSV. Export names are unique and both exporters refuse to overwrite existing files. Generated files go under ignored `debug_exports/`; a .gdignore prevents treating exports as game assets. Existing .gdignore contents are preserved. Snapshot exports never rewrite source UnitStats/AbilityData resources or auto-load settings on startup. Reset synchronizes visible tuning controls without emitting new override changes.

CombatLog stores the whole arena run, separately from the last-200-event HUD window, with tick/event/source/target/value/extra columns. Payloads are captured by value and CSV quoting preserves structured text. F5 clears the run log for the new simulation epoch. Logs/exports are presentation/debug helpers and never affect simulation or RNG. The F1 panel now scrolls to keep its controls accessible.

Verification: all 123 scripts parse/load, all 8 stock scenes import, all 47 GUT tests pass (2,131 assertions), and the main scene completes 600 consecutive ticks without runtime errors. New tests cover snapshot round trips/source resource immutability/no overwrite, empty snapshots, CSV quoting/payload isolation, and retaining log rows beyond the HUD window. Strict editor import still reports the known sandbox TCP-listener errors; no gameplay changes were made in this slice.

Manual export check: change a value in F1, click Export tuning, then Reset tuning to file and confirm the control returns to its resource default. Attack/cast a dummy, click Export combat log, and find the files in `~/Projects/blood-powder/debug_exports/`. Exporting is explicit and never changes existing application/system configuration.

Remaining before M1 sign-off: visually mark attack_a and attack_b in the Animation Lab, then perform the final movement/attack/status/camera/reset regression. M2 remains gated on Ishak's explicit M1 approval.


### 2026-11-14 — animation fine-tuning deferred by user

Ishak said: “I like it we can fine tune animations later should there be need of it.” Keep the accepted movement, visuals, timing, and current hit markers unchanged. Manual fine-tuning is deferred until a later feel/visual issue warrants it. This user instruction supersedes the guide's requirement to manually mark both attack clips before the foundation handoff. The existing `calibrated=false` values remain truthful; no calibration was fabricated or performed automatically.

No gameplay/source resource/system configuration changes were made. The latest implementation still has 47 passing tests and a successful 600-tick scene smoke run; documentation-only updates do not require repeating those unchanged checks. The M1 implementation checkpoint is ready for final milestone sign-off; M2 has not been started in this documentation follow-up.


### 2026-11-14 — M1 accepted; M2 keg slice started

Following acceptance of movement/visuals and explicit deferral of fine animation calibration, Ishak instructed “Lets just keep going.” Treat this as approval to move beyond the M1 checkpoint and begin M2. Preserve current movement, attack timing, visuals, and deferred marker values. Work continues locally; do not spend effort retrying GitHub pushes in this slice. First M2 slice: E charge-based keg placement/decay/graph/chaining plus targeted Q Flintlock and homing projectile. Searing Edge, Ration, Broadside, and further polish follow as later M2 slices.

### 2026-11-14 — M2 work-in-progress handoff saved

At Ishak's request, saved `docs/SESSION_HANDOFF.md` before finishing the current slice so another session can resume without reconstructing tool history. Current branch is `feature/m2-captain-kegs`. Implemented Q/E controllers, pending/placed keg graph, decay, serial charges, exact chain queue, damage snapshots/hit-once tracking, homing projectiles, owned-keg attacks, prototype barrels/pips/rings/links, HUD/tuning, and pistol/throw animation roles. Searing Edge/W/R remain unimplemented. First complete integration verification passed 65 tests (2,214 assertions), all 132 scripts, 8 stock assets, and 600 runtime ticks; strict import failed only at the known sandbox debugger socket. Final expanded run is still to be collected. This handoff is not a claim that M2 is complete or that the user has playtested the new mechanics.


### 2026-11-14 — M2 Q/E keg slice verified and ready for playtest

Implemented targeted Q Flintlock and E powder-keg combos with guide-default cast times/ranges/cooldowns. Q homes at 26 m/s, crits physical damage, hits enemy units or owned live kegs, and fizzles if its target disappears. E reserves a pending ghost during the cast, validates walls/spacing, spends one of three charges, and serially recharges every 780 ticks. Out-of-range casts approach first and new move/attack input cancels that pending intent.

Kegs materialize after 15 ticks, decay from 3→2→1 at their locked-in tier, expire after 1500 ticks, connect within 6.9 m, and chain in a tick-keyed queue at 20-tick intervals. Pending nodes can join chains before materialization, supporting the one-part Q→E combo. Each chain snapshots damage/penetration/crit/slow parameters and tracks hit units once. A scheduled keg destroyed early keeps its original chain and cannot explode twice. Removed nodes and orphan chain payloads are cleaned up. Reset/respawn clears the controller, ghosts, schedules, projectiles, and charges.

Added prototype barrel geometry, health pips, decay rings, links, explosion radius overlay, orange blast feedback, targeted selection, Q/E cooldown/failure UI, E recharge progress, and resource-backed Q/E tuning. Pistol-shot/throw animation roles use existing stock libraries; a simple right-hand pistol swaps with the sword for shooting. Casts face their target. W/R/passive remain inactive in this first M2 slice. Existing movement/basic-attack defaults and the accepted red character appearance are unchanged.

Final verification: all 132 scripts load, all 8 stock scenes import, all 68 GUT tests pass (2,231 assertions), and the main scene completes 600 consecutive ticks without runtime errors. The M1 temporary-pulse regression fixture remains explicitly isolated with `captain_enabled=false`; the real arena and new Captain tests enable the controller. Strict editor import fails only at the already documented restricted-session debugger socket. No process is left running.

New tests include melee and Flintlock detonation, exact projectile/cast timing, target removal in flight, invalid placement/spacing, charge exhaustion/serial recharge, exact decay/expiry/graph boundaries, overlap hit-once behavior, scheduled-node double-explosion safety, live chain extension, pending materialization, snapshot offense, stun interruption, reset cleanup, and the one-part combo (root at tick 166, second keg at 186).

Playtest next: restart the project, place E on clear ground, wait until one pip, place another within 6.9 m, then Q or RMB the first keg. Use F2 for radii and F4 for events. Try two/three-keg chains and Q→E; F5 resets the training state. Full prop/VFX/audio polish is not part of this prototype slice. Stun retains the spent E charge/cooldown; that initial interruption choice is documented for later feel review.

Current checkpoint: `feature/m2-captain-kegs` with local commits only. Existing uncommitted `project.godot` editor formatting is preserved. Read `docs/SESSION_HANDOFF.md` first next session. Remaining M2: Searing Edge, W Ration, R Broadside, more training controls/polish, and full milestone acceptance before M3. Fine animation calibration remains deferred per Ishak's instruction.


### 2026-11-15 — W Ration implemented

Continued M2 with one vertical slice per the guide: W Ration. Added a resource-backed 15-tick self-cast, 18-second cooldown, completion-time heal of 100 + 13% missing health capped at max HP, and shared cleanse. Burn remains active. Integrated command routing, W cooldown/failure display, F1 tuning, green healing numbers/ring, combat-log healing events, reset/death handling, and previous-intent resumption. Q/E polish remains deferred; accepted movement/attack timings and visuals are preserved. Existing `project.godot` editor serialization remains untouched.

Known guide conflict: Ration lists stun cleansing, but the shared stun rule prohibits and interrupts all casts. Preserved the explicit shared rule: W cannot start while stunned and is interrupted by a new stun, retaining cooldown. A Ration-specific stun exception is a proposed future deviation requiring user approval; it was not silently implemented. Root/slow cleanse and burn preservation are implemented.

Manual playtest: restart the project, use F1 → Apply to player → Burn to lose some health, then press W. Confirm the short cast, green heal, cooldown, and continuing burn. Apply Root/Slow and W to remove them; test W during movement and F5 reset. Stun currently blocks/interrupts W as described above. No polished VFX/audio is claimed. Searing Edge and Broadside remain next; M2 is not complete.

Verification for the Ration slice: `python tools/verify.py` loaded all 132 scripts, imported all 8 stock scenes, passed all 72 tests / 2,256 assertions, and completed 600 main-scene ticks. The command exits failed only at editor import with the previously documented sandbox debugger TCP-socket restriction. `git diff --check` is clean.


### 2026-11-15 — W keyboard routing fix

Ishak reported that W did not activate. Traced the defect to InputRouter's action whitelist: `ability_w` existed in the input map and arena but was missing from the forwarded actions. Added W to the router. Full HP is allowed and still starts the cast/cooldown (healing is capped at max HP). Prior tests issued Commands directly and missed the raw keyboard path; added a physical KEY_W regression through InputRouter and the real arena, asserting W begins at full health and completes after 15 ticks.

Manual check: stop and restart the running game, focus the viewport, press W at full HP, and confirm the W cooldown and green ring. Use F1 Burn to lose HP, close the panel, then W after cooldown or F5 reset followed by Burn. Project settings and Q/E timing are unchanged.

W input fix verification: all 73 tests passed (2,261 assertions), all 132 scripts loaded, all 8 stock scenes imported, and the main scene ran 600 ticks. Strict verification still exits failed only for the known editor-import sandbox socket errors.


### 2026-11-15 — W input fix confirmed by user

Ishak reported “It works” after the W keyboard-routing fix. Record W activation as confirmed in desktop playtesting. No additional individual healing/cleanse scenarios or full M2 approval were reported. No code changes; latest verification remains 73 passing tests / 2,261 assertions and the 600-tick smoke check, with the documented editor-import sandbox socket limitation. Next M2 slices remain Searing Edge and Broadside; Q/E polish stays deferred.


### 2026-11-15 — Searing Edge slice

Implemented the Captain passive: a landed basic attack on an enemy applies a 150-tick burn (five 24 true-damage pulses), grants 25% movement speed for 120 ticks, and starts a 900-tick cooldown. Misses/cancellations, Q, and keg hits do not consume the passive. The first explosion of each keg chain resets readiness and grants the same nonstacking speed buff; child explosions do not repeat the reset. A direct KegManager signal drives gameplay and EventBus only logs results. Added P cooldown/readiness, F1 tuning, and orange blade emission while ready. Accepted attack timing and character appearance otherwise remain unchanged. Q/E polish remains deferred.

Added simulation checks for exact melee/burn timing and true damage, speed expiry, cancellation/Q exclusions, chain reset followed by a melee before the child explosion (no second reset), cooldown boundary, and reset cleanup.

Manual check: restart the game; P and the blade should indicate readiness. RMB a dummy, then S after one hit; watch five orange burn numbers and P's 15-second cooldown. Move during the two-second speed buff. Place linked kegs, wait for one pip and detonate; P should become ready again and speed should refresh. Q alone should not burn a dummy or consume P. F5 resets. Full flame particles/audio remain deferred; Broadside remains the next M2 slice. No M2 approval or M3 work is implied.

Searing Edge verification: `python tools/verify.py` loaded all 132 scripts, imported all 8 stock scenes, passed 77/77 tests (2,295 assertions), and completed 600 main-scene ticks. Strict editor import fails only with the previously documented restricted-session TCP socket errors. `git diff --check` passed. Desktop glow/feel still requires user playtesting.


### 2026-11-15 — Searing Edge playtest confirmed

Ishak reported “Works perfectly” after the Searing Edge handoff. Record the passive slice as confirmed in user playtesting. No implementation changes or additional verification run were needed; latest checks remain 77 passing tests / 2,295 assertions, 132 scripts, 8 asset scenes, and 600 runtime ticks, with the documented sandbox editor-import socket limitation. R Broadside is next. Q/E polish remains deferred, and M2 still requires completion and explicit milestone approval before M3.


### 2026-11-15 — R Broadside implemented

Implemented resource-backed R quick cast anywhere inside the arena: 15-tick cast, 1800-tick cooldown, 5.8 m fixed area for 480 ticks, twelve waves of 40 magic damage and 30% slow for 30 ticks. Wave offsets are measured from cast completion: +30/+45/+60 and three more clusters 120 ticks apart (last wave +420). Radius intersects target gameplay radius, consistent with existing area effects. Allies/kegs are excluded and no passive burn is applied. Cast parameters snapshot at zone creation; custom waves outside the tuned duration are excluded. Stun interrupts pending R, retaining cooldown; a completed zone continues through stun/death until expiry or controller reset/respawn. F5 clears all zones and cooldown.

Added R input routing (including the physical key), cooldown/failure UI, F1 tuning, full-duration ground ring, tick-based falling streaks/impact flashes, and seeded uniform-circle impact points. Cosmetic positions are drawn from the simulation RNG at creation; rendering never consumes gameplay RNG. Full VFX/audio remain later polish. Existing Q/E polish remains deferred.

Manual playtest: restart, point near a dummy and press R. Confirm short cast, orange area ring, falling cannonballs, blue damage in four clusters of three, slow, and 30-second cooldown. Walk away after casting; the area stays fixed. Cast at distant arena ground to confirm no approach. F4 shows wave ticks; F9/F10 pause/step the effect. F5 mid-bombardment must clear it and restore R. No M2 approval is inferred; final combo acceptance still needs user playtesting.

Broadside verification: `python tools/verify.py` loaded all 134 scripts, imported all 8 stock scenes, passed all 82 tests (2,352 assertions), and completed 600 main-scene ticks. Strict editor import still fails only with the documented sandbox TCP-socket errors. New tests cover all 12 exact wave ticks, full ring duration, slow expiry, area boundaries/moving targets, damage snapshot, global range, interruption/cooldown/reset, physical R forwarding, invalid ground, seeded impacts, and render RNG isolation. `git diff --check` passed. Desktop effects/feel await user playtest.


### 2026-11-15 — denser Broadside cannonball visuals

Ishak requested “much much more” falling models. Increased visuals from one to sixteen cannonballs per damage wave: 192 per default cast, with seeded positions across the area and ±5-tick stagger for a denser barrage. Added F1 `cannonballs_per_wave` tuning (1–32, snapshotted on cast completion), shared low-poly meshes/materials, and a 2048-visual cap for extreme custom wave settings. Cosmetic expansion uses a local RNG seeded from each existing wave anchor, so changing visual density preserves simulation RNG consumption, future crits, damage waves, slows, and cooldowns. This is a requested visual refinement, not a change to combat balance.

Added a regression comparing dense/sparse casts with the same seed, confirming equal simulation RNG state, wave anchors and relative schedules; checks default count and circle bounds. Manual check: restart, cast R near dummies, and inspect the denser staggered rain; use F1 cannonballs_per_wave for preference tuning. Rendering smoothness still needs desktop playtesting.

Density verification: all 83 tests passed (2,572 assertions), 134 scripts loaded, 8 stock scenes imported, and the 600-tick runtime check passed. Full `python tools/verify.py` still exits failed only for the known editor-import sandbox socket restriction. `git diff --check` passed.

2026-11-15: Ishak confirmed the denser Broadside visuals are “Much better” and authorized continued work, asking first for the documented map-art schedule and sourcing process. Record density feedback as accepted; this is not explicit full M2 milestone approval. Environment dressing is scheduled for M5, using the guide’s Quaternius dungeon/nature packs and Kenney Pirate Kit; verify actual archives/licenses before integration.


### 2026-11-15 — M2 training targets and final playtest aid

Added resource-backed F1 dummy controls: count 1–5, armor presets, 2000/10000 finite HP, infinite HP (default), Elite flag, selected-target damage/DPS, Reset damage / DPS, Restore player health, and explicit keg decay-tier selection. Settings apply on the next simulation tick; target settings reset/recenter dummies and preserve source resources. F5 preserves session settings and clears target damage; Reset tuning restores defaults. Damage/DPS use resolved amounts and simulation ticks, include idle time from first hit, and match combat-log overkill semantics for finite targets.

Added dedicated default-training tests for infinite lethal hits, burn retention, next-tick options, count/shared-target-array/selection safety, source-resource preservation, finite death/reset/default restoration, Elite keg bonus, player healing, and locked keg tiers. Existing M1/Captain combat fixtures explicitly opt out of training defaults so their finite-health assertions remain meaningful. Added docs/M2_PLAYTEST.md with final combo and training checks.

Stationary targets are implemented; strafe/chase behavior and enemy keg-attacking toggle remain later training/PvE work. Q/E polish is deferred and final map art stays M5. M2 manual acceptance still requires the guide's five consecutive three-keg chains on three dummies, plus explicit milestone approval before M3.

Training slice verification: all 88 tests passed (2,624 assertions), 136 scripts loaded, all 8 stock scenes imported, and the 600-tick main-scene smoke check passed. Full `python tools/verify.py` exits failed only at editor import with the known sandbox debugger TCP-socket errors. `git diff --check` passed. No desktop UI/playtest approval is claimed.


### 2026-11-15 — milestone-level communication requested

Ishak instructed continued autonomous work according to the docs and requested notifications at milestone inspection checkpoints rather than per-feature updates. Recorded in AGENTS.md. Maintain detailed implementation/verification records here, finish the current milestone implementation before inspection handoff, and retain the explicit approval gate before the next milestone. This communication preference is not automatic M2 approval.


### 2026-11-15 — final M2 training behavior and implementation audit

Continued autonomously per the milestone-level communication preference. Completed the remaining training behavior selector: Stationary / Strafe (3 m span at 3.45 m/s) / Chase slowly (1.5 m/s, stops at 2 m). All parameters live in TrainingSettings and are exposed in F1. Driver commands use existing integer-tick movement, pathfinding, and root/stun/slow behavior; pending commands are preserved. F5/settings changes reset patrol direction. Added the default-Off enemy keg-attacking toggle: dummies attack the nearest live in-range keg with normal melee timing; hits remove one pip and enemy destruction never explodes/reset-passives. Dummies do not attack the player or chase kegs. This is training-only behavior, not M3/Hunter or M4 challenge AI.

Added simulation coverage for strafe reversals/bounds/root/reset, slow chase/stop-mode switching, and Off→On keg destruction without an explosion. Updated final M2 playtest checklist. Existing accepted movement/abilities/visual density remain unchanged. Final inspection must still include the five consecutive three-keg chains and the known W guide conflict: global stun currently prevents its cast even though its ability table lists stun cleanse. Do not silently implement an exception or claim full milestone approval.


### 2026-11-15 — Ration stun exception approved and implemented

Asked Ishak to resolve the actual guide conflict: whether Ration should complete its 0.25-second cast while stunned and cleanse it. Ishak answered “yes,” approving the recommended Ration-only exception. Appended the effective amendment to the guide before implementation. W now starts during stun, survives newly applied stun, and heals/cleanses at its original completion tick. Normal cast lock/buffering, cooldown, death cancellation, and Q/E/R stun restrictions remain. W's HUD availability and avatar casting reflect the exception. Tests now cover physical W during stun, exact cleanse timing, retained buffered movement, new stun during W, W cooldown failure while stunned, and Q still rejected. The earlier conflict/approval limitation is resolved; historical log entries remain unchanged.


### 2026-11-15 — M2 implementation inspection checkpoint

All Captain implementation and training controls are ready for milestone inspection, with user-approved Ration stun exception included. Added docs/M2_ACCEPTANCE.md mapping each section-8 automated gate to its tests and refreshed SESSION_HANDOFF.md to reflect current behavior without stale decision requests. Initial patrol coverage exposed an incorrect test comparison between different phases of a full patrol; replaced that comparison with actual reversal/positive-negative span checks. Final verification has no test failures.

Final `python tools/verify.py`: 136 scripts load, 8 stock scenes import, 93/93 tests pass with 2,652 assertions, and main scene runs 600 consecutive ticks. Strict command exits failed only for the previously documented editor-import debugger TCP-socket restriction. `git diff --check` passed. No system/application configuration was changed; pre-existing project.godot serialization remains unstaged. Work remains local with no milestone merge/tag.

Remaining gate is user inspection/approval, including five consecutive three-keg chains on three dummies. Desktop feel and manual reliability cannot be claimed by headless checks. Preserve deferred Q/E/animation polish and M5 environment/VFX/audio schedule. No Hunter/M3 work was started.


### 2026-11-15 — barrel-link visibility feedback

Ishak requested more visible links during M2 inspection. Replaced the thin dark line with an amber ground ribbon and dark border; scheduled links brighten to pale gold. Default core width is 0.16 m plus 0.06 m border each side, tunable under F1 Powder Keg. Double-sided unshaded triangle strips provide stable thickness instead of hardware-dependent line widths. No graph, collision, or combat logic changed. Manual check: restart, place linked kegs and inspect the brighter/thicker trail; F1 link_width/link_border adjust thickness. M2 approval remains pending.

Link-visibility verification: 93 tests / 2,652 assertions passed, 136 scripts loaded, 8 asset scenes imported, and 600 runtime ticks passed. Strict verification retains only the known sandbox editor-import socket error. `git diff --check` passed; desktop visibility awaits inspection.


### 2026-11-15 — M2 inspection approved; M3 authorized

After final M2 inspection and the requested barrel-link visibility fix, Ishak said “Great, you may proceed.” Treat this as approval of the inspected M2 implementation and authorization for M3. No individual five-chain result was reported; do not invent that playtest detail. Preserve accepted Captain feel/visuals and deferred polish. New work branch: feature/m3-hunter. M3 is Apex Hunter and remains gated before M4. Milestone-only communication continues.

### 2026-11-15 — M3 Hunter implementation and audit

Implemented HunterController, Ferocity, HunterData resources/stats, brush Area3D center containment/vision rules, fixed-destination colliding leaps and visual arcs, airborne ability commands/movement buffer, Rend reset/protected first windup/AS/range/bonus, Howl grey HP/empowered cleanse, swept Bola cast/projectile/slow/root, Stalk camouflage/mark/armor shred, class switching, and Hunter HUD/tuning/visual adaptations. Preserved Captain scene defaults and shared combat regressions. Hunter is selected with F1; provisional green hooded stock human uses existing assets. Added grey health bar, claw/Ferocity state, leap/mark/aim overlays, jump animation and a substitute Howl cast pose. Final audio/VFX/map dressing remain M5; M4 AI/challenge was not started.

M3-specific checks cover section-9 timing/range/linger/ground-vs-airborne cast/reset/Ferocity/grey-health gates plus walls, dead/moving targets, protected first windup, buffered movement, camouflage/vision/armor expiry, Bola width/wall/launch origin, full Ferocity combo/empowered cooldown bypass, AS buff persistence, class switching, render RNG isolation, and reset cleanup. Initial validation caught Godot's imported `_Loop` suffix removal on Jump; corrected to the imported Jump clip. Existing accepted animation markers remain untouched.

Interpretations are recorded in ARCHITECTURE.md: leap distance is actual origin-to-landing-point travel, wall-blocked impact retains its original deadline, grey health remains reusable inside its rolling window, and the specific empowered Howl cleanse permits W during stun. No manual calibration or user feel approval is fabricated. See docs/M3_PLAYTEST.md for milestone inspection.

Local milestone provenance: created annotated m2-approved at cd07c59, the inspected barrel-link refinement checkpoint, after Ishak approved proceeding. Hunter implementation remains on feature/m3-hunter and has not been merged/tagged as approved.


### 2026-11-15 — M3 implementation ready for inspection

Completed the guide's M3 implementation and section-9 gate mapping in docs/M3_ACCEPTANCE.md, refreshed README/architecture/credits/session handoff, and retained Captain as the default startup class. F1 class selection exposes the completed Hunter with a provisional green hooded human. No M4/M5 implementation was started. Prior accepted Captain mechanics, Q/E polish deferral, and animation marker deferral remain intact.

Final full `python tools/verify.py` run: 143 scripts loaded, all 8 stock scenes imported, 113/113 tests passed with 2,758 assertions, Captain main scene and Hunter each completed 600 consecutive runtime ticks. Strict import failed only at the known restricted-session debugger TCP listener. A focused Hunter follow-up passed all 18 tests / 96 assertions after matching Hunter armor to the guide's 30 and adding a regression assertion. `git diff --check` and staged whitespace checks passed. Logs are in .local/m3-final-verification.log, .local/gut-suite.log, .local/hunter-final-focused.log, and per-stage verification logs. No verification process remains running.

M3 is an implementation inspection checkpoint, not fabricated feel approval. User must inspect brush leap → airborne Bola → Rend reset → empowered ability, Hunter look/camouflage/mark/grey health, interruptions and class-switch/reset cleanup, then explicitly approve M3 before M4. The stock Howl pose and provisional visuals are documented; final roar/audio/full VFX/map dressing remain M5. Existing unstaged project.godot serialization was preserved and excluded from the implementation commit; no system/application config changes or remote pushes were made.


### 2026-11-15 — function-key accessibility during M3 inspection

Ishak reported that F keys do not work in the game and asked whether Arch Linux is responsible. The exact desktop/hardware cause is unconfirmed. Project bindings are present, but the router previously handled debug keys only after GUI input, allowing focused controls to consume them. Routed reserved debug shortcuts before GUI handling, retained gameplay after GUI, and centralized dispatch for mouse controls. Added visible Tools (Tab/F1), Ranges, States, Log, Reset, Slower/Faster, Pause/Resume and Step buttons. Tab supports physical/logical events, ignores echo and preserves menu blocking. Buttons do not grab keyboard focus and blank toolbar area does not intercept world clicks. Existing input map and all system/editor/keyboard settings remain untouched.

Tests inject real viewport keyboard events with a focused SpinBox to verify Tab/F1, single-toggle/echo behavior; exercise toolbar signals for overlays/clock/reset, menu blocking, and class-switch persistence. Updated active playtest docs with function-key-free instructions. External Fn/media/desktop/editor interception remains possible; no unverified platform diagnosis is claimed.

Also connected the previously mapped but unforwarded F6 class-switch action. The focused input test exercises F6 through the real viewport, then steps the queued class change and verifies toolbar availability after the HUD rebuild. Synthetic input tests explicitly flush Godot’s buffered events before asserting state and release injected keys after each test.

Debug-control verification: all 117 tests passed (2,779 assertions), all 144 scripts loaded, 8 stock asset scenes imported, and Captain/Hunter each ran 600 ticks. Focused debug-input checks passed 4/4 tests (20 assertions). Full verification retains only the known sandbox editor-import TCP-listener error. `git diff --check` passed. Exact host F-key interception remains unconfirmed; Tools/Tab/mouse alternatives are ready for desktop inspection.


### 2026-11-15 — automatic Hunter jump-range circle

Ishak confirmed the debug-control workaround works “amazingly” and requested a character-centered leap-range circle from brush or R. Added a bright outlined ring independent of F2, automatically green for brush/linger and gold for Stalk camouflage after the two-second warmup. It follows the interpolated actor, reads actual leap eligibility, and hides during flight/root/stun/death or Captain selection. Radius uses the same configured edge range plus Hunter gameplay radius (8.1 m default); width is visual-only tuning in Tools. Cached annulus geometry has no collision or RNG influence. Removed the duplicate F2 leap ring while retaining other overlays.

Added integration checks for automatic display with F2 off, brush/linger expiry, root/in-flight hiding, R warmup, range tuning, class-switch cleanup, and rendering RNG isolation. Manual check: restart/select Hunter, enter/exit brush, and cast R outside brush; the circle should appear in brush and turn gold when R grants camouflage after two seconds. This feedback does not imply full M3 approval.

Automatic leap-circle verification: all 119 tests passed (2,791 assertions), all 145 scripts loaded, 8 stock scenes imported, and both Captain/Hunter 600-tick runtime checks passed. Strict verification retains only the known sandbox editor-import socket failure. `git diff --check` passed. Desktop appearance remains for user inspection.


### 2026-11-15 — end-of-session handoff saved

At Ishak's request, consolidated docs/SESSION_HANDOFF.md for the next session with milestone status, exact gameplay checkpoints/branch, launch commands, Tools/Tab/mouse alternatives, Hunter/Captain mechanics and training, approved/deferred choices, asset sourcing schedule, final verification, and persistent workspace/Git constraints. User positively confirmed the debug-control workaround and automatic jump circle. M3 is implemented/verified and awaiting explicit final milestone approval; M4 has not begun. Do not infer a full manual combo sign-off from individual positive feedback.

Latest gameplay commit is 1a4610d on feature/m3-hunter. Latest complete verification remains 119 passing tests / 2,791 assertions, 145 scripts, 8 stock scenes, and separate Captain/Hunter 600-tick smoke checks; only the known sandbox editor-import socket error remains. No code changed in this handoff and no unchanged tests were rerun. Pre-existing project.godot editor serialization remains unstaged and preserved. Next work is M3 feedback/approval, then guide-defined M4; M5 art/textures/audio/export remain later.

## 2026-11-15 — M3 approved; M4 authorized

Ishak explicitly approved M3 and instructed completion of M4, reporting at the milestone checkpoint or when information is needed. Working on `feature/m4-pve`; M5 remains gated. Existing unstaged project.godot serialization is preserved.


## 2026-11-15 — M4 implementation and inspection preparation

- Implemented guide-stat Chaser, Kiter and Elite resources/AI; ranged travel/wall interception; fixed-center uninterruptible slam and stun; brush/camouflage sight memory and return; opt-in keg attacks; fixed-tick crowd spreading.
- Added resource-backed waves, exact opening/inter-wave delays, Victory/Defeat statistics and panels, no Challenge respawn, class-aware reset, persistent mode controls and return to configured Training.
- Added exact-precision command recordings and validated binary save/load with seed/class/mode/tuning initialization and byte-for-byte whole-log comparison. Full successful stock-stat runs for both classes reproduce. Runtime tuning/debug changes require Reset before recording; playback rejects gameplay input and interrupts on tuning changes.
- Fixed navigation initialization exposed by replay: the first movement queried a map before synchronization; replay could therefore follow a different route. Navigation map iterations now initialize synchronously and readiness waits for map synchronization; retargeted path queries refresh before finished checks. Existing navigation clearance and player movement stats are preserved.
- Added focused challenge/replay tests, full-run command pilots and Challenge smoke stage. Existing Captain, Hunter, movement, training and debug gates remain required. `verify.py` accelerates frame-driven tests with fixed render delta and gives the expanded suite a 300-second timeout.
- **Proposed deviation requiring approval with M4 inspection:** replace the guide's asynchronous NavigationAgent avoidance velocity solver with synchronous stable-order crowd separation. This keeps combat motion on admitted 60 Hz ticks and supports exact replay/pause/slow/step. NavigationAgents remain for paths; chase repaths remain six ticks. The original guide was not changed. See ARCHITECTURE and M4_PLAYTEST for details.
- Automated pilots use ordinary player commands and unmodified resource stats, with no artificial healing/damage/teleports. Their exact state/timing knowledge is stronger than human play; human balance/feel remains an inspection limitation. Environment art, final enemy costumes, final VFX/audio and exports remain M5. No external assets or network writes were needed.
- Existing unstaged `project.godot` editor serialization is preserved and excluded from implementation commits. No system/application settings were changed. Work remains local; no GitHub retry was attempted.

Latest required run: `python tools/verify.py`, full output in `.local/m4-inspection-verification.log`.

- **134/134 GUT tests passed, 2,863 assertions across 17 scripts** (68.614 seconds).
- All **155 scripts** loaded; all **8 stock asset scenes** imported.
- Captain, Hunter and Challenge each completed **600 consecutive simulation ticks**.
- Both full successful class recordings replayed with identical serialized combat-log bytes. A focused replay scenario also passes with extra physics/render frames between playback ticks.
- Strict verification exits failed **only at editor import**, with the previously documented sandbox TCP listener errors (`_sock == -1`, `ERR_CANT_CREATE`). No gameplay/import errors were suppressed. Run `python tools/verify.py` from an unrestricted normal terminal for a strict editor-import result.
- `git diff --check` passed. All verification processes completed. Documentation-only handoff edits do not require repeating gameplay checks.

M4 is ready for inspection. Full command pilots: Captain clear 110.02 s / 1,757 damage taken / 313.01 HP remaining; Hunter clear 100.35 s / 319 damage taken / 690.38 HP remaining. Both saved full runs reproduce identical logs and Victory. Human balance and the proposed crowd-avoidance guide refinement await approval. Local `m3-approved` tags accepted checkpoint `1902821`. M4 has not been merged/tagged and M5 has not started.
