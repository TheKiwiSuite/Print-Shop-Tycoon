# Contributing to Print Shop Tycoon

Open an issue with the game version, steps to reproduce, expected/actual results, and a screenshot where relevant. Fork this public repository and submit a pull request for a focused change. See [GAME-AUDIT.md](GAME-AUDIT.md) for confirmed findings and recommended priorities.

## Run and inspect the game

Open `source/project.godot` in Godot 4.5.1 and run the main scene. The target is a native Windows game. Use a separate QA profile when testing saves or destructive scenarios; `--qa-ui` selects a test profile rather than the normal player's shop.

The supplied PowerShell runners currently expect this directory at `WORKSPACE/outputs/PrintShopTycoon-Native`, with the Godot executables under `WORKSPACE/work/godot`. Matching Windows export templates are required for exports. `Build-Release.ps1` accepts `-GodotPath` and `-ExportTemplatePath` for locally installed tools. The committed export preset contains no machine-specific template path.

Run relevant checks through `Run-QA.ps1 -Test NAME`; add `-Graphics` for `ui_dtf_placement`, `session_reliability`, or other tests that wait for rendered frames. Always give specialized Godot launches a unique writable `--log-file`. The diagnostic `audit_edge_cases` intentionally exposes open defects and currently fails; its result is explained in the audit report.

For gameplay changes, include focused regression evidence and inspect the native interface when presentation or input changes. Keep generated caches, binaries, player saves, credentials and machine-specific paths out of Git.

## Art and design

Preserve the approved DTF equipment views and official logo in `art/branding/Transparent Print Shop Tycoon Logo.png`. New equipment/character art needs owner review. Follow the existing isometric camera and approved 2.5D cartoon references; do not replace approved equipment with generated alternatives. Keep editable source files and calibrate sprite feet, shadows, collision footprints and selection areas together.

## Releases and permissions

The owner controls the installed Windows release and version sequence. Do not replace the normal player's save or create competing desktop shortcuts as part of a contribution.

The repository is public, and the owner has not selected a top-level project license. Discuss broader reuse/redistribution terms with the owner. The bundled font retains its separate SIL Open Font License.

Windows icon: use `art/branding/Print-Shop-Tycoon-Windows-Icon-1024.png` exactly. The owner rejected the square badge. Do not add backgrounds, frames or other decorations to the logo.
