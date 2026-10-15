# Print Shop Tycoon

Native Windows print-shop game built with Godot. This repository contains the editable Godot project, game scripts and tests, approved art assets, Blender and Krita source files, and release/QA scripts for the current **v0.2.13** build.

Open `source/project.godot` in Godot 4.5.1 to run or edit the game. Read [README.txt](README.txt) for the current gameplay, controls, equipment, and known scope. `Run-QA.ps1` runs the named Godot test scripts with isolated logs.

`Build-Release.ps1` is the development machine's Windows release workflow. It expects this project under `outputs/PrintShopTycoon-Native` in the workspace. Install matching Godot export templates, or pass `-ExportTemplatePath` with your own Windows release template. The script also detects a workspace template under `work/export-templates/templates`. Local paths are applied during export and then restored to keep them out of the shared preset.

The compiled executable and player saves are intentionally excluded from Git. Windows release packages are backed up separately in Kiwi Suite Google Drive. The reference art and editable files remain in this repository.
