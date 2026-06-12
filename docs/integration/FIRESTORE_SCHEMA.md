# Firestore Schema & Backend Contract — Phase 1

> **This is THE data contract between the Admin app, the User app, and Cloud Functions.**
> Any field added/renamed here must be reflected in: `core/lib/models/*` (shared models),
> `functions/src/config/constants.ts`, `firestore.rules`, and `firestore.indexes.json`.
> Neither app may use a collection/field name that is not defined here.

---

## 1. Global conventions (BINDING)

| Convention | Rule |
|---|---|
| **Money** | `int` paise (INR minor units). `14900` = ₹149.00. Never floats. Razorpay natively uses paise. Format via `core/lib/utils/money.dart`. |
| **Dates** | ISO-8601 UTC strings (`DateTime.now().toUtc().toIso8601String()` / JS `new Date().toISOString()`). Matches existing `UserModel`. Sorts chronologically under `orderBy`. **Exception:** TTL fields (`expireAt`) are native Firestore `Timestamp`s — written only by Cloud Functions, never surfaced in Dart models. |
| **Roles** | `users/{uid}.role` ∈ `'admin' \| 'designer' \| 'user'` is the editable source of truth. The `onUserWrite` function mirrors it into **Firebase Auth custom claims**; security rules check `request.auth.token.role` (free) instead of `get()` (billed read). Clients must refresh ID token after a role change (`getIdToken(true)`). |
| **Function-only collections** | `orders`, `users/*/purchases`, `stats`, `statsDaily`, `adminOtps`, `counters` are written **only by Cloud Functions** (Admin SDK bypasses rules; rules say `allow write: if false`). |
| **Collection names** | From `FirestoreCollections` in `shree_krishna_core` (Dart) and `functions/src/config/constants.ts` (TS mirror). **No string literals in app code.** |
| **Fee formula** | `platformFee = round(subtotal * feePct / 100)`; `gst = round((subtotal + platformFee) * gstPct / 100)`; `total = subtotal + platformFee + gst`. Single Dart source `core/lib/utils/money.dart`, mirrored in `functions/src/utils/money.ts`, kept in sync by shared golden-value tests. Server amounts are always authoritative. |

---

## 2. Collections

### 2.1 `users/{uid}` — exists today; additions marked NEW

| Field | Type | Written by | Notes |
|---|---|---|---|
| email | string | client (auth flows) | existing |
| name | string? | client | existing |
| phoneNumber | string? | client | existing |
| photoUrl | string? | client | existing |
| userId | int? | client | existing |
| loginMethod | string | client | `'email' \| 'google' \| 'phone'` |
| createdAt / loginAt / logoutAt | ISO string | client | existing |
| isActive | bool | admin client | suspend/ban |
| role | string | client at signup (`'user'`/`'designer'` only), admin can change | claims-mirrored by `onUserWrite` |
| **purchaseCount** NEW | int | `finalizeOrder` fn | denorm for admin user list (no N+1) |

Read: owner + admin. Write: owner (rules block changing `role`→elevated, `isActive`, `purchaseCount`), admin (all), functions.

### 2.2 `users/{uid}/purchases/{designId}` — NEW, the purchase index (keystone)

| Field | Type | Notes |
|---|---|---|
| designId | string | = doc id |
| orderId | string | the order that bought it |
| title | string | snapshot at purchase |
| thumbUrl | string | snapshot |
| fileFormat | string | snapshot (`'EMB' \| 'DST' \| 'PES' \| …`) |
| pricePaid | int paise | snapshot |
| purchasedAt | ISO string | |

Written **only** by `finalizeOrder` fn; **deleted by `initiateRefund` fn → revokes download rights.**
Read: owner + admin. Powers: (a) "My Library"/re-download list in 1 query, (b) review gating via
rules `exists()`, (c) `getDesignDownloadUrl` ownership check, (d) "already purchased" badge.

### 2.3 `designs/{designId}` — auto-id

