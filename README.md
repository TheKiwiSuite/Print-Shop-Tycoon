# Print Shop Tycoon

Native Windows print-shop game built with Godot. This repository contains the editable Godot project, game scripts and tests, approved art assets, Blender and Krita source files, and release/QA scripts for **v0.3.2**.

Version 0.3.0 adds Relaxed / Standard / Expert / Custom shop rules, commitment and cash forecasts (Q), separate premises/fit-out/equipment investments, client focus and repeat inquiries, compatible mixed-client DTF sheets, named staff tasks and utilization, keyboard placement/remapping, native focusable controls, and task-linked production/carrying cues. New shops use save schema 4; older shops retain their existing economy until a deliberate rules change. See [the upgrade record](STRATEGY-UPGRADE.md) for rules, validation and limitations. A release is published only after rendered checks and the actual packaged Windows executable complete their gates.

Version 0.2.22 repairs the Oct 16 assessment checkpoint: stalled pickups, loaded DTF line validation, interrupted print consumption, live-panel pause controls, sound preference restoration, tutorial quantity and discounted payout feedback. See [assessment integration](ASSESSMENT-INTEGRATION.md) for tested scope and remaining work.

Version 0.2.21 uses the owner-supplied transparent Windows icon unchanged. It removes the rejected square badge from v0.2.20. The desktop shortcut and runtime icon show only the logo, with no added background or frame.

Version 0.2.19 adopts the owner-supplied transparent Print Shop Tycoon logo on the title screen, shop dock and Windows shortcut. The approved original is kept unchanged under `art/branding`; previous branding remains archived source material.

Version 0.2.18 adds an auto-hiding desktop menu bar. Move the pointer to the top edge or press F10 for File, Edit, View, Window and Help, plus minimize, window/fullscreen and Close buttons. Window offers windowed restore, maximize and fullscreen. Menus pause shop input, outside clicks dismiss without moving Sam, and Close uses the existing guarded save flow. F11 still toggles fullscreen.

Version 0.2.17 reserves separate docks for the HUD, shop desk, orders and equipment controls. They no longer cover the shop floor. The camera fits both shop sizes into the clear play area, and Fit Whole Shop / Home restores this view after zooming. The game opens fullscreen and adapts to the display without letterboxing or stretching the artwork; Window Mode / F11 returns to a maximized window. Warehouse pendant lights now have a ceiling beam, mounting plates, short cords, shaped metal shades and warm interiors. A main Music On/Off button controls playback immediately and stores the preference separately from the shop save, including on the title screen after restart. Drops onto UI docks cancel safely.

Version 0.2.16 redraws both wall signs with centered, fitted, stacked lettering and the reference slogans (PRINT MORE GROW BIGGER / GOOD PRINTS HAPPIER PEOPLE). Their frames and lettering follow the wall perspective. Both locations now have three wider windows separated by solid wall, with the entrance door kept at the customer entrance. Pendant lights are spaced clear of the signs. `wall_visual_review.gd` captures both locations and minimum zoom for visual review.

Version 0.2.15 fixes equipment jumping during rotation. Installed equipment, new placement previews, and held/moving equipment share an exact floor pivot through all 16 views, including quarter turns and save/reload. Invalid previews remain at the attempted location with a red footprint, while rejected drops preserve the installed layout. Placement previews are rendered once. `rotation_stability.gd` reproduces the former pivot drift and checks all equipment types, dragging, preview behavior, and save/reload.

Version 0.2.14 integrates the approved illustrated equipment: 10 equipment sets with 16 distinct views each. In Build / Arrange, select equipment and press R or Rotate to turn it by 22.5 degrees. The DTF printer and shaker move and rotate together. Placement checks use the rotated footprint, preserve service access, and reject walls and occupied spaces. Saved layouts retain their orientation. The equipment menu uses the same illustrated art. Original approved sheets remain in `art/cartoon-style-v1`; `prepare_game_assets.py` copies them unchanged and produces the runtime frame and floor-anchor metadata.

Open `source/project.godot` in Godot 4.5.1 to run or edit the game. Read [README.txt](README.txt) for the current gameplay, controls, equipment, and known scope. `Run-QA.ps1` runs the named Godot test scripts with isolated logs.

See [RELEASE-NOTES.md](RELEASE-NOTES.md) for current changes and validation.

The [game audit](GAME-AUDIT.md) records 15 findings from v0.2.13, reproduction steps, screenshots, and the recommended fix order. All 397 checks available then passed in the October 15 audit, while additional edge-case probes exposed open defects. See [CONTRIBUTING.md](CONTRIBUTING.md) to help with a focused fix or improvement.

`Build-Release.ps1` is the development machine's Windows release workflow. It expects this project under `outputs/PrintShopTycoon-Native` in the workspace. Install matching Godot export templates, or pass `-ExportTemplatePath` with your own Windows release template. The script also detects a workspace template under `work/export-templates/templates`. Local paths are applied during export and then restored to keep them out of the shared preset.

The compiled executable and player saves are intentionally excluded from Git. Windows release packages are backed up separately in Kiwi Suite Google Drive. The reference art and editable files remain in this repository.
