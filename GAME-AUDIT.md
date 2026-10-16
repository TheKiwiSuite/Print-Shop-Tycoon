# Game audit — v0.2.13

Audit date: October 15, 2026. The installed Windows executable is still v0.2.13.
This is a findings report, not a claim that the gameplay defects below are fixed.

## Coverage and results

- Reran all eight existing suites through `Run-QA.ps1`: **397 checks passed** across acceptance, empty shop/rotation, DTF art, customer loop, customer walking, sales growth, DTF input, and session reliability.
- Ran 14 additional diagnostic scenarios. All reproduced the reported behavior; one is a staff-rule decision rather than a confirmed requirements violation. A separate native UI check confirmed the help-text layout defect, making **15 findings** in the table below.
- Played the installed Windows executable in its separate `--qa-ui` profile. Confirmed a blank new shop, equipment catalog, initial DTF placement, rotation, relocation of an already placed line, wall rejection, a successful relocation after rejection, and normal save/exit. The rejected wall placement retained the installed printer/shaker pair and its cash balance.
- Inspected native viewport captures of the shop, build mode, gang builder, stock, marketing, staff, daily report, shaker controls, and industrial room. The help overlap was also checked in the actual installed executable.
- The all-product acceptance suite covers transfer, sticker, apparel, banner and CNC completion/payment. This audit did not manually replay every production route in the installed UI.
- Every audit write used a QA or workspace scratch profile. No normal player save was used for destructive probes.
- The previously reported Windows memory-access popup did not recur with the isolated writable logs used here. The damaged-save probe produced GDScript errors; that is a different failure from the Windows access-violation popup.

The existing suite passing does not imply the edge cases are correct. The diagnostic runner deliberately reports failure because BUG-01 triggers script errors. Its output finishes with 14 reproduced scenarios; it must not be described as an additional clean passing suite. The DTF-art test also emitted an ObjectDB cleanup warning at exit; a production memory leak has not been established from that test-only warning.

## Findings awaiting fixes

P1: progress/recovery risk. P2: incorrect behavior or misleading UI. P3: lower-impact usability issue. “Decision” requires an explicit gameplay rule.

| ID | Priority | Finding and reproduction | Expected correction |
| --- | --- | --- | --- |
| BUG-01 | P1 | A syntactically valid but structurally damaged main save is accepted despite a good backup. Supply `workers: [{}]`, empty `machines`/`orders`, and valid format metadata. `load_game()` returns true, then `owner()` raises an invalid `id` access. | Validate required nested data and the owner before adopting state; reject the main file and try the backup. |
| BUG-02 | P1 | New Game promises to retain the previous shop as a backup. The first new-shop save does so, but the next save replaces that backup with the new shop. Normal autosave can therefore erase the previous shop after about ten seconds. | Keep a distinct previous-shop archive or save slot, and describe its retention accurately. |
| BUG-03 | P2 | Sam can walk onto a waiting customer's exact position. The probe ended with owner/customer distance `0.0`. Customer movement checks people, while worker/owner movement only checks equipment. | Apply consistent crowd collision or a deliberate separation/yield rule to both sides. |
| BUG-04 | P2 | Start a print, interrupt Sam after stock is consumed, then resume. The worker is operating and the machine is active, but the order remains `queued`. | Restore the production stage on resume without consuming stock a second time. |
| BUG-05 | P2 | Begin dragging a gang-sheet design, then close the builder with Escape while still dragging. `gang_drag` stays active and subsequent mouse motion changes the hidden sheet. The probe moved a design to `[-56.5, -31.0]` with the modal closed. | Cancel/revert the drag on close and modal changes; restrict gang motion to the builder. Avoid saving transient invalid layouts. |
| BUG-06 | P2 | An order ready to pack needs one box with zero packaging in stock, but `forecast()` returns empty requirements and shortages. Garment needs are also outside this forecast. | Include outstanding packing and garment requirements in forecasts and supply feedback. |
| BUG-07 | P2 | Fix Cause + Reprint consumes a maintenance kit but records `$0` of kit expense in the materials ledger. Ordinary Clean/Calibrate does book its kit cost. | Book the kit consumption consistently so profit and job costs include it. |
| RULE-08 | Decision | Explicit station assignment lets a prepress artist reserve a DTF job even though `role_matches()` rejects that role for automatic dispatch. | Decide whether cross-training/manual overrides are allowed. Enforce the same rule or explain the override in the interface. |
| BUG-09 | P2 | During the DTF line's `Cure transfer` phase, the shaker panel says `Current action: Idle` and lists an active printing job below it. | Derive the connected shaker's displayed activity/operator from the running line, or model its activity separately. |
| BUG-10 | P3 | At nine total workers, Hire remains enabled when cash is sufficient. Clicking it does nothing and adds no explanation. | Disable hiring at the cap and display the capacity limit. |
| BUG-11 | P2 | Start with only the sticker station, let the starter order adapt to stickers, then select Replay Tutorial. It creates an immediately available transfer tutorial although no DTF printer exists. | Replay a tutorial suited to owned equipment or offer an explicit tutorial equipment setup. |
| BUG-12 | P2 | Help item 12 and the local-save footer occupy overlapping vertical space. Confirmed in the installed Windows UI. | Reflow/scroll the list or reserve separate footer space. |
| BUG-13 | P2 | If both save candidates are invalid JSON, Continue returns to the same title screen without a visible explanation. The failure notice is written to a gameplay notice that the title screen never displays. | Show a visible recovery dialog and available next steps. |
| BUG-14 | P2 | Change Sound on the title screen, then Continue. Loading the shop overwrites the title preference with the saved shop setting. Startup also begins from default preferences. | Load/persist preferences independently of the shop and apply them at startup. |
| BUG-15 | P3 | Save `fullscreen: true`, return to a windowed session, then Continue. The setting loads as true but the actual window stays windowed. | Apply the saved window mode after loading preferences. |

