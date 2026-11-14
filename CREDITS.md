# Credits and provenance

## Project-owned content

- Game design and original guide: Ishak. Original DOCX preserved in `docs/mvp_development_guide.docx`; searchable text extracted without changing design decisions.
- `docs/concepts/visual_direction_v1.png`: generated concept image approved by Ishak as the visual direction. Documentation/reference only; not a rigged model, sprite sheet, or playable screenshot.
- Setup room geometry, materials, scripts, and UI: project content. Stock character/animation candidates are listed below; no external environment or sound packs are included yet.

## GUT — Godot Unit Test

- Author: Tom “Butch” Wesley and contributors.
- Version: **9.7.1**.
- Source: <https://github.com/bitwes/Gut/releases/tag/v9.7.1> (user-provided `Gut-9.7.1.zip`).
- License: MIT; upstream notice preserved in `addons/gut/LICENSE.md`.
- Installed files: the complete upstream `addons/gut/` subtree. Includes upstream fonts, icons, and GUI resources; bundled license files are retained.
- Local modification: `gut_plugin.gd` uses bundled/cached version data at editor startup instead of automatically fetching updates. Manual update checks remain available. No changes to upstream test execution or assertions.
- Source ZIP SHA256: `14969aa46adc84aa08cdd21b9f6d1a64addd92ae60b36f02d0521ed305aa4086` (local fingerprint; not independently authenticated against a publisher checksum).

## Engine

Godot Engine 4.7.2 stable, official build `ed1daf0bf`; MIT licensed. Editor binary is installed outside the repository. See <https://godotengine.org/license/>. Distribution notices must be reviewed when producing executables in M5.

## Future assets

Before adding third-party gameplay assets, record exact paths, author, original source, and applicable license here. Pack compatibility and per-file licensing must be verified rather than inferred from the design guide.

## Quaternius character and animation candidates

Author: Quaternius. License: CC0 1.0, verified against each supplied archive's notice. The male ranger outfit, male base body/head, and animation libraries are now used by the M1 arena. Other files remain candidates; the original M0 setup room is unchanged. Exact file paths and fingerprints are in `docs/asset_manifest.json`.

| Files | Original pack/source | Retained notice |
| --- | --- | --- |
| `assets/characters/base/superhero_male.glb`, `superhero_female.glb` | [Universal Base Characters](https://quaternius.com/packs/universalbasecharacters.html), Standard | `assets/licenses/base_characters.txt` |
| `assets/characters/outfits/male_peasant.glb`, `female_peasant.glb`, `male_ranger.glb`, `female_ranger.glb` | [Modular Character Outfits – Fantasy](https://quaternius.com/packs/modularcharacteroutfitsfantasy.html), Standard | `assets/licenses/fantasy_outfits.txt` |
| `assets/animations/ual1/ual1_standard.glb` | [Universal Animation Library](https://quaternius.com/packs/universalanimationlibrary.html), Standard in-place | `assets/licenses/ual1.txt` |
| `assets/animations/ual2/ual2_standard.glb` | [Universal Animation Library 2](https://quaternius.com/packs/universalanimationlibrary2.html), Standard in-place | `assets/licenses/ual2.txt` |

Modifications: body/outfit glTF files repackaged with original textures and binary buffers into self-contained GLBs; broken texture URIs corrected to existing pack files as recorded in the manifest. No pixel/mesh edits or retargeting. Animation GLBs copied unchanged. Raw packs remain outside the repository.


M1 runtime adaptations: the male base body's rendered head is cropped in memory by height and head/neck weights for use under clothing; original GLB files remain unchanged. Stock animation tracks are rest-compensated and strike/recovery segments combined into cached libraries. Player cloth material overrides provide a red prototype palette; dummy materials are grey. The primitive sword geometry and animation/debug UI are project-owned code, not additional external assets.
