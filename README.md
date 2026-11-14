# Blood & Powder

An offline 3D top-down combat arena for Linux and Windows, built with Godot and GDScript.

Current slice: **M0 — setup room**. A grey room, static capsule scale marker, simulation clock, and setup controls. Movement, attacks, navigation, classes, and final art are not implemented yet.

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

## M0 controls

| Input | Result |
| --- | --- |
| F5 in the game window | Reset clock, speed, pause state, and session overrides |
| F7 / F8 | Reduce / increase simulation speed by 0.1×, bounded to 0.1×–1× |
| F9 | Pause / resume simulation |
| F10 while paused | Advance one simulation tick |
| Esc | Open / close setup menu |

The capsule does not move. QWER and the remaining gameplay/debug bindings are defined for later milestones but have no gameplay behavior yet. Keys 1–4 remain unbound.

## Verify

From the repository root:

```bash
python tools/verify.py
```

The command verifies the pinned engine version, imports the project, explicitly loads every GDScript, runs the GUT suite, and runs the actual main scene for 600 consecutive simulation ticks. It treats engine/script errors as failures even when Godot returns exit code zero and runs all stages before reporting failures. Logs and test output live in ignored `.local/`; existing application settings are not used by verification.

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

Eight stock character/animation candidates have been prepared and documented in [the asset audit](docs/asset_audit.md). Matching Linux/Windows x86_64 export templates are installed. No environment packs are integrated yet. M0 remains pending until setup dependencies and Ishak's sign-off are complete. No runtime network service is required.
