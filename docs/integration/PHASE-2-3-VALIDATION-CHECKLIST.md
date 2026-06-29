# Phase 2 + Phase 3 — Validation Checklist

**Scope:** cart → checkout → owned designs (user app), admin transactions / live dashboard / reports / payouts / platform fees / payment-mode toggle, and the production Razorpay Cloud Functions. Covers **both** the **Test mode** path (client-side demo checkout, works on Spark or Blaze) and the **Live/Production** path (server-trusted Razorpay via Cloud Functions, Blaze).

> **Money unit (resolved):** all catalog/cart/order/stats amounts are **integer rupees** (matching what the admin design dialog stores and both apps display as `₹$amount`). Only the Razorpay API boundary uses **paise** — the Cloud Functions multiply ×100 when creating a Razorpay order and when refunding; everything stored in Firestore stays in rupees. The functions read the **real**design fields (`name`, `images[]`, `finalPrice`, `status: active`, `isFree`) — not the older documented `title`/`thumbUrl`/`processingStatus`/paise schema.

## Build status (this delivery)

- [x] `functions` — `npm run build` (tsc) clean; money tests pass.

- [x] `shree_krishna_emb_admin` — `flutter analyze lib` → **No issues found**.

- [x] `shree_krishna_emb_user_app` — `flutter analyze lib` → 0 issues in any Phase-2/3 file (pre-existing lint in untouched auth/walkthrough/theme files remains).

- [x] `design_system` — unchanged (1 pre-existing unused-import).

---

## 0. One-time setup

### 0.1 Deploy rules

- [x] `firebase deploy --only firestore:rules,storage` — ships the Phase-2/3 rule changes (client order/purchase writes gated on `config/platform.paymentTestMode == true`; Live mode is function-only) and the `design_files/` rules from the earlier round.

- [x] (web images) `gsutil cors set storage.cors.json gs://shree-krishna-emb.firebasestorage.app`

### 0.2 Seed `config/platform` (admin)

- [ ] Open **Admin → Settings → Payments**. Set **Platform fee %** (e.g. 12) and **GST %** (e.g. 18).

- [ ] Set **Payment mode = Test**. Paste the **Razorpay Test key id** (`rzp_test_…`) if you want the real Razorpay test sheet; leave blank to use the zero-dependency **mock** checkout.

- [ ] Save → confirms a `config/platform` doc exists with `paymentTestMode: true`, `platformFeePercent`, `gstPercent`, `razorpayKeyIdTest`.

### 0.3 Deploy Cloud Functions (Blaze — required for Live mode + stats/refunds)

- [ ] `cd functions && npm install && npm run build` → compiles clean (no `tsc` errors).

- [ ] Set secrets (see `functions/RAZORPAY_SETUP.md`): `firebase functions:secrets:set RAZORPAY_KEY_SECRET_TESTfirebase functions:secrets:set RAZORPAY_KEY_SECRET_LIVEfirebase functions:secrets:set RAZORPAY_WEBHOOK_SECRET`

- [ ] `firebase deploy --only functions (region asia-south1)`.

- [ ] In the **Razorpay dashboard**, set the webhook URL to the deployed `razorpayWebhook` URL and subscribe to `payment.captured`, `order.paid`, `payment.failed`.

> Test mode works WITHOUT deploying functions (client-side demo writes). Live mode and refunds/stats REQUIRE the functions deployed.

---

## 1. User app — Cart (Phase 2.1)

- [x] On a design detail screen (paid design), an **Add to Cart** CTA appears.

- [x] Tapping adds it; the CTA flips to **In Cart / Go to Cart**; the **cart badge** in the app bar increments.

- [x] Open **Cart**: items listed (thumb, title, ₹ price), each removable; empty state shows when cleared.

- [x] Totals show **Subtotal**, **Platform fee (x%)**, **GST (x%)**, **Total** — and the percentages match what admin set in `config/platform`.

- [x] Cart **persists** across app restart (reads `carts/{uid}`).

- [x] Max 50 items enforced; adding a duplicate doesn't double-add.

- [x] Dark mode + light mode both render correctly; long titles ellipsize (no overflow).

## 2. User app — Checkout (Phase 2.2) — TEST mode

- [x] From Cart → **Proceed to Checkout**: order summary shows items + fee + GST + total.

- [ ] **Mock path** (no Razorpay key set): "Pay" simulates success after a moment.

- [ ] **Razorpay Test path** (test key set): the Razorpay **test** sheet opens; pay with a Razorpay **test card** (e.g. `4111 1111 1111 1111`, any future expiry/CVV) → success.

- [ ] On success: an `orders/demo_<ts>` doc is written (status `paid`), a `users/{uid}/purchases/{designId}` doc per item is written, and the **cart is cleared**.

- [ ] Cancel/failure → friendly message, **cart kept** (no order/purchase written).

- [ ] Land on success / **My Purchases**.

## 3. User app — My Purchases & ownership (Phase 2.3)

- [x] **My Purchases** (from Account/Profile): lists owned designs (thumb, title, format, date); empty state before any purchase.

- [x] Tapping an owned design → detail screen in **owned** state: **Add to Cart is hidden**, the **Design Files Download** section is enabled, and files download (opens the Storage URL).

- [x] A **free** design shows **Get for free** → grants ownership (a ₹0 order + purchase) → becomes downloadable. *(Test mode: client-side. Live mode: see §8 note.)*

