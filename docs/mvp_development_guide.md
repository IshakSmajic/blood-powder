# MVP development guide

Text extracted from Ishak’s original DOCX; table cells appear sequentially.
The DOCX alongside this file preserves table formatting and diagrams.
The extracted source text is preserved; dated user-directed amendments appear at the end of this document.

Blood & Powder — MVP Development Guide

Oct 31, 2026 · @Ishak

1. Purpose and MVP definition

The MVP is one offline Godot 4 executable for Linux and Windows: a single 3D top-down arena, two playable classes (Powder Captain and Apex Hunter), three enemy types and a training mode, with combat whose timing matches the reference mechanics within one physics tick (1/60 s).

This guide is the single source of truth for v0.1. Anything not written here is either listed under Open decisions (section 15) or out of scope. When this guide and a chat message disagree, update the guide first, then build.

In scope (v0.1)

Click-to-move with pathfinding, right-click attack with chase, attack-move, stop, hold.

Basic attacks with windup, backswing, cancel and reset rules.

QWER quick cast for both classes, all four abilities plus passive each.

Powder Captain keg system: charges, decay, connection graph, chained detonation, one/two/three-part combos.

Apex Hunter leap system: brush zones, leap eligibility, airborne casting, Ferocity resource and empowered abilities.

Shared combat: stats, damage types, armor, crits, status effects, death and respawn.

Training arena with configurable dummies; Challenge mode with three scripted waves.

HUD: ability bar, cooldowns, charges, Ferocity, health bars, damage numbers, cast-fail feedback.

Debug tooling: live tuning panel, overlays, time scale, frame step, tick-stamped combat log, input replay.

Low-poly 3D characters with stock animations, procedural VFX, generated or CC0 sound effects.

Desktop export for Linux and Windows that runs with no network access.

Out of scope (v0.1)

Multiplayer, accounts, cloud services, telemetry or any online dependency.

Dungeon crawling, bosses, procedural generation, quests, loot, inventory, items, shop, leveling, upgrades.

Consumables (keys 1–4 stay reserved), save/load, settings persistence beyond the input map.

Mana or energy costs for the Captain (cooldowns and charges only).

Fog of war, minimap, controller support, rebinding UI, localization, music.

Bespoke models or hand-made animations.

Roles

Who

Does

Claude

All GDScript, scenes, resources, input map, tests, shaders, procedural VFX and SFX, debug tools, docs in the repo

Ishak

Installs software, downloads assets, runs builds, playtests, tunes feel with the debug panel, approves each milestone

Guiding principles

Copy timing and geometry, not assets or damage. Cast times, delays, ranges and radii come from the reference; damage and health are our own, balanced for PvE.

Feel is verified by Ishak, logic is verified by tests. Every timing rule gets an automated test; every milestone gets a playtest.

Simulation is deterministic. All gameplay timers count physics ticks at 60 Hz, never render frames or wall-clock time.

Data and behavior are separate. Every tunable number lives in a resource file and appears in the debug panel.

One vertical slice per prompt. No prompt rewrites a working system without explicit permission.

Original identity. Original names, models, sounds, UI and lore. The reference game is a mechanical reference only. Public distribution needs independent legal review.

Original names used in this guide

Class

Passive

Q

W

E

R

Powder Captain

Searing Edge

Flintlock

Ration

Powder Keg

Broadside

Apex Hunter

Ambush Pounce

Rend

Howl

Bola

Stalk

2. Software and tools

The project uses the newest Godot 4.7.x stable release with GDScript, the standard (non-.NET) build. Godot 4.8 is in beta as of this guide (Beta 1 shipped 15 Oct 2026), so it is not used until a stable 4.8 ships and a milestone is complete. Godot 4.8 Beta 1 · 4.7.1 stable listing

Required

Tool

Version

Purpose

Notes

Godot Engine

Newest 4.7.x stable, standard build

Engine and editor

4.7.1 was the newest stable confirmed on 31 Oct 2026. Pin the exact version in README.md; upgrade only between milestones

Godot export templates

Same exact version as the editor

Building the Linux and Windows executables

Installed from the editor's Export dialog. A version mismatch blocks export

GUT (Godot Unit Test)

9.x release that matches the Godot minor version

Automated tests, headless runs

MIT license. Claude vendors it into addons/gut/ and enables it in project.godot

Git

Any recent

Version control

Every milestone ends with a tagged commit

GitHub

Private repository

Shared code between sessions; Claude can attach the repo and push

Repo name decision in section 15

OBS Studio

Any recent

Screen recording for feel feedback

60 fps recording is required so clips can be frame-stepped

mpv

Any recent

Frame-stepping recorded clips (. and , keys)

Used for hit-frame calibration and bug reports

A Windows machine or Windows VM

Windows 10 or 11

Testing the Windows export

Exporting for Windows from Linux works; running it does not prove it works on Windows

Optional

Tool

Purpose

When you would need it

VS Code + godot-tools extension

Reading code with better navigation

Only if you want to read the code; you never have to edit it

Blender 4.x

Fixing a model the engine cannot fix in code

Last resort only, e.g. a broken export from a pack

Audacity

Trimming or normalizing a sound file

Only if a downloaded sound needs cleanup

jsfxr (browser)

Making placeholder sound effects by hand

Only if you want to replace generated sounds yourself

Deliberately not used

Godot .NET / C# — adds a toolchain and export complexity for no MVP benefit.

Godot 4.8 beta — breaking changes are still landing.

Mixamo — its skeleton differs from the recommended asset family, which would force retargeting; it is also in maintenance mode. Mixamo status 2026

Any online service at runtime — the game must launch and play with networking disabled.

Engine settings fixed for this project

Setting

Value

Why

Renderer

Forward+

Desktop-only target; best 3D quality. Switch to Compatibility only if a test machine lacks Vulkan

Physics ticks per second

60

All combat timing is counted in these ticks

Max physics steps per frame

8

Prevents a slow frame from silently skipping simulation

Physics interpolation

On

Smooth rendering above or below 60 fps without changing simulation

3D physics engine

Jolt (the Godot 4.4+ built-in option)

Stable character collisions

Navigation

NavigationServer3D, mesh baked at runtime from code

No editor bake step required

Window

1920×1080 default, resizable, V-Sync on

Typical desktop

Arch Linux and Hyprland notes

Install Godot from the official GitHub release binary rather than a distribution package, so the version matches the export templates exactly.

If the editor or game window misbehaves under Hyprland, launch with --display-driver x11 to run through XWayland.

Run the game once with networking off before calling M5 done.

3. Asset sourcing

Every character in the game comes from one Quaternius family whose bodies, outfits and both animation libraries share an identical 65-joint skeleton with the same joint names and bind pose, so no animation retargeting is ever needed. Shared-skeleton writeup

The one non-negotiable rule: never mix in a character or animation from a different rig (Mixamo, Kenney characters, Unity Asset Store packs). Doing so brings back retargeting, which needs editor work Claude cannot do.

Recommended packs

Need

Pack

Author

License

Cost

Used for

Character bodies

Universal Base Characters

Quaternius

CC0

Free (Standard, 122 MB)

Every player and enemy body: 6 models in Superhero, Regular and Teen proportions, 20 hairstyles

Outfits

Modular Character Outfits – Fantasy

Quaternius

CC0

Free (Standard, 280 MB)

Class and enemy looks: 12 outfits from 62 parts, 3 texture variants each

Animations

Universal Animation Library

Quaternius

CC0

Free Standard (45 clips); Pro $9.99 (120+ clips)

Locomotion, attacks, gun, deaths, emotes

Animations 2

Universal Animation Library 2

Quaternius

CC0

Free Standard (about 70% of the kit)

Melee combos split into hits and recoveries, armed combat

Barrels and pirate props

Pirate Kit

Kenney

CC0

Free

Powder kegs, cannons, crates, dock props (70 models)

Arena dressing

LowPoly Modular Dungeon Pack

Quaternius

CC0

Free

Walls, floors, pillars for the M5 arena

Brush zones

Ultimate Stylized Nature Pack

Quaternius

CC0

Free

Bushes and tall grass for brush zones. Verify the license on the download page

Particle textures

Kenney Particle Pack

Kenney (Godot repack by Calinou)

CC0

Free

80 sprites for smoke, sparks, flashes, light cookies

VFX flipbooks

Brackeys VFX Bundle

Brackeys (Kenney, Picster, Thomas Iché, CodeManu)

CC0

Free

Explosion and impact flipbooks

Sound effects

Generated by Claude, plus CC0 packs

—

CC0 only

Free

Gunshot, explosion, fuse, roar, hits. Any downloaded sound must be CC0; check each file

Font

Any SIL Open Font License font from Google Fonts

—

OFL

Free

HUD and damage numbers

Ability icons

Drawn in code by Claude

—

Ours

Free

Avoids attribution-required icon sets such as game-icons.net (CC BY 3.0)

Start with the free Standard versions. Pay for UAL Pro only if a clip in the animation table below is missing from Standard; check the animation viewer first.

Character recipes

These are starting points. Final picks depend on what the outfit pack actually contains; confirm by looking at the pack's preview images before downloading.

Character

Body

Outfit direction

Silhouette goal

Powder Captain

Superhero-proportion male

Longest coat available, boots, any wide hat; red and black palette

Broad, coat flares, pistol in one hand

Apex Hunter

Superhero-proportion body

Hooded or leather ranger-style outfit; fur and bone tints

Lean, crouched. The beast feel comes from VFX (claw trails, roar shockwave), not the model

Melee Chaser

Regular-proportion

Peasant outfit, muted brown

Reads as weak fodder at a glance

Ranged Kiter

Regular-proportion

Different peasant or light outfit, green tint, holds a firearm

Distinct color from the chaser

Elite

Superhero-proportion, scaled ×1.25

Knight outfit, dark steel

Largest unit on screen

Training dummy

Any base body

No outfit, flat grey material

Clearly not an enemy

If the outfit pack has no weapon meshes, Claude builds a flintlock, cutlass and bola from primitive shapes in code and attaches them to hand bones. That is acceptable for v0.1.

Animation clips required

Role

Used by

Loops

Needs a calibrated hit frame

Idle

All

Yes

No

Run

All

Yes

No

Melee attack A and B (alternating)

Captain, Hunter, Chaser, Elite

No

Yes

Heavy melee strike

Hunter empowered Rend, Elite slam

No

Yes

Pistol or gun shot

Captain Flintlock, Kiter

No

Yes (muzzle moment)

Throw or cast

Captain Powder Keg and Broadside, Hunter Bola

No

Yes (release moment)

Drink, emote or quick self-buff

Captain Ration

No

No

Roar or shout emote

Hunter Howl

No

Yes (shockwave moment)

Jump start, jump loop, land

Hunter leap

Loop only

Land frame

Hit reaction

All

No

No

Stunned or dazed

All

Yes

No

Death

All

No

No

Download checklist (M0)

☐ Download the Standard zip of each Quaternius pack above from itch.io (name-your-price; $0 is allowed).

☐ Download the Kenney Pirate Kit and Particle Pack.

☐ Unzip everything into a folder outside the repo, e.g. ~/bp-assets-raw/.

☐ Run tree -L 3 ~/bp-assets-raw > assets_tree.txt and send that file to Claude.

☐ Claude replies with the exact list of files to copy into the repo's assets/ folder; copy only those, commit and push.

☐ Claude records every used file in CREDITS.md with author, source link and license.

Raw packs never go into the repo; only the files the game uses do. This keeps the repo small enough to skip Git LFS.

4. Asset pipeline

Assets enter the project as glTF binary (.glb) files and Godot imports them automatically on first open. Every per-asset setting (loops, scale, materials, bone attachments) is applied in code, so no editor clicks are required.

Rules

Format: .glb first. Use .fbx only if a pack has no glTF; Godot imports FBX natively, but glTF is the safer path.

Units: 1 Godot unit = 1 meter. On first import Claude measures each character's height and logs it; bodies should be about 1.8 m. A mismatch is fixed by a scale constant in code, never by editing the file.

Orientation: Godot forward is −Z. If a model faces +Z, the fix is a 180° rotation on its visual child node in the character scene.

No root motion. All movement, leaps and knockbacks are driven by code. Animations play in place. This is what keeps combat timing exact.

One animation library. The UAL clips are loaded once as a shared AnimationLibrary and attached to every character's AnimationPlayer. Same skeleton means every character can play every clip.

Loop flags in code. Idle, run, jump-loop and stunned are set to loop when the library loads.

Materials stay original. Team colors and enemy tints use material overrides set in code.

Weapons attach by bone. A BoneAttachment3D on the right-hand bone holds the weapon mesh, chosen in code.

Repository layout for assets

assets/  characters/    base/          # chosen base body .glb files    outfits/       # chosen outfit part .glb files  animations/    ual1/          # chosen UAL 1 clips (.glb)    ual2/          # chosen UAL 2 clips (.glb)  props/           # kegs, weapons, cannons  environment/     # dungeon pieces, foliage  vfx/textures/    # particle sprites, flipbooks  audio/sfx/       # .wav or .ogg  fonts/CREDITS.md         # every file above: author, link, license

Naming

Folders and files: snake_case. Example: captain_body.glb, keg_explosion_01.wav.

Animation names inside the library keep their original UAL names; a mapping table in data/anim_profiles/ translates roles (attack_a, cast_throw) to clip names, so swapping a clip is a one-line change.

Hit-frame calibration

A stock clip's visual hit moment rarely matches the reference windup, so each attack and cast clip is time-scaled to fit the logic, not the other way round. The logic timing is authoritative; the animation is stretched to match it.

\text{speed\_scale} = \frac{t_{\text{hit, clip}}}{t_{\text{windup, logic}}}

Example: the clip shows the blade connecting at 0.42 s and the logic windup is 0.25 s, so the clip plays at 1.68× speed until the hit, then the backswing plays at whatever speed fills the remaining attack time.

Procedure, done once per clip in M1 (attacks) and M2–M3 (casts):

Open the Anim Lab debug scene Claude builds in M1.

Pick a character and a clip. Press . and , to step one frame.

Stop on the frame where the hit, shot, throw or roar visually lands. The screen shows its frame number and time.

Press M to mark it. The value is written to that clip's profile resource.

Commit the changed file under data/anim_profiles/.

Profile resource (one per clip role)

Field

Example

Meaning

clip_name

Sword_Attack_A

Name in the animation library (example only)

hit_time

0.42

Seconds into the clip where the hit visually lands

clip_length

1.10

Total clip length, read automatically

blend_in

0.05

Crossfade time into the clip

blend_out

0.10

Crossfade time out of the clip

Editor steps you may need to do

None are expected. First open triggers the import automatically. If a specific asset needs an import option that cannot be set from code, Claude will either write its .import settings file directly or give exact click-by-click steps for that one asset.

5. Project architecture

Every unit (player, enemy, dummy, keg) is a scene built from small components, and every action, whether from the mouse or from enemy AI, enters the game as a Command processed by the same unit state machine. Enemies therefore use exactly the same movement, attack and damage code as the player.

runtime architecture · input to damage to feedback

Orders from the mouse and from enemy AI become the same Commands; damage flows one way into health, and the event bus fans results out to everything visual without gameplay depending on it.

Folder structure

project.godotREADME.md              # pinned Godot version, how to run, how to testARCHITECTURE.md        # living summary Claude re-reads every sessionPROGRESS.md            # milestone checklist, known issues, last session notesCREDITS.mdaddons/gut/autoload/              # SimClock, EventBus, DebugConfig, InputRoutercore/  units/               # unit.tscn, unit.gd, action_state_machine.gd  components/          # health, stats, status_effects, attack, movement, targetable  combat/              # damage_request.gd, damage_resolver.gd, projectile.gd  abilities/           # ability_base.gd, ability_runner.gd, targeting.gd  commands/            # command.gd and one file per command typeclasses/  powder_captain/      # captain.tscn, abilities/*.gd, keg/*.gd  apex_hunter/         # hunter.tscn, abilities/*.gd, leap/*.gd, ferocity.gdenemies/               # chaser, kiter, elite, dummy + ai/*.gdworld/                 # arena.tscn, brush_zone.gd, spawners, camera_rigui/                    # hud, ability_bar, health_bars, damage_numbers, cursorvfx/                   # shaders, particle scenes, screen_shake, hit_flashaudio/                 # sfx_player.gd, bus layoutdebug/                 # debug_panel, overlays, combat_log, replay, anim_labdata/  stats/               # UnitStats .tres per unit type  abilities/           # AbilityData .tres per ability  anim_profiles/       # AnimProfile .tres per clip role  encounters/          # wave definitionstests/  unit/                # pure-logic tests (damage math, keg graph, Ferocity)  sim/                 # scripted tick-by-tick scenario testsassets/                # see section 4

