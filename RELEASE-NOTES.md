# Native Windows v0.2.16

October 16, 2026. The fixed desktop shortcut and installed Windows executable use this version. Open `source/project.godot` to edit the matching game source.

## Changes since v0.2.13

- Integrated the user-approved illustrated equipment: ten assemblies with sixteen distinct views each. The equipment menu uses the same artwork. Editable Blender models, measured camera renders, approved original PNG sheets, provenance and reference viewers are included under `art/`.
- Connected all sixteen views to equipment rotation in 22.5-degree steps. The DTF printer and shaker move as one assembly. Placement checks include rotated footprints, walls, occupied tiles and walkable service access.
- Fixed equipment jumping during rotation. Installed equipment, new placement previews and held/moving equipment use an exact floor pivot, including half-tile offsets at quarter turns. The pivot persists through save/reload. Invalid previews remain at the attempted location with a red footprint, while rejected drops preserve the installed layout. Removed duplicate preview rendering.
- Rebuilt the wall signs with centered, fitted lettering and the reference slogans. The signs follow the wall perspective, and lights no longer overlap them.
- Replaced the continuous row of narrow windows with three larger windows separated by solid wall in each shop location.

## Validation

The final applicable runs passed through the isolated `Run-QA.ps1` runner:

| Suite | Checks | Result |
| --- | ---: | --- |
| `rotation_stability` | 397 | Passed; all ten equipment types, installed/preview/drag rotation, wall preview and saved pivots |
| `illustrated_equipment` | 2865 | Passed; all 160 placements, relocation, footprint and access checks |
| `illustrated_ui` | 500 | Passed; all 160 rendered views and selection |
| `ui_dtf_placement` | 63 | Passed; actual input handler, repeated relocation and wall rejection |
| `session_reliability` | 49 | Passed; save failure/retry and saved layouts |
| `acceptance` | 109 | Passed; all product routes, inventory, payment and reload |
| `wall_visual_review` | Visual review | Both locations and minimum zoom rendered; actual native UI inspected |

The Windows export passed its packaged startup check. Native screenshots and a rotation demonstration are under `captures/`. These checks do not resolve every finding in the older `GAME-AUDIT.md`; that document remains the v0.2.13 audit snapshot.

## Contributor notes

The game is a native Godot project. The HTML pages are equipment reference viewers. Run script tests with `Run-QA.ps1`; use `-Graphics` for rendered UI checks. Keep QA profiles separate from player saves and supply a writable, isolated Godot log when launching specialized runners.

Approved artwork can be copied and calibrated with `art/cartoon-style-v1/prepare_game_assets.py` (Python with Pillow). Browser-based reference tooling uses the standard `playwright` package; install its Chromium browser or set `PLAYWRIGHT_CHROMIUM_EXECUTABLE`. Temporary Python caches, logs, credentials, and the local installed executable are excluded from Git.
