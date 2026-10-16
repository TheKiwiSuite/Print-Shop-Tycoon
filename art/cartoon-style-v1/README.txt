CURRENT STATUS - native v0.2.16
The user approved the illustrated equipment and it is installed in the game.
The original review-stage notes below describe the earlier art checkpoint.
Measured Blender models remain editable geometry sources; the runtime uses
the illustrated sheets from art/cartoon-style-v1 through source/assets/equipment.
All ten sets have 16 views. Rotation, placement, collision and saved pivots
are integrated. See the root README for the latest build and checks.
Viewer scripts require Node.js and npm install --no-save playwright, then
npx playwright install chromium. Optionally set PLAYWRIGHT_CHROMIUM_EXECUTABLE
to use another installed Chromium executable. No local account paths are needed.

PRINT SHOP TYCOON - ILLUSTRATED EQUIPMENT STYLE REVIEW
October 16, 2026

Scope: all 10 current Blender equipment assemblies, 16 views each (160).
DTF printer/shaker, sticker print/cut, heat press, design workstation,
finishing bench, packing bench, supply storage, wide-format banner printer,
CNC flatbed cutter, and delivery truck.

Open index.html to compare illustrated and original Blender views, select
each angle, play the rotation, and download each transparent PNG sheet.
illustrated-overview.png shows all ten sets together.

Production method: built-in image generation, reference-guided style edits.
The geometry input is a transparent 4x4 guide composed of unchanged Blender
frames. The drawing-style input is the user's Level 2 shop illustration.
Each guide has 0 through 337.5 degrees at 22.5-degree steps in row-major order.
Source models and original render files were preserved without modification.
guide-manifest.json points to their source manifests.

Output: sheets/*.png. These are the generated transparent originals, copied
without pixel editing from the tool's output folder. provenance.json records
the original prompts and files; truck-correction.json records the selected
truck revision, which fixes incorrectly visible cab lights in rear views.
style-prompt.txt contains the shared direction and initial DTF prompt.

Validation: check_sheets.py reads pixels only and verifies transparency,
16 occupied and pixel-unique regions per sheet, and records PNG hashes.
It also detects sprite bounds for the review viewer. Generated sheets are
1254px square and do not use perfectly even, integer-aligned cells. Some
artwork crosses nominal quarter-sheet boundaries. Therefore index.html uses
detected per-sprite rectangles, NOT an assumed 4x4 equal-cell crop. The
original artwork is unchanged; the viewer uses CSS clipping and positioning.
quality-report.json retains both the original grid warnings and these regions.
Unique hashes are not proof of correct angle geometry. Manual visual review
checked the sixteen directional sequences against the guides, including
front/back distinctions, side views, major accessories and equipment identity.
The truck's rear-view cab occlusion was corrected in a separate targeted edit.

Limitations: these are new style-review candidates, not user-approved final
assets and not installed in the native game. AI repainting alters fine details
and can change proportions or alignment. The design desk plant pot is white
in the repaint rather than the source's gold. Small print artwork, labels and
screens are interpreted rather than pixel-identical. The source camera steps
are exact; painted perspectives are not mathematically certified camera views.
Final gameplay import needs consistent scale, floor-anchor calibration and
native placement/rotation checks. Review centering is not a gameplay anchor.

UI checks: check_review.cjs verifies all ten selections, 16 views per set,
next/previous wraparound, play/pause, file links, loading and narrow layout.
The viewer is an art-review document, not a browser edition of the game.

No game code, installed executable, normal save, or desktop shortcut changed.
