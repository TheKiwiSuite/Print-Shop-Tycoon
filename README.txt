PRINT SHOP TYCOON — NATIVE WINDOWS PLAYABLE BUILD

PLAY
Use the Print Shop Tycoon desktop shortcut to play the latest installed build.
The current version is always shown in the bottom-left footer and window title.
Equipment uses floor-contact anchors and shadows at its feet/wheels. The
default camera keeps the complete shop floor above the bottom interface.
The DTF line uses your supplied printer/shaker combo. Open either component,
then EQUIPMENT VIEWS to see the supplied main, right, left, back and front images.
BUILD-INFO.json records the installed version, build time, and executable hash.
You can also double-click windows/Print Shop Tycoon.exe. The executable contains its game
data. No browser, account, web server, installation, or internet is required.
Choose Start a New Shop for an empty floor. ADD EQUIPMENT opens the station
catalog; choose PLACE, move the preview to clear floor and click to install.
The clock starts paused. Starter artwork, inspection and packing benches
are included at no charge, but you choose their positions. Resume the clock
after setup. Continue preserves the equipment in your existing save.

CONTROLS
WASD or arrows: walk Sam. Clicking clear floor: walk there around equipment.
E: open the nearest station. Click a machine or order card to inspect it.
Work This Job as Sam: walk to and operate the next station.
Sam Auto Assist: operate prepared jobs automatically. Walking returns to manual.
Drag a worker onto a station: assign that worker. Drag Sam onto clear floor:
walk to it. Drag the yellow output token to the next station: work the handoff.
B: enter/leave Build. Drag equipment to rearrange. R rotates eligible benches.
Click a machine > MOVE EQUIPMENT, then click clear floor to relocate it.
Build also has MOVE SELECTED. Invalid previews retain the installed machine;
red markers show blocked locations. Escape cancels and preserves its position.
The DTF printer moves and rotates its connected shaker. Select the line in
Build mode, then use R or ROTATE (R). Four placement orientations change the
collision footprint, connected film gap and operator access. Invalid layouts
are rejected. The direction visuals use the supplied images; they are discrete
sprite views, not a continuously rotatable 3D model.
Wheel: zoom. Middle mouse drag: pan. Home: reset camera.
Space: pause. 1/2/4: speed. F5: save. F11: fullscreen. Escape: back/settings.

PLAY LOOP
New shops receive inquiries over time for equipment they own. A sticker-only
shop starts with a 36-sticker job. Add the included inspection and pickup
benches, then Open Shop. Unaccepted inquiries wait three shop-hours; accepted
jobs remain committed. Pause/build mode freezes customer waiting time.
CUSTOMERS + RECEIPTS shows upcoming inquiries, active jobs and completed sales.
Packing makes a job ready for pickup; finishing handoff pays once and records
customer satisfaction. The receipt uses actual payment, including quality
discounts. Saved delivery tasks cannot replay a completed payment.
Existing saves retain their prior order schedule; start a new shop to test the
new staggered arrival flow. Your existing layout and progress still load.
Customers walk in, wait for acceptance, leave during production, and return
for pickup. Click a customer to open their order. Pickup handoff waits until
the customer reaches the counter. Declined and expired inquiries walk out.

Accept a job, approve/repair artwork or request a customer revision, choose a
gang sheet or product preset, queue production, and operate the station.
Transfers: print CMYK/white, apply powder, cure, wind, inspect, pack, pickup.
Shirts additionally reserve the right blanks and use the heat press/peel preset.
Stickers print, laminate, read registration, and contour cut before inspection.
The industrial shop adds roll-to-roll banners, CNC signs, and shipping.
Faults need a cause correction and a material-consuming reprint, or discounted
payment. Restocked supplies take shop time to arrive. Staff roles, assignment,
training, maintenance, upgrades, deadline/quality reputation, wages, and daily
reports affect the business. A prepress artist can prepare accepted artwork.
Garage expansion requires cash and successful on-time, good-quality orders;
the expansion panel shows the current goals.

SAVE
Production autosaves every 10 seconds, on exit, and with F5/Save.
Save folder: %APPDATA%/PrintShopTycoonNative
File: native-shop-v3.json, with a .bak fallback. QA profiles are separate.
Cash, materials, garments, jobs, in-flight production, workers and layout persist.

SOURCE AND ART
source/project.godot is the editable Godot project. Tested/exported with Godot
4.5.1 stable, GL Compatibility, Windows x86_64 release with embedded PCK.
DTF-Line.blend contains the original, separate printer/shaker geometry and the
connected film lane. art/build_dtf_models.py rebuilds the projections in a fresh
Blender process. It does not touch an unrelated open Blender scene.
art/project_dtf_contacts.py measures the existing Blender model's floor,
caster contacts and film ports; art/dtf-floor-contacts.json records those
projections. source/scripts/grounding.gd uses them for the native equipment.
art/DTF-Reference.kra is a Krita workspace containing the approved Level 2 guide
and hidden equipment projection layers, for further drawing/paint refinement.
Godot is the game engine. Blender is used for equipment modeling and projection.
Krita is used for the editable visual-reference workspace. Unity Hub is installed
as an available alternative; this game does not require Unity Editor.

REBUILD
For local releases, close the running game normally and run Build-Release.ps1
with -Version X.Y.Z (a higher version than BUILD-INFO.json). It checks the staged
export before replacing the installed executable and current release ZIP,
updates the same desktop shortcut, and launches the normal player profile.
Use -NoLaunch when doing isolated validation. Saves are never removed or reset.
Each successful release replaces the last; do not distribute numbered EXE copies.

Open the project in Godot 4.5.1. For release exports install matching Godot 4.5.1
Windows export templates, or set the Windows Desktop preset's custom release
template to windows_release_x86_64.exe. Build-Release.ps1 also accepts an
ExportTemplatePath argument and detects the workspace's local export template.
Machine-specific template paths are used only during export, then restored.
Run source/test/acceptance.gd with the Godot --headless --script option to repeat
the acceptance suite. It writes separate acceptance save profiles.

VALIDATION AND CURRENT SCOPE
109 simulation acceptance checks passed, covering all five product routes,
both rooms, solid machine footprints, route/access validation, stock shortages
and delayed delivery, garment sizes, faults/reprints, hires/upgrades, several
shop days, and local/in-flight save restoration. Windows UI testing completed
the tutorial order and restored its payment/progress through Continue. Walking,
keyboard shortcuts, and new-day order generation after Continue were verified.
This is the first native playable build, not the final illustrated art pass or
a finished commercial release. The scene does not yet match the supplied
references pixel for pixel. Equipment paint, environment density, staff visual
variety, character operating animations and interface styling need refinement.
Customers use the current walking sprite sheet with distinct clothing tints.
Additional approved customer artwork and operating animations remain future work.
The two shops use a tile layout with fixed camera orientation. There is no
third shop, multiplayer, controller mapping, arbitrary uploaded customer art,
or freehand pixel editing inside the game. Production parameters are game
balancing values, not instructions for operating real print equipment.
NEXT-VERSION-PLAN.txt lists the proposed blank-shop starter choices and the
gameplay, collision, interface, and art work for the next development pass.
