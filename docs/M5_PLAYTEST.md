# M5 inspection — presentation and offline build

M4 was accepted by Ishak on 15 November 2026. M5 implementation is in progress on `feature/m5-polish`; this checklist records what must be inspected before M5 acceptance. Automated verification does not establish visual feel or platform compatibility.

## Arena and controls

1. Start Training and walk around the arena perimeter, pillars, center wall, and both brush zones. The stone floor/walls should cover the old boxes without visible collision changes, gaps, or snagging. Grass/bushes should make each brush region easy to identify.
2. Check both Captain and Hunter from the Tools panel. Walk, attack and cast near walls, pillars, low wall, and brush. Verify character and enemy movement still respects the original collision/nav paths.
3. Run the three-wave Challenge with both classes. Check that the floor/foliage and torch lights remain readable during combat and that M4 enemy warnings/projectiles are still visible.

## Feedback and menu

4. Confirm basic hits flash the target, critical hits have a slightly longer visual pause, and damage numbers remain readable. Check the critical effect does not pause the simulation clock or move attack/cast deadlines.
5. Trigger Flintlock, Powder Keg chains, Ration, Broadside, Hunter leap/Rend/Bola/Howl, and Elite slam. Confirm the sound/effect is visible/audible, does not cover warning circles, and ends cleanly on Reset.
6. Open Pause / Escape. Verify simulation and combat timers stop, camera/gameplay input is blocked, Resume restores the previous pause state, Credits opens and returns to Pause, Restart resets the arena, and Quit exits.
7. Test at the default resizable window and at a smaller window size. Confirm toolbar, HUD, pause panel and credits remain usable.

## Offline exports

8. Export Windows and Linux desktop builds from the pinned Godot 4.7.2 templates. Launch each with networking disabled and check first-run asset imports, Training, both classes, Challenge, Pause/Credits and sound.
9. Windows must be run on Windows 10/11. Linux must be run on a Linux desktop. Record host/OS and build results here before M5 sign-off.

## Automated gate

Run `python tools/verify.py` from the project root with `GODOT_BIN` set to the pinned standard Godot 4.7.2 binary. It imports the project, parses all scripts, checks character/environment model imports, runs GUT, and smoke-runs Captain, Hunter and Challenge for 600 ticks. Any failures or environment-specific limits belong in `PROGRESS.md`.

Automated gate passed on 15 November 2026: 158 scripts parsed, 8 character/animation scenes plus 15 environment models imported, 134/134 GUT tests with 2,863 assertions passed, and all three 600-tick smoke runs passed. Both desktop presets exported; the Windows executable ran headlessly for 1,200 frames. Manual visual/audio checks, disabled-network launch checks, and Linux-host execution remain unrecorded.