Autoloads (global singletons)

Name

Responsibility

SimClock

Counts physics ticks since scene start; converts seconds to ticks (round(s × 60)); owns the time-scale and pause/frame-step for debug

EventBus

Signals for combat events (damage dealt, unit died, ability cast, keg exploded, leap started/landed). UI, audio, VFX and logs listen; gameplay never depends on listeners

DebugConfig

Live overrides of any AbilityData or UnitStats field from the debug panel

InputRouter

Turns raw mouse and keyboard input into Commands for the player's unit

Unit components

Component

Owns

Reads from

StatsComponent

Final stats after buffs/debuffs (AD, armor, attack speed, move speed, crit)

UnitStats resource, StatusEffectComponent

HealthComponent

Current HP, grey health, death and respawn

DamageResolver

StatusEffectComponent

Slow, root, stun, burn, move-speed buffs, camouflage; cleanse

Abilities, damage events

MovementComponent

Path following, facing, dash execution, collision

NavigationAgent3D, state machine

AttackComponent

Attack timer, windup, backswing, reset, chase, target validity

Stats, state machine

AbilityRunner

Four ability slots, cooldowns, charges, cast locks, input buffer

AbilityData resources

TargetableComponent

Selection radius, team, hover highlight

Cursor queries

ActionStateMachine

The unit's current action and legal transitions

Commands, components

Class-specific: KegManager and KegGraph (Captain), LeapController and FerocityComponent (Hunter). Enemies add an AIBrain that emits Commands.

Commands

Command

Fields

Issued by

MoveTo

world point

Right-click ground, AI

AttackUnit

target unit

Right-click enemy, AI

AttackMove

world point

A + left-click, AI

CastAbility

slot (Q/W/E/R), target unit or point or direction

QWER keys, AI

Stop

—

S

Hold

—

H

Data resources

UnitStats — base HP, AD, armor, magic resist, attack speed, windup %, attack range, move speed, selection radius, crit chance.

AbilityData — every number for one ability: cooldown, cast time, range, radius, speed, width, charges, recharge, durations, damage, ratios, provisional flags.

AnimProfile — clip name, hit time, blends (section 4).

EncounterData — wave lists for Challenge mode.

Simulation clock and determinism

All timers are integers in ticks. 0.25 s = 15 ticks, 0.33 s = 20 ticks, 0.35 s = 21 ticks, 0.5 s = 30 ticks.

Gameplay runs only in _physics_process. _process is for visuals.

Randomness (crits, Broadside wave positions) uses one seeded RNG owned by SimClock, so a replay with the same seed and commands gives identical results.

Hit-stop and screen shake are visual only; they never pause the simulation.

6. Controls, input and camera

Right mouse moves and attacks, QWER quick-casts at the cursor with no confirmation click, and every new order replaces the previous one on the next physics tick. Input latency from click to the unit changing course must be one tick (16.7 ms) plus render latency.

Input map

Action

Binding

Behavior

Move / attack

Right mouse (press)

Ground: path to point. Enemy or own keg under cursor: AttackUnit

Continuous move

Right mouse (hold)

Re-issues MoveTo to the cursor every 6 ticks (0.1 s) while held

Select / inspect

Left mouse

Selects a unit to show its stats in the HUD. Never casts or moves

Ability Q / W / E / R

Q / W / E / R

Quick cast at hovered unit or cursor point (rules below)

Attack-move

A, then left mouse

Issues AttackMove to the clicked point. A alone arms the cursor for 3 s; right-click or Esc cancels

Stop

S

Cancels movement and any un-committed attack windup; keeps current target cleared

Hold position

H

Stops moving; still auto-attacks enemies already in range

Center camera

Space (hold)

Camera snaps to player while held

Toggle camera lock

Y

Locked follows the player; unlocked uses edge pan

Zoom

Mouse wheel

Between min and max zoom

Reserved

1–4

Future consumables; unbound in v0.1

Debug panel

F1

Toggle live tuning panel

Hitbox / range overlay

F2

Toggle

State overlay

F3

Unit state, current command, timers

Combat log

F4

Toggle tick-stamped log

Reset arena

F5

Respawn all units, clear kegs and cooldowns

Switch class

F6

Swap Captain and Hunter in training mode

Time scale

F7 / F8

Slower / faster (0.1× to 1×)

Pause / frame step

F9 / F10

Pause simulation / advance one tick

Pause menu

Esc

Resume, restart, quit

Quick-cast targeting rules

Target type

Abilities

Rule

Unit-targeted

Captain Flintlock

Uses the enemy or own keg under the cursor. If none is under the cursor, picks the valid target nearest the cursor within 1.5 m. No target: cast fails with "No target"

Ground-targeted

Captain Powder Keg, Broadside

Uses the cursor ground point. Keg beyond range: the unit walks until in range, then casts. Broadside has no range limit inside the arena

Direction (skillshot)

Hunter Bola

Fires from the unit toward the cursor, travels full range

Self

Captain Ration, Hunter Rend, Howl, Stalk

Casts instantly on the unit

An out-of-range unit-targeted or ground-targeted cast is a pending order: any new move or attack order cancels it.

Cursor and hover

The cursor ray hits a ground plane on its own collision layer; walls and units never block ground picking.

Hover uses a sphere query at the ground point with each unit's selection radius (1.2 m for player-sized units).

When several units overlap, the one whose center is closest to the cursor wins.

Cursor states: default, hover-enemy (red outline on the unit), hover-own-keg (orange), attack-move armed (crosshair), invalid (red flash for 0.3 s with a short reason text).

Camera rig

Parameter

Default

Notes

Projection

Perspective

Gives depth to leaps and explosions

Pitch

56° down from horizontal

Provisional; tune in M5

Field of view

40° vertical

Narrow FOV keeps distortion low at screen edges

Default visible width

About 22 m at screen center

Must show a full 3-keg chain (about 14 m) with margin

Zoom range

0.8× to 1.25× of default distance

Default mode

Locked to player

Toggle with Y

Edge pan speed

25 m/s

Activates within 8 px of the window edge, only when unlocked

Follow smoothing

None on the sim; 0.05 s visual lag

Never smooth the cursor-to-world mapping

Bounds

Clamped to arena plus 4 m

Click feedback

Move click: small green ring at the point, fades over 0.4 s.

Attack click: red ring under the target.

Attack-move click: amber ring at the point.

7. Shared combat systems

All spatial reference values convert at 100 reference units = 1 m, all durations convert to whole ticks at 60 Hz, and basic attacks follow a windup / backswing model where only the windup can be cancelled. The scale factor is one constant (UNITS_PER_METER = 100) so it can be changed in one place.

Player stat blocks

Timing and spatial values follow the reference at level 1. Health and damage are ours, balanced for PvE. Values marked P are provisional until checked in play.

Stat

Powder Captain

Apex Hunter

Source

Max health

1200

1000

Ours

Attack damage (AD)

70

75

Ours

Armor / magic resist

40 / 32

30 / 32

Ours

Base attack speed

0.658 attacks/s

0.667 attacks/s

Reference

Attack windup

16.4% of attack time (P)

20% of attack time (P)

Reference, unverified

Attack range (edge to edge)

1.25 m (P)

1.25 m (P)

Reference standard melee

Gameplay radius

0.65 m

0.65 m

Reference standard

Selection radius

1.2 m

1.2 m

Reference

Move speed

3.45 m/s

3.45 m/s

Reference

Crit chance / crit damage

20% / 175%

20% / 175%

Crit damage reference, chance ours

Basic attack model

T_{\text{attack}} = \frac{1}{\text{attack speed}} \qquad T_{\text{windup}} = w \times T_{\text{attack}} \qquad T_{\text{backswing}} = T_{\text{attack}} - T_{\text{windup}}

For the Captain at base speed: T attack = 1.52 s (91 ticks), windup = 0.25 s (15 ticks), backswing 76 ticks.