- [ ] Re-opening a purchased design still shows owned state (reads `users/{uid}/purchases`).

## 4. Admin — Transactions (Phase 2.4)

- [x] Sidebar **Transactions** now opens a real screen (no longer the dashboard).

- [x] The demo/test orders from §2 appear: order id, buyer, item count, **₹ total**, status chip, date.

- [x] **Filters** work: by status, by date range, search by buyer/order id; **per-page** selector + pagination behave like the catalog lists.

- [ ] **Order detail** dialog: line items, fee/GST breakdown, payment id, invoice number, timeline.

- [ ] **Refund** button shows on `paid` orders → calls `initiateRefund` (Live/Blaze) → order becomes `refunded` and the buyer's purchase doc is deleted (download revoked). *(Requires functions.)*

- [ ] Theme-aware, localized (EN/HI), responsive, ResponsiveSnackbar feedback.

## 5. Admin — Live Dashboard counts (Phase 2.5)

- [x] Dashboard KPI cards show **live** numbers (total users, designers, designs total/active/pending, total orders, orders today, revenue) — **no hardcoded** `2,450` **/** `$45,320` **/** `856`.

- [ ] Revenue chart (fl_chart) renders a real per-day revenue trend (from orders/`statsDaily`).

- [ ] Numbers change as data changes (create a design / place a demo order → counts update on refresh).

- [ ] Loading shows shimmer; error shows retry; "—" when no data yet.

## 6. Admin — Reports + CSV (Phase 3.3)

- [ ] Sidebar **Reports** opens; pick a **date range**.

- [ ] Cards: total sales ₹, orders count, **AOV**, top designs, top categories, new users.

- [ ] **Export CSV** downloads a file (sales summary + line items) honoring the date filter.

- [ ] Numbers reconcile with the Dashboard for the same period.

## 7. Admin — Payouts + Platform Fees (Phase 3.5 / 3.6)

- [ ] **Payouts** opens: per-designer **earnings owed** (paid orders → design `authorId` → sale − platform-fee share), with totals. *(Interim read-only until wallet/payout functions land.)*

- [ ] **Platform Fees** opens: edit fee % + GST % (0–100 validated) → saved to `config/platform` → **changing it updates cart/checkout totals app-wide** (re-check §1 totals).

## 8. Admin — Payment mode toggle (Phase 3.0) + Live production flow (Phase 3.1/3.2)

### 8.1 Toggle

- [ ] Admin → Settings → Payments: **Test ↔ Live** toggle; switching to **Live** shows a clear warning.

- [ ] Test/Live **Razorpay key id** fields persist to `config/platform`(`razorpayKeyIdTest` / `razorpayKeyIdLive`, `paymentTestMode`).

### 8.2 Live (server-trusted) checkout — Blaze

- [ ] Set **Payment mode = Live**, fill the **live key id**, ensure secrets are set and functions deployed.

- [ ] User checkout now calls `createRazorpayOrder` (re-reads design prices server-side, computes fee+GST from `config/platform`, creates a Razorpay order, writes `orders/{razorpayOrderId}`status `created`).

- [ ] Razorpay sheet opens with the server order id → pay with a **live/test card** per your Razorpay mode → app calls `verifyRazorpayPayment` → function verifies the signature and **finalizes**: order → `paid`, **invoice minted** (`SKE-YYYY-#####`), `users/{uid}/purchases/*` written, `carts/{uid}` cleared.

- [ ] The **webhook** (`razorpayWebhook`) independently reconciles the same payment (idempotent — no duplicate purchases/invoices).

- [ ] In Live mode, a **direct client write** to `orders` / `purchases` is **denied** by rules (only functions can write) — verify in the Firestore rules simulator or by attempting a write.

- [ ] Admin **Refund** (`initiateRefund`) on a paid Live order → Razorpay refund succeeds, order → `refunded`, purchase doc deleted (download revoked in the user app).

> **Free designs in Live mode:** the "Get for free" client grant is gated to Test mode by rules. In Live mode a free claim needs a small `claimFreeDesign` callable (noted as a follow-up; paid flow is fully covered).

---

## 9. Cross-cutting quality gates

- [ ] `flutter analyze lib` clean in `shree_krishna_emb_user_app`, `shree_krishna_emb_admin`, `design_system` (pre-existing lint in untouched auth/walkthrough/theme files excepted).

- [ ] `cd functions && npm run build` clean.

- [ ] Dark mode verified on every new user-app + admin screen.

- [ ] All new strings localized (EN + HI); every `Text` has `maxLines` + `ellipsis`.

- [ ] Admin uses `ResponsiveSnackbar`; user app uses `AppSnackbar`.

- [ ] DEMO rule relaxations are clearly tagged and auto-disable in Live mode (`paymentTestMode()`).

---

## 10. Known seams / follow-ups (by design)

- Test-mode checkout writes orders/purchases **client-side**; Live mode routes everything through Cloud Functions. The same UI/blocs serve both — only the `CheckoutService` impl swaps.
- Payouts is **read-only earnings owed** for now; the full designer wallet + `requestPayout`/ `processPayout` + Razorpay Payouts is a later phase.
- Stats (`stats/global`, `statsDaily/{date}`) are maintained by the order-write trigger; until the function is deployed, the admin dashboard/reports client-aggregate from `orders` as a fallback.