# Print Shop Tycoon 0.3.0

The October 16 assessment is implemented against main `ff8de4ea3b052674aa93e6f5b6e71df251b3b593` (0.2.22). This upgrade retains approved equipment textures, rotation pivots, branding and isolated player saves. WorldClaw integration is parked.

## Shop rules and migration

New games choose Relaxed, Standard, Expert or Custom before the first save. These are authored game values, not real printer economics or measured manufacturer throughput.

| Factor | Relaxed | Standard | Expert |
| --- | ---: | ---: | ---: |
| Opening cash | $2,400 | $1,600 | $1,360 |
| Deadline slack | 1.50 | 1.00 | 0.85 |
| Overhead | 0.75 | 1.00 | 1.15 |
| Supplier lead time | 0.75 | 1.00 | 1.15 |
| Inquiry patience | 1.50 | 1.00 | 0.85 |
| Recoverable defect risk | 0.50 | 1.00 | 1.15 |

Custom factors are bounded to 0.50–2.00. Base recoverable defect risk is 2% per attempt, divided by the operating worker's skill, with deterministic per-order/per-reprint rolls. Incorrect presets and neglected equipment still cause their explicit faults. Accepted orders snapshot rules and their initial roll; changing difficulty does not alter accepted rewards, due dates or cash. Normal deadlines include the resource-scheduled completion estimate plus slack; rush offers tighter terms, a 30% premium and a one-premium-per-day limit.

New or explicitly converted shops use schema 4 and rules version 1. Existing schema 3 shops preserve the old $1,200 origin, current funds, accepted terms and expansion behavior. Rules change only through the paused Settings action. Opening cash is applied only to a new game. Sound, music, Reduce Motion, movement keys and display mode are application preferences; Continue cannot roll them back. Starting another shop copies the previous save to a timestamped archive before ordinary backup rotation can replace it.

## Planning and growth

Q opens the capacity board. Required inputs cover ink/media, remaining garment sizes and packaging. Deliveries are finite, shared resources. Forecasts schedule station and operator availability from live tasks and respect walkable service paths. They assume prompt approval, no unexpected defect and uninterrupted labor. Customer-return time remains uncertain. Estimates are refreshed at most twice per second for smooth UI; accepting a quote recomputes its current terms.

The board exposes input, blocked, overdue and ready filters, due/margin sorting, daily wages/overhead/loan repayment, possible receipts and cash after bills. Stock allocation is a forecast, not an inventory grant or a cash reservation. A shortfall without a delivery has no invented ETA. New-economy hiring requires enough cash for its fee and the next day's bill buffer.

Larger premises ($900), industrial fit-out ($350) and individual machines are separate. Expansion retains every installed equipment transform. A second DTF line ($900) is placed only where the full assembly and access fit. Client focus favors a supported daily inquiry; it never invents an equipment capability. Repeating a completed order preserves approved art and preset as a new, unpaid inquiry. A repeated rush order starts from its original base quote instead of compounding the premium.

Mixed sheets accept unstarted DTF/apparel work sharing film width, sheet length and white preset. Shelf packing records every design's customer ID, sheet and physical rectangle. The combined recipe allocates saved film across orders, then consumes each member's inputs once. Printing occurs as one batch; apparel still needs pressing, each order still needs inspection and packaging, and each client is paid separately. Reprinting one member restores its full individual recipe. A grouping with no film saving is rejected with a reason.

The recovery shift earns $100 while using two shop hours and retaining existing due dates. The Relaxed rescue loan is optional, once per shop, interest-free and repaid $50 per day until its $400 principal is cleared. These are disclosed recovery mechanisms; they are not hidden income or debt forgiveness.

## Presentation and input

Native Button proxies provide focus, activation and accessibility names for the custom-drawn controls. Tab/Shift+Tab navigates and Enter activates. Equipment placement works with arrows/Enter; movement letter keys can be remapped. Reserved game commands remain available. The roster exposes unique IDs, roles, skill, wages, active/idle reason and measured shift utilization.

Production overlays derive from authoritative task elapsed time and phase. Printer material/scan, CNC toolpath, press dwell, artwork, inspection and packing cues stop with the job clock. Workers carry output and completed customers carry parcels. Reduce Motion retains progress information while reducing repeated cosmetic movement. These cues supplement the approved artwork; they are not a replacement skeletal-character animation set.

## Verification and remaining acceptance

- `strategy_growth`: preset budgets, migration, frozen commitments, finite delivery allocation, garment/box requirements, staged expansion, repeat pricing, batch stock/payments, recovery/loan, damaged-save fallback and real input/preferences.
- `strategy_balance`: 12 scripted policies across all three presets and two starter branches, over 14 actual shop days. It records first payment, cash floor, paid orders, on-time fraction, shortfalls, expiry and day-7/day-14 cash/profit. No cash or completed jobs are injected. This is feasibility evidence, not broad human balance certification or proof of an optimal strategy.
- `customer_walking`: includes the previously failing placement-helper check. The render-preview suite still verifies attempted geometry and authoritative layout separately.
- `strategy_visual_review`: actual rendered screens at requested window sizes, input rectangles, runtime texture validity, accessibility control presence, and pause-linked motion. Its JSON records the actual viewport dimensions so window-size requests are not confused with physical UI-scale certification.
- `animation_review`: a video of transfer and CNC routes at 1x and 4x with a pause transition; other routes retain state and placement tests.
- `native_release_walkthrough`: runs inside the actual exported Windows executable in CI and exercises all five routes at 1x/4x, in-production pause/save/reload, appropriate downstream stations and idempotent payment.

Publication is gated on existing regression suites, strategy/balance/render checks and the native Windows executable test. The QA ZIP carries the generated evidence. Physical Windows DPI scaling, screen-reader/Braille software, manual player understanding, all-route animation cadence and long-term balance remain acceptance work; they must not be described as tested by CI. Earlier headless scene tests have emitted an ObjectDB cleanup warning at exit; errors and failed assertions still fail the gate.
