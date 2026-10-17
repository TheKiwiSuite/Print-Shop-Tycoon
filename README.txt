PRINT SHOP TYCOON — NATIVE WINDOWS PLAYABLE BUILD

VERSION 0.3.2 — GAME UPDATES AND SAVE CONTINUITY
Settings > Game updates + save backups checks the official release channel,
downloads a verified update, then saves, backs up and restarts on your command.
Older builds need one manual download to gain this updater. Choose Continue;
existing AppData saves are kept. Read UPDATING.md for instructions and recovery.

VERSION 0.3.0 — PLANNING AND STAGED GROWTH
Choose Relaxed, Standard, Expert or Custom when starting a new shop. Existing
shops retain their previous economy until you explicitly apply new rules in
Settings. Accepted prices and deadlines remain fixed. Starting another shop
archives the previous save; Continue keeps the current shop.
Q opens capacity, input, deadline and cash forecasts. Expand premises, fit out
the industrial floor and buy machines separately. Completed clients can repeat
approved orders; compatible transfer/apparel work can share a film batch.
Tab / Shift+Tab / Enter navigate controls. Arrow keys / Enter place equipment.
Settings includes movement remapping and Reduce Motion.
Read STRATEGY-UPGRADE.md for exact rules, assumptions and remaining acceptance;
RELEASE-NOTES.md records this version. Older scope notes below are historical.

PLAY
Extract the complete download and open windows/Print Shop Tycoon.exe.
If you installed a local build, its desktop shortcut opens that installed copy.
The current version is always shown in the bottom-left footer and window title.
Equipment uses floor-contact anchors and shadows at its feet/wheels. The
default camera keeps the complete shop floor above the bottom interface.
The DTF line uses your supplied printer/shaker combo. Open either component,
then EQUIPMENT VIEWS to see the supplied main, right, left, back and front images.
The download's BUILD.txt records the source commit and engine. Local installer
builds also write BUILD-INFO.json with their version and executable hash.
You can also double-click windows/Print Shop Tycoon.exe. The executable contains its game
data. No browser, account, web server, installation, or internet is required.
Choose Start a New Shop for an empty floor. ADD EQUIPMENT opens the station
catalog; choose PLACE, move the preview to clear floor and click to install.
The clock starts paused. Starter artwork, inspection and packing benches
are included at no charge, but you choose their positions. Resume the clock
after setup. Continue preserves the equipment in your existing save.

CONTROLS
Move the pointer to the top edge or press F10 for File, Edit, View, Window,
and Help menus and minimize / window-fullscreen / close buttons. Window also
offers restore and maximize. Escape dismisses menus; F11 toggles fullscreen.
Close saves before quitting and stays open if saving fails.
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
benches, then Open Shop. Inquiry patience follows the selected rules; accepted
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
Marketing campaigns charge once and schedule equipment-matched inquiries;
campaign spending appears in the daily profit report and survives save/load.

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

HISTORICAL VALIDATION AND SCOPE — SEE STRATEGY-UPGRADE.md FOR 0.3.0
The October 15 audit reran 397 existing checks across eight suites, covering
all five product routes, both rooms, machine footprints, walking, arrivals,
stock, faults, staffing, marketing, payments, placement, and save reliability.
Additional edge-case probes and native UI inspection identified 15 findings;
see GAME-AUDIT.md for the open defects, evidence, and recommended priorities.
The existing checks passing does not mean these additional findings are fixed.
This is a native playable development build. The scene does not yet match the supplied
references pixel for pixel. Equipment paint, environment density, staff visual
variety, character operating animations and interface styling need refinement.
Customers use the current walking sprite sheet with distinct clothing tints.
Additional approved customer artwork and operating animations remain future work.
The two shops use a tile layout with fixed camera orientation. There is no
third shop, multiplayer, controller mapping, arbitrary uploaded customer art,
or freehand pixel editing inside the game. Production parameters are game
balancing values, not instructions for operating real print equipment.
GAME-AUDIT.md and NEXT-VERSION-PLAN.txt list the remaining gameplay, collision,
interface, starter-equipment, and art work for the next development pass.
