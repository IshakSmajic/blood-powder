# Progress

## Active milestone: M2 — Powder Captain

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
