# M0 stock asset audit

All four requested Standard packs were extracted to `~/bp-assets-raw/`, outside the repository. Each passed ZIP CRC validation. Each included license identifies the assets as CC0 1.0; notices are preserved under `assets/licenses/`.

## Prepared candidates

`docs/asset_manifest.json` records exact source/output paths, SHA256 fingerprints, bone counts, texture-reference fixes, bind-matrix differences, and animation names. `python tools/prepare_assets.py` reproduces the outputs and refuses to overwrite different files.

- Two superhero base bodies, male and female, retained as selection candidates.
- Male/female peasant and ranger outfits.
- UAL1 and UAL2 Standard in-place animation libraries. `_RM` root-motion variants are excluded.

Body/outfit source files are external-buffer `.gltf` files. The preparation tool embeds their original geometry buffers and textures in self-contained `.glb` files without changing geometry, rigs, animation data, or texture pixels. It checks that accessor data and geometry-buffer bytes are preserved. Broken base-pack references to `T_Eye_Normal_png.png` and `T_Hair_1_Normal_png.png` are explicitly resolved to existing sibling `T_Eye_Normal.png` and `T_Hair_1_Normal.png` files; each correction is in the manifest.

The setup room does not instantiate these candidates. Final choices and visual integration belong to M1.

Godot extracts texture sidecars named `<model>_T_*.png` beside these GLBs during import. They and their own `.import` sidecars are ignored as generated data; the original pixels remain embedded in the tracked GLBs. The GLBs' scene `.import` settings remain tracked. Godot consumes the `_Loop` animation-name suffix and enables looping; the asset check explicitly recognizes that naming rule. M1 animation profiles must use imported names, with source names retained in the manifest.

## Differences from guide assumptions

1. All selected rigs have 65 joints with the same names and hierarchy, but their inverse-bind matrices differ. UAL1 and UAL2 match each other; bodies/outfits do not all match the animation mannequin. The guide's identical-bind-pose assumption is not supported by the actual files. M1 must test playback and may need Godot bone mapping/rest compensation.
2. The free outfit pack contains peasant and ranger outfits only, not the proposed captain coat, wide hat, or knight outfit. No purchase was made. Final recipes and any change to the no-bespoke-model scope require approval before implementation.
3. The outfit README requires only the base character's head beneath clothing; full bodies cause clipping. Body hiding/head extraction needs validation in M1.
4. This free base pack contains superhero male/female bodies; the guide's regular/teen alternatives are absent. Enemy outfit/tint/scale choices remain pending.

## Available animation roles

| Role | Clip candidates | Library |
| --- | --- | --- |
| Idle/run | `Idle_Loop`, `Jog_Fwd_Loop`, `Sprint_Loop` | UAL1 |
| Alternating melee | `Sword_Regular_A`, `Sword_Regular_B`, separate `_Rec` clips | UAL2 |
| Heavy melee | `Sword_Heavy_Combo` | UAL2 |
| Pistol | `Pistol_Shoot`, `Pistol_Idle_Loop` | UAL1 |
| Throw/cast | `OverhandThrow`; `Spell_Simple_Shoot` | UAL2 / UAL1 |
| Consume | `Consume` | UAL2 |
| Jump/land | `Jump_Start`, `Jump_Loop`, `Jump_Land` | UAL1 |
| Hit/death | `Hit_Chest`, `Hit_Head`, `Death01` | UAL1 |
| Roar/stunned loop | No explicitly named clips; choose visual substitutes or revisit sourcing in M1/M3 | — |

Names do not establish visual suitability or calibrated timing. No paid library is required based on this inspection alone.

## Export templates

`Godot_v4.7.2-stable_win64.exe.zip` contains Windows editor executables, not export templates; it was left untouched. Standard `Godot_v4.7.2-stable_export_templates.tpz` was subsequently supplied. Linux/Windows x86_64 debug/release binaries, console wrappers, ICU data, and the version marker are installed in `~/.local/share/godot/export_templates/4.7.2.stable/`; extracted bytes match the archive. Both Linux binaries report the pinned official version. Other targets remain in the TPZ. Existing config files were not changed.


## M1 integration result

The male ranger outfit and male base body are now instantiated in the arena. The base head is cropped by height plus head/neck bone weight to avoid wearing a full body beneath the outfit. Original GLBs remain unchanged. The skeleton bind poses are compensated in a cached runtime animation adapter; an actual T-pose comparison now verifies the target rest positions/rotations are preserved. Head skin fit and sampled pose bounds are also tested. Player cloth material overrides provide a provisional red palette; dummy materials are flat grey.

Idle/run, alternating strike+recovery, temporary cast, and death clips are connected. A code-built sword attaches to the right hand. No pirate hat/coat was added. Attack hit markers remain provisional pending manual Animation Lab calibration; headless tests do not replace checking the appearance on screen.
