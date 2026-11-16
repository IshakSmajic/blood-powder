# Session handoff — M5 polish and export

Last updated: 15 November 2026. Read `AGENTS.md`, `PROGRESS.md`, `ARCHITECTURE.md`, and the relevant sections of `docs/mvp_development_guide.md` before further gameplay changes.

## Current status

- M0–M4 are approved. Ishak accepted M4 on 15 November 2026 with “It works perfectly. You may proceed.” This authorizes M5.
- M5 is active on `feature/m5-polish`, based on the updated `Main` branch. Do not merge or tag M5 before Ishak approves it.
- M1 animation fine-tuning remains deferred. Keep game outcomes, timers, collision and navigation independent of presentation.
- The Windows Godot 4.7.2 standard executable is in ignored `.local/tools/godot-4.7.2/`. Python 3.14 is available.

## M5 work in this branch

- Added 15 selected Quaternius environment GLBs and built a visual dressing layer for the 36×28 m arena. Existing static collision shapes, brush gameplay and navigation bake inputs remain authoritative and unchanged.
- Added EventBus driven hit sparks/flash, critical visual hit-stop and shake, keg fire/smoke/scorch, ability bursts/rings, leap trail/dust and Elite slam feedback. Generated PCM SFX run offline in memory; no downloaded sound files or runtime network calls.
- Added a pause panel with Resume, Credits, Restart and Quit, plus an in-game credits text file.
- Added portable Windows and Linux x86_64 export presets. Local export templates are in ignored `.local/`; raw environment downloads are outside the repository. Build outputs are in ignored `builds/`.
- M5 manual inspection steps are in `docs/M5_PLAYTEST.md`. License/source/hashes are documented in `CREDITS.md` and `docs/m5_asset_manifest.json`.

## Verification and build checkpoint

`python tools/verify.py` passed with Godot 4.7.2. Results: 158 scripts parsed; 8 stock character/animation scenes and 15 environment models imported; 134/134 GUT tests and 2,863 assertions passed in 572.746 seconds; Captain, Hunter and Challenge all passed 600-tick smoke runs. Its Windows path redirects Godot app-data/log writes into `.local/` and omits `--fixed-fps` for GUT; smoke scripts still use fixed 60 Hz. Details are in `PROGRESS.md`.

Final export presets produced Windows/Linux executables after the last particle/cleanup fixes: `builds/BloodAndPowder.exe` (370,261,400 bytes) and `builds/BloodAndPowder.x86_64` (334,653,128 bytes, ELF64). The Windows build ran headlessly for 1,200 frames without script errors. A real Linux host/VM is not installed (WSL is unavailable), so Linux execution still requires Ishak's PC/VM inspection.

The Windows sandbox logs `Failed to read the root certificate store` on Godot start. Verification filters only that known platform restriction; the offline project has no network feature. Report it as an environment limitation, not as a project pass/failure.

## Local state to preserve

- Before M5 work, the new-PC Godot editor had already modified tracked existing `.import` sidecars and `project.godot`. These are user/device serialization state. Preserve them, and exclude them from implementation commits unless a specific change is required.
- New environment `.glb.import` sidecars are part of the M5 asset pipeline and should be committed along with their source GLBs.
- Do not add `.local/`, `.godot/`, generated `builds/`, export templates, or raw packs to Git. Do not change desktop/system/application settings.
- Preserve Ishak's Git identity; never add AI attribution trailers.
- M5 implementation remains as working-tree edits on `feature/m5-polish`. The restricted sandbox denied writing `.git/index`, so nothing was staged or committed; the user's existing `project.godot` and old `.import` edits were left untouched.

## Next checkpoint

Present the M5 build for Ishak's visual/audio/platform playtest using `docs/M5_PLAYTEST.md`. Then record actual Windows/Linux offline launch results and any final feel adjustments. Do not merge/tag M5 before explicit approval; do not claim offline user-machine testing until it has actually been done.
