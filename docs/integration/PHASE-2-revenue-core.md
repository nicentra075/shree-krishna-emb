# Phase 2 — Revenue core (cart → buy → owned designs)

**Runs on:** Firebase Spark (free). **Fully demo-able with no cost.**
**Goal:** A user can add designs to a cart, "pay" (Razorpay **Test Mode** or mock), and see
purchased designs; admin can see those orders.

> Payment here is **test/demo only**. Real money, server-trusted prices, invoices and refunds
> arrive in Phase 3. Keep all Phase-3 seams in place (don't trust client prices in Phase 3).

---

## Demo-mode strategy (answers "no Blaze")

Two interchangeable options behind one `CheckoutService` interface:

- **Option A — Razorpay Test Mode (client-side):** open Razorpay checkout with the **test
  `key_id`** and amount; on the success callback, write the order + purchases client-side.
  No real charge. Realistic UX for demos. Requires `razorpay_flutter` in the user app.
- **Option B — Mock checkout:** a "Pay (demo)" button that simulates success after a delay and
  writes the same records. Zero dependencies; use if Razorpay test keys aren't handy.

Either way, **temporarily relax rules** so the signed-in owner can write their own order &
purchases. Phase 3 reverts this and moves writes to Cloud Functions.

The checkout path is chosen by the **`paymentTestMode` flag** in `config/platform` (admin
Settings toggle — see Phase 3 §3.0), so the same production-ready code runs in test mode now and
live mode later with no rebuild.

- [ ] `firestore.rules`: TEMP allow `orders` create where `request.resource.data.userId ==
      uid && status == 'pending'|'paid'`; allow `users/{uid}/purchases/{designId}` create by
      owner. **Mark clearly with `// PHASE-2 DEMO ONLY — revert in Phase 3`.**

---

## 2.1 Cart  *(user app)*

**Reuse:** `CartModel` + `carts/{uid}` + rules (exist).

- [ ] `CartRepository` + `firebase_cart_datasource.dart` (read/write `carts/{uid}`), cache-first
- [ ] `CartCubit`: `load`, `add(design)`, `remove(designId)`, `clear`, item count; max 50;
      `isClosed` guards
- [ ] **Add to Cart** button on design detail + favorites + card long-press (optional)
- [ ] **Cart screen**: list items, remove, empty state; totals computed from `config/platform`
      (subtotal + platformFee% + GST%); "Proceed to Checkout"
- [ ] Cart badge/count in app bar or bottom nav
- [ ] Route + Profile/nav entry; strings (en_US + hi_IN)

**Acceptance:** Add/remove designs; cart persists; totals reflect platform fee + GST.

---

## 2.2 Checkout  *(user app)*

- [ ] `domain/services/checkout_service.dart` interface: `Future<CheckoutResult> pay(orderDraft)`
- [ ] `RazorpayTestCheckout` (Option A) and `MockCheckout` (Option B) implementations; pick via
      service locator (so Phase 3 swaps in the real server-backed impl with no UI change)
- [ ] Build an **order draft** (items frozen with title/thumb/price/format/category, fee, GST,
      total) — mirrors `OrderModel`
- [ ] On success: write `orders/{orderId}` (id = `demo_<ts>` in Phase 2), write
      `users/{uid}/purchases/{designId}` per item, clear cart
- [ ] Checkout screen: order summary, address/email if needed, Pay button, loading + result
- [ ] Failure handling (cancel / error) → friendly message, cart kept
- [ ] Strings + theme-aware

**Acceptance (demo):** Pay with a Razorpay test card (or mock) → success → order + purchases
written → cart cleared → land on success/My Purchases.

---

## 2.3 My Purchases / Downloads  *(user app)*

- [ ] `PurchasesRepository` + datasource (query `users/{uid}/purchases`), cache-first
- [ ] `PurchasesCubit` (load, refresh)
- [ ] **My Purchases screen**: list/grid of owned designs (thumb, title, format, date),
      tap → design detail in "owned" state with **Download** (high-res from Storage)
- [ ] Design detail reflects ownership: hide "Add to Cart", show "Download" when a purchase
      doc exists for that design
- [ ] Entry from Profile/Account; route; empty state; strings

**Acceptance:** After buying, the design appears in My Purchases and is downloadable; detail
screen shows owned state.

---

## 2.4 Admin Transactions  *(admin)*

**Reuse:** `orders` collection + `OrderModel`.

- [ ] Add `case 'transactions'` to admin `_buildContent()` (currently falls through to dashboard)
- [ ] `OrdersRepository` + `firebase_orders_datasource.dart` (list, filter by status/date,
      search by buyer/order id), in-memory cache + pagination (reuse catalog pagination pattern)
- [ ] `OrdersCubit` (status filter, date range, page, page-size)
- [ ] **Transactions screen**: table/list (order id, buyer, items count, total, status, date),
      `_PaginationBar` + Per-page selector (reuse `CatalogScaffold` patterns)
- [ ] **Order detail** drawer/dialog: items, fee/GST breakdown, payment id, timeline; refund
      action stubbed (enabled in Phase 3)
- [ ] Theme-aware, `ResponsiveSnackbar`, localized, `maxLines`/`ellipsis`

**Acceptance:** Demo orders from 2.2 show up in admin Transactions with working filters and a
detail view.

---

## 2.5 Admin Dashboard — live counts  *(admin)*

**Why:** Replace hardcoded KPIs with real numbers (no functions needed; Firestore `count()`).

- [ ] `DashboardStatsCubit` + datasource using Firestore aggregate `count()`:
      total users, designers, total/active/pending designs, pending approvals, total orders,
      orders today
- [ ] Revenue today / 7-day / total summed from `orders` (bounded query; show "—" until orders exist)
- [ ] Replace hardcoded KPI cards + "Recent activity" with live data (latest users/designs/orders)
- [ ] Loading via shimmer; error + retry; theme-aware
- [ ] (Charts deferred to Phase 3 with `fl_chart`)

**Acceptance:** Dashboard cards show real counts that change as data changes; no fake numbers.

---

## Phase 2 exit criteria
- [ ] User can add to cart, checkout (test/mock), and see owned designs
- [ ] Cart totals use platform fee + GST from `config/platform`
- [ ] Orders + purchases are written and cart is cleared on success
- [ ] Admin Transactions lists orders with filters + detail
- [ ] Dashboard shows live counts (no hardcoded KPIs)
- [ ] DEMO rule relaxations clearly tagged for Phase-3 revert
- [ ] `flutter analyze` clean; dark/light pass