| Field | Type | Written by | Notes |
|---|---|---|---|
| title | string | admin client | |
| titleLower | string | admin client | autocomplete prefix matching |
| keywords | array\<string\> ≤30 | admin client | via `KeywordBuilder` (core): tokenized lowercase title + categoryName + techniques + threadType |
| description | string | admin client | |
| categoryId | string | admin client | |
| categoryName | string | admin client at save; `onCategoryWrite` fn fan-out on rename | denorm |
| techniques | array\<string\> | admin client | values from `DesignTechniques.all` |
| threadType | string | admin client | |
| estimatedTimeMinutes | int | admin client | |
| price | int paise | admin client | rules validate `int > 0` |
| currency | string | admin client | `'INR'` |
| previewUrl | string? | `onDesignAssetUpload` fn | watermarked 1200px public URL |
| thumbUrl | string? | fn | 400px public URL |
| processingStatus | string | fn | `'pending' \| 'ready' \| 'failed'` — publish blocked until `ready` |
| fileStoragePath | string | admin client | private Storage path of EMB/pattern source |
| fileName / fileFormat / fileSizeBytes | string/string/int | admin client | |
| status | string | admin client | `'draft' \| 'active' \| 'archived'` — user app sees ONLY `active` |
| isTrending | bool | admin client | trending picks rail |
| avgRating | double (1dp) | `onReviewWrite` fn | |
| ratingCount / ratingSum | int | fn | |
| salesCount | int | `finalizeOrder` fn | |
| createdAt / updatedAt | ISO string | admin client | |
| createdBy | string uid | admin client | |

Read: user app **must filter `status == 'active'`** in every query (rules enforce); admin reads all.
Write: admin client; functions maintain aggregate fields.

### 2.4 `categories/{categoryId}` — auto-id

