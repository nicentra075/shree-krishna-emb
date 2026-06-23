# Integration Roadmap — Favorites, Buy Flow, Media, Admin Analytics

**Apps:** User App (`shree_krishna_emb_user_app`) + Admin Web (`shree_krishna_emb_admin`)
**Shared:** `core` (models + Either/Failure), `design_system` (components), `firestore.rules`, `functions/`
**Last updated:** 2026-06-18

This is a **3-phase** plan. Each phase is independently shippable. Phase 1 and 2 run
fully on the **free Firebase Spark plan**. Only Phase 3 needs **Blaze**.

> Do NOT start coding from this doc until the user says "start Phase N".

---

## What already exists (verified)

| Thing | Status | Where |
| --- | --- | --- |
| Theme infra (ThemeCubit, light/dark ThemeData, MaterialApp.themeMode) | ✅ works | `core/lib/theme/theme_cubit.dart`, user `lib/theme/app_theme.dart`, `lib/main.dart` |
| Wishlist model + `wishlists/{uid}` + rules | ✅ exists (no UI/bloc) | `core/lib/models/wishlist_model.dart`, `firestore.rules` |
| Cart model + `carts/{uid}` + rules | ✅ exists (no UI/bloc) | `core/lib/models/cart_model.dart` |
| Order model + `orders/{orderId}` + rules | ✅ exists (no UI) | `core/lib/models/order_model.dart` |
| Purchase model + `users/{uid}/purchases/{designId}` + rules | ✅ exists (no UI) | `core/lib/models/purchase_model.dart` |
| Razorpay (server-side) | scaffolded, **not deployed** | `functions/` (Spark = off) |
| Admin Transactions / Reports / Payouts / Platform Fees menus | ❌ stubs (fall through to dashboard) | `admin .../admin_dashboard_screen.dart` |
| Admin Dashboard KPIs | ❌ all hardcoded/mock | `admin .../admin_dashboard_screen.dart` |
| Catalog images | URL-only (no upload) | admin design/category/collection dialogs |
| Cascade delete (collection/category) | ✅ just built | admin `widgets/cascade_delete_dialog.dart` |

---

## Decisions baked in (from Q&A)

1. **Blaze is NOT required for demos.** Phase 2 uses **Razorpay Test Mode (client-side)** or mock
   checkout, with temporarily relaxed `orders`/`purchases` write rules (owner-only). Phase 3
   re-locks the rules and moves order creation/verification/finalization to Cloud Functions.
2. **Images → Firebase Storage** (free on Spark). Upload replaces URL-only. Deleting an item
   deletes its Storage file(s). A reusable **Media Library** supports multi-upload + pick/replace/delete.
3. **Favorites = cloud wishlist** (`wishlists/{uid}`, already modeled), cache-first for offline.
4. **Home loading → shimmer** using existing `AppShimmer`.
5. **Payment code is production-ready from the start, gated by an admin "Test mode" switch.**
   A `paymentTestMode` flag (+ test & live Razorpay key fields) lives in `config/platform` and is
   editable from **admin Settings**. All client + function code reads this flag and behaves
   accordingly — **test mode** (Razorpay test keys / mock, relaxed demo writes on Spark) vs
   **live mode** (real keys, server-trusted, Blaze). We develop and ship on Spark in test mode
   now; flipping the switch (after buying Blaze + deploying functions) turns on live payments
   with **no code rewrite**.

---

## The 3 phases

### Phase 1 — Foundation, polish & content tooling  *(free / Spark)*
Quick wins + content management. See [PHASE-1-foundation.md](PHASE-1-foundation.md).
- Admin logout confirmation dialog
- User-app dark mode fix (theme-aware screen refactor — the real bug)
- Home screen shimmer loading
- Favorites (wishlist) end-to-end (user app)
- Image upload (Firebase Storage) for collections / categories / designs
- Media Library (multi-upload, browse, select, replace, delete)
- Delete Storage images on item / cascade delete

