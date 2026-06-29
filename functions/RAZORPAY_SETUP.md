# Razorpay Payments — Deploy & Operations (Phase 3)

Region: **asia-south1**. firebase-functions **v2**. Node 20. Money is **int paise** everywhere
(designs.price, order amounts, Razorpay amounts) — no ×100 conversion; Razorpay uses paise natively.

## 1. Secrets (firebase-functions v2 `defineSecret`)

The key **secrets** are stored in Cloud Secret Manager (never in Firestore). Test vs Live is chosen
at runtime from `config/platform.paymentTestMode`.

```bash
# Razorpay key secrets — one per mode (recommended)
firebase functions:secrets:set RAZORPAY_KEY_SECRET_TEST
firebase functions:secrets:set RAZORPAY_KEY_SECRET_LIVE
# Webhook secret (the value you set when creating the webhook in Razorpay dashboard)
firebase functions:secrets:set RAZORPAY_WEBHOOK_SECRET

# Optional legacy fallback (used only if a mode-specific secret is unset)
firebase functions:secrets:set RAZORPAY_KEY_SECRET
```

## 2. Firestore config (`config/platform` — admin-write, authed-read)

The publishable **key IDs** (safe client-side) and the mode flag live in Firestore:

```jsonc
{
  "platformFeePercent": 12,        // double
  "gstPercent": 18,                // double
  "paymentTestMode": true,         // true → TEST keys, false → LIVE keys
  "razorpayKeyIdTest": "rzp_test_xxxxxxxx",
  "razorpayKeyIdLive": "rzp_live_xxxxxxxx",
  "invoicePrefix": "SKE"
  // ...other platform fields
}
```

(Legacy single `razorpayKeyId` is still honored as a fallback for either mode.)

## 3. Webhook registration (Razorpay Dashboard → Settings → Webhooks)

After deploy, the webhook URL is:

```
https://asia-south1-<PROJECT_ID>.cloudfunctions.net/razorpayWebhook
```

- Set the **webhook secret** to the same value you stored in `RAZORPAY_WEBHOOK_SECRET`.
- Subscribe to events: `payment.captured`, `order.paid`, `payment.failed`, `refund.processed`.
- The webhook verifies `X-Razorpay-Signature` over the raw body and is the idempotent source of truth.

## 4. Deploy (do NOT auto-deploy in CI without review)

```bash
cd functions
npm install
npm run build              # tsc → lib/
firebase deploy --only functions
# or target specific functions:
firebase deploy --only functions:createRazorpayOrder,functions:verifyRazorpayPayment,functions:razorpayWebhook,functions:initiateRefund,functions:onOrderWrite
```

## 5. Function contracts

| Function | Type | Auth | Input → Output |
|---|---|---|---|
| `createRazorpayOrder` | onCall | user | `{}` (reads server cart) → `{razorpayOrderId, amount(paise), currency:'INR', keyId, orderDocId, breakdown, items}` |
| `verifyRazorpayPayment` | onCall | user | `{razorpay_order_id, razorpay_payment_id, razorpay_signature}` → `{success:true, invoiceNumber, purchasedDesignIds}` |
| `razorpayWebhook` | onRequest | — (HMAC) | Razorpay event → 200 |
| `initiateRefund` | onCall | **admin** | `{orderId, reason}` → `{success:true, refundId, status:'refund_initiated'}` |
| `onOrderWrite` | trigger | — | `orders/{orderId}` written → maintains `stats/global` + `statsDaily/{yyyy-MM-dd}` |

## 6. Stats ownership (no double-counting)

`stats/global` and `statsDaily/*` order metrics are owned **only** by the `onOrderWrite` trigger,
keyed off status transitions (`created→paid`, `paid→refund_initiated`, `refund_initiated→refunded`).
`finalizeOrder` / `initiateRefund` / the webhook only flip status + write purchases/cart/activity.