### Reproduction code

`source/test/audit_edge_cases.gd` reproduces every programmatic row above. BUG-12 is verified by screenshot rather than a synthetic text-position assertion.

Run from the documented development workspace:

```powershell
.\Run-QA.ps1 -Test audit_edge_cases -Graphics
```

The runner currently fails on the deliberately damaged save's invalid `id` accesses. See the printed `AUDIT` rows and the unique log path returned by the runner. Do not weaken the runner's error detection to make this diagnostic appear clean.

Relevant implementation locations:

- Save validation/backup: `source/scripts/simulation.gd`, `load_game()` and `save_game()`.
- Crowd movement: `simulation.gd`, `_walk_customer()`, `_walk()`, and `tick()`.
- Interrupted production: `simulation.gd`, `interrupt_owner()` and `_begin_task()`.
- Gang gesture lifetime: `source/scripts/native_game.gd`, `_input()`, `_cancel_world_drag()`, and `_action()`.
- Forecast/repair/roles/capacity: `simulation.gd`, `forecast()`, `recover()`, `assign()`, `_auto_dispatch()`, and `hire()`.
- Status/tutorial/preferences/layout: `native_game.gd`, `_machine_panel()`, `_staff_panel()`, `_help_panel()`, and `_action()`.

## Visual and workflow imperfections

These are separate from proven logic errors. Preserve the approved machine images while resolving the surrounding presentation.

1. **Official start screen is not integrated.** The title uses an empty in-game room behind the logo; the supplied garage title-screen artwork is absent from the current title implementation. Evidence: `title.png`.
2. **Overall scene is still a prototype art pass.** Room surfaces, exterior, lighting, product symbols and sparse props do not match the detailed approved 2.5D cartoon reference. The approved DTF images should remain the equipment authority.
3. **Fixed panels cover usable floor and people.** In the populated neighborhood/industrial views, the left customer/tutorial panels cover the entrance area and part of Sam. The camera does not reserve space around those panels. This reduces readable play space even when the simulated floor is larger.
4. **Rotated sprites need a consistent camera/footprint review.** The supplied side/front views are used as discrete rotations. In the side view the visual feet and machine silhouette do not closely match the isometric highlighted footprint. Benches change collision orientation while retaining their original illustrated view. More suitable approved views or per-view calibration are needed; do not rotate a flat image to fake a new machine design.
5. **Invalid new-equipment previews disappear.** A rejected new placement shows a clamped red tile and message instead of the whole blocked equipment silhouette. Existing equipment is retained correctly. A red full-size ghost would make rejection easier to understand.
6. **Starter selection remains incomplete.** There is no Cricut-style vinyl cutter or small desktop DTF setup. The starter sticker station uses the older atlas pending its approved replacement. Equipment cannot currently be sold/removed through the UI.
7. **Characters and operating animation remain placeholders.** Staff/customers reuse the current walking sheet with clothing tints. Dedicated customer variety, handling/packing gestures, and equipment operation animation are incomplete.
8. **Production/economy depth needs a separate design pass.** Material quantities scale with job size, while phase durations are largely fixed per job. Storage has no stock-capacity progression, expansion replaces the layout with a supplied industrial setup, and there is no equipment resale. Review these against the owner's real print-shop progression before adding many more machines.
9. **Onboarding/accessibility need refinement.** Paused setup also freezes Sam, which can feel like failed controls. Most menus are drawn directly with no keyboard focus navigation or exposed native control tree. Add clear pause feedback and accessible menu interaction.
10. **Public-contributor setup is incomplete.** Build/QA helpers still expect the original `outputs/PrintShopTycoon-Native` plus `work` workspace layout. A clean-clone bootstrap and CI would reduce contributor friction. No top-level project license has been selected; keep that owner decision explicit.

## Recommended fix order

1. Save validation, previous-shop archive, and visible Continue failure (BUG-01/02/13).
2. Gang gesture cancellation, crowd collision, interrupted production state, and equipment-matched tutorial (BUG-03/04/05/11).
3. Supply/repair accounting, connected-machine status, preferences, and help/capacity feedback (BUG-06/07/09/10/12/14/15).
4. Settle RULE-08, then carry out the approved art/onboarding pass and improve contributor setup.

## Evidence

All images are under `captures/audit-v0.2.13/`.

- `help-overlap-native.png`: overlapping help/footer text in the installed executable.
- `shaker-idle-while-curing.png`: contradictory shaker activity and active job status.
- `title.png`: current title compared with the requested garage start screen.
- `catalog-native.png` and `empty-native.png`: actual starter choices and blank setup.
- `rotation-native.png`, `wall-rejected-native.png`, `relocated-native.png`: the same DTF line rotates, rejects a wall position and then relocates correctly.
- `gang-sheet.png`, `industrial-shop.png`: current builder and expanded-room presentation.
- `findings.json`: values recorded by the 14 diagnostic reproductions. RULE-08 is labeled BUG-08 in the raw diagnostic output for stable probe identification.

The audit covers the current routes, common interfaces and the listed edge cases. Long-duration soak testing, multiple simultaneous player instances, other GPUs/display scales, gamepads, localization and every possible player layout have not been exhaustively tested. Absence from this list is not proof of correctness.
