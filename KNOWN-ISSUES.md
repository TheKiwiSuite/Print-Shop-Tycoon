# Known issues and acceptance limits — v1.1.0

This replaces the October 2026 v0.2.13 audit (`GAME-AUDIT.md`, kept for history). Every programmatic finding in that audit is now either fixed or confirmed fixed by `source/test/audit_edge_cases.gd` (14 probes, 0 reproduced).

## Open items

- **Unsigned executable.** Windows SmartScreen may warn on first launch. Choose *More info → Run anyway*. Publisher signing needs a code-signing certificate and is not set up.
- **Players on v1.0.0** update in-game through the legacy ZIP channel (`vX.Y.Z-windows-alpha`). Their older updater can't read the stable standalone EXE release. The first in-game update moves them to the 1.1.0 updater, which reads both formats.
- **Not machine-certified:** physical Windows DPI scaling above 100%, screen-reader listening, gamepads, localization, and multi-week human balance play. Automated checks cover rendered window sizes from 1280×720 to 3840×2160 (window size, not OS scaling) and scripted 14-day balance runs on all three presets.
- **Manual-only checks for this release:** a complete installed-EXE update and rollback drill on a player PC. Component and executable tests cover replacement, failed replacement and rollback in isolated copies; a full live drill was not performed.
- **Rule decision kept as-is (RULE-08):** a manually assigned worker must still match the station's role. The assignment is refused without moving the worker.
- **Equipment resale:** machines can be moved but not sold. Decor can be removed without a refund.
- **Historical dev tools:** `record_dtf_walkthrough.gd`, `sales_ui.gd` and `customer_ui.gd` are pre-1.0 recorders and UI probes for the old empty-shop start. They are not release gates and are not run in CI.
