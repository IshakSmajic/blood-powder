# M4 inspection — repeatable combat challenge

M3 was explicitly approved on 15 November 2026. M4 is implemented on `feature/m4-pve`; M5 still requires approval after this inspection.

Run the project with the pinned Godot 4.7.2 editor and press F5. Use the clickable toolbar; function keys are optional.

1. In Training, use **Tools → Powder Captain / Apex Hunter** to choose a class. Click **Challenge** in the top toolbar. Switching class during Challenge restarts its encounter. Switching class during Training retains the accepted clock behavior; Reset before recording a new replay.
2. Advance toward the enemies after the three-second opening countdown: enemies acquire within 12 meters. Wave 1 has four Chasers; after clearing it, a four-second countdown leads to three Chasers and two Kiters. Wave 3 has an Elite and two Chasers.
3. Test Chasers following, attacking and returning to their spawn after three seconds without sight. Kiters retreat when closer than five meters, then attack; their gold projectiles travel and stop at walls. Use pillars and movement to manage pressure.
4. Fight the Elite. Every eight seconds, while you are within four meters, it begins a red 2.5-meter circle that fills over one second. Move clear. Stun/root cannot interrupt a started warning; killing the Elite cancels it. A hit deals magic damage and stuns for one second. Captain W or empowered Hunter W can cleanse the stun under the accepted class rules.
5. As Hunter, enter brush or use Stalk to break sight. Enemies search the last observed position rather than track your hidden position; proximity, sharing brush and a recent hit reveal you. Captain also gets ordinary brush hiding, without Hunter's leap or camouflage.
6. Clear all waves and check Victory, clear time, damage taken and Retry. Die and check Defeat and wave reached. Challenge has no respawns. Reset/Retry starts a fresh three-wave encounter with the current class. **Back to Training** restores the configured dummies. Mode buttons also work while paused by admitting the transition tick.
7. For a reproducible run, choose the class and any tuning, then Reset. Do not change tuning or apply debug statuses during the recorded run. Commands are recorded automatically. Click **Save replay** during the run or at its result screen. Files are under `debug_exports/` as `.bpr`.
8. Click **Load replay**, choose that file, and let it run. Gameplay input is suppressed during playback; pause, speed, Step, camera and overlays are available. Playback pauses at its saved final tick and displays **REPLAY MATCH** only when the entire serialized combat log matches byte for byte. Reset exits playback. Replays require the same gameplay build and pinned engine; a changed build may mismatch.
9. Repeat Challenge with the other class. Check whether enemies feel readable and whether healing, kegs, slows, leap and slam dodging make success achievable without making it effortless. Automated pilots establish feasibility; your hands-on balance/feel judgment remains the acceptance check.

Tools includes live enemy stats and behavior parameters, with behavior timers explicitly labeled in ticks. Changing tuning or debug state invalidates replay saving until Reset, rather than producing a misleading recording. Source resources are never overwritten by tuning. Enemy attacks on kegs remain controlled by the existing training toggle, off by default; configure it before entering Challenge and Reset before recording.

## Proposed guide refinement for inspection

The guide requests NavigationAgent3D avoidance. M4 instead keeps the asynchronous NavigationServer velocity solver disabled and uses synchronous, stable-unit-order crowd separation against the same physical walls. This keeps enemy spreading on admitted simulation ticks and makes pause/slow/step and command replay deterministic. This implementation choice is explicitly proposed for approval with M4; the original guide is unchanged. NavigationAgents still calculate paths and chase repaths remain six ticks apart.

Environment art, finished enemy costumes, sound, final VFX and exports belong to M5. Enemy stock avatars and warning/projectile graphics are provisional.
