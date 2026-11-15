# Session handoff — 15 November 2026

Read AGENTS.md, PROGRESS.md, ARCHITECTURE.md, and the relevant guide section before gameplay changes. PROGRESS.md keeps the dated history.

## Current gate

- Workspace `/home/aurelius/Projects/blood-powder`; branch `feature/m3-hunter`.
- M2 was approved after the barrel-link visibility fix (“Great, you may proceed”). Local `m2-approved` tags accepted code `cd07c59`. No individual five-chain playtest result was supplied; do not fabricate it.
- M3 Hunter implementation is ready for inspection after final verification. User approval is still required before M4. No M4 enemies/challenge or M5 environment work was started.
- User wants autonomous milestone completion and milestone-level handoffs. Avoid per-feature reports; raise actual blockers/design decisions when needed.
- Game still starts as Captain. **Tools / Tab → Apex Hunter** switches on the next simulation tick. F5 preserves class. Switching resets player and clears prior class effects, while preserving simulation tick sequence and training settings.
- Read `docs/M3_PLAYTEST.md` and `docs/M3_ACCEPTANCE.md` for the inspection/gate mapping.

## Hunter implementation

- HunterController owns Ferocity, W/E/R/passive runners, brush/leap state, Rend buffs, grey damage window, Bola shots, and Stalk/mark state. Q runner remains unit.ability. HunterData resources and hunter stats are in data/.
- BrushZone Area3D has a box shape and green 6×3 m footprint; fixed-tick center containment drives brush/leap/vision. Linger 21 ticks, leap 7.45 m edge range, 14.5 m/s, fixed destination 0.5 m beyond target gameplay edge. Actual body collision stops at walls; original impact deadline still applies. Landing hits a moved/hidden target without a range recheck, consumes Rend on dead target, and precedes buffered movement. Stun cancels flight without impact; root blocks takeoff only. Arc height 1.2 m is visual.
- Ferocity 0–4; leap-derived-stack flag clears at zero. Normal W/E casts and first normal Q-buffed hit gain stacks. Non-burn damage dealt/taken resets 600-tick inactivity deadline; the first gained stack initializes that window. Q/E reaching four lock their empowered form 6 ticks. Empowered Q/W/E consume all, grant 40% speed for 90 ticks, ignore/preserve base cooldowns, and lock base same-slot 6 ticks (W 15).
- Q Rend: reset attack, two buffed attacks in 180 ticks, 40% AS, first-hit +60 physical and +0.25 m range. First windup buffers commands rather than cancels. Bonus range ends 15 ticks after leap eligibility begins. Empowered first-hit +150 and 75% AS for 300 ticks; AS persists through a later normal Q. Midair Q buffs landing.
- W Howl: 90 magic/4.5 m, heal 50% rolling post-mitigation damage from last 90 ticks, grey bar. Empowered: 160 plus cleanse slow/root/stun, usable during stun. Grey damage remains reusable inside the window (normal+empowered healing); burn contributes grey HP but does not refresh Ferocity combat time.
- E Bola: 15-tick ground cast, instant midair; aim fixed at start, origin sampled at completion. 10 m/15 m/s/1.4 m swept width, first enemy, walls/starting overlaps stop it. Normal 80 physical +60% slow105 ticks; empowered140 +root105. Q/W buffer behind ground cast.
- R Stalk: instant, 30 s cooldown, 720-tick duration, 50% speed, camouflage/leap after120 ticks. Nearest enemy within16 m marked. Marked hit adds100% AD and applies -20 armor before damage for240 ticks; expiry checked at exact deadline regardless target turn order. Attacks/non-Q basic casts end it; leap preserves until impact. R gives no Ferocity.
- Visibility: camouflage hides beyond7.1 m. Brush hides after30 ticks unless same brush, within1.5 m, or hit by Hunter in last60 ticks. Training chase respects it; future M4 AI can reuse it.
- Shared CombatUnit hooks isolate Hunter effects and preserve Captain defaults. Death clears Hunter Ferocity/Stalk/Rend and cancels leap/cast. Reset/class switch also remove projectiles. Existing one-command buffer remains last-wins, extended through leap for movement.

