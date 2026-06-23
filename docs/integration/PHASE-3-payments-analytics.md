# Phase 3 — Production payments & admin analytics

**Runs on:** Firebase **Blaze** (Cloud Functions required).
**Goal:** Replace demo checkout with server-trusted Razorpay, lock the rules back down, and
build the admin analytics suite (Reports, revenue Dashboard, Payouts).

> Prerequisite: upgrade the Firebase project to Blaze and configure Razorpay live/test secrets
> in functions config. No UI/bloc changes are needed in the user app — only the
> `CheckoutService` implementation swaps (see Phase 2, 2.2).

---

## 3.0 Payment Test/Live mode switch  *(admin + shared)*

**Why:** Ship production-ready payment code now, run it in **test mode** on Spark, and flip to
**live** from admin Settings after Blaze — no code change.

- [ ] `config/platform`: add `paymentTestMode` (bool, default true), `razorpayKeyIdTest`,
      `razorpayKeyIdLive` (publishable; secrets stay in functions config, never in Firestore)
- [ ] Admin **Settings**: a "Payment mode" toggle (Test / Live) + key fields; saved to
      `config/platform`; clear warning when switching to Live
- [ ] `CheckoutService` + functions read `paymentTestMode`: choose test vs live keys; in test
      mode allow the Spark demo path, in live mode require verified server flow
- [ ] Phase-2 demo rule relaxations apply **only while `paymentTestMode == true`** where feasible

**Acceptance:** Admin can flip Test↔Live from Settings; the app uses the matching keys/flow with
no rebuild.

## 3.1 Cloud Functions (Razorpay, server-trusted)  *(functions)*

- [ ] `createRazorpayOrder` (callable): re-reads design prices server-side, computes
      subtotal + platformFee + GST from `config/platform`, creates a Razorpay order, writes a
      `pending` `orders/{razorpayOrderId}`
- [ ] `verifyRazorpayPayment` (callable): verifies signature with Razorpay secret
- [ ] `finalizeOrder`: on verified payment → set order `paid`, mint `invoiceNumber`
      (via `counters`), write `users/{uid}/purchases/{designId}`, clear `carts/{uid}`
- [ ] `razorpayWebhook` (HTTPS): idempotent server-source-of-truth for payment events
- [ ] `initiateRefund` (callable, admin): Razorpay refund → set order `refunded`, delete the
      purchase doc(s) (revokes download)
- [ ] Stats aggregation (scheduled or trigger): write `stats` + `statsDaily`
      (orders, revenue, users, designs) for cheap dashboards
- [ ] Deploy: `firebase deploy --only functions`

**Acceptance:** A real (test-card) payment flows create→verify→finalize; invoice minted;
purchase granted; webhook reconciles; admin refund revokes access.

---

## 3.2 Re-lock rules + swap checkout  *(rules + user app)*

- [ ] Revert the **PHASE-2 DEMO** relaxations in `firestore.rules`: `orders` and
      `users/{uid}/purchases/*` become **function-only** (`allow write: if false`)
- [ ] Service locator: bind `CheckoutService` → `ServerRazorpayCheckout` (calls the callables)
- [ ] Remove/disable `MockCheckout`; keep test vs live keys via `config/platform.razorpayKeyId`
- [ ] Add `razorpay_flutter` to user app if using native checkout
- [ ] Regression: cart → checkout → purchase → download still works end-to-end

**Acceptance:** Client can no longer write orders/purchases directly; the whole buy flow works
through functions; prices are server-trusted.

---

## 3.3 Admin Reports  *(admin)*

- [ ] Add `case 'reports'` to `_buildContent()`
- [ ] `ReportsRepository` + cubit over `orders` / `users` / `designs` (date-range)
- [ ] Report cards: total sales, orders count, AOV, top designs, top categories, new users,
      designer earnings; date-range picker
- [ ] **CSV export** (sales + line items) with date filter
- [ ] Theme-aware, localized, responsive

**Acceptance:** Pick a date range → see accurate sales/top lists; export CSV downloads.

---

## 3.4 Admin revenue Dashboard  *(admin)*

- [ ] Add `fl_chart` to admin `pubspec.yaml`
- [ ] Replace the hardcoded custom bar chart with real charts (revenue trend, signups,
      orders/day) sourced from `statsDaily`
- [ ] KPI cards from `stats` (or live counts from Phase 2.5) — revenue, orders, users, pending
- [ ] Real "Recent activity" feed
- [ ] Loading shimmer; error+retry; theme-aware

**Acceptance:** Dashboard shows real revenue trend + KPIs that match Reports.

---

## 3.5 Admin Payouts (designer earnings)  *(admin + functions)*

> Heaviest item — designer wallet/payout system does not exist yet.

- [ ] Data model: `payouts/{payoutId}` + `designerWallets/{uid}` (balance, pending, lifetime);
      rules (designer reads own; admin reads all; writes via functions)
- [ ] Earnings accrual: on `finalizeOrder`, credit the design's `authorId` wallet
      (sale price − platform fee)
- [ ] Admin **Payouts screen**: list payout requests, approve/reject, mark paid; per-designer
      earnings; status pipeline (pending→approved→processing→completed)
- [ ] `requestPayout` (designer) + `processPayout` (admin) functions; optional Razorpay Payouts
- [ ] Add `case 'payouts'` to `_buildContent()`
- [ ] Interim (if deferred): read-only "earnings owed" computed from `orders` by `authorId`

**Acceptance:** A sale credits the designer; admin can see and process a payout request.

---

## 3.6 Platform Fees menu  *(admin)*

- [ ] Surface `config/platform` fee% + GST% config under the Platform Fees menu
      (may already exist in Settings — consolidate)
- [ ] Add `case 'fees'`; validation; saved to `config/platform`

**Acceptance:** Changing fee/GST updates checkout totals app-wide.

---

## Phase 3 exit criteria
- [ ] Real Razorpay flow (create→verify→finalize→webhook) works on Blaze
- [ ] Rules re-locked: client cannot write orders/purchases
- [ ] Invoices minted; refunds revoke access
- [ ] Reports with CSV export; revenue dashboard with charts
- [ ] Payouts (at least read-only earnings) + Platform Fees configurable
- [ ] `flutter analyze` clean; emulator rule tests pass