| Field | Type | Written by |
|---|---|---|
| name / nameLower | string | admin |
| nameHi | string? | admin (hi_IN display label) |
| iconUrl | string? | admin |
| sortOrder | int | admin |
| status | string `'active' \| 'archived'` | admin (archive, don't delete, once designs exist) |
| designCount | int | `onDesignWrite` fn |
| createdAt / updatedAt | ISO string | admin |

Read: both apps (≤30 docs — fetch once, Hive-cache 24h). Write: admin only.

### 2.5 `orders/{razorpayOrderId}` — **doc id IS the Razorpay order id** (`order_xxx`) → idempotent webhook/verify lookups

| Field | Type | Set by |
|---|---|---|
| userId | string | `createRazorpayOrder` fn |
| buyerName / buyerEmail | string | fn (denorm — admin list needs no joins) |
| items | array\<map\> | fn — **server-side snapshots**: `{designId, title, thumbUrl, price, fileFormat, categoryId, categoryName}` — client prices never trusted |
| itemsSubtotal / platformFee / gstAmount / totalAmount | int paise | fn (formula §1) |
| platformFeePercent / gstPercent | double | fn (frozen snapshot at order time) |
| currency | string `'INR'` | fn |
| status | string | fns only: `'created' → 'paid' \| 'failed'`; `'paid' → 'refund_initiated' → 'refunded'` |
| razorpayPaymentId | string? | `finalizeOrder` |
| invoiceNumber | string? | `finalizeOrder` — `SKE-2026-00042` via transactional `counters/invoices` |
| refund | map? | `{refundId, amount, reason, initiatedBy, initiatedAt, status}` |
| createdAt / paidAt / refundedAt | ISO string | fns |

Read: owner (`where userId == uid`) + admin. Write: **functions only**.

### 2.6 `carts/{uid}` — single doc per user

```
items: array<map> { designId, title, thumbUrl, price, categoryName, addedAt }   // cap 50, digital goods → no quantity
updatedAt: ISO string
```
Read/write: owner. Cleared server-side by `finalizeOrder` (a paid cart can never resurrect).
Rationale: 1 read restores cart on any device; atomic; ~15KB max ≪ 1MiB doc limit.
Client mirrors in Hive (`cart_cache`) for offline render; Firestore authoritative; checkout
re-prices server-side regardless.

### 2.7 `wishlists/{uid}` — single doc per user

```
items: array<map> { designId, title, thumbUrl, price, avgRating, addedAt }      // cap 100 client-side
updatedAt: ISO string
```
Read/write: owner. One read renders the wishlist screen AND powers filled-heart state app-wide.

### 2.8 `designs/{designId}/reviews/{uid}` — **doc id = reviewer uid** → one review per user per design, natural upsert

| Field | Type |
|---|---|
| userId / userName / userPhotoUrl | string (denorm) |
| rating | int 1–5 (rules validate) |
| comment | string ≤1000 (rules validate) |
| orderId | string |
| createdAt / updatedAt | ISO string |

Read: public. Create/update: owner **only if** `exists(users/{uid}/purchases/{designId})` (post-purchase gate in rules). Delete: owner or admin. Aggregates by `onReviewWrite` fn.

### 2.9 `config/platform` — fixed doc id

| Field | Type |
|---|---|
| platformFeePercent | double (0–100, rules validate) |
| gstPercent | double (0–100) |
| razorpayKeyId | string — **publishable** test key (safe client-side; rotatable without app release) |
| supportEmail | string |
| invoicePrefix | string `'SKE'` |
| sellerName / sellerAddress / sellerGstin | string (invoice PDF header) |
| updatedAt / updatedBy | ISO string / uid |

Read: any authed user (Hive-cache 6h). Write: admin.

### 2.10 `config/homeFeed` — fixed doc id; banners live HERE (single doc = 1 read per home open)

```
banners: array<map> { id, imageUrl, title, targetType: 'design'|'category'|'none', targetId, sortOrder, isActive }   // ≤10 enforced in admin UI
updatedAt, updatedBy
```
Read: authed (Hive-cache 30m). Write: admin.

### 2.11 `stats/global` — fixed doc id (cheap admin KPIs)

`totalUsers, totalDesigners, totalDesigns, totalOrders, totalRevenue (paise), totalPlatformFees (paise), pendingRefunds, updatedAt` — maintained by fns via `FieldValue.increment`. Read: admin. Write: fns only.

### 2.12 `statsDaily/{yyyy-MM-dd}` — date-keyed doc ids

`date, newUsers, ordersPaid, revenue, platformFees, gst, refundsCount, refundsAmount` — fns upsert with increments. Today/7d/30d KPIs = ≤31 reads, Hive-cached 5 min. Read: admin. Write: fns only.

### 2.13 `activity/{autoId}` — admin recent-activity feed

| Field | Type |
|---|---|
| type | string — `'user_signup' \| 'order_paid' \| 'design_created' \| 'design_updated' \| 'category_created' \| 'refund_initiated' \| 'refund_completed'` |
| message | string (pre-rendered EN) |
| refId / actorId / actorName | string |
| metadata | map |
| createdAt | ISO string |
| expireAt | **Timestamp** = createdAt + 30d (Firestore TTL policy auto-prunes free) |

Writers: functions (order/user/refund events) + admin client (design/category CRUD — same `WriteBatch` as the op). Read: admin, `orderBy createdAt desc limit 20`.

### 2.14 `adminOtps/{uid}` — doc id = admin uid (one live OTP, self-overwriting)

`otpHash (sha256(otp + uid + OTP_PEPPER)), attempts (int), verified (bool), createdAt (ISO), expireAt (Timestamp +10min, TTL)` — Read/write: **nobody** (functions only).

### 2.15 `counters/invoices`

`{ seq: int, year: int }` — transactional increment inside `finalizeOrder`; seq resets on year roll. Functions only.

---

## 3. Firebase Storage layout

```
designs/{designId}/source/{fileName}      PRIVATE  — EMB/DST source. Admin write ≤50MB. NO client read ever.
                                                     Delivered only via 15-min signed URL from getDesignDownloadUrl fn.
designs/{designId}/original/{img}         PRIVATE  — pristine un-watermarked image. Admin write/read only.
designs/{designId}/public/preview.jpg     PUBLIC   — watermarked 1200px. Written by fn (Admin SDK) only.
designs/{designId}/public/thumb.jpg       PUBLIC   — 400px thumb. Written by fn only.
banners/{bannerId}.jpg                    PUBLIC   — admin write ≤2MB image/*.
users/{uid}/profile.jpg                   PUBLIC read — owner write ≤5MB image/*.
```

Functions attach `firebaseStorageDownloadTokens` and write resulting `https://` URLs into the design
doc — clients never call `getDownloadURL()` (saves a round trip). Path builders: `StoragePaths` in core.

---

## 4. Cloud Functions catalog

TypeScript, Node 20, firebase-functions v2, region **`asia-south1`**.
Secrets (`defineSecret`): `RAZORPAY_KEY_ID`, `RAZORPAY_KEY_SECRET`, `RAZORPAY_WEBHOOK_SECRET`, `SMTP_USER`, `SMTP_PASS`, `OTP_PEPPER`.

### Callables (apps call via `cloud_functions` plugin)

| Function | Input → Output | Behavior |
|---|---|---|
| `createRazorpayOrder` | `{items: [{designId}]}` → `{orderId, amount, currency, keyId, breakdown:{itemsSubtotal, platformFee, gstAmount, totalAmount}, items:[snapshots]}` | Auth required. Re-reads each design (`active` + `ready`), reads `config/platform`, computes amounts (formula §1), `razorpay.orders.create`, writes `orders/{rzpOrderId}` status `created`. Client renders the RETURNED breakdown (authoritative), then opens Razorpay SDK. |
| `verifyRazorpayPayment` | `{razorpayOrderId, razorpayPaymentId, razorpaySignature}` → `{success, invoiceNumber, purchasedDesignIds}` | HMAC-SHA256(`orderId\|paymentId`, KEY_SECRET) → shared `finalizeOrder()` (below). |
| `getDesignDownloadUrl` | `{designId}` → `{url, fileName, fileFormat, expiresAt}` | Auth required. 1 read: `users/{uid}/purchases/{designId}` exists → 15-min signed URL on `fileStoragePath`. Else `permission-denied`. (Needs Token Creator role on runtime SA.) |
| `requestAdminOtp` | `{}` → `{sent, expiresInSeconds}` | Requires `token.role=='admin'`. 60s resend cooldown. 6-digit code → hashed → `adminOtps/{uid}` (+10min TTL). Email via nodemailer + Gmail SMTP app password. |
| `verifyAdminOtp` | `{otp}` → `{verified}` | Hash compare, `attempts < 5` (incremented on fail), not expired → `verified: true` + activity log. Enforcement is app-level in Phase 1 (AdminAuthBloc blocks dashboard until verified; re-required per login). |
| `initiateRefund` | `{orderId, reason}` → `{refundId, status}` | Admin claim required. Order must be `paid`. Full-order `razorpay.payments.refund` → status `refund_initiated`, `refund` map, **delete the order's `purchases/` docs (revokes downloads)**, `stats.pendingRefunds++`, activity. Completion via webhook. |

### HTTP

| Function | Behavior |
|---|---|
| `razorpayWebhook` | Raw-body HTTP; verifies `X-Razorpay-Signature` (WEBHOOK_SECRET). `payment.captured` → same `finalizeOrder()` (safety net if client dies mid-flow; idempotent by status transition). `refund.processed` → order `refunded` + `refundedAt`, `pendingRefunds--`, `statsDaily.refunds*`, activity `refund_completed`. |

### `finalizeOrder()` — shared idempotent core (called by verify callable AND webhook)

1. **Transaction:** order `created → paid` (exit cleanly if already `paid`), set `razorpayPaymentId`, `paidAt`, mint `invoiceNumber` from `counters/invoices`.
2. **Batch:** create `users/{uid}/purchases/{designId}` per item • `salesCount++` per design • `users.purchaseCount++` • `stats/global` + `statsDaily/{today}` increments (`ordersPaid, revenue, platformFees, gst`) • delete `carts/{uid}` • activity `order_paid`.

### Firestore triggers

| Function | Trigger | Behavior |
|---|---|---|
| `onUserWrite` | `users/{uid}` written | role changed/created → `setCustomUserClaims(uid, {role})`; on create → `stats.totalUsers++` (+`totalDesigners` if designer), `statsDaily.newUsers++`, activity `user_signup`. |
| `onReviewWrite` | `designs/{id}/reviews/{uid}` written | Delta math (create `+r/+1`, update `+(new−old)/+0`, delete `−r/−1`) → `ratingSum/ratingCount`, `avgRating = round(sum/count, 1)`. |
| `onDesignWrite` | `designs/{id}` written | Maintains `categories.designCount` (create/delete/category-move/status-change aware), `stats.totalDesigns`, activity `design_created`. |
| `onCategoryWrite` | `categories/{id}` written | If `name` changed → paged batched update (500/batch) of `designs where categoryId == id` → `categoryName`. |

### Storage trigger

| Function | Trigger | Behavior |
|---|---|---|
| `onDesignAssetUpload` | object finalized matching `designs/{id}/original/*` (memory 1GiB) | sharp: tiled diagonal semi-transparent "Shree Krishna Embroidery" watermark → `public/preview.jpg` (1200px); plain resize → `public/thumb.jpg` (400px); attach tokens; update design `{previewUrl, thumbUrl, processingStatus: 'ready' | 'failed'}`. Admin UI blocks publish until `ready`. |

---

## 5. Security rules sketch (`firestore.rules`)

```
match /databases/{db}/documents {
  function isAuthed()   { return request.auth != null; }
  function isAdmin()    { return isAuthed() && request.auth.token.role == 'admin'; }
  function isOwner(uid) { return isAuthed() && request.auth.uid == uid; }

  match /users/{uid} {
    allow read: if isOwner(uid) || isAdmin();
    allow create: if isOwner(uid) && request.resource.data.role in ['user', 'designer'];  // no self-promote to admin
    allow update: if isAdmin() ||
      (isOwner(uid) && !request.resource.data.diff(resource.data)
         .affectedKeys().hasAny(['role', 'isActive', 'purchaseCount']));
    allow delete: if isAdmin();
    match /purchases/{designId} { allow read: if isOwner(uid) || isAdmin(); allow write: if false; }
  }

  match /designs/{id} {
    allow get, list: if isAdmin() || resource.data.status == 'active';   // user queries MUST filter status=='active'
    allow write: if isAdmin()
      && request.resource.data.price is int && request.resource.data.price > 0
      && request.resource.data.title.size() > 0;
    match /reviews/{reviewerUid} {
      allow read: if true;
      allow create, update: if isOwner(reviewerUid)
        && exists(/databases/$(db)/documents/users/$(reviewerUid)/purchases/$(id))
        && request.resource.data.rating is int
        && request.resource.data.rating >= 1 && request.resource.data.rating <= 5
        && request.resource.data.comment.size() <= 1000;
      allow delete: if isOwner(reviewerUid) || isAdmin();
    }
  }

  match /categories/{id} { allow read: if isAuthed(); allow write: if isAdmin(); }
  match /carts/{uid}     { allow read, write: if isOwner(uid); }
  match /wishlists/{uid} { allow read, write: if isOwner(uid); }

  match /orders/{id} {
    allow read: if isAdmin() || (isAuthed() && resource.data.userId == request.auth.uid);
    allow write: if false;   // functions only
  }

  match /config/{doc}     { allow read: if isAuthed(); allow write: if isAdmin(); }  // platform doc adds 0–100 pct validation
  match /stats/{doc}      { allow read: if isAdmin(); allow write: if false; }
  match /statsDaily/{doc} { allow read: if isAdmin(); allow write: if false; }
  match /activity/{id}    { allow read, create: if isAdmin(); allow update, delete: if false; }
  match /adminOtps/{uid}  { allow read, write: if false; }
  match /counters/{doc}   { allow read, write: if false; }
}
```

**Storage rules:** `designs/**/source/**` + `**/original/**` → no client read (admin write, size/type
validated); `**/public/**` + `banners/**` → public read, client write false; `users/{uid}/**` →
public read, owner write `image/*` ≤5MB. Admin check via the same custom claim.

**Claims migration:** one-off `functions/scripts/backfillClaims.ts` stamps claims for existing users;
admin app calls `getIdToken(true)` post-login.

---

## 6. Composite indexes (`firestore.indexes.json`)

**designs:**
1. `status ASC, createdAt DESC` — new arrivals
2. `status ASC, categoryId ASC, createdAt DESC` — category browse
3. `status ASC, price ASC` — price sort
4. `status ASC, categoryId ASC, price ASC`
5. `status ASC, avgRating DESC` — rating sort/filter
6. `status ASC, categoryId ASC, avgRating DESC`
7. `status ASC, isTrending ASC, createdAt DESC` — trending rail
8. `keywords ARRAY_CONTAINS, status ASC, createdAt DESC` — keyword search
9. `keywords ARRAY_CONTAINS, status ASC, price ASC`
10. `status ASC, titleLower ASC` — autocomplete prefix
11. `techniques ARRAY_CONTAINS, status ASC, price ASC` — technique filter

**orders:** 12. `userId ASC, createdAt DESC` (My Orders) 13. `status ASC, createdAt DESC` (admin filters; date range rides the same index)
**users:** 14. `role ASC, createdAt DESC` (admin role filter + paginated user list)

Add further combos only when the console error link demands them.

---

## 7. Search strategy (Firestore-native, Phase 1)

- **Autocomplete** (min 2 chars, 300ms debounce): `where status=='active'` + `orderBy titleLower` + `startAt(q).endAt(q + '')` + `limit(8)`.
- **Search execution:** tokenize query; first meaningful token → `where keywords arrayContains token` + `status=='active'` + `orderBy <sort>` + `limit(20)`; remaining tokens refine client-side on the page.
- **Filters:** category `categoryId ==`; price `orderBy price` (+range); rating `avgRating >=` + `orderBy avgRating desc`; technique `arrayContains` on `techniques`.
- **Hard limits (enforced in UI):** one `array-contains` per query → **text search and technique filter are mutually exclusive**; prefix-only matching, no typo tolerance.
- **`KeywordBuilder`** (pure Dart, core) builds `keywords` so admin writes and future backfills agree.
- **Algolia trigger point:** catalog >2–3k designs or fuzzy search demanded → new `SearchDataSource` impl behind the same repository interface; zero domain/UI change.

---

## 8. End-to-end flows

### Purchase
```
Cart screen (carts/{uid}, Hive-mirrored)
 → Checkout: preview breakdown from cached config/platform
 → callable createRazorpayOrder({items})
      fn: validate designs (active+ready, authoritative prices) → compute amounts
          → razorpay.orders.create → write orders/{order_xxx} 'created'
      ← {orderId, amount, keyId, breakdown}
 → render AUTHORITATIVE breakdown → open Razorpay SDK (keyId, orderId)
 → Razorpay returns {paymentId, signature}        [cancel/fail → order stays 'created']
 → callable verifyRazorpayPayment(...)
      fn: HMAC verify → finalizeOrder() (txn + batch, idempotent)
      ← {success, invoiceNumber, purchasedDesignIds}
 [parallel safety net: webhook payment.captured → same finalizeOrder()]
 → success screen → callable getDesignDownloadUrl({designId})
      fn: purchases doc exists → 15-min signed URL
 → download EMB file • My Orders = orders where userId==uid • invoice PDF generated client-side
```

### Admin design publish
```
Design form → new doc ref id
 → upload EMB → designs/{id}/source/{fileName}        (private)
 → upload image(s) → designs/{id}/original/{img}      (private)
 → batch write: designs/{id} {…, status:'draft', processingStatus:'pending',
                titleLower, keywords} + activity('design_created')
 Storage trigger onDesignAssetUpload:
    sharp → public/preview.jpg (watermarked) + public/thumb.jpg → design {previewUrl, thumbUrl, 'ready'}
 Firestore trigger onDesignWrite: categories.designCount++ • stats.totalDesigns++
 Admin sees 'ready' → sets status:'active' → instantly visible to user-app queries
```

### Refund
```
Admin transaction detail → callable initiateRefund(orderId, reason)
 fn: razorpay refund → order 'refund_initiated' + refund map
     delete users/{uid}/purchases/{designId} ×N   ← download revoked immediately
     stats.pendingRefunds++ • activity('refund_initiated')
 webhook refund.processed → order 'refunded' • pendingRefunds-- • statsDaily.refunds* • activity('refund_completed')
```

---

## 9. `functions/` project structure (repo root)

```
firebase.json  .firebaserc  firestore.rules  firestore.indexes.json  storage.rules
functions/
  package.json (node 20)  tsconfig.json  .eslintrc.cjs
  src/
    index.ts                          # export-only manifest
    config/constants.ts               # MUST mirror core FirestoreCollections (comment links the Dart file)
    config/secrets.ts                 # defineSecret declarations
    payments/createRazorpayOrder.ts   payments/verifyPayment.ts
    payments/finalizeOrder.ts         # shared idempotent core
    payments/webhook.ts               payments/refund.ts
    downloads/getDesignDownloadUrl.ts
    media/onDesignAssetUpload.ts      # sharp pipeline, memory: '1GiB'
    aggregates/onReviewWrite.ts  onDesignWrite.ts  onCategoryWrite.ts  onUserWrite.ts  stats.ts
    adminAuth/requestAdminOtp.ts  adminAuth/verifyAdminOtp.ts
    email/mailer.ts                   # nodemailer Gmail-SMTP transport
    utils/dates.ts  utils/money.ts  utils/activity.ts
  scripts/backfillClaims.ts  scripts/seed.ts
```

---

## 10. Prerequisites checklist (console/client config)

1. Firebase **Blaze** upgrade (functions + outbound Razorpay/SMTP calls).
2. `firebase init` at repo root (functions TS, firestore rules+indexes, storage rules).
3. Razorpay TEST account: `key_id` → `config/platform`; `key_secret` + webhook secret → `firebase functions:secrets:set`; webhook URL registered for `payment.captured`, `refund.processed`.
4. Gmail app password (or Brevo free tier) → `SMTP_USER`/`SMTP_PASS`; random `OTP_PEPPER`.
5. **Service Account Token Creator** role on the functions runtime SA (signed URLs).
6. Firestore **TTL policies** on `adminOtps.expireAt` and `activity.expireAt`.
7. Run `scripts/seed.ts` (config docs, stats/global, counters) and `scripts/backfillClaims.ts` (first admin claim).
8. Deploy `firestore.rules`, `firestore.indexes.json`, `storage.rules` BEFORE feature work lands.

---

## 11. Migration-readiness (per CLAUDE.md)

- Backend knowledge confined to datasource impls (swapped in `service_locator.dart`), rules, functions. Domain/presentation untouched on migration.
- Dual serialization everywhere; ISO dates + int paise map 1:1 to Postgres `timestamptz`/`integer`.
- Callables → Express `POST /api/...` 1:1; HMAC + finalizeOrder logic is plain Node, portable verbatim. Triggers → Postgres triggers/service calls; per-field denorm ownership documented above survives the move.
- No realtime listeners in the contract (pull-to-refresh + Hive TTL) → no Firestore-only UX behavior.
- `FirestoreCollections` strings become table names; doc-id conventions (cart=uid, review=uid, order=rzp id) become natural/composite PKs.
