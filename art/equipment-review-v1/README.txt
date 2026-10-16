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

PRINT SHOP TYCOON - REMAINING EQUIPMENT REVIEW

Purpose
Nine editable equipment assemblies, each rendered in 16 genuinely distinct
directions spaced 22.5 degrees apart. This completes art-review coverage of
the current ten purchase choices when combined with the user-approved DTF
printer/shaker pair. DTF duplicate stations reuse that approved assembly.

Included catalog entries
sticker - mint desktop print/cut workstation
heat - red heat press, blue cap press, shirts and storage
art - monitor, keyboard, tablet, computer, supplies and plant
finish - cutting mat, inspection lamp, ruler and trimmer
pack - parcels, tape gun, label printer and order terminal
storage - four-tier material shelving with rear bracing
banner - blue roll-to-roll printer with sunset output and take-up
cnc - flatbed cutter, tool carriage, gantry and operator console
dock - delivery truck with an open rear cargo bay

Review
Open index.html. Choose a station or its overview card; use the angle slider,
arrow buttons, keyboard arrows or Play rotation. All sixteen views are also
shown together. Each station includes its original atlas reference, an
editable .blend download, and measured camera information.
equipment-overview.png shows all nine models.
Each equipment folder contains all-16-angles.png.

Current artwork
Use rotations-v3, except heat uses rotations-v4 for readable display lettering.
Earlier rotation folders are internal review iterations
and are not linked from the viewer. The editable model beside each current
render set is the source used for the source hash in its manifest.
Each PNG is 900x900 RGBA. The camera elevation is fixed at 30 degrees, the
orthographic scale stays fixed throughout each set, and every visible
mesh, curve and text object retains its transform throughout the orbit.
Floor anchors are recorded per direction for future game sprite placement.

Sources and style
The user approved the DTF model on October 16, 2026. Its materials and lighting
form the benchmark here. Existing shop-atlas.png supplies equipment shapes,
colors and printed cat/sunset artwork; the original file is unchanged.
Artwork/finish/pack formerly shared one atlas cell. This collection gives
them distinct task-specific setups. Rear and hidden surfaces are reconstructed.
These are stylized interpretations, not measured manufacturer CAD models.

Editable source
../build_equipment_collection.py - authored geometry and equipment props
../equipment_geometry.py - primitive helpers and shared DTF-style materials
../render_measured_rotations.py - exact camera orbit and manifest
../build_equipment_review.ps1 - isolated background Blender builds
Reproduction requires Blender 5.2 and the original source/assets/shop-atlas.png.
Rendering refuses to overwrite an existing angle folder: choose a fresh folder
when rebuilding, then explicitly update the viewer and validation target.

Validation
check_collection.py verifies catalog coverage, camera angles, unique PNG
hashes, transparent bounds, floor datum, source .blend hashes and anchors.
review-check.cjs verifies the actual viewer controls and asset links and
captures an overview plus nine 16-angle contact sheets.
Reports: collection-check.json and review-ui-check.json.

Status
New equipment artwork is ready for user review, not yet user-approved.
The DTF style benchmark is approved. No game sprites, executable, player save,
or desktop shortcut were replaced during this art-only checkpoint. Installing
these in the game still requires directional sprite selection, scale/pivot
integration, rotated footprint/collision tests and native Windows UI QA.