### Phase 2 — Revenue core  *(free / Spark, demo-able)*
Cart → checkout (test/mock) → owned designs. See [PHASE-2-revenue-core.md](PHASE-2-revenue-core.md).
- Cart (add/remove, cart screen, totals from `config/platform`)
- Checkout via **Razorpay Test Mode (client)** or mock; writes `orders` + `purchases` (demo rules)
- "My Purchases / Downloads" screen (user app)
- Admin **Transactions** screen (orders list + detail)
- Admin **Dashboard live counts** (users, designs, pending, orders) via client `count()` queries

### Phase 3 — Production payments & admin analytics  *(Blaze)*
Harden + analytics + payouts. See [PHASE-3-payments-analytics.md](PHASE-3-payments-analytics.md).
- Deploy Cloud Functions: `createRazorpayOrder`, `verifyRazorpayPayment`, `finalizeOrder`,
  `razorpayWebhook`, `initiateRefund`
- Re-lock `orders`/`purchases` rules to function-only; server-trusted prices + invoices
- Admin **Reports** (sales / top designs / new users + CSV export)
- Admin **revenue Dashboard** (charts via `fl_chart`, `statsDaily`)
- Admin **Payouts** (designer earnings + payout requests; Razorpay Payouts)

---

## Cross-cutting rules (every task)
Theme-aware (`Theme.of(context).colorScheme`, dark mode must visibly change), localized
(`AppLocalization.strings`, en_US + hi_IN), design-system components, admin uses
`ResponsiveSnackbar`, every `Text` has `maxLines` + `ellipsis`, errors via `AppLogger.logError`,
clean architecture (entity → model dual-serialization → datasource → repository `Either<Failure,T>`
→ cubit → screen), service locator is the only place backends are swapped.

## Coverage map — every requested item → where it lives

| # | Your instruction | Phase / section |
| --- | --- | --- |
| 1 | Favorites for designs (add + delete) in user app | P1 §1.4 |
| 2 | Dark/light mode toggle not working — analyze + fix | P1 §1.2 (root cause: hardcoded colors) |
| 3 | Admin logout confirmation dialog | P1 §1.1 |
| 4 | Home screen shimmer (replace circular loader, based on real layout) | P1 §1.3 |
| 5 | Image **upload** for collections/categories/designs (not URL-only) | P1 §1.5 |
| 6 | Media **gallery/library**: multi-upload in one shot, select/replace/delete, pick at create/edit | P1 §1.6 |
| 7 | Delete the **image** too when admin deletes a collection/category/design (incl. cascade) | P1 §1.7 |
| 8 | Design detail: **dot indicator** for multiple images | P1 §1.8 |
| 9 | Tap image → **full-screen swipeable** viewer (see all images, zoom) | P1 §1.8 |
| 10 | Buy designs from the **detail screen** and from the **favorites list** (full cart + buy flow) | P2 §2.1–2.2 |
| 11 | Where **purchased designs** are shown in the user app | P2 §2.3 (My Purchases / Downloads) |
| 12 | Where **purchase details** are shown in the admin panel | P2 §2.4 (Transactions + order detail) |
| 13 | How **reports** about purchases are generated | P3 §3.3 (Reports + CSV export) |
| 14 | More **live, working statistics** on the admin dashboard | P2 §2.5 (live counts) + P3 §3.4 (charts) |
| 15 | UI + details for **Payout** menu (admin) | P3 §3.5 |
| 16 | UI + details for **Report** menu (admin) | P3 §3.3 |
| 17 | UI + details for **Transaction** menu (admin) | P2 §2.4 |
| 18 | Platform Fees menu | P3 §3.6 |
| Q1 | Avoid Blaze / zero-cost demo to clients | Decisions §1 + P2 demo strategy (Razorpay Test Mode / mock, temp rules) |
| Q2 | Need image upload + gallery? (yes) | P1 §1.5–1.7 |
| Q3 | Home shimmer | P1 §1.3 |
| — | 3-phase approach for **both** admin + user apps, with steps + checklists | all phase docs |
| — | Final verification checklist | VERIFICATION-CHECKLIST.md |

If anything here is mis-scoped or you want an item moved to a different phase, say so and I'll
adjust before we start.

## Final sign-off
After all phases: run [VERIFICATION-CHECKLIST.md](VERIFICATION-CHECKLIST.md) end-to-end.
