# Print Shop Tycoon

A native Windows isometric tycoon game about running a print shop. Start in your home garage with a gifted vinyl cutter, press your first shirts, and grow through a storefront and warehouse into a print factory with a loading yard. Built with Godot 4.5.1 (GL Compatibility).

**Current version: 1.1.0.** See [RELEASE-NOTES.md](RELEASE-NOTES.md) for what changed, [KNOWN-ISSUES.md](KNOWN-ISSUES.md) for open items, and [README.txt](README.txt) for controls and how to play.

## Download and play

Download `PrintShopTycoon-Windows-v1.1.0.zip` (or the standalone `Print.Shop.Tycoon.exe`) from the [releases page](https://github.com/TheKiwiSuite/Print-Shop-Tycoon/releases). Extract it and run `windows/Print Shop Tycoon.exe`. No installer, account or internet connection is needed. Saves live in `%APPDATA%/PrintShopTycoonNative` and carry over between versions. To update, use **Settings → Game updates + save backups**. [UPDATING.md](UPDATING.md) covers manual updates and recovery.

The build is unsigned, so Windows SmartScreen may ask for confirmation the first time you run it.

## Build from source

1. Install Godot 4.5.1 stable and its matching export templates.
2. Import the project: `godot --headless --path source --editor --import`
3. Export: `godot --headless --path source --export-release "Windows Desktop" "<output>/Print Shop Tycoon.exe"`

The export embeds the game data in the executable. Record the SHA-256 of what you build; embedded-pack bytes can differ between build hosts.

## Tests

Each `source/test/*.gd` file is a self-contained suite (`extends SceneTree`). Several suites write scratch files to `res://../../../work`, which is a folder two levels above the repository root. Create it first:

```bash
mkdir -p "$(realpath -m source/../../../work)"
xvfb-run -a godot --path source --rendering-method gl_compatibility --audio-driver Dummy --script res://test/acceptance.gd
```

A run fails on any `SCRIPT ERROR:`, `ERROR:` or `FAIL:` line. That includes engine resource-leak warnings at exit, so UI fixtures free the game and give the audio mixer 0.2 s to finish before quitting. `.github/workflows/windows-alpha.yml` holds the release-gating list: every gameplay, layout, updater and balance suite, then the exported executable's walkthrough on a real Windows runner. `final_visual_review.gd` checks rendered panels for text/control collisions and containment and writes screenshots to `captures/final-review`.

On Windows, `Run-QA.ps1 -Test NAME` runs one suite with an isolated log. `Build-Release.ps1` is the owner's local install script.

## Art, saves and updates

- Approved equipment art, the official logo (`art/branding/`) and the Windows icon must be used as supplied. See [CONTRIBUTING.md](CONTRIBUTING.md).
- Every earlier save must keep loading. State changes need a migration in `simulation.gd` and a test.
- The updater accepts only official releases of this repository whose GitHub SHA-256 digest and exact size match (see [UPDATING.md](UPDATING.md)). Don't loosen these checks.

Game numbers are authored balance values, not real equipment economics. The repository is public; the owner has not chosen a project license. The bundled font keeps its own SIL Open Font License.
