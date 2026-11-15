# Session handoff — 15 November 2026

Read this file first, then AGENTS.md, PROGRESS.md, ARCHITECTURE.md, and the relevant development-guide section before gameplay changes. PROGRESS.md is the dated history; ARCHITECTURE.md describes implemented behavior.

## Resume checkpoint

- Project: `/home/aurelius/Projects/blood-powder`.
- Branch: `feature/m3-hunter`.
- Latest gameplay commit: `1a4610d` — automatic Hunter jump circle. Previous checkpoints: `4191223` — debug-input/toolbar workaround; `70d98a2` — Hunter milestone implementation.
- M0 setup, M1 foundation, and M2 Powder Captain are accepted. Local tags: `m0-approved`, `m1-approved`, `m2-approved` (M2 inspected code `cd07c59`).
- **M3 Apex Hunter implementation is complete and verified, with positive inspection feedback; explicit final M3 approval is still pending. Do not start M4 yet.** No individual full Hunter combo/manual regression result was reported; do not invent one.
- No M4 enemy/challenge/replay implementation or M5 environment art has begun.

## Latest user feedback and working agreement

- Captain functionality accepted; Q/E polish explicitly deferred. Captain movement/attack feel and red character appearance must remain preserved.
- Fine animation calibration is deferred unless later playtesting reveals a need. Existing markers remain provisional, not falsely calibrated.
- Hunter was implemented, then user reported F keys unavailable. Visible mouse toolbar and Tab alternative were added, plus pre-GUI debug-key routing. User confirmed it “Works amazingly.” Exact OS/hardware cause was never established; do not blame Arch or change desktop/keyboard settings.
- User requested a Hunter jump-range circle; added automatic green brush/linger circle and gold Stalk-camouflage circle. User responded “Amazing.” Record this as positive circle feedback, not automatic milestone approval.
- Work autonomously through each authorized milestone according to the guide. **Notify at milestone inspection checkpoints rather than after each feature.** Raise only actual blockers/design decisions sooner. Full milestone approval remains required before the next milestone.
- Final map art/textures belong to M5, after M4 PvE. Planned free CC0 packs in the guide: Quaternius LowPoly Modular Dungeon, Quaternius Ultimate Stylized Nature, Kenney Pirate Kit. These environment packs are not imported yet. Verify actual downloads/licenses, keep raw packs outside the repo, import only used assets, and update CREDITS.md.

## Open, run, and inspect

```bash
~/Applications/Godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64 --editor --path ~/Projects/blood-powder
```

Press F5 in the editor to start. Or launch directly:

```bash
~/Applications/Godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64 --path ~/Projects/blood-powder
```

- The game starts as Captain. **Click Tools at the top or press Tab, then select Apex Hunter.** Do not rely on the user's F keys.
- Mouse toolbar provides Tools, Ranges, States, Log, Reset, Slower/Faster, Pause/Resume, and Step. F1–F10 equivalents remain; F6 switches class. Gameplay keys still respect GUI editing. Debug buttons do not grab keyboard focus.
- Class selection applies on the next simulation tick; if paused, use Step/Resume. Switching resets player/old class effects, preserves clock sequence and training settings, and rebuilds the HUD. Reset/F5 preserves the current class.
- Main Hunter inspection combo: **brush leap → Bola midair → Rend reset → empowered ability**. Full checklist: `docs/M3_PLAYTEST.md`; automated-gate mapping: `docs/M3_ACCEPTANCE.md`.

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

## Current UI, visuals, and training

- Automatic leap circle needs no F2: green for brush/21-tick linger, gold for Stalk camouflage after the two-second warmup. It hides during flight, root, stun, death, and Captain selection. Nominal radius is leap range + Hunter radius (8.1 m default), representing reach to the enemy's near edge; width is tunable. It follows the interpolated actor without changing collision/combat/RNG.
- HUD shows claw eligibility, Ferocity pips, empowered abilities, grey HP, red valid-leap target ring, gold eye/mark, camouflage, and Bola aim under Ranges. Hunter uses a provisional green hooded stock human, Jump clip/visual arc, a substitute Howl cast pose, and 30% opacity camouflage. Captain stays red. Final VFX/audio/roar/environment dressing remain M5.
- Tools exposes dummy count1–5, stationary/strafe/slow chase, armor0/50/100, finite HP2000/10000 or Infinite(default), Elite flag, damage/DPS reset, restore player health, and ability tuning. Select a dummy for total resolved damage and encounter-average DPS (idle time included). Settings apply next tick, persist through Reset, export through DebugConfig, and restore via Reset tuning to file.
- Enemy keg-attacking defaults Off. On makes dummies melee only live in-range kegs; enemy destruction removes without explosion/passive reset. No real challenge enemy AI is implied.
- Captain remains fully available: Flintlock, keg graphs/pending combos/serial charges/decay, Searing Edge with once-per-chain reset, Ration (approved cast-through-stun exception), and dense Broadside (192 cosmetic cannonballs/cast). Keg links are bright outlined amber ribbons, pale gold when scheduled.

## Verification

Latest complete run (`.local/leap-ring-verification.log`):

- **119/119 tests passed, 2,791 assertions.**
- All **145 scripts** loaded; all **8 stock asset scenes** imported.
- Captain main scene and Hunter each completed **600 consecutive simulation ticks**.
- Strict `python tools/verify.py` still exits failed **only at editor import** because the restricted session blocks Godot's debugger TCP listener. This is the previously confirmed sandbox limitation; do not claim full strict success or suppress unknown errors.
- Whitespace checks passed. All verification processes finished. These handoff-only edits do not require another gameplay test run.

Pinned editor: Godot `4.7.2.stable.official.ed1daf0bf`; GUT9.7.1 is vendored. Verification command is `python tools/verify.py`; logs live in ignored `.local/`. It now runs both Captain/main-scene and Hunter smoke stages.

## Persistent constraints

- Preserve pre-existing **unstaged `project.godot` editor serialization**, exclude it from implementation commits, and do not overwrite it. At this handoff it is the only non-documentation uncommitted change.
- No system/shell/desktop/other-application configuration edits without explicit approval.
- Keep work local. Previous GitHub pushes failed on DNS and user requested no repeated attempts. No remote synchronization is claimed.
- Preserve configured Git identity. **Never add AI authorship/coauthor trailers.**
- Work on branches; no milestone merge/tag until approval. M3 has no approval tag yet.
- Simulation stays deterministic at integer60Hz ticks. Rendering must not change combat/RNG.
- Captain Ration's stun exception is explicitly approved in the guide amendment. Hunter empowered Howl's specific cleanse uses the same cast-while-stunned interface; normal Howl is blocked.
- Raw packs stay outside repo; record used files/licenses in CREDITS.md. No new external assets were required in M3.

## Next session

1. Resume from this checkpoint; do not reimplement completed Hunter/Captain features or repeat unchanged verification merely to reconstruct context.
2. Address any new M3 inspection feedback. If user approves proceeding beyond M3, record that approval before M4 and follow the guide.
3. M4: Melee Chaser, Ranged Kiter, Elite/telegraphed slam, vision/camouflage AI, challenge waves/win-lose flow, balancing, deterministic command replay.
4. M5 later: environment dressing/textures, final VFX/audio, camera polish, credits and Linux/Windows offline exports. Preserve collision/navigation when dressing the arena.
