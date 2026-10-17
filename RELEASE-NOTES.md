# v0.4.0 — Your workshop

Permanent industrial Growth / fit-out route; safer Help and Settings spacing; separated world labels; community sale trust recovery; equipment agreements and cash bridge; scheduled maintenance, neglect recovery, optional timing and daily decisions; capped Away/offline work; shirt and transfer displays, floor presets and local PNG imports; worker clothing and earned suits; purchase unboxing; local landscape, square and portrait photos; configurable title-screen partner links (blank by default).

Existing career and playable demo saves migrate separately. Read [WORKSHOP-UPGRADE.md](WORKSHOP-UPGRADE.md) for costs, controls, security boundaries and remaining polish. The editable source is supplied separately alongside the Windows and QA ZIPs.

# Native Windows v0.3.3

## Version 0.3.3 — playable demo and clear shop controls

- Added Play Demo Shop to the title screen. Equipment, a four-person team and $5,000 are supplied, with a prepared first order and owner Auto Assist. Ordinary production, inputs, wages and payment rules still apply.
- Demo progress saves separately from the career. Save and Title restores the career slot; Continue restores the career. Settings offers a confirmed demo-only reset with an archive.
- Separated Capacity, More Orders and Fullscreen controls. Shortened setup text so it clears the equipment button. Added an explicit paused-clock heading and Space-to-resume guidance.
- Improved muted/error/success text contrast and bounded long button/toolbar labels. Approved equipment and character artwork are unchanged.
- Added career-isolation, demo save/resume/reset, real owner movement and control-overlap checks across the existing render matrix.

# Native Windows v0.3.2

## Version 0.3.2 — player updates and save continuity

- Added Settings → Game updates + save backups: optional check, verified download, then explicit save/back up/restart.
- Fixed official GitHub release channel, numeric upgrade-only versions, HTTPS, GitHub asset size/SHA-256 verification and fresh helper revalidation. No downloaded script is executed.
- Existing saves and preferences stay in AppData and receive an additional byte-for-byte backup. The helper waits for the old process to exit and uses Windows atomic replacement with a retained previous executable.
- Startup/save validation failure triggers rollback. Read-only folders, low disk space, interrupted downloads and hash mismatches fail safely. No elevation, service, installation dependency or execution-policy change.
- Players with older builds need one manual download to gain the updater. See `UPDATING.md` for steps, trust boundaries and recovery. The alpha is still unsigned; GitHub digest verification is not an independent publisher signature.
- Added security/integrity/save-backup checks and actual packaged Windows atomic replacement, failed-install preservation, rollback and startup-confirmation checks.


## Version 0.3.1 — preserve player saves during updates

- Help > Check for updates launches the packaged Windows updater with explicit player confirmation.
- Newer official Windows alpha downloads require the GitHub API SHA-256 digest and safe archive validation.
- Profile backups are verified before a separate version folder becomes available; old binaries and saves remain intact.
- Existing players need one manual download to acquire the updater. See PLAYER-UPDATES.md for steps, rollback and unsigned-alpha trust limits.

# Native Windows v0.3.0

## Version 0.3.0 — planning and staged growth

