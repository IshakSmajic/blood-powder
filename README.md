# Blood & Powder

An offline 3D top-down combat arena for Linux and Windows, built with Godot and GDScript.

Current slice: **M1 — stock character visuals and animation integration**. Right-click navigation around obstacles, stationary training dummies, attack timing/cancellation, damage/armor/crits, respawn, camera controls, and prototype debug HUD. A temporary Q Training Pulse exercises cast/cooldown/status behavior. The player uses the downloaded ranger outfit with a red prototype palette; dummies use grey stock bodies. Idle/run, alternating melee, test-cast, and death clips are connected. Class abilities and final Captain clothing are not implemented yet. M0 is approved and preserved in `world/setup_room.tscn` (local tag `m0-approved`).

## Open and run

Pinned editor: **Godot 4.7.2 stable, standard non-.NET**, official build `ed1daf0bf`.

```bash
~/Applications/Godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64 --editor --path ~/Projects/blood-powder
```

Wait for asset import, then press **F5** in the editor. To run the project directly:

```bash
~/Applications/Godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64 --path ~/Projects/blood-powder
```

On Hyprland, if the window misbehaves, add `--display-driver x11` to that command. This is a per-launch option and does not change desktop configuration.

## Sandbox controls

| Input | Result |
| --- | --- |
| Right-click ground / hold RMB | Move with pathfinding / steer every 6 simulation ticks |
| Right-click dummy | Chase and repeatedly attack |
| Left-click | Inspect nearest unit under the ground cursor |
| A then left-click | Attack-move to the clicked point |
| S / H | Stop / hold position and attack in range |
| Q | Temporary Training Pulse: nearby magic damage and slow, 0.25 s cast, 3 s cooldown |
| Y / Space / wheel | Toggle camera lock / center while held / zoom |
| F1 / F2 / F3 / F4 | Live player stats / range and path overlay / state and tick timers / combat log |
| F5 in game | Reset units, camera, simulation clock, speed, and combat log; retain live tuning |
| F7 / F8 | Reduce / increase simulation speed by 0.1× |
| F9 / F10 | Pause / single tick while paused |
| Esc | Cancel armed attack-move, or open/close pause menu |

Start by moving north around the central low wall to reach the three dummies. Unlock the camera with Y to pan at screen edges. The two green patches are visual brush placeholders. Q is a prototype test ability; W/E/R and passive remain placeholders. Keys 1–4 remain unbound. F6 class switching, actual class abilities, and full tuning/export tools arrive in later slices.

The collision/navmesh radius stays fixed in this slice; the F1 panel exposes other numeric player stats. Changes apply next simulation tick. Restarting the game clears live tuning. Session tuning is not written to resource files. F1 includes an **Open Animation Lab** button and exposes test-ability values and buttons to apply slow, root, stun, burn, speed buff, or cleanse to the player. Status actions are processed on the next simulation tick; use F10 while paused. Burn survives cleanse; F5 clears all statuses and cooldowns.

## Verify

From the repository root:

```bash
python tools/verify.py
```

The command verifies the pinned engine version, imports the project, explicitly loads every GDScript, checks all prepared stock assets, runs the GUT suite, and runs the actual main scene for 600 consecutive simulation ticks. It treats engine/script errors as failures even when Godot returns exit code zero and runs all stages before reporting failures. Logs and test output live in ignored `.local/`; existing application settings are not used by verification.

In a restricted session that prohibits socket creation, the editor import can report debugger TCP listener errors even when assets import and the standalone checks pass. Those errors remain failures in this script; run the same command from your normal terminal to confirm a clean import.

For an engine at another location, supply its path without editing shell configuration:

```bash
GODOT_BIN=/absolute/path/to/godot python tools/verify.py
```

## Project documents

- [Development guide](docs/mvp_development_guide.md) — extracted text for searching; the [original DOCX](docs/mvp_development_guide.docx) preserves tables and diagrams.
- [Architecture](ARCHITECTURE.md) — implemented systems and boundaries.
- [Progress](PROGRESS.md) — milestone status, verification evidence, pending decisions.
- [Credits](CREDITS.md) — dependency and asset provenance.
- [Approved visual direction](docs/concepts/visual_direction_v1.png) — concept reference, not a screenshot or game-ready 3D asset.

Eight stock character/animation candidates have been prepared and documented in [the asset audit](docs/asset_audit.md). Matching Linux/Windows x86_64 export templates are installed. No environment packs are integrated yet. M0 is approved. M1 remains in progress; see `PROGRESS.md` for slice status. No runtime network service is required.


## Character animation and calibration

The player now uses the Quaternius male ranger outfit, with only the base character's head underneath. The red outfit is a provisional Captain appearance: the free pack does not include the concept sheet's pirate coat/hat. Dummies use the superhero male base body with flat grey materials. Physics remains a capsule collider; stock meshes are visual only.

Open **F1 → Open Animation Lab** to inspect the stock animations. Choose a character and clip; use **Space** to play/pause and **, / .** to step at 60 fps. For `attack_a` and `attack_b`, stop at the visual contact frame and press **M** to mark it. This saves only the corresponding project data resource under `data/anim_profiles/`. **Esc** returns to a reset arena.

The initial attack markers are **provisional**. Marking changes animation time scaling and does not change the authoritative 15-tick attack windup or 91-tick attack period. Rest-pose compensation keeps target proportions, while the in-place library never drives actor movement. Visual polish and final calibration require desktop inspection.
