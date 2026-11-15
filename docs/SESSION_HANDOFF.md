# Session handoff — 15 November 2026

Read `AGENTS.md`, `PROGRESS.md`, `ARCHITECTURE.md`, and the relevant guide section before continuing. This file is a concise restart aid; the dated work log is in PROGRESS.md.

## Current work

- Workspace: `/home/aurelius/Projects/blood-powder`.
- Branch: `feature/m2-captain-kegs`, based on local tag `m1-approved`.
- M0 and M1 accepted. User explicitly deferred finer animation calibration; keep current markers and do not invent calibrated values.
- On November 15, Ishak confirmed Q/E functionality after playtesting and explicitly deferred polish. No specific defects were reported; this is not full M2 approval.
- M2 first slice is being implemented: Q Flintlock + E keg placement, decay, charges, graph, and chains. **M2 is not complete.** W Ration is now implemented as a separate slice. Searing Edge and R Broadside remain later M2 work.
- User wants local progress; GitHub pushes have never succeeded because this session cannot resolve GitHub. Do not repeatedly interrupt work for pushes.

## Implemented Q/E slice (code checkpoint on current branch)

- `classes/powder_captain/captain_controller.gd`: targeted Q, homing projectiles, ground E, approach-then-cast, placement checks, charge pool, interruption/reset integration.
- `classes/powder_captain/keg/`: KegData, ChargePool, KegState, KegGraph, PowderKeg view, KegManager. The graph includes pending placements. Scheduled chains propagate in 20 ticks and track a shared damage payload/hit set. Decay tier locks at materialization; lifetime is 1500 ticks by default.
- `data/abilities/flintlock.tres`, `powder_keg.tres`: guide defaults. Q damage is 40 + 100% AD, physical, crit capable; cast 15 ticks, speed 26 m/s, cooldown 270 ticks. E: 3 charges, serial recharge 780 ticks, 15-tick cast, 30-tick recast lock, 60-tick decay, 6.9 m links, 3.45 m blast.
- Shared UnitCommand gains a slot; CombatUnit supports a class cast controller, active cast runner, pending approach, and attacking targetable keg nodes. Original movement/attack defaults are preserved.
- Arena enables Captain by default. The M1 regression fixture explicitly sets `captain_enabled=false` to retain its temporary Training Pulse tests. New Captain tests use the actual enabled controller.
- HUD has Q/E cooldowns, keg charges/recharge ring, separate live tuning, and owned keg selection. Existing selected targets may be freed; HUD validates them first.
- CharacterAvatar/AvatarLibrary add stock pistol-shot and throw roles, swapping a simple procedural pistol/sword in the right hand. Existing red outfit and model appearance remain.
- `tests/unit/test_keg_graph.gd`, `tests/sim/test_captain.gd` cover new logic.

## Final verification

- **72/72 tests passed**, **2,256 assertions**; all **132 scripts** load; all **8 stock asset scenes** import; the actual main scene runs **600 consecutive ticks** without runtime errors.
- Includes actual melee keg detonation, a Q target removed in flight, empty-charge failure, Q facing its target, two/three-keg propagation, pending-keg one-part combo at ticks 166/186, snapshot damage, serial recharge, decay/lifetime boundaries, reset/stun cleanup, and the retained M1 regression fixture.
- `python tools/verify.py` still exits failed only because editor import attempts a debugger TCP listener blocked by this restricted session. Do not suppress unknown errors or claim strict success here. The user previously ran checks in a normal terminal and verified this environment distinction.
- Logs: `.local/gut-suite.log`, `.local/600-tick-main-scene-smoke-test.log`, `.local/all-script-parse.log`, `.local/stock-asset-imports.log`. No test process is left running.
- No further automated reruns are needed unless code changes, failures, or a new concern justify them.

## Important semantics / limitations

- Simulation phase: debug commands; Captain pre-tick (charges, live decay/expiry, due chains); unit ticks/cast completion; projectiles; final due-chain pass. Pending kegs materialize on successful E cast completion, not automatically from the graph.
- Stun cancels pending E and keeps the spent charge/cooldown. This is an explicit initial interruption choice; refine if playtesting requires it.
- A scheduled keg destroyed early uses the existing chain payload, and its later queue entry is safely ignored.
- Chain damage snapshots triggering raw damage, crit bonus, penetration, elite bonus, slow magnitude/duration at root detonation. Critical payload uses an additional 1.05 multiplier by default; elite bonus is added afterward. This interpretation is documented/tunable.
- Kegs are nonblocking procedural prototype barrels, not a downloaded Kenney prop. Full VFX/audio/prop polish is later work.
- F5/respawn resets the Captain controller, projectiles, kegs, charges, and queues. Fine animation calibration remains deferred per user.

## Next steps

1. The tested Q/E implementation and documentation are committed on `feature/m2-captain-kegs`; inspect `git log -1` for the checkpoint. Only pre-existing editor serialization in `project.godot` should remain unstaged.
2. Q/E has been user-playtested: functionality confirmed, polish deferred. Detailed individual scenario results were not supplied. Revisit polish later when specific feedback is available.
3. Preserve accepted movement/attack timings and character appearance while continuing the remaining M2 abilities.
4. Playtest W Ration: F1 Burn to lose HP, W to heal; Root/Slow then W to cleanse; burn remains. Existing global stun rules block/interrupt W (the guide conflict is recorded in PROGRESS.md). Continue later M2 slices with Searing Edge passive/reset and R Broadside. M2 is incomplete; do not start Hunter/M3 before M2 approval.
5. Keep all progress local as requested. No successful push has occurred; no AI co-author/authorship trailers are permitted.

## Persistent user constraints

- No system/shell/application config edits without approval. Project-local implementation and explicit debug exports are authorized.
- Preserve the accepted movement/attack feel and red stock character appearance.
- Keep PROGRESS.md updated each session/handoff.
- Never add AI authorship/co-authorship to commits or GitHub submissions.

## November 15 Ration checkpoint

W Ration is implemented: 15-tick cast, 1080-tick cooldown, 100 + 13% missing HP healing on completion (capped), shared cleanse, W HUD/tuning, green healing feedback. Root/slow are removed and burn retained. The guide's global stun prohibition is preserved; a W-specific exception needs approval before implementation. New simulation coverage checks completion boundaries, healing/cap, cooldown failure, burn retention, stun interruption, movement resumption, death, and reset. No changes to Q/E timing or accepted visuals.

Ration verification: 132 scripts, 8 stock scenes, 72 tests / 2,256 assertions, and 600 runtime ticks passed. Strict editor import still fails only with the known restricted-session socket errors.


### W keyboard correction

The first Ration checkpoint missed `ability_w` in InputRouter's forwarded action list. Fixed after Ishak's playtest report; restart the running game to load it. W is usable at full HP and consumes cooldown. The new regression uses a physical W key through the router and real arena rather than issuing a Command directly.

W input fix verification: all 73 tests passed (2,261 assertions), all 132 scripts loaded, all 8 stock scenes imported, and the main scene ran 600 ticks. Strict verification still exits failed only for the known editor-import sandbox socket errors.