Acquire: a valid target in range and attack timer ready → windup starts and the attack timer starts counting from zero.

Windup: the unit faces the target. Any new order before the hit tick cancels the attack: no damage, and the attack timer is refunded so the unit may attack again immediately.

Hit tick: damage is applied (melee) or the projectile spawns (ranged). The attack is committed.

Backswing: any order is accepted instantly with no penalty. This is what makes kiting and animation-cancelling work. The attack timer keeps counting.

Ready: when the attack timer reaches T attack, the next attack may start.

Reset: an attack reset (Hunter Rend) sets the attack timer to ready immediately.

Chase: if the target is out of range, the unit paths toward it, re-pathing every 6 ticks, and attacks on the first tick it is in range.

Uncancellable windup: some attacks (Rend's first hit) ignore new orders until the hit tick; orders are buffered.

Range is measured edge to edge: center distance minus both gameplay radii.

Attack-move

The unit moves toward the clicked point. Each tick it checks for enemies within its attack range plus 0.5 m; if any, it attacks the one closest to itself. When the target dies it resumes moving to the point. Arriving at the point ends the command.

Damage resolution

Type

Reduced by

Used by

Physical

Armor

Basic attacks, Flintlock, kegs, Rend, Bola

Magic

Magic resist

Broadside, Howl, enemy elite slam

True

Nothing

Searing Edge burn

\text{final} = \text{raw} \times \frac{100}{100 + R_{\text{eff}}} \qquad R_{\text{eff}} = R \times (1 - \text{pen\%}) \qquad (R_{\text{eff}} \ge 0)

If the effective resist is negative, the multiplier is 2 − 100 / (100 − R eff). A critical strike multiplies the raw damage by 1.75 before resistances. Every damage instance is a DamageRequest with source, target, raw amount, type, flags (basic attack, crit, area, on-hit, from keg) and armor-pen percent, resolved by one DamageResolver.

Status effects

Effect

Behavior

Stacking

Cleansable

Slow

Reduces move speed by a percent

Only the strongest active slow applies

Yes

Root

No movement or dashes; can attack and cast non-movement abilities; removes leap eligibility

Longest remaining wins

Yes

Stun

No movement, attacks or casts; interrupts windups and casts

Longest remaining wins

Yes

Burn

True damage every 0.5 s over the duration

Reapplying refreshes duration

No

Move-speed buff

Adds a percent to move speed

Different sources add together

No

Camouflage

Enemies beyond 7.1 m cannot see or target the unit

—

No

Move speed = base × (1 + sum of buffs) × (1 − strongest slow).

Unit action states

State

Can move

Can attack

Can cast

Exits to

Idle

Yes

Yes

Yes

Any

Moving

Yes

Yes

Yes

Any

Chasing

Yes

On reaching range

Yes

Attack windup, any order

Attack windup

No

—

Yes, cancels attack

Backswing, or any order (cancel)

Attack backswing

Yes, instantly

Waits for timer

Yes

Any

Casting

No (cast time)

No

Buffered

Previous intent after cast

Dashing / leaping

Controlled

Landing attack only

Yes (Hunter)

Idle or chase on land

Rooted / stunned

Per table above

Per table above

Per table above

Previous intent on expiry

Dead

No

No

No

Respawn

Cooldowns, cast locks and buffering

Cooldowns start on cast start and count in ticks.

During a cast time or uncancellable windup, one new input is buffered (last input wins). It executes on the first tick the lock ends, if still valid. A buffered input expires after 30 ticks (0.5 s, provisional).

Casting an ability during an attack windup cancels the attack (refunded timer), except where noted.

After a cast completes, the unit resumes its previous intent: continue moving, or keep attacking the same target.

Death and respawn

Player: respawns at the arena spawn point after 3 s with full health, abilities ready.

Dummies: respawn in place after 2 s.

Enemies: no respawn in Challenge mode; F5 resets the wave.

Combat events (all logged with tick number)

order_issued, attack_windup_started, attack_cancelled, attack_hit, ability_cast_started, ability_cast_completed, ability_cast_failed(reason), damage_dealt, status_applied, status_expired, keg_placed, keg_decayed, keg_exploded, leap_started, leap_landed, ferocity_changed, unit_died, unit_respawned.

8. Powder Captain

The Captain wins fights by pre-placing kegs that decay from 3 to 1 health, then detonating one with a melee hit or a pistol shot so the explosion chains to every connected keg at 0.33 s intervals. Reference values come from the League of Legends Wiki page fetched on 31 Oct 2026; values marked P are provisional, and damage numbers are ours. Gangplank reference

Passive — Searing Edge

Field

Reference

MVP

Notes

Cooldown

15 s static

15 s

Starts after the empowered hit lands

Effect

Next basic attack burns for true damage over 2.5 s

120 true damage, 5 ticks of 24 every 0.5 s

Ours

Move-speed buff on hit

15–30% for 2 s

25% for 2 s

Reset

Any keg explosion resets the cooldown and grants the move-speed buff

Same

One reset per chain, not per keg (P)

Exclusions

Not applied by the pistol or kegs

Same

Q — Flintlock

Field

Reference

MVP

Notes

Target

Unit-targeted, enemy or own keg

Same

Homing projectile, cannot miss

Range

625 units

6.25 m

Edge to edge

Cast time

0.25 s

15 ticks

Cooldown starts on cast start

Projectile speed

2600 units/s

26 m/s

Cooldown

4.5 s

4.5 s

Damage

Ratio of AD

40 + 100% AD physical

Ours. Can crit at 175%

On keg

Deals 1 damage to the keg

Same

Counts as the triggering attack for the explosion

W — Ration

Field

Reference

MVP

Notes

Cast time

0.25 s

15 ticks

Cooldown

22–14 s by rank

18 s

Heal

Flat + 13% missing health

100 + 13% missing health

Cleanse

All crowd control

Removes slow, root, stun

Burn is not removed

E — Powder Keg

Field

Reference

MVP

Notes

Cast time

0.25 s

15 ticks

Delay between casts

0.5 s static

30 ticks

Range

1000 units

10 m

Out of range: walk, then place

Charges

3 / 3 / 4 / 4 / 5 by rank

3 (debug: 3, 4 or 5)

Recharge per charge

17–13 s by rank

13 s

One charge at a time

Lifetime

25 s

25 s

Expired kegs fade without exploding

Health

Starts at 3

3

Each Captain basic attack or Flintlock deals exactly 1

Decay

Loses 1 max health every 2 / 1 / 0.5 s by level, minimum 1

Tier selectable: 2.0 / 1.0 / 0.5 s; default 1.0 s

Level thresholds unknown, so the debug panel picks the tier directly. Tier is locked in when the keg is placed

Explosion radius

345 units

3.45 m

Hits a unit if center distance ≤ 3.45 m + its gameplay radius

Connection

Kegs with overlapping areas connect

Center distance ≤ 6.9 m (P)

Twice the radius; tune if combos feel too loose or tight

Chain delay

0.33 s per explosion

20 ticks

Hits per chain

Each enemy hit once per chain

Same

Tracked by a per-chain hit set

Explosion damage

The triggering attack's damage, ignoring 40% armor; crit adds 5%

Same rule

Payload is snapshotted when the root keg is destroyed

Bonus damage

Bonus physical damage vs champions

135 bonus vs Elite only

Elites stand in for champions

Slow

40–80% for 2 s

60% for 2 s

Who can damage kegs

The Captain and enemies

The Captain only

Enemy keg-attacking is a toggle, off by default

Placement

—

Not inside walls; minimum 0.8 m between kegs (P)

R — Broadside

Field

Reference

MVP

Notes

Cast time

0.25 s

15 ticks

Range

Global

Anywhere in the arena

Cooldown

160–120 s

30 s

Shortened for training

Area

580-unit radius

5.8 m

Inner 170-unit radius exists in the reference; its effect is undocumented, so it is not implemented

Duration and waves

12 waves over 8 s in clusters of 3 every 2 s

Same

Spacing inside a cluster: 0.25 s (P). First cluster 0.5 s after cast (P)

Per wave

Magic damage to all enemies in the area, 30% slow for 0.5 s

40 magic damage, same slow

Ours

Visual

—

Cannonballs fall at seeded random points in the circle

Damage is area-wide, not per cannonball

Keg graph rules

Nodes are all live kegs, plus pending kegs: an E cast in progress at a fixed target point.

Edges connect any two nodes whose centers are within the connection distance. Edges are recomputed whenever a node is added or removed (at most 6 nodes, so a full pairwise check is fine).

Trigger: when a keg reaches 0 health from a Captain hit, it explodes on that tick. A new chain is created with a damage payload and an empty hit set.

Propagation: on the tick a keg explodes, every node connected to it that is not already exploded or scheduled is scheduled to explode 20 ticks later. This check runs at explosion time, so kegs placed after the chain started still join it if they connect in time.

Pending kegs: a pending keg that a chain reaches is scheduled at whichever is later: its materialize tick, or the scheduling tick + 20. This reproduces the reference's "phantom keg" behavior and is what makes the one-part combo possible (see below). Flagged P; it needs calibration.

Safety: scheduled explosions live in a queue keyed by tick, never recursion. Each keg has a unique id and an exploded flag. Freed kegs are removed from the graph on the same tick.

Damage: each explosion damages every enemy in radius that is not in the chain's hit set, then adds them to it.

Combos to support

Combo

Setup

Expected result

Single

One keg at 1 health; hit or shoot it

Explodes on the hit tick

Two-keg chain

Keg A at 1 health, keg B within 6.9 m; detonate A

A at tick t, B at t + 20

Three-keg chain

A, B, C in a line, each within 6.9 m of the next

A at t, B at t + 20, C at t + 40

Two-part

Keg A at 1 health; place keg B linked to A; then detonate A

Same as two-keg chain

Chain extension

Detonate A; during the 20-tick wait, place C linked to B

C joins and explodes at B + 20 or on materializing, whichever is later

One-part

Keg A at 1 health; Flintlock A, then immediately E a keg linked to A

The new keg explodes as part of the chain thanks to rule 5

Why rule 5 matters: E cannot start until the Flintlock cast ends (tick 15), so the new keg materializes at tick 30. The Flintlock reaches a keg 6 m away at about tick 29 (15 + 14 ticks of travel). Without pending-keg chaining, the one-part combo would fail by one tick.

Captain acceptance tests (automated)

☐ A new keg reads 3, 2, 1 health at placement, +60 and +120 ticks at the 1.0 s tier, then stays at 1.

☐ A keg expires at +1500 ticks without exploding.

☐ Three-keg chain explodes at t, t + 20, t + 40 exactly.

☐ A dummy inside all three radii takes damage once.

☐ Two kegs 7.0 m apart do not connect; 6.9 m apart do.

☐ Destroying a keg that is already scheduled does not double-explode it.

☐ Pending keg linked during the chain explodes on materialize.

☐ Keg explosion resets Searing Edge and grants the move-speed buff.

☐ Charges: 3 used, the fourth cast fails with "No charges"; one charge returns after 780 ticks.

9. Apex Hunter

The Hunter wins fights by attacking from brush, which turns a basic attack into a 7.45 m leap at 14.5 m/s that lands an attack on arrival, while every ability cast builds Ferocity toward one empowered ability at 4 stacks. Reference values come from the League of Legends Wiki page fetched on 31 Oct 2026; values marked P are provisional, and damage numbers are ours. Rengar reference

Passive — Ambush Pounce

Field

Reference

MVP

Notes

Eligibility

In brush, or during Stalk's camouflage

Same

Linger after leaving brush

0.35 s

21 ticks

Leap range

745 units, edge range

7.45 m edge to edge

Leap speed

1450 units/s

14.5 m/s

A 7 m leap takes about 29 ticks

Landing distance

50 units from target

0.5 m from target's edge

Won't leap if

Target already in normal attack range

Same

Does a normal attack instead

Leap requires

Attack timer ready

Same

Otherwise the Hunter does not path toward the target

Rooted

Loses the leap range

Same

Abilities during leap

Any ability can be cast mid-leap

Same

Leap destination

Leaps to the target's location

Target position sampled at leap start; not homing (P)

Calibrate against a clip if it feels wrong

Landing attack

Goes off at the end of the dash even if the target moved, lost sight or the path was blocked

Same

If the target died, the attack has no effect but still consumes Rend

Ferocity on leap

+1 at leap start if no current stack came from a leap

Same, via a leap_stack_present flag

Flag clears when Ferocity hits 0

Arc

—

Visual parabola, 1.2 m peak

Visual only

Ferocity

Rule

MVP

Maximum

4 stacks

Gain

+1 on casting Howl or Bola; +1 when Rend's first empowered attack lands; +1 from a leap (rule above). Stalk gives none

At 4 stacks

The next basic ability (Q, W or E) is the empowered version, consumes all 4, and grants 40% move speed for 1.5 s

Decay

All Ferocity is lost after 10 s (600 ticks) without dealing or taking damage. Burn ticks do not count

Lockout on reaching 4

Reaching 4 via Rend or Bola locks that ability's empowered version for 6 ticks

Lockout on consuming

The unempowered version of the consumed ability is locked for 6 ticks (15 ticks for Howl)

Cooldown interaction

Empowered casts ignore and do not start the base cooldown (P, verify)

Q — Rend

Field

Reference

MVP

Notes

Cast time

None

0

Cooldown

6–4 s

5 s

Buff

Next two attacks within 3 s gain 40% attack speed

Same

First attack

Uncancellable windup, +25 range, bonus damage

+0.25 m range, 60 bonus physical

Ours. The bonus range is lost 0.25 s after gaining leap eligibility

Attack reset

Resets the attack timer

Same

Cast right after a hit for a double strike

Empowered

Bigger damage plus 50–101% attack speed for 5 s

150 bonus physical, +75% attack speed for 5 s

Ours

Mid-leap

Empowers the landing attack

Same

Landing attack becomes Rend's first hit

W — Howl

Field

Reference

MVP

Notes

Cast time

None

0

Cooldown

16–10 s

12 s

Radius

450 units

4.5 m

Damage

Magic

90 magic

Ours

Grey health

Stores 50% of post-mitigation damage taken in the last 1.5 s

Same, rolling 90-tick window

Shown as a grey segment on the health bar

Heal

Heals for the stored grey health

Same

Empowered

More damage and a full cleanse

160 magic, removes slow, root, stun

E — Bola

Field

Reference

MVP

Notes

Cast time

0.25 s; none while leaping

15 ticks; 0 mid-leap

Cooldown

10 s

10 s

Range

1000 units

10 m

Width

140 units

1.4 m

Speed

1500 units/s

15 m/s

Hit

First enemy hit

Same

Walls stop it

Effect

Slow 30–90% for 1.75 s

60% slow for 1.75 s, 80 physical

Damage ours

Empowered

Root instead of slow

Root for 1.75 s (P), 140 physical

Root duration not stated in the reference

Buffering

Q or W pressed during the cast fire right after it

Same

Launch point

Where the Hunter stands at the end of the cast; aim point fixed at cast start

Same

R — Stalk

Field

Reference

MVP

Notes

Cast time

None

0

Cooldown

100–80 s

30 s

Shortened for training

Duration

12–20 s

12 s

Move speed

+40–60%

+50%

Camouflage

After 2 s, gains camouflage and leap eligibility

Same (120 ticks)

Enemies farther than 7.1 m cannot see or target the Hunter

Mark

Nearest enemy is marked

Nearest enemy within 16 m gets a marker

Marked bonus

Next attack on the marked enemy: 100% AD bonus, armor reduced 15–25 for 4 s

100% AD bonus, −20 armor for 4 s

Ends when

Attacking or casting anything except Rend

Same

A leap attack ends it at the end of its windup

Brush zones

Each brush is an Area3D with a box shape and tall-grass visuals. A unit is in brush when its center is inside.

AI vision: an enemy outside the brush loses sight of the player 0.5 s after the player enters it, unless the enemy is within 1.5 m or was hit by the player in the last 1 s. Units in the same brush see each other.

A brush icon on the HUD glows while leap eligibility is active, including the 0.35 s linger.

Leap state machine

leap state machine · 7 states

Target locked and Airborne begin on the same tick; the only exits from Airborne are a landing (Impact) or a stun (Interrupted).

Leap interruption rules

Situation

Result

Hunter leaves brush before the leap starts

Eligibility lingers 21 ticks, then the order becomes a normal chase

Hunter rooted before leap start

No leap; normal chase

Hunter stunned mid-air

Leap ends where the Hunter is; no landing attack (P)

Target dies mid-air

Hunter lands at the destination; attack has no effect; Rend is consumed

Target runs out of range mid-air

Attack still goes off on landing

Destination blocked by a wall

Hunter stops at the wall; attack still goes off

New move order mid-air

Ignored until landing, then executed (buffered)

Hunter acceptance tests (automated)

☐ Attack order on a dummy 7.4 m away from inside brush starts a leap; 7.6 m away does not.

☐ Leap from brush still works 20 ticks after exiting; fails at 22 ticks.

☐ Leap of distance d lands after round(d / 14.5 × 60) ticks.

☐ Bola cast mid-leap fires on the same tick with no cast time.

☐ Rend cast then attack: attack timer resets and the next attack starts immediately.

☐ Ferocity: Howl, Bola, Rend hit, leap → 4 stacks; next ability is empowered and stacks return to 0.

☐ Ferocity drops to 0 after 600 ticks of no combat.

☐ Howl heals exactly 50% of damage taken in the previous 90 ticks.

10. Arena, enemies and AI

One rectangular arena, 36 m by 28 m, hosts both modes: Training (dummies, unlimited time, instant reset) and Challenge (three scripted waves of real enemies). It starts as untextured boxes in M1 and is dressed with the dungeon pack in M5 without changing any collision.

Arena layout

Element

Spec

Floor

36 × 28 m, flat, single navigation region

Outer walls

2 m high, 1 m thick, on all four sides

Pillars

4 square pillars, 2 × 2 m, placed so straight paths and navigation around corners are both tested

Low wall

One 6 m wall segment in the middle third, so leaps and Bola collisions against walls can be tested

Brush zones

2 zones, 6 × 3 m each, near the dummy line on opposite sides

Player spawn

Center of the south edge, 3 m from the wall

Dummy line

5 dummy slots, 3 m apart, east–west, in the north half

Enemy spawns

3 gates on the north and side walls

Training dummies

Setting

Options

Default

Behavior

Stationary / Strafe (moves 3 m side to side at 3.45 m/s) / Chase player slowly

Stationary

Armor

0 / 50 / 100

50

Health

2000 / 10 000 / Infinite

Infinite, with a damage-per-second readout

Count

1–5

3

Counts as Elite

On / Off (for keg bonus damage tests)

Off

Enemy types

Stat

Melee Chaser

Ranged Kiter

Elite

Max health

450

350

2200

Damage per attack

30 physical

25 physical

60 physical; slam 120 magic

Armor / magic resist

20 / 20

10 / 20

60 / 40

Move speed

3.3 m/s

3.0 m/s

2.9 m/s

Attack range

1.25 m

6.0 m, projectile at 15 m/s

1.5 m

Attack speed / windup

0.8 / 25%

0.7 / 30%

0.6 / 30%

Gameplay radius

0.55 m

0.55 m

0.8 m

Special

None

Keeps 5–6.5 m away

Telegraphed slam every 8 s

All enemy numbers are first-pass and tuned in M4.

AI behavior

Every AI runs a small explicit state machine and outputs the same Commands as the player.

Melee Chaser: Idle → Acquire (player within 12 m and visible) → Chase → Attack → back to Chase when out of range. Loses the player after 3 s without sight and returns to its spawn.

Ranged Kiter: Acquire as above. If the player is closer than 5 m, retreats away from the player for up to 1.5 s (staying on the navigation mesh), then attacks. Between 5 and 6.5 m it stands and attacks. Farther than 6.5 m it approaches.

Elite: Chases and attacks like a chaser. Every 8 s, if the player is within 4 m, it stops and telegraphs a slam: a red ground circle of 2.5 m radius that fills over 1.0 s (60 ticks). On completion, everything inside takes 120 magic damage and is stunned 1.0 s. The telegraph cannot be cancelled once started, which is the counterplay window.

Movement and crowding

Each enemy uses a NavigationAgent3D with avoidance on, so groups spread around the player instead of stacking.

Re-path every 6 ticks while chasing; never every tick.

Enemies do not attack kegs (toggle in the debug panel).

Challenge mode waves

Wave

Enemies

Starts

1

4 Melee Chasers

3 s after the mode starts

2

3 Melee Chasers, 2 Ranged Kiters

4 s after wave 1 is cleared

3

1 Elite, 2 Melee Chasers

4 s after wave 2 is cleared

Winning shows the clear time and damage taken. Dying shows the wave reached. F5 restarts.

11. HUD, feedback, VFX and audio

Every timing-critical state (keg health, decay countdown, chain links, leap eligibility, Ferocity, attack timer) must be readable on screen at a glance, because combo timing that cannot be seen cannot be learned. Feedback is mostly procedural (shaders, particles, tweens) and never alters the simulation.

HUD elements

Element

Position

Spec

Ability bar

Bottom center

Passive + Q W E R slots with key labels; radial cooldown sweep plus seconds remaining (one decimal under 3 s); greyed when unusable; red flash on failed cast

Keg charges

Above the E slot

One pip per charge; a filling ring shows recharge progress

Ferocity

Above the ability bar (Hunter)

4 pips; glow and pulse at 4; leap-generated stack drawn in a distinct color

Leap eligibility

Left of the bar (Hunter)

Claw icon lit while eligible, including linger

Player health

Bottom center, under the bar

Numeric and bar; grey-health segment for Howl

Status icons

Above player health

Slow, root, stun, burn, buffs with remaining time

Unit health bars

Above every unit

Team colored; ticks every 100 HP; grey segment where relevant

Selected-unit panel

Top left

Name, HP, armor, MR, current state

Mode banner

Top center

Training / Challenge wave n, timer

Cast-fail text

Near the cursor

"Out of range", "No charges", "No target", "On cooldown", "Rooted"; 0.6 s

In-world indicators

Indicator

Spec

Keg health

3 pips over each keg; the next pip to drop shows a shrinking ring counting down the decay interval

Keg links

Dark powder-trail line between connected kegs; brightens while a chain is scheduled

Keg explosion radius

Faint ring around each keg while any keg is hovered or the F2 overlay is on

Pending keg

Translucent keg at the target point during the E cast

Leap target

Red pulsing ring under the enemy that a right-click would leap to

Elite telegraph

Red circle filling over 1.0 s

Bola path

Thin line from the Hunter toward the cursor while the F2 overlay is on

Broadside area

Ring showing the area for the full 8 s

Attack range

Thin ring around the player while F2 overlay is on

Damage numbers

Physical: white. Magic: blue. True: orange. Heal: green.

Crits: 1.4× size with a short punch-scale.

Numbers rise 0.8 m over 0.7 s with slight random sideways drift, then fade.

Damage from one keg chain on one unit is shown as one number.

Visual effects

Event

Effect

Basic hit

Hit flash on target (white shader flash, 3 frames), small spark burst

Crit

Larger spark burst, 40 ms hit-stop (visual only)

Flintlock

Muzzle flash, smoke puff, bright tracer on the projectile

Keg explosion

Flipbook fireball, smoke column, debris particles, ground scorch decal for 3 s, screen shake scaled by distance

Chain

Fuse spark runs along the powder trail during the 20-tick delay

Searing Edge

Blade glow while ready; flame particles on the burning target

Ration

Green swirl, citrus-colored particles

Broadside

Falling cannonball streaks, small explosions at impact points

Leap

Motion trail, dust burst on takeoff and landing, small screen punch on impact

Rend

Claw-slash arc on hit; brighter arc when empowered

Howl

Expanding shockwave ring, 4.5 m

Bola

Spinning bola mesh; tether ring around a slowed or rooted target

Stalk

Character fades to 30% opacity with a shimmer; marked enemy gets an eye icon

Ferocity full

Hands or weapon glow; pulse ring

Death

Ragdoll-free: death clip, then sink and fade

Screen shake

Source

Strength

Duration

Keg explosion

0.25 at the player, fading to 0 at 15 m

0.25 s

Leap impact

0.15

0.12 s

Elite slam hit on player

0.35

0.3 s

Shake and hit-stop affect only the camera and animation playback, never simulation ticks.

Audio

Sound

Source plan

Melee swing and hit, light and heavy

Generated, plus CC0 pack if better

Pistol shot, projectile whizz

Generated

Keg place (thunk), fuse hiss, explosion (3 variants)

Generated

Cannon boom, cannonball impacts

Generated

Leap whoosh, landing thud

Generated

Roar

CC0 animal roar, pitch-shifted, if found; otherwise generated

Bola throw, snap on hit

Generated

UI: cast fail, cooldown ready, charge ready, Ferocity full

Generated

Enemy hit, death, elite telegraph warning

Generated

Audio buses: Master, SFX, UI. Each sound randomizes pitch ±5% to avoid repetition. No music in v0.1.

12. Debug tooling and testing

Logic is proven by automated tests that Claude runs headlessly before handing over any change; feel is proven by Ishak in the debug build, using live sliders instead of describing problems in words. A change is not delivered until it parses, its tests pass, and it has manual test steps attached.

Debug panel (F1)

One collapsible section per ability and per unit type, listing every field of its AbilityData or UnitStats resource as a slider or number box.

Changes apply on the next tick, no restart.

Export writes the current values to a .tres diff file you send back; Claude folds them into the real resources.

Reset to file discards live changes.

Global controls: keg decay tier, keg charges (3/4/5), enemy keg-attacking toggle, dummy settings, class switch, RNG seed, time scale.

Overlays

Key

Shows

F2

Gameplay radii, selection radii, attack ranges, explosion radii, keg links, navigation paths, Bola path

F3

Per-unit text: state, current command, attack timer (ticks), cooldowns, statuses, Ferocity, leap eligibility

F4

Scrolling combat log, each line stamped with its tick

Time controls

Time scale 0.1× to 1× (F7/F8). The simulation still runs whole ticks; only how often ticks happen changes.

Pause (F9) and single-tick step (F10) for inspecting combo windows tick by tick.

Combat log and replay

The log can be exported as CSV: tick, event, source, target, value, extra.

Every player Command is recorded with its tick. Save replay writes the command list plus RNG seed; Load replay re-runs it and must reproduce the same log byte for byte. This turns any bug you hit into a file Claude can reproduce exactly.

Anim Lab scene

A separate debug scene for hit-frame calibration (section 4): pick a character and clip, frame-step, mark the hit frame, save to the profile.

Automated tests (GUT)

Suite

Covers

tests/unit/test_damage.gd

Armor and magic resist formula, negative resist, armor penetration, crit multiplier

tests/unit/test_ticks.gd

Seconds-to-ticks conversion, cooldown counting

tests/unit/test_status.gd

Strongest slow only, root vs stun permissions, cleanse

tests/unit/test_keg_graph.gd

Edges at 6.9 vs 7.0 m, propagation order, no double explosion, pending kegs

tests/unit/test_ferocity.gd

Gain, consume, decay at 600 ticks, lockouts

tests/sim/test_basic_attack.gd

Windup, cancel refund, backswing cancel, reset, chase

tests/sim/test_captain_combos.gd

Every row of the Captain acceptance list (section 8)

tests/sim/test_hunter_leap.gd

Every row of the Hunter acceptance list (section 9)

tests/sim/test_replay.gd

A recorded replay reproduces the same combat log

Sim tests build a tiny scene in code, issue Commands on exact ticks, step the physics loop manually and assert on the combat log.

Claude's verification before every hand-off

Headless parse check of the whole project; zero errors.

Run the full GUT suite from the command line; zero failures.

Launch the main scene headlessly for 600 ticks; zero runtime errors in the output.

List files changed, manual test steps, and known limitations in the hand-off message.

If headless Godot cannot be installed in Claude's workspace, steps 1–3 move to Ishak: run one provided command and paste the output.

Ishak's manual test routine per hand-off

Pull, open the project, wait for import.

Run the game (F5 in the editor).

Follow the manual test steps from the hand-off.

Report using the feedback template (section 15), with a clip if anything feels wrong.

Reference calibration (optional)

Wiki values are the default. Only if something feels wrong and the cause is unclear: find a reference clip of the mechanic, record it at 60 fps, step through it in mpv and note the frame numbers of the relevant moments (for example: shot fired, first keg explodes, second keg explodes). Claude compares them with the tick log.

13. Milestones and acceptance criteria

The MVP is six milestones, M0 to M5, each ending in a playable build, a tagged commit and Ishak's explicit approval; nothing in a later milestone starts until the earlier one is approved. Durations are rough part-time estimates, not commitments, and integration bugs can extend any of them.

MVP roadmap · 6 milestones, 6 gates

Realistic total: 17 to 35 working days, roughly 4 to 7 weeks part-time, dominated by M2 and M3.

M0 — Setup (0.5–1 day)

Deliverable: an empty project that launches, with tests running.

☐ Ishak installs Godot (exact 4.7.x), export templates, Git, OBS, mpv.

☐ Ishak creates the private GitHub repo and shares its name.

☐ Claude attaches the repo, creates the folder structure, project.godot, input map, autoloads, GUT, README.md, ARCHITECTURE.md, PROGRESS.md.

☐ Claude confirms whether headless Godot runs in its workspace.

☐ Ishak downloads asset packs and sends the file tree (section 3).

☐ Ishak opens the project; it launches to a grey test room with no errors.

M1 — Foundation (2–4 days)

Deliverable: a playable movement-and-attack sandbox with capsule units.

☐ Graybox arena with walls, pillars, low wall, brush zones (visual only) and dummy slots.

☐ Right-click move with pathfinding around pillars; hold-to-move works.

☐ Right-click enemy: chase, attack, retarget instantly on a new click.

☐ Windup cancel refunds the attack; backswing cancel loses nothing; tests pass.

☐ Attack-move, stop, hold.

☐ Damage, armor, crits, death, respawn; damage numbers.

☐ Camera: locked/unlocked, edge pan, zoom, center on Space.

☐ Health bars and a placeholder ability bar with working cooldown display (test ability).

☐ Debug panel, F2–F4 overlays, time scale, pause, frame step, combat log.

☐ Characters swapped from capsules to the chosen Quaternius bodies with idle, run and attack clips; Anim Lab works and attack hit frames are calibrated.

M2 — Powder Captain (4–8 days)

Deliverable: a keg-combo training arena.

☐ Flintlock with homing projectile, keg damage, cooldown.

☐ Powder Keg: charges, recharge, placement range, decay tiers, lifetime, health pips and countdown rings.

☐ Keg graph: links, chain delay, hit-once rule, pending kegs.

☐ Combos: single, two-keg, three-keg, two-part, chain extension, one-part all performable by hand.

☐ Searing Edge with keg reset.

☐ Ration heal and cleanse.

☐ Broadside with timed waves.

☐ Captain acceptance tests (section 8) all pass.

☐ Ishak can perform a three-keg chain on 3 dummies five times in a row.

M3 — Apex Hunter (4–8 days)

Deliverable: a hunter combat arena.

☐ Brush zones affect eligibility; linger works; HUD claw icon.

☐ Leap: target lock, airborne arc, landing attack, interruption rules.

☐ Rend with attack reset and uncancellable first windup.

☐ Bola mid-leap with no cast time; slow and empowered root.

☐ Howl with grey health and empowered cleanse.

☐ Ferocity: gain, empowered selection, lockouts, decay.

☐ Stalk: camouflage after 2 s, leap anywhere, mark bonus.

☐ Hunter acceptance tests (section 9) all pass.

☐ Ishak can do brush leap → Bola mid-air → Rend reset → empowered ability, reliably.

M4 — PvE validation (3–7 days)

Deliverable: a repeatable combat challenge.

☐ Melee Chaser, Ranged Kiter and Elite with their AI.

☐ Elite telegraphed slam and stun.

☐ AI uses brush-vision and camouflage rules.

☐ Challenge mode with three waves, win and lose screens.

☐ Both classes can clear Challenge mode; neither trivially.

☐ Replay save and load reproduces a full Challenge run.

M5 — Polish and export (3–7 days)

Deliverable: the offline v0.1 executable.

☐ Arena dressed with dungeon and foliage assets; collision unchanged.

☐ All VFX, screen shake, hit-stop and sounds from section 11.

☐ Final camera tuning and input-feel pass.

☐ Pause menu.

☐ Linux and Windows exports; each runs on a machine with networking disabled.

☐ CREDITS.md complete; in-game credits screen.

☐ Full regression list below passes.

Definition of done (whole MVP)

☐ Movement around obstacles; right-click attack with chase; instant retarget.

☐ QWER quick cast for both classes.

☐ Damage, armor, crit, cooldowns, death and respawn.

☐ Every keg acceptance test and every leap acceptance test passes.

☐ Regression: attack cancel during move; cast during windup; rapid repeated inputs; wall collisions during leaps and Bola; multi-target chains; enemy death during leap; class switch mid-fight; F5 reset mid-chain.

☐ Offline launch on Linux and Windows.

☐ Ishak signs off on feel for both classes.

14. Risk register

The two risks most likely to sink the MVP are not single features but feel that Claude cannot observe and context lost between sessions; both are mitigated by process (sliders, replays, repo docs) rather than code. The rest are specific mechanics, sorted by risk.

#

Risk

Likelihood

Impact

Mitigation

Watch in

1

Combat feels wrong in ways that are hard to describe

High

High

Live sliders for every value; 60 fps clips; feedback template; replays for exact reproduction

M1 onward

2

Context decay: later sessions forget earlier design and break it

High

High

ARCHITECTURE.md and PROGRESS.md re-read every session; full test suite before every hand-off; no rewrites without permission

M2 onward

3

One-part keg combo fails by a tick or two

Medium

High

Pending-keg rule (section 8, rule 5); tick-exact tests; tunable chain delay and spawn timing

M2

4

Click-to-move feels laggy or jittery

Medium

High

Orders applied next tick; no smoothing on cursor mapping; re-path throttled to 6 ticks; physics interpolation for visuals only

M1

5

Animation does not line up with logic timing (hits look late or early)

High

Medium

Logic is authoritative; clips time-scaled from calibrated hit frames; Anim Lab

M1, M3

6

Mid-leap casting and leap interruption edge cases

Medium

Medium

Explicit leap state machine and interruption table; dedicated sim tests

M3

7

Attack-cancel and buffering rules conflict (inputs eaten or doubled)

Medium

Medium

One buffer slot, last-wins, 30-tick expiry; regression list covers rapid inputs

M1, M3

8

Asset rig or style mismatch

Low (if section 3 is followed)

High

One Quaternius family only; no Mixamo; check previews before download

M0, M1

9

Enemy crowding and navigation jitter around the player

Medium

Medium

Avoidance on; throttled re-path; separation radius tuning

M4

10

Headless Godot not installable in Claude's workspace

Medium

Medium

Fallback: Ishak runs one command and pastes output; doubles bug-report load

M0

11

Editor or game window problems on Hyprland/Wayland

Low

Low

Launch with --display-driver x11

M0

12

Windows export broken but untested

Medium

Medium

Test on a real Windows machine or VM before M5 sign-off

M5

13

Scope creep into 3D polish before combat is proven

High

Medium

Capsules until M1's last step; dressing only in M5; out-of-scope list in section 1

All

14

Reference values wrong or outdated

Medium

Low

Values marked P; wiki cited with date; feel overrides reference when they disagree

M2, M3

15

IP exposure on public release

Low for private use

High if published

Original names, models, sounds and UI; legal review before any public distribution

Before release

15. Open decisions, workflow and reference

Every choice this guide made on your behalf is listed below with its default; change any of them before the milestone that needs it and the guide gets updated first. Everything else in this section is how each working session runs.

Open decisions

#

Decision

Default in this guide

Needed by

D1

Repository name and GitHub account

blood-and-powder, private

M0

D2

Exact Godot patch version

Newest 4.7.x stable on M0 day

M0

D3

Camera default

Locked to player

M1

D4

Unit scale

100 reference units = 1 m

M1

D5

Hunter body type (male or female base)

Your pick from the previews

M1

D6

Keg decay tier default

1.0 s

M2

D7

Keg connection distance

6.9 m

M2

D8

Enemies can attack kegs

Off

M2

D9

Leap destination: fixed at start or homing

Fixed at start

M3

D10

Empowered Hunter abilities ignore cooldowns

Yes

M3

D11

Buy UAL Pro ($9.99)

Only if a required clip is missing

M1

D12

Game title in builds

Blood & Powder

M5

Session protocol

Every build prompt follows the same shape so context survives between sessions.

You name the milestone and slice (for example: "M2, keg graph and chaining").

Claude pulls the repo and reads ARCHITECTURE.md, PROGRESS.md and this guide's relevant section.

Claude builds only that slice, runs the verification steps (section 12) and pushes to a branch.

Claude's hand-off lists: files changed, what to test and how, known limitations, and any guide change it proposes.

You test, then reply with the feedback template.

On approval, Claude merges, updates PROGRESS.md and ticks the milestone boxes in this guide.

Feedback template

Slice: M?, <name>Build works: yes / no (paste errors if no)What I did: <steps>Expected: <what should happen>Got: <what happened>Feel notes: <too slow / too fast / floaty / delayed, with numbers if tuned>Tuned values (debug panel export attached): yes / noClip or replay attached: yes / noApprove slice: yes / no

What you provide, per milestone

Milestone

You provide

M0

Installed tools, repo name, asset file tree, first launch confirmation

M1

Hand-picked character bodies; hit-frame marks for attack clips; feel feedback on movement and attacks

M2

Keg combo playtests; decay tier and connection distance feel; cast-clip hit marks

M3

Leap and Ferocity playtests; leap clip marks; Hunter look approval

M4

Challenge mode runs on both classes; difficulty feedback

M5

Visual and audio approval; Windows test; final sign-off

Glossary

Term

Meaning

Tick

One physics step, 1/60 s. All gameplay timers count ticks

Windup

Part of an attack before damage; cancellable unless stated

Backswing

Part of an attack after damage; any order is accepted instantly

Attack reset

Makes the attack timer ready immediately

Edge-to-edge range

Center distance minus both units' gameplay radii

Quick cast

Ability fires on key press at the cursor, no confirm click

Chain

A sequence of keg explosions sharing one damage payload and hit set

Pending keg

A keg whose placement cast is in progress; it can join a chain

Leap eligibility

The Hunter's ability to turn an attack into a leap (brush, linger, Stalk)

Ferocity

The Hunter's 0–4 resource; at 4 the next basic ability is empowered

Grey health

Recent damage taken that Howl converts to healing

P (provisional)

A value not yet verified in play or against the reference

CC0

Public-domain dedication; free for any use with no attribution required

Sources (opened or checked 31 Oct 2026)

League of Legends Wiki — Gangplank

League of Legends Wiki — Rengar

Godot releases on GitHub

Godot 4.8 Beta 1 report

GUT — Godot Unit Test

Quaternius — Universal Animation Library

Quaternius — Universal Animation Library 2

Quaternius — Universal Base Characters

Quaternius — Modular Character Outfits: Fantasy

Shared-skeleton compatibility writeup

Quaternius — LowPoly Modular Dungeon Pack

Kenney — Pirate Kit announcement

Kenney Particle Pack for Godot

Brackeys VFX Bundle

Mixamo and alternatives, 2026


# User-directed amendment — 14 November 2026

Ishak accepts the current animation appearance and explicitly defers further manual animation fine-tuning unless later playtesting reveals a need. The mandatory manual attack hit-frame marking step in sections 4 and 13 (M1) is therefore deferred rather than treated as completed. Keep the current provisional markers and authoritative combat timing unchanged. The original DOCX remains an unmodified historical copy; this amendment records the effective project instruction.


# User-directed amendment — 15 November 2026: Ration during stun

Ishak approved a Ration-specific exception to the shared stun rule: W may begin its 15-tick cast while stunned and completes through existing or newly applied stun, then heals and cleanses slow/root/stun. Other abilities remain blocked/interrupted by stun. Death still cancels Ration. Cooldown and cast buffering rules remain unchanged. This resolves the conflict between section 7's general cast prohibition and section 8's Ration stun cleanse. The original DOCX remains an unmodified historical copy.


# User-directed amendment — 15 November 2026: keg-link visibility

During M2 inspection, Ishak requested more visible barrel links. Replace the faint dark single-pixel trail with a thicker amber ground ribbon and dark border, brightening to pale gold while scheduled. Link width/border remain tunable; connection geometry and combat timing are unchanged. This refines section 11’s visual link specification.
