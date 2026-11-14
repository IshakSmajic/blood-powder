# Progress

## Active milestone: M1 — foundation

Ishak explicitly approved M0 and proceeding to M1. M0 setup is accepted; remote synchronization remains pending because this session cannot resolve GitHub.

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

Working branch: `setup/m0-foundation`. The setup slice is committed locally using Ishak's configured author and committer identity, with no co-author trailers. Push was attempted and failed because this session cannot resolve `github.com`; there is no remote branch/PR yet. Working tree was clean after the setup commit. No milestone tag or merge has been made.

## Current verification

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
