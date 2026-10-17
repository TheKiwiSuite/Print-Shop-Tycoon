# October 16 assessment integration

Baseline: `152da3c7190470a37fff177de97a41137d54c27b`, native Windows v0.2.21. The supplied assessment played v0.2.13 (`8ea6350` per its metadata). It contains findings and proposed work, not a source patch. Later approved artwork, branding, rotation and workspace work is retained.

## Implemented in v0.2.22

LIVE-01/LIVE-02: reproduced the supplied day-eight checkpoint unchanged, then repaired numeric dimension comparison and customer lifecycle/traffic failures. All seven stalled jobs must complete and pay exactly once. Test copies run only in isolated profiles. The fixture contains fictional game customers and the assessed shop snapshot.

LIVE-03: valid unrelated desk placement is no longer rejected by the numeric line comparison; real disconnected lines remain invalid. This does not remove global access validation.

LIVE-05: separate sound preferences. LIVE-07: dynamic tutorial quantity. LIVE-19: keyboard and in-panel clock controls. LIVE-10: corrected order-panel discounted payout; broader cost receipt work remains. LIVE-06: hire-cap button guard; full roster identity/utilization redesign remains.

Interrupted printing also resumes with an authoritative production stage and without double consumption.

## Validation

Run `handoff_recovery` with Godot 4.5.1 and a writable isolated log. It loads `source/test/fixtures/day8-blocked.json` as input only, exercises dispatch/settlement, checks cash reconciliation, saves/reloads a separate QA copy, retries settlement, and checks interrupted stock use, real keyboard handlers and sound preference restoration.

Local Godot 4.5.1 headless runs: handoff recovery 31/31, acceptance 109/109, customer loop 47/47 and sales growth 49/49. The optional older customer_walking suite reported 32/33: its invalid-preview expectation fails against the current rendering behavior; it is not counted as passing or silently removed. This helper and assertion predate these changes and require separate placement review. GitHub's packaging workflow additionally runs the rendered existing suites before exporting the Windows build. The headless scene tests emitted an ObjectDB cleanup warning at exit; this is recorded as a test cleanup limitation, not proof of a production leak. Native Windows UI/playthrough, animation cadence, seven/fourteen-day balancing and full visual matrix are not certified by headless tests.

## Open assessment work

The full handoff remains the design target. Remaining work includes Relaxed/Standard/Expert/Custom with safe save migration and measured tuning; capacity/BOM/deadline forecasting; staged property/equipment economy; route/state/receipt clarity; full staff roster; all-asset framing and Help layout audit; production/customer animation; accessibility; repeat clients; mixed-order batching; specializations; daily cash reporting; and broader manual/auto/staff, relocation, overnight and display-setting validation.

The repository deploys a downloadable Windows alpha through GitHub Releases. Its HTML files are art reference viewers, not a web export of the native game. A website link to the new download is a separate integration with the printshop site; no web-port work is represented as complete.
