# Customer flow and sales growth

Scope approved October 14, 2026. Stop after this phase is tested and installed.

- [x] Audit the existing native customer-to-payment loop and record defects.
- [x] Harden customer entry, waiting, departure and pickup routes around equipment.
- [x] Verify installed-equipment movement, rotation and rejected wall placement.
- [x] Add marketing with visible costs and equipment-matched scheduled inquiries.
- [x] Include campaign spending in daily profit and preserve it through save/load.
- [x] Test pause, multiple orders, missing stations, departures, payment once and save recovery.
- [x] Inspect the native Windows interface for overlap, hidden controls and floor contact.
- [x] Deploy v0.2.12 through the fixed executable and desktop shortcut.
- [x] Record results and stop; leave new equipment artwork and levels for later.

## Delivered results

- Release: `BUILD-INFO.json` reports v0.2.12 (Godot 4.5.1); installed executable SHA-256 matches the manifest and the current playable ZIP contains the same export.
- Gameplay suites: 321 checks passed across acceptance (109), empty shop/rotation (70), DTF art, customer loop (47), customer walking (33), and sales growth/save recovery (49).
- UI: inspected marketing/campaign, customer arrival and walking, order status, and day-end accounting captures; no overlapping text or hidden controls in the inspected states.
- Walkthrough: `outputs/PrintShopTycoon-Phase-Walkthrough-v0.2.12.mp4` (240 viewport frames, 20 fps).
- Normal player save SHA-256 stayed `D5F54FB020058079881BE0C2D5FADF263A114E1C5505A88A883B8F7172BF8621` before and after deployment.
- Godot logged the Windows root-certificate-store diagnostic in this restricted build environment. The offline game does not make HTTPS requests; release validation continues to fail on every other engine error or script error.
- The development runner's prior access violation was a generic Godot Application Error during QA startup. No faulting module was available in the Windows event log, so the exact underlying cause is not established. The installed v0.2.12 export passed the headless smoke test.
- Stop after this phase. Defer additional equipment art/levels to a later phase.

## DTF controls and full walkthrough follow-up — v0.2.13 candidate

- [x] Commit equipment drags from the actual release coordinates, including a final drop without a mouse-motion event.
- [x] Clear earlier relocation/drag state when choosing another piece of equipment.
- [x] Verify the complete printer/shaker pair remains linked and selectable through all four quarter-turn views.
- [x] Reject wall drops without moving or removing the installed line; successfully relocate it again afterward.
- [x] Run the native input regression (27 checks) and the existing six gameplay suites (321 checks).
- [x] Record and inspect the complete DTF transfer workflow with visible controls and captions: 82.92 seconds, 24 fps, 24 transfers, $480 collected.
- [x] Encode the MP4 with Blender, decode it again, verify its duration and inspect a decoded production frame.
- [x] Export and smoke-test an isolated Windows candidate without replacing the installed executable.
- [x] Back up the normal player save and verify the backup matches the original.
- [x] Install v0.2.13 through Build-Release.ps1 after the old player process is closed.

At the original checkpoint, the older installed player process exposed no closable main window and installation awaited permission. On October 15 the user granted permission after disclosure of possible unsaved-progress loss. The verified old process was terminated, and v0.2.13 was installed successfully through Build-Release.ps1.

The new walkthrough is `outputs/PrintShopTycoon-DTF-Walkthrough-v0.2.13.mp4`, outside the release folder. Chapter highlights: rotation at 0:07, wall rejection at 0:18, Kiwi Suite at 0:39, DTF production at 0:43, inspection/packing from 0:58, and payment at 1:15. Artwork is the existing supplied sprite views; this follow-up does not generate replacement equipment art.

QA now writes its engine logs into the workspace. A QA startup crash was reproduced immediately after Godot failed to rotate its AppData log; the same input runner passed after redirecting that log. Release export/smoke logs and temporary files now use the workspace staging directory.

## Recurring Godot popup investigation — October 14

- Two failed startup logs show `Failed to open user://logs/...` immediately followed by signal 11. Godot 4.5.1's `RotatedFileLogger::rotate_file()` opens the log and dereferences the result without a null check (upstream `core/io/logger.cpp`, lines 153–154). This supports the logging failure as a reproducible crash trigger; the screenshot alone does not prove every popup has the same cause.
- Closed two verified leftover QA sessions (`sales_growth.gd` and `sales_ui.gd`) and confirmed their engine/console processes were gone. The installed player process was left running.
- Added `Run-QA.ps1`: unique writable engine log, workspace temporary directory, direct engine launch without a console wrapper, bounded timeout and cleanup of only the process it started. Ordinary errors still fail QA.
- Reran sales growth (49 checks) and native DTF input/rotation (27 checks) through the runner: all 76 passed, both engine processes exited, no crash signatures in their logs.
- This changes the development test launcher only. Installed release remains v0.2.12; v0.2.13 installation still awaits the previously requested player-process decision.

## Save and placement reliability checkpoint — October 15

User authorized a bounded next phase and requested a pause at a meaningful checkpoint.

- [x] Check save errors before leaving for the title screen or quitting, including the Windows close button.
- [x] Add an inspected native retry/keep-playing panel; preserve the requested save/exit action for retry.
- [x] Report write, backup-rotation, and final-file replacement failures; attempt recovery from backup after a failed final replacement.
- [x] Cancel placement previews when opening menus and prevent hidden equipment rotation or mouse-release placement behind those menus.
- [x] Clear pending placement feedback on Escape.
- [x] Verify all four linked printer/shaker rotations, positions, and funds through save/reload.
- [x] Run 49 new session-reliability checks plus the existing 348 gameplay/input/art checks: 397 checks passed.
- [x] Inspect `captures/save-retry-panel.png`, captured from the actual native viewport with a deliberately unavailable QA save folder. No normal save error was induced.
- [x] Export and smoke-test the updated v0.2.13 candidate; no stray QA engine processes remain.
- [x] Confirm the normal player save still matches its backup.
- [x] Install the candidate after closing the older installed player with the user's explicit permission.

Checkpoint reached; pause here as requested. Installation was initially held because Computer Use exposed no targetable game window for the older installed process. That hold was resolved by the user's explicit permission on October 15; see the delivery verification below.

The existing 83-second DTF walkthrough demonstrates the printer workflow and placement fixes. It predates this added save-error safeguard and does not demonstrate that new panel.

## Delivery verification — October 15

- Installed v0.2.13 using Build-Release.ps1 after backing up the current save and backup file, then terminating only the verified older player process with user permission.
- Verified installed executable and packaged executable checksum against BUILD-INFO.json.
- Verified the fixed desktop shortcut targets the installed executable with no QA flags.
- Inspected the launched native title screen with Computer Use: window title and bottom-left footer both show v0.2.13; Continue is available.
- Normal player save is byte-for-byte unchanged from the verified backup.
- Cleanup limitation: automatic review rejected both recursive deletion of `work/dtf-review-0.2.13` and deletion of its exact `Print Shop Tycoon.exe` with `blocked by policy`. No approval control was available. The temporary QA executable therefore remains in that development folder; it has no desktop shortcut. The fixed installed executable is the new build.
- Paused at the completed gameplay/reliability checkpoint. No further feature work started.
