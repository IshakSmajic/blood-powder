# Session handoff — M4 inspection checkpoint, 15 November 2026

Read this file, AGENTS.md, PROGRESS.md, ARCHITECTURE.md and the relevant development-guide section before gameplay changes.

## First action next session — PC migration and review

Ishak requested that the next session explicitly ask for an M4 review after moving the project to his PC. Help restore/open the project on that PC first, then request the review using `docs/M4_PLAYTEST.md`, including the proposed deterministic crowd-separation refinement. M4 is not approved; do not start M5.

The project repository contains the used assets and vendored GUT. On the PC, clone the repository, check out `feature/m4-pve`, install the pinned Godot 4.7.2, open `project.godot`, let assets import, then run the verification script with `GODOT_BIN` pointing to that PC's engine executable. Paths in older notes refer to this Linux machine. Ignored `.local/`, `.godot/`, `debug_exports/`, external raw packs and installed engine/export templates are not transferred by Git; copy any wanted replays/tuning exports separately.

On 15 November Ishak explicitly requested pushing everything to GitHub, superseding the earlier no-retry instruction for this synchronization. The existing editor serialization of `project.godot` is included in the migration checkpoint, separately from the M4 implementation commit.

GitHub synchronization attempt failed on DNS (`Could not resolve host: github.com`); no successful remote synchronization is claimed. All changes are locally committed. A transfer bundle is available at `/home/aurelius/Downloads/blood-powder-migration.bundle`, containing all local branches and tags. It can be cloned on the PC with `git clone blood-powder-migration.bundle blood-powder`, then `git switch feature/m4-pve`; replace the bundle origin with `https://github.com/IshakSmajic/blood-powder.git` before later pushes. To upload from this machine once DNS works: `git push origin --all` and `git push origin --tags`.

## Resume checkpoint

- Project: `/home/aurelius/Projects/blood-powder`.
- Branch: `feature/m4-pve`.
- M0–M3 are explicitly approved. M3 approval was received in this session before any M4 implementation; local `m3-approved` points to the accepted M3 checkpoint `1902821` (latest gameplay there is `1a4610d`).
- M4 implementation is ready for inspection after verification below. **Do not start M5 until Ishak explicitly approves M4.** No M4 merge/tag has been made.
- User requested autonomous work through the milestone and a report only when finished, except actual blockers or needed decisions. Keep that communication preference.
- No M5 environment art/textures, final audio/VFX, camera polish or exports have begun.

## Open and inspect

```bash
~/Applications/Godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64 --editor --path ~/Projects/blood-powder
```

Press F5. The game starts in Training as Captain. Use **Tools** (mouse or Tab) to choose Apex Hunter. Click the top **Challenge** button to start the three-wave encounter. Advance toward enemies: acquisition is within 12 meters. Function keys are optional.

Full inspection instructions: `docs/M4_PLAYTEST.md`. Automated gate mapping: `docs/M4_ACCEPTANCE.md`.

- Wave 1: four Chasers, 180 ticks after start. Wave 2: three Chasers/two Kiters, 240 ticks after clear. Wave 3: Elite/two Chasers, 240 ticks after clear.
- Kiters retreat below 5 m, attack through 6.5 m, launch 15 m/s projectiles and respect walls. Chasers pursue visible targets, remember the last seen point for 180 ticks, then return to spawn.
- Elite uses a fixed-center red slam warning, radius 2.5 m, 60 ticks of warning, 120 magic damage/60-tick stun, 480-tick cooldown from warning start. Stun/root cannot cancel a started warning; death cancels it. Dodge the circle.
- Both classes get ordinary brush hiding. Hunter keeps brush leap and Stalk camouflage. Recent hits reveal to the damaged observer. Hidden players are searched at their last observed point.
- Challenge never respawns player/enemies. Victory/Defeat panels show clear time, damage taken and wave, with Retry/Training/Save actions. Reset preserves class and tuning. A Challenge class switch restarts the encounter; Training class switching retains its accepted clock behavior.
- Tools has live enemy stats/behavior tuning; behavior timers are ticks. Keg attacking is off by default; the existing explicit training toggle also applies in Challenge. Kiters use traveling shots against kegs and enemy destruction never explodes them.

## Replay workflow

Choose class and tuning, then Reset. Commands are recorded automatically. Click **Save replay**, then **Load replay** and choose a `.bpr` under `debug_exports/`. Playback restores seed/class/mode/tuning, suppresses gameplay input and checks the full serialized combat log byte for byte at the saved final tick. It pauses with MATCH or MISMATCH. Camera/overlays/pause/speed/Step remain available. Reset exits playback. Mode buttons admit a transition tick even when paused.

