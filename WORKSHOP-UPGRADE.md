# Workshop update — v0.4.0

Open **Workshop + Style** at the top of the left desk. The File menu also opens Workshop, Growth and Photo mode. The playable demo and career retain separate save slots. Existing saves migrate without resetting accepted jobs, stock, machines, staff or money.

## Growth and capacity

The Growth route remains visible after premises purchase. Equipment links directly to the exact premises / $350 fit-out prerequisite. Larger premises retain the layout; the optional $2,200 production annex adds a 22 × 16 floor and $75 daily overhead after fit-out, ten paid jobs and 80 trust, with the next-bill buffer required. Place additional production and display zones yourself.

The capacity board uses committed work, qualified staff, stock reservations, service downtime, equipment wear and debt payments. Proposed and committed deadlines are labelled separately. Accepting more than capacity can cause queues, shortages, late jobs and trust loss; decline unrealistic inquiries before committing. No accepted terms are silently extended.

## Trust and equipment agreements

Community promotion costs $25 and creates one discounted print inquiry per day. It still needs normal acceptance and production. Good on-time delivery earns normal trust plus two; spending does not directly buy trust.

Optional equipment agreements require a 20% deposit and add a fixed fee of 10% of the equipment price. The remaining 90% is paid over up to ten daily bills, rounding the final payment down to the exact remainder. At most two agreements may remain unpaid. You need the deposit plus the next daily bills and proposed payment in cash. Invalid/cancelled placement creates no debt. Agreements do not disappear when equipment is moved. This is authored game balancing, not a real credit product.

Daily accounts now link to a cash bridge: opening cash, receipts, actual purchases, capital, hiring, upgrades, artwork, marketing, event costs and closing bills. Inventory use is not charged a second time. Equipment repayments affect cash rather than operating profit.

## Service and shop decisions

Service consumes one maintenance kit ($8 stock value), reserves a qualified free worker and locks the station for twelve work seconds plus walking. Machine service coordinates remain separate from service task state. Four uses trigger routine warnings; condition below 65% adds 15% production time. Eight uses, condition at most 40%, and three days without service can stop an idle machine. Service recovers it. Light use does not cause instant failure after one missed day.

A saved daily hurdle can appear from day three: supplies, artwork confirmation, shift absence, or an optional project. Review decisions in Workshop. No accepted deadline changes without your action. Hurdles can be disabled. Industrial rare commissions can propose banner or CNC work before the needed equipment is owned; the quote remains unaccepted while you assess financing, space and capacity. The artwork card currently confirms the existing brief; a full negotiation/revision event remains a later extension.

Optional sticker registration and apparel press timing are available from a job or File menu. Maximum two interventions per day; first is practice; Timing Assist defaults on; skipping keeps ordinary production. Timing holds when focus is lost and is independent of shop speed. Success gives a bounded 5% task-time benefit, never cash. Broken stations offer optional three-step jam recovery with one kit, or normal service. Saved intervention IDs prevent replaying a result. Reload safely selects ordinary automatic fallback for an unfinished prompt.

## Away and offline work

Away uses real Auto Assist, staff routes, stock, service, wear, jobs and payments. No new orders, repeat orders or supplies are automatically purchased. Waiting inquiries are held. Pending artwork/layout/quality choices, hurdles and closing pause work safely. Optional automatic service has a $24 service sublimit within a $100 shift limit.

Offline work is off by default. Enable it before leaving an Away shift. On resuming that profile, the saved interval runs once at 1×, capped at 900 real seconds. One real second advances 0.009 shop hours. Closing or a manager decision stops it. The result saves atomically before being reported; save failure restores the prior state. Repeated settlement at the same saved timestamp does nothing. See the Away page for the return report. The local system clock is not a trusted anti-cheat source; clock reversal grants no time and forward jumps remain capped.

## Personal style

Buy T-shirt displays, transfer/packing racks, sample stands, shop-made banner stands and plants. Click clear floor to place; Escape cancels. Footprints physically block walking; placement must retain service access. You can remove the last decoration without a resale payout. Moving individual decorations and custom shop-name signage remain future improvements.

Choose floor presets or import a PNG. Imports are local only: PNG signature checked before decoding, maximum 8 MB, 2048 × 2048 pixels, copied into the game's own custom-floors folder. No executable content, remote images or uploads. You retain responsibility for imported artwork. Per-worker Workshop, Blue apron and Red apron outfits are available; Executive suit unlocks after five fulfilled jobs and a profitable day. Faces and existing walk frames remain intact; garments follow the original animated cloth pixels, with small executive lapel/tie details.

Purchases show a brief cosmetic crate reveal after valid placement. Reduce Motion skips it. Pausing does not stall the cosmetic reveal; reload completes it without repurchasing.

## Photos and optional links

Photo mode holds the shop and restores camera/pause state on return. Wheel zooms, middle-drag pans, Home fits. Exports are actual opaque PNG files at 1920×1080, 1080×1080 or 1080×1350, written to the local photos folder. HUD, version, paths, staff/customer names, stage labels, popups and partner links are excluded. Imported floor artwork is excluded unless explicitly enabled. Select an aspect preset to preview its crop frame, then export that frame. There is no social login, posting, clipboard scraping or automatic upload. Logo/watermark controls remain future polish.

Partner links are confined to a reserved title-screen panel, away from the shop floor. Shipped configuration has no destinations, so the panel is hidden. A local `partner-banners.json` in the game's user data folder can override `source/config/partner-banners.json`. Schema: version 1, banners array; each item has unique id, enabled, title, caption, HTTPS url and optional integer Unix starts/ends. Only explicit button activation opens a browser. Invalid schemes, credentials, duplicate IDs and malformed entries are rejected. No remote HTML, script or image loads. Configurable text cards rotate every twelve seconds; imported partner artwork is not implemented.

## Validation and limits

New operations and visual/export suites run with the existing production, batching, persistence, updater, difficulty/balance and Windows executable checks. The supplied nine-job career and three-job demo reproduction saves were loaded locally, bought fit-out successfully and retained byte-identical evidence files. CI renders the new panels at review and fullscreen sizes and exports all three photo dimensions. See the matching QA release artifact for rendered evidence and logs.

Native accessible controls and keyboard navigation are retained. Manual Windows screen-reader, display-scaling, physical input/focus and animation smoothness acceptance still require human review. Automated coverage is not a claim that all thirty assessment items have passed manual acceptance.
