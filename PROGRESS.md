# Progress

## Active milestone: M0 — setup

M0 is in progress. M1 is not authorized until Ishak approves M0.

- [x] Private repository created and cloned at `~/Projects/blood-powder`.
- [x] Standalone Godot 4.7.2 installed; Ishak confirmed the editor opens.
- [x] Original guide and approved visual concept preserved in `docs/`.
- [x] Project structure, scene, input map, core autoloads, and session docs created.
- [x] GUT 9.7.1 addon vendored with license and enabled locally in this project.
- [x] All 96 GDScripts load; all 9 GUT tests pass; main scene runs for 600 ticks.
- [ ] Strict verification exits successfully outside restricted session (editor debugger socket error here).
- [ ] Ishak launches the actual project and approves the grey test room.
- [ ] Matching 4.7.2 export templates installed.
- [ ] Initial character/animation packs obtained and actual files inspected.
- [ ] Branch pushed for review; milestone merged/tagged after approval.

## Current verification

Verified locally with Godot `4.7.2.stable.official.ed1daf0bf` and GUT 9.7.1:

- All-script loader: 96 scripts load successfully, exit 0, no script errors.
- GUT: 9/9 tests, 729 assertions, zero failures, exit 0.
- Main-scene smoke: 600 consecutive simulation ticks, exit 0, no runtime errors.
- Editor import completed and generated the project cache, but reported sandbox socket errors (`_inet_open` and `TCPServer.listen` / `ERR_CANT_CREATE`). These are not suppressed: strict verification remains failed for the import stage until checked outside this restricted session.
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
- Export templates, stock character packs, final visuals, and exports are not part of the implemented test room.
- Generated concept HUD and arena proportions are illustrative; mechanics/layout must follow the guide.

## Open decisions

- Keep the concept's human hooded Hunter appearance unless Ishak requests a change; exact stock body/outfit selection remains pending asset inspection and approval in M1.
- Final code license has not been selected. No license for project-owned code is implied by vendored MIT dependencies.
