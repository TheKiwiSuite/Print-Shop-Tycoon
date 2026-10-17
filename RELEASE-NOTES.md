# Native Windows v0.2.19

## Version 0.2.19 — new official transparent logo

- Replaced the active title/shop logo with the exact newly supplied transparent PNG.
- Updated the Godot window icon and desktop shortcut icon using proportional transparent conversions of that same artwork. The shortcut references a new icon filename to avoid reusing the old cached icon.
- Archived prior logo inputs under `art/branding`; contributor guidance now identifies the new official source for future work. No equipment artwork or gameplay logic changed.

## Version 0.2.18 — accessible desktop window controls

- Move to the top edge or press F10 to reveal File, Edit, View, Window and Help menus plus minimize, window/fullscreen and Close controls. The bar hides when the pointer leaves; F10 can pin or dismiss it. It stays above dialogs and uses the existing HUD dock.
- Window offers Minimize, Windowed / Restore, Maximize and Fullscreen. F11 remains available. Restored windows retain native Windows caption controls.
- File connects to New Game, Continue, Save, Save and Title, Settings and guarded Save and Quit. Edit connects to arrangement, selected equipment movement/rotation and placement cancellation. View controls framing, music and fullscreen; Help opens game instructions and keyboard controls. Unavailable actions are disabled.
- Open menus block walking, hidden equipment input and click-through. Opening a menu cancels held placement safely. Arrow keys navigate menus, Enter activates and Escape dismisses.
- `window_controls` passed 43 Windows checks, including real window modes and minimize/restore, isolated saving, disabled commands, menu hit regions, music playback and failed-save protection for the Close button. Workspace (155), save reliability (49) and DTF input/placement (63) checks also passed. Native UI was reviewed. The automated public CI includes the new suite; native minimize checks run on Windows only.

## Version 0.2.17 — clear workspace and audio controls

- Docked HUD, customer/setup cards, order list and build controls outside the play area. The bottom equipment bar and placement feedback also stay in their own dock.
- Fit Whole Shop / Home frames every floor corner and wall top in both locations. Zoom and pan remain available inside the shop view. Blank dock clicks cannot move the owner, and dropping equipment on a dock cancels the move.
- The game starts fullscreen. The adaptive canvas fills the display without black bars or distortion; dialogs and their input regions stay centered. Window Mode / F11 returns to a maximized window.
- Rebuilt hanging warehouse fixtures with ceiling support, mounting plates, short suspension cords, shaped dark metal shades and warm bulbs.
- Added a main Music On/Off button. Playback changes immediately; a separate preference file retains the choice across Continue and restart. QA tests use separate preference files.
- `shop_workspace` passed 155 checks covering dock separation, room visibility, dock input, camera reset, fullscreen sizing, centered dialog/gang-sheet input and real audio playback/preference persistence. Existing DTF input, rotation, save/retry and illustrated UI suites passed after the layout change. Native UI was reviewed during verification.

## Previous release: v0.2.16

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
