# First-person Captain experiment

Run from any directory:

```bash
~/Projects/blood-powder/tools/run_first_person.sh
```

Or launch the scene explicitly:

```bash
~/Applications/Godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64 --path ~/Projects/blood-powder res://experiments/first_person/captain_lab.tscn
```

The launcher respects `GODOT_BIN` if the engine is installed elsewhere. You can add `--display-driver x11` if needed. The ordinary project launch and F5 still open the top-down battlefield.

Click **Start / Resume** to capture the mouse. The scene starts paused intentionally.

| Control | Action |
| --- | --- |
| WASD | Direct movement relative to facing; diagonal speed is normalized |
| Mouse | Look; pitch limited to ±85° |
| LMB, hold or click | Sword; stay aimed at the target when the windup lands |
| RMB or Q | Flintlock at the soldier or barrel under the crosshair |
| E | Place a barrel on the ground under the crosshair |
| F | Ration heal/cleanse (W is forward movement here) |
| R | Broadside on aimed ground |
| Esc or Tab | Pause, release mouse, show Resume/Reset/Return/Quit |

The single soldier has 2,000 HP, does not attack or chase, and respawns two seconds after defeat. Its armor and the Captain's stats are the existing project resources. The bottom strip shows pistol/Ration/Broadside cooldowns and available barrel charges. The ground marker is gold at an eligible barrel point and red when out of range or blocked/too close. Target name/health appear when aimed at. Target damage and hit-event count reset with the lab.

## Try these

1. Start facing the soldier. Fire RMB; the muzzle flashes and the shared homing projectile takes time to reach it. Empty/out-of-range shots give feedback without auto-walking or consuming cooldown.
2. Walk closer with W, hold LMB, and strafe with A/D. Look away during the windup to miss the impact. Walk into the soldier or outer scenery to check collision.
3. Look at the dirt a few meters in front of the soldier. Press E, wait at least half a second, and place another barrel within link distance. Wait for one health pip (two seconds after placement), aim at a barrel and shoot it. A connected chain should hit the nearby soldier.
4. Aim at nearby ground and cast R to inspect Broadside from eye level. F uses the existing Ration cooldown/heal/cleanse.
5. Esc/Tab pauses and clears held movement/fire. Resume, reset the practice setup, or return to the normal arena using the buttons. Alt-tabbing away also pauses and releases the mouse.

## Deliberate limits

This is a separate control/perspective trial, not a conversion of the main game. Hands and weapons are simple primitives. No jump, sprint, first-person body rig, active opponent AI, first-person replay, audio pass or difficulty balancing is included. Flintlock retains targeted homing and its original range/cooldown, rather than becoming a free-aim hitscan gun. Both sword targeting and placement stop at scenery. Area effects are still planar on uneven terrain, and headshots are not a separate mechanic. Human feel is for inspection.

All motion, hit deadlines, statuses, casts, barrel decay/chains and damage run on admitted integer 60 Hz simulation ticks. Mouse/camera presentation cannot change combat timing. Shared top-down behavior is covered by the normal regression suite.