Runtime tuning/debug changes invalidate saving until Reset. Applying debug statuses is ignored during playback; changing tuning explicitly interrupts it. Replays require the same gameplay code/resources and pinned engine. Binary loading disables object deserialization and validates before resetting gameplay. Exports are explicit and ignored by Git; source resources are not overwritten.

## Proposed guide refinement requiring M4 inspection approval

The guide specifies NavigationAgent avoidance. M4 keeps asynchronous server velocity avoidance disabled and instead uses synchronous stable-order crowd separation with bounded fixed-tick collision motion. NavigationAgents still compute paths, chase repaths remain six ticks, and walls/root/stun/slam states are respected. This keeps spreading deterministic under pause/slow/step/replay. The original guide is unchanged. The deviation is explicitly recorded in PROGRESS, ARCHITECTURE and M4_PLAYTEST; ask for its acceptance as part of M4 inspection, not silently treat it as already approved.

## Important implementation details

`ChallengeEncounter` owns wave/outcome state; `EnemyUnit` extends only ranged hits/visibility, and `EnemyAI` emits ordinary commands. Shared CombatUnit changes are command-record notification, opt-out respawn and authoritative per-source damage timestamps. Player class mechanics and Captain red appearance are preserved.

Replay exposed an initial unsynchronized-navigation query: first-run move could select origin while replay got the real path. Arena now disables asynchronous map iterations before setup and waits for nonzero map iteration before accepting simulation commands. Movement refreshes its path before checking navigation-finished status. Arena geometry/navmesh clearance and player movement parameters are unchanged.

Simulation order and replay initialization are documented in ARCHITECTURE. Presentation consumes no combat RNG. New enemies use the existing stock grey avatars; no new assets/licenses were needed. Human balance/feel and warning readability still require inspection; exact-state automated pilots are stronger than human play.

## Verification

Latest required run: `python tools/verify.py`, full output in `.local/m4-inspection-verification.log`.

- **134/134 GUT tests passed, 2,863 assertions across 17 scripts** (68.614 seconds).
- All **155 scripts** loaded; all **8 stock asset scenes** imported.
- Captain, Hunter and Challenge each completed **600 consecutive simulation ticks**.
- Both full successful class recordings replayed with identical serialized combat-log bytes. A focused replay scenario also passes with extra physics/render frames between playback ticks.
- Strict verification exits failed **only at editor import**, with the previously documented sandbox TCP listener errors (`_sock == -1`, `ERR_CANT_CREATE`). No gameplay/import errors were suppressed. Run `python tools/verify.py` from an unrestricted normal terminal for a strict editor-import result.
- `git diff --check` passed. All verification processes completed. Documentation-only handoff edits do not require repeating gameplay checks.

Automated stock-stat command pilots clear both classes and reproduce their whole successful runs byte for byte:

- Captain: 110.02 seconds, 1,757 resolved damage taken, 313.01 HP remaining.
- Hunter: 100.35 seconds, 319 resolved damage taken, 690.38 HP remaining.

These are automated feasibility/regression results, not user playtest or final difficulty approval. Pilots use ordinary commands and no artificial healing/damage/teleport/tuning during a run.

## Persistent constraints and next steps

- The pre-existing `project.godot` editor serialization was preserved through M4 implementation and is included in the subsequent user-requested migration checkpoint. It is not an M4 gameplay change.
- User requested GitHub synchronization for PC migration on 15 November; consult the latest PROGRESS entry for the actual push result. Do not claim remote success without verification.
- Preserve configured Git identity and never add AI authorship/coauthor trailers.
- No system, shell, desktop or other application configuration changes without explicit approval.
- Keep authoritative combat at integer 60 Hz. Raw asset packs remain external; used asset licenses belong in CREDITS.
- F keys are unavailable for the user; keep mouse toolbar and Tab access. No established OS/hardware diagnosis exists.
- Captain Q/E polish and fine animation calibration remain deferred by the user. Existing provisional markers are not falsely calibrated.
- Address M4 feedback, including human balance/readability and the disclosed avoidance refinement. Do not repeat unchanged verification just to reconstruct context.
- Once M4 is explicitly approved, record it before M5 environment dressing, final VFX/audio/camera work, credits and Linux/Windows offline exports. Preserve arena collision/navigation while dressing it.
