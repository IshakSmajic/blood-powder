# Blood & Powder

An offline 3D top-down combat arena for Linux and Windows, built with Godot and GDScript.

Current milestone: **M3 — Apex Hunter**, ready for inspection after verification. M2 Powder Captain is accepted (`m2-approved`); M0/M1 tags remain available. All Captain abilities and training controls remain usable. Click **Tools** (or press **Tab**) and select **Apex Hunter** to inspect brush leaps, Ferocity, Rend, Howl, Bola, and Stalk. See [M3 playtest](docs/M3_PLAYTEST.md) and [progress](PROGRESS.md).

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
| Q | Captain: targeted Flintlock / Hunter: Rend attack reset and buff |
| W | Captain: Ration heal/cleanse / Hunter: Howl magic damage/grey-health heal |
| E | Captain: ground-targeted keg / Hunter: aimed Bola (instant mid-leap) |
| R | Captain: Broadside at ground cursor / Hunter: Stalk speed/camouflage/mark |
| Y / Space / wheel | Toggle camera lock / center while held / zoom |
| F6 / Tools class selector | Switch between Captain and Hunter on the next tick |
| Tab / F1 / Tools button | Open or close class selection and tuning |
| F2 / F3 / F4 or toolbar buttons | Ranges / state and tick timers / combat log |
| F5 in game | Reset units, camera, simulation clock, speed, and combat log; retain live tuning |
| F7 / F8 | Reduce / increase simulation speed by 0.1× |
| F9 / F10 | Pause / single tick while paused |
| Esc | Cancel armed attack-move, or open/close pause menu |

Start by moving north around the central low wall to reach the three dummies. Unlock the camera with Y to pan at screen edges. The two green patches are brush zones: Hunter can leap from them or during Stalk camouflage, with a brief linger after exiting. Tools / Tab provides the class selector and configurable dummies. All passive/QWER mechanics are active for both classes. Keys 1–4 remain unbound; replay tooling is later work.

The collision/navmesh radius stays fixed in this slice; the F1 panel exposes other numeric player stats. Changes apply next simulation tick. Restarting the game clears live tuning. Session tuning is not written back to source resource files. Explicit export can save a separate snapshot. F1 includes an **Open Animation Lab** button and exposes class ability values and buttons to apply slow, root, stun, burn, speed buff, or cleanse to the player. Status actions are processed on the next simulation tick; use F10 while paused. Burn survives cleanse; Captain Ration and empowered Hunter Howl can cleanse stun. F5 clears all statuses and cooldowns.

## Verify

From the repository root:

```bash
python tools/verify.py
```

The command verifies the pinned engine version, imports the project, explicitly loads every GDScript, checks all prepared stock assets, runs the GUT suite, and runs both the actual main scene and the Hunter class for 600 consecutive simulation ticks each. It treats engine/script errors as failures even when Godot returns exit code zero and runs all stages before reporting failures. Logs and test output live in ignored `.local/`; existing application settings are not used by verification.

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

Eight stock character/animation candidates have been prepared and documented in [the asset audit](docs/asset_audit.md). Matching Linux/Windows x86_64 export templates are installed. No environment packs are integrated yet. M0 and M1 are accepted, with finer animation calibration deferred by Ishak. M2 is in progress; see `PROGRESS.md` for slice status. No runtime network service is required.


## Character animation and calibration

The player now uses the Quaternius male ranger outfit, with only the base character's head underneath. The red outfit is a provisional Captain appearance; Hunter uses the same hooded human in green: the free pack does not include the concept sheet's pirate coat/hat. Dummies use the superhero male base body with flat grey materials. Physics remains a capsule collider; stock meshes are visual only.

Open **F1 → Open Animation Lab** to inspect the stock animations. Choose a character and clip; use **Space** to play/pause and **, / .** to step at 60 fps. For `attack_a` and `attack_b`, stop at the visual contact frame and press **M** to mark it. This saves only the corresponding project data resource under `data/anim_profiles/`. **Esc** returns to a reset arena.

The initial attack markers are **provisional**. Marking changes animation time scaling and does not change authoritative combat timing (Captain defaults: 15-tick windup, 91-tick period; Hunter uses its own stats). Rest-pose compensation keeps target proportions, while the in-place library never drives actor movement. Ishak has accepted the current animations and deferred finer calibration unless later playtesting shows a need. The Animation Lab remains available when that work is useful.


## Export playtest feedback

In **F1**, use **Export tuning (.tres)** to save the current overrides, **Reset tuning to file** to restore source defaults, or **Export combat log (.csv)** to save every combat event since the last arena reset. Scroll the debug panel if necessary.

Files appear in `~/Projects/blood-powder/debug_exports/` (or the same folder inside your project checkout). Each export has a unique filename. These files are ignored by Git and the game importer; source stats/abilities and system/application configuration are unchanged. Tuning snapshots are feedback artifacts and are not loaded automatically on startup. F5 clears the current run log.


## Try the keg-combo slice

1. Press **E** over clear ground to place a keg. It materializes after 0.25 s and decays from **3 → 2 → 1** health, once per second. At one pip it is ready for a one-hit detonation.
2. Place another keg within **6.9 m** of the first; a thick amber powder link appears. Use **F2** to show the **3.45 m** explosion radii.
3. Hover the one-pip keg and press **Q**, or right-click it for a melee attack. Connected kegs explode **20 ticks** apart. A unit overlapping multiple blasts takes damage once per chain.
4. Try **Q → E**: shoot an existing one-pip keg, then immediately place a linked keg. The in-progress ghost counts in the graph, allowing the one-part combo. New move/attack orders cancel an out-of-range pending cast.
5. **F5** clears kegs/projectiles/schedules and restores charges/cooldowns. E starts with **3 charges** and recharges one every **13 s**. Live charges (3–5), decay, connection distance, and other Q/E values are in F1.

Kegs expire after 25 s without exploding. They cannot be placed in walls or within 0.8 m of another keg. Pending ghosts are not attackable until materialized. Stun interrupts placement; the committed charge/cooldown remains spent. Q is homing and passes walls; a dead/removed target causes the shot to fizzle. The current barrels and explosion rings are procedural prototypes; full prop/VFX/audio polish comes later.

The M1 Training Pulse resource and fixture remain only for regression testing. The normal arena starts as Captain; F1 can switch to Hunter and back. Captain movement/attack timing and the accepted red outfit remain preserved.


## If function keys do not reach the game

Use the visible toolbar: **Tools**, Ranges, States, Log, Reset, Slower/Faster, Pause/Resume, and Step. **Tab** also toggles Tools. Reserved debug keys are handled before GUI focus can consume them; movement/abilities still respect GUI editing. Keyboard Fn/media mode or shortcuts outside the game may intercept function keys, which the game cannot override. No desktop or keyboard configuration is changed.
