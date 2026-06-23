# Final Verification Checklist

Run this end-to-end after all phases. Tick each on a real device/emulator, in **both light and
dark mode**, and verify localization (en_US + hi_IN).

## Phase 1 — Foundation
- [ ] Admin: Logout shows a confirm dialog; Cancel keeps session; Confirm signs out
- [ ] User: toggling dark/light in Account visibly changes the WHOLE app and persists on restart
- [ ] User: no screen stays light in dark mode (Home, catalog, detail, auth, profile, settings)
- [ ] User: Home shows shimmer skeletons on first load (not a spinner), matching the layout
- [ ] User: tap heart on a design → added to My Favorites; tap again → removed; persists + offline
- [ ] User: design detail shows dot indicators for multi-image designs
- [ ] User: tapping a design image opens full-screen, swipeable viewer with counter + pinch-zoom
- [ ] Admin: can upload an image from disk for collection/category/design; preview + progress
- [ ] Admin: design supports multiple image uploads (add/reorder/remove)
- [ ] Admin: Media Library — multi-upload in one shot; browse, select, replace, delete
- [ ] Admin: can pick an existing library asset when creating/editing an item
- [ ] Admin: deleting an item deletes its Storage image(s); cascade removes children's images
- [ ] Admin: shared library assets are NOT deleted while still used elsewhere

## Phase 2 — Revenue core (demo)
- [ ] User: Add to Cart from detail + favorites; cart persists
- [ ] User: Cart totals = subtotal + platform fee% + GST% (from config/platform)
- [ ] User: Checkout (Razorpay test card OR mock) succeeds → order + purchases written → cart cleared
- [ ] User: My Purchases lists owned designs; detail shows owned state + Download
- [ ] Admin: Transactions lists the demo orders with filters (status/date) + search
- [ ] Admin: Order detail shows items, fee/GST breakdown, payment id, timeline
- [ ] Admin: Dashboard shows LIVE counts (users, designs, pending, orders) — no hardcoded numbers
- [ ] DEMO rule relaxations are tagged `// PHASE-2 DEMO ONLY`

## Phase 3 — Production payments & analytics (Blaze)
- [ ] Real Razorpay: create→verify→finalize→webhook all succeed (test card)
- [ ] Invoice number minted; purchase granted; cart cleared server-side
- [ ] Rules re-locked: client CANNOT write orders/purchases (emulator test passes)
- [ ] Admin refund revokes the purchase (download no longer available)
- [ ] Admin Reports: date-range sales/top lists accurate; CSV export downloads
- [ ] Admin Dashboard: revenue trend + KPI charts (fl_chart) match Reports
- [ ] Payouts: a sale credits the designer; admin can view/process a payout (or read-only earnings)
- [ ] Platform Fees: changing fee/GST updates checkout totals app-wide

## Global quality gates
- [ ] `flutter analyze` clean: user app, admin app, design_system
- [ ] No hardcoded user-visible strings (all via AppLocalization, en + hi)
- [ ] No hardcoded colors in screens (theme-aware); dark mode correct everywhere
- [ ] Every `Text` has `maxLines` + `overflow: ellipsis`
- [ ] Admin notifications use `ResponsiveSnackbar`; errors logged via `AppLogger.logError`
- [ ] Works at 320px width and on tablet/desktop (admin)
