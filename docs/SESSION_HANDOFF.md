# Session handoff — 15 November 2026

Read `AGENTS.md`, `PROGRESS.md`, `ARCHITECTURE.md`, and the relevant guide section before continuing. This file is a concise restart aid; the dated work log is in PROGRESS.md.

## Current work

- Workspace: `/home/aurelius/Projects/blood-powder`.
- Branch: `feature/m2-captain-kegs`, based on local tag `m1-approved`.
- M0 and M1 accepted. User explicitly deferred finer animation calibration; keep current markers and do not invent calibrated values.
- On November 15, Ishak confirmed Q/E functionality after playtesting and explicitly deferred polish. No specific defects were reported; this is not full M2 approval.
- Q/E, W, and Searing Edge are implemented and user-playtested; Q/E polish is deferred. R Broadside is implemented and awaiting playtest. **M2 is not complete or approved.**
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

- **82/82 tests passed**, **2,352 assertions**; all **134 scripts** load; all **8 stock asset scenes** import; the actual main scene runs **600 consecutive ticks** without runtime errors.
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
4. Playtest W Ration: F1 Burn to lose HP, W to heal; Root/Slow then W to cleanse; burn remains. Existing global stun rules block/interrupt W (the guide conflict is recorded in PROGRESS.md). Playtest R Broadside, then finish the M2 combo/manual acceptance checks before milestone approval. M2 is incomplete; do not start Hunter/M3 before M2 approval.
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

User subsequently confirmed “It works” after the W input fix. W activation is desktop-playtest confirmed; no full M2 approval is implied. Searing Edge and Broadside remain next.


## Searing Edge checkpoint

Passive implemented: next landed enemy basic attack burns for 5 × 24 true damage at 30-tick intervals, grants 25% speed for 120 ticks, and starts 900-tick cooldown. Q/keg hits do not consume/apply it. KegManager's direct chain signal resets passive and grants speed on the first explosion only; child nodes cannot reset it again. Same-source speed refreshes without stacking. P HUD, F1 tuning (damage per pulse), and ready blade glow are present. Playtest melee → stop/burn → keg detonation/reset; R Broadside remains next. Q/E polish and full VFX/audio remain deferred.

Searing Edge verification: `python tools/verify.py` loaded all 132 scripts, imported all 8 stock scenes, passed 77/77 tests (2,295 assertions), and completed 600 main-scene ticks. Strict editor import fails only with the previously documented restricted-session TCP socket errors. `git diff --check` passed. Desktop glow/feel still requires user playtesting.

Searing Edge playtest: Ishak confirmed “Works perfectly.” The passive slice is user-confirmed; R Broadside is next. M2 is not yet complete or approved.


## Broadside checkpoint

R implemented: physical R quick-casts at cursor ground anywhere inside arena. Cast 15 ticks/cooldown 1800 ticks; fixed 5.8 m area lasts 480 ticks from completion. Twelve 40-magic/30%-slow waves at completion offsets 30/45/60, 150/165/180, 270/285/300, 390/405/420. Resource-backed parameters snapshot on completion. Area-wide damage checks enemy gameplay radii; cannonball points are cosmetic and generated from the shared seeded RNG at creation. Persistent ring/streaks/impact flashes are tick-based prototypes; no final audio/VFX. Stun/death interrupts pending R, keeping cooldown. Completed zones persist until expiry/reset/respawn. F5 clears zones and R. HUD, F1 tuning, R failure feedback, and input route included. Playtest R near dummies and F5 mid-effect; finish M2 manual combo acceptance before approval/M3.

Broadside verification: `python tools/verify.py` loaded all 134 scripts, imported all 8 stock scenes, passed all 82 tests (2,352 assertions), and completed 600 main-scene ticks. Strict editor import still fails only with the documented sandbox TCP-socket errors. New tests cover all 12 exact wave ticks, full ring duration, slow expiry, area boundaries/moving targets, damage snapshot, global range, interruption/cooldown/reset, physical R forwarding, invalid ground, seeded impacts, and render RNG isolation. `git diff --check` passed. Desktop effects/feel await user playtest.


### Broadside density feedback

Ishak requested many more falling models. Broadside now defaults to 16 cannonballs per wave (192 per cast), spread across its area with ±5-tick staggering. F1 exposes cannonballs_per_wave (1–32). Each existing seeded wave anchor initializes a separate cosmetic RNG; visual density does not alter the simulation RNG, damage, slow, or wave schedule. Shared low-poly resources and max 2048 visuals bound the prototype. Restart and playtest density/performance; M2 approval remains pending.

Density verification: all 83 tests passed (2,572 assertions), 134 scripts loaded, 8 stock scenes imported, and the 600-tick runtime check passed. Full `python tools/verify.py` still exits failed only for the known editor-import sandbox socket restriction. `git diff --check` passed.

2026-11-15: Ishak confirmed the denser Broadside visuals are “Much better” and authorized continued work, asking first for the documented map-art schedule and sourcing process. Record density feedback as accepted; this is not explicit full M2 milestone approval. Environment dressing is scheduled for M5, using the guide’s Quaternius dungeon/nature packs and Kenney Pirate Kit; verify actual archives/licenses before integration.


## Training target controls checkpoint

F1 now supports dummy count 1–5, armor 0/50/100, health 2000/10000, infinite HP (default On), Counts as Elite, Reset damage / DPS, Restore player health, and explicit keg decay tiers. LMB a dummy for total damage/average DPS since first hit (idle time included). Resource-backed settings export through DebugConfig, apply next tick, reset/recenter targets when changed, survive F5, and restore with Reset tuning. Counts mutate the shared units array so active class effects see updates. Existing combat regressions opt out of training defaults; dedicated tests use real defaults. Read docs/M2_PLAYTEST.md for final manual checks and five consecutive three-keg attempts. Stationary dummies only; strafe/chase/enemy keg-attacking toggle remain later training/PvE work. M3 is still gated on explicit M2 approval.

Training slice verification: all 88 tests passed (2,624 assertions), 136 scripts loaded, all 8 stock scenes imported, and the 600-tick main-scene smoke check passed. Full `python tools/verify.py` exits failed only at editor import with the known sandbox debugger TCP-socket errors. `git diff --check` passed. No desktop UI/playtest approval is claimed.
