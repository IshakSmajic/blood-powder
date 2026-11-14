# Blood & Powder

An offline 3D top-down combat arena for Linux and Windows, built with Godot and GDScript.

Current slice: **M1 — capsule movement and basic attacks**. Right-click navigation around obstacles, stationary training dummies, attack timing/cancellation, damage/armor/crits, respawn, camera controls, and prototype debug HUD. Class abilities, stock character animation, and final art are not implemented yet. M0 is approved and preserved in `world/setup_room.tscn` (local tag `m0-approved`).

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
| Y / Space / wheel | Toggle camera lock / center while held / zoom |
| F1 / F2 / F3 / F4 | Live player stats / range and path overlay / state and tick timers / combat log |
| F5 in game | Reset units, camera, simulation clock, speed, and combat log; retain live tuning |
| F7 / F8 | Reduce / increase simulation speed by 0.1× |
| F9 / F10 | Pause / single tick while paused |
| Esc | Cancel armed attack-move, or open/close pause menu |

Start by moving north around the central low wall to reach the three dummies. Unlock the camera with Y to pan at screen edges. The two green patches are visual brush placeholders. QWER slots are placeholders; keys 1–4 remain unbound. F6 class switching, abilities, and full tuning/export tools arrive in later slices.

The collision/navmesh radius stays fixed in this slice; the F1 panel exposes other numeric player stats. Changes apply next simulation tick. Restarting the game clears live tuning. Session tuning is not written to resource files.

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