## UI/presentation

- F1 class selector, relevant ability tuning, all accepted dummy/Elite/decay/enemy-keg controls, exports/reset.
- Four Ferocity pips/empowered cooldown bypass, claw eligibility, grey HP, red pulsing valid leap-target ring, gold eye/mark indicator, F2 leap radius/Bola aim, camouflage status.
- Human hooded stock ranger in green for Hunter; Captain stays red. Existing rig/animation adapter plus imported Jump (Godot strips `_Loop`), visual arc, landing contact/recovery, substitute Howl cast pose, 30% opacity camouflage, full-Ferocity blade glow. No new external assets.
- Animation fine-tuning/QE polish stay deferred. Final Hunter roar/audio/full particles/trails/map dressing remain M5.

## Verification and constraints

Final verified totals are in PROGRESS.md and appended below. tools/verify.py now includes main-scene and Hunter 600-tick smoke stages. Strict editor import still reports the known sandbox debugger TCP-listener restriction; never claim overall strict success. No rerun needed for documentation-only changes.

- Preserve pre-existing unstaged project.godot editor serialization and exclude it from implementation commits.
- No system/shell/desktop/other-app config edits without approval.
- Keep raw packs outside repo and record licenses/used files in CREDITS.md.
- Keep work local; prior pushes failed on DNS, and user requested no repeated attempts. Preserve user Git identity and never add AI authorship/coauthor trailers.
- Captain Ration's stun exception is explicitly approved in the guide amendment. Hunter empowered Howl's specific cleanse is implemented through the same cast-while-stunned interface; normal Howl is blocked.

## Next

User inspects M3: F1 Hunter, brush leap → Bola midair → Rend reset → empowered ability; inspect root/stun/walls, grey health, Stalk mark/camouflage, class switching/F5, and accepted Captain regression. Address defects and wait for explicit M3 approval before M4.

Final verification: full suite 113/113 tests (2,758 assertions), all 143 scripts, 8 stock scenes, and Captain/Hunter 600-tick smoke checks passed. Strict editor import fails only the known sandbox TCP-listener check. Focused Hunter follow-up passed 18/18 tests (96 assertions), including the guide’s 30 armor stat. Whitespace checks are clean. No verification process remains running.

Function-key feedback: user cannot activate F keys in-game; exact OS/hardware cause unconfirmed. Added persistent clickable debug toolbar and Tab to toggle Tools, and moved reserved debug-key dispatch before GUI focus can swallow it. Gameplay still respects GUI focus. Use Tools/Tab to choose Hunter, plus toolbar for all other debug functions. No system/editor/input-map configuration was changed. M3 approval remains pending.

Debug-control verification: all 117 tests passed (2,779 assertions), all 144 scripts loaded, 8 stock asset scenes imported, and Captain/Hunter each ran 600 ticks. Focused debug-input checks passed 4/4 tests (20 assertions). Full verification retains only the known sandbox editor-import TCP-listener error. `git diff --check` passed. Exact host F-key interception remains unconfirmed; Tools/Tab/mouse alternatives are ready for desktop inspection.

Hunter range feedback: added automatic outlined leap circle (no F2 needed), green for brush/linger and gold for Stalk camouflage after120 ticks. Hides during flight/root/stun/death and on Captain. Default nominal radius8.1 m reaches the enemy near edge, follows interpolated actor, and tracks leap_range/leap_ring_width tuning without touching combat/RNG. Debug-control workaround received positive user feedback; M3 still awaiting approval.

Automatic leap-circle verification: all 119 tests passed (2,791 assertions), all 145 scripts loaded, 8 stock scenes imported, and both Captain/Hunter 600-tick runtime checks passed. Strict verification retains only the known sandbox editor-import socket failure. `git diff --check` passed. Desktop appearance remains for user inspection.