- Added new-shop Relaxed, Standard, Expert and bounded Custom rules. Standard opens with $1,600; opening funds, quoted slack, overhead, supplier timing, inquiry patience and recoverable defect risk are disclosed. Existing prices/deadlines/fault rolls survive prospective difficulty changes. Legacy shops retain their prior economy until an explicit change.
- Added the Q capacity board with actionable input/blocker/overdue/ready filters, due/margin sorting, finite stock and delivery allocation, garment/box requirements, shared operator/station scheduling, finish estimates and daily bill/cash forecasts. Estimates assume prompt approvals and normal quality; returning customers and disruptions add uncertainty.
- Normal quotes cover the modeled route plus slack; rush quotes show the premium and tighter deadline before commitment. New rules allow one rush premium per day, preventing a universal premium on every job.
- Larger premises cost $900 and preserve installed equipment/layout. A separate $350 fit-out enables industrial equipment purchases. An additional DTF line costs $900 and requires safe service access. Old-economy saves retain their grandfathered expansion.
- Added reversible client focus and repeat inquiries retaining approved art/presets with separate fulfillment. Compatible DTF/apparel jobs can share physically packed sheets; each customer retains output ownership, finishing, stock charges and exactly-once payment. Batches are offered only when the shelf-packed layout saves film. Individual reprints detach from shared film allocations.
- Added unique hire names/IDs, role enforcement, current-task/idle reasons, shift utilization and an opening-bill cash guard for hiring. Added a disclosed two-hour/$100 recovery shift and an optional one-time Relaxed rescue loan with fixed repayment.
- Added native focusable button controls, keyboard equipment placement, movement remapping and Reduce Motion. Actual assistive-technology behavior still needs hardware acceptance.
- Added task-clock-driven printer, cutter, heat press, artwork, inspection and packing cues, worker carrying and customer parcel/payment cues. Help spacing is corrected; labels use authoritative station activity. Approved equipment art and logos are retained.
- Sound, motion, remapped input and window-mode preferences are separate from shop snapshots. New-game creation archives the previous shop beyond the ordinary rotating backup. Structurally damaged saves fall back to a valid backup.
- Fixed the older placement helper regression without changing attempted-preview geometry. Discount and reprint input displays include the real settlement and maintenance costs. Day reports distinguish current cash, pending daily bills and operating costs.

Validation and exact boundaries: `STRATEGY-UPGRADE.md`. The release pipeline packages a separate QA ZIP with the render matrix, motion video, 14-day policy results and actual Windows executable walkthrough log. Physical Windows display scaling and screen-reader interaction are not certified by CI.

## Version 0.2.22 — assessment recovery pass

- Fixed valid printer/shaker assemblies rejecting JSON-loaded dimensions because numeric array element types differed. Dimensions are compared as grid sizes. Real disconnected assemblies remain rejected.
- Fixed customers stalled at fractional doorway positions whose rounded route was already empty. Exiting visitors have passage priority over other customers so doorway and narrow aisle traffic can clear. This can briefly overlap visitor sprites in a narrow aisle; full crowd animation remains future work.
- Recovered the supplied day-eight fixture's four unpaid pickups and three queued DTF jobs, through ordinary dispatch and settlement. No player save is rewritten or reset by this update.
- Interrupted printing returns to the production state and consumes stock only on its first start.
- Space now pauses/resumes order, machine and staff panels. Those live panels expose an explicit clock button. Other management panels retain their existing automatic pause policy.
- Sound effects now use the separate audio preferences file alongside music. Continuing a shop cannot undo the saved Sound Off choice.
- Tutorial acceptance text reads the current order quantity; discounted order payout display matches settlement; Hire buttons disable at the nine-person team limit.
- Preserved v0.2.21 approved branding, equipment artwork, rotation pivots and workspace docks.

Validation: see `ASSESSMENT-INTEGRATION.md`. This is a reliability update, not completion of the full difficulty, economy, progression, animation or accessibility specification. Windows packaging CI runs after the commit; it does not certify a native Windows playthrough.

## Version 0.2.21 — supplied logo-only Windows icon

- Removed the rejected square badge and adopted the owner-supplied `Print-Shop-Tycoon-Windows-Icon-1024.png`. The runtime PNG is an exact copy; the multi-resolution ICO preserves its transparency and proportions.
- Updated the desktop shortcut to a new logo-only icon filename to avoid the cached badge.
- Updated branding instructions to prohibit adding backgrounds, frames or decorations. The title/shop logo stays the previously approved wide source.

## Version 0.2.20 — full-size Windows icon

- Placed the approved logo, without stretching or changing its lettering, on a full-size rounded navy badge with a blue edge. The square silhouette fills normal Windows icon bounds instead of leaving most of the height transparent.
- Updated multi-resolution shortcut ICO and Godot runtime PNG. A new shortcut icon filename avoids stale Windows icon-cache entries.
- Title/shop logo PNGs remain the exact approved originals. Editable packaging script and preview are in `art/branding`.

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
