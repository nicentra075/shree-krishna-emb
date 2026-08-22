# Workstreams A + B — Combined Test Checklist

**Status:** Both workstreams code-complete. `flutter analyze` clean on user app AND admin app; Cloud Functions compile + 12/12 unit tests pass.
**Date:** 10 July 2026
**Supersedes:** WORKSTREAM_A_TEST_CHECKLIST.md (its content is folded in here).

---

## What was implemented

### Workstream A (security & auth)
| Task | Change |
|---|---|
| A1 | `role` custom-claim pipeline: `onUserRoleWritten` trigger + `refreshRoleClaim` callable (`functions/src/users/syncRoleClaim.ts`); admin app syncs the claim at sign-in/session restore; `storage.rules` catalog writes tightened from any-signed-in-user to admin/designer only |
| A2 | Real forgot-password in the admin panel (both the standalone screen and the login screen's inline panel) with spinner + success/error toasts; unknown emails get the generic success message |
| A3 | Apple Sign-In in the user app via firebase_auth's native `AppleAuthProvider` — **iOS-only button** (your decision); new Apple users go through complete-profile; iOS entitlement wired into all 3 Xcode configs. Bonus: signup screen's dead Google/Phone buttons now work |

### Workstream B (user-app Phase 1 features)
| Task | Change |
|---|---|
| B1 Search + filters | Search icon in the main app bar → new Search screen: debounced search over design name/code/description, filter sheet (sort, category chips, price min/max, free-only), removable active-filter chips, results grid with wishlist hearts + star badges. Index-free (client-side over a capped fetch, consistent with the app's catalog queries) |
| B2 Reviews | Buyers can write/edit/delete a 1–5 star review with comment on any owned design (server-enforced by existing rules); design detail shows average stars + count under the title and a reviews section (top 3 + show all); new `onReviewWritten` Cloud Function maintains `avgRating`/`reviewCount` on the design doc; search cards show a star badge |
| B3 Orders + invoice | My Purchases is now tabbed: **Designs** (unchanged grid) + **Orders** (order history: reference, date, items, total, status chip) → Order detail screen (line items, subtotal/platform fee/GST/total breakdown, payment id) → **Download Invoice** button generating a branded PDF (share/save sheet) for paid orders |
| B4 | Pinch-zoom in the image viewer **unlocks only for owned designs** (D1); Notification Preferences screen (master push switch drives the FCM `all_users` topic + three category toggles persisted to `users/{uid}.notificationPrefs`) wired from the profile row; offline "No internet connection" banner on the main shell; profile About row shows an app-info dialog; dead WhatsApp/Contact/Privacy/Terms rows are hidden until WS-F/E3 give them real targets (no dead taps) |

**New deps:** `pdf`, `printing` (user app — run `cd ios && pod install` before an iOS build).

---

## ⚙️ One-time setup YOU must do before testing (in order)

- [ ] **1. Deploy the new/changed Cloud Functions:**
  ```bash
  cd /Applications/Documents/dev/shree-krishna-emb
  firebase deploy --only functions:onUserRoleWritten,functions:refreshRoleClaim,functions:onReviewWritten
  ```
- [ ] **2. Log OUT and back IN on the admin app** (syncs your admin `role` claim).
- [ ] **3. Review `git diff storage.rules`, then:** `firebase deploy --only storage`
  ⚠️ Order matters: functions first, admin re-login second, storage rules last — otherwise admin uploads fail until the claim exists.
- [ ] **4. (iOS later)** Enable the **Apple** provider in Firebase Console → Authentication → Sign-in method. Full Apple sign-in also needs the real bundle ID from Task E2.
- [ ] **5. User app:** `flutter pub get` (already run) — for iOS builds also `cd ios && pod install`.

---

## ✅ A1 — Storage security

- [ ] Admin app: create/edit a design with an **image upload** → succeeds
- [ ] Admin app: upload an **EMB/DST file** → succeeds
- [ ] Admin app: category/collection image upload + Media Library upload → succeed
- [ ] Reload the admin web app (session restore, no fresh login) → uploads still work
- [ ] Firebase Console → Storage → Rules Playground: simulate a `write` to `designs/test.jpg` as an authenticated token WITHOUT a `role` claim → **DENIED**; with claim `role: admin` → allowed
- [ ] User app still displays all catalog images (public read unchanged)

## ✅ A2 — Admin forgot-password

- [ ] Login screen → forgot password → your real admin email → spinner → success toast → **reset email actually arrives** (check spam); link works; login with the new password
- [ ] Non-existent email → same generic success toast (no account-existence leak)
- [ ] Invalid format ("abc") → error toast; Wi-Fi off → error toast
- [ ] Repeat in Hindi → localized toasts/labels

## ✅ A3 — Apple Sign-In (user app)

- [ ] **Android**: login + signup show ONLY Google + Phone — no Apple button
- [ ] **iOS**: Apple button appears below the social row on login AND signup
- [ ] Signup screen: Google button now actually signs in; a NEW Google/Apple user lands on Complete Profile; Phone button routes to the login OTP flow
- [ ] (After setup step 4 + E2) iOS: Apple sheet → authorize → new user → Complete Profile → Home; relogin goes straight to Home; cancelling shows "cancelled" toast without crashing
- [ ] Firestore user doc for an Apple user: `loginMethod: 'apple'`, `role: 'user'`, sequential `userId`

## ✅ B1 — Search + filters (user app)

- [ ] Search (magnifier) icon appears in the main app bar (left of the cart)
- [ ] Tap → Search screen opens with keyboard up; before typing: "Search designs by name or code" hint
- [ ] Type a design name fragment → results appear after the debounce; result count/order sensible
- [ ] Search by design **code** → matches
- [ ] Nonsense query → "No results" empty state
- [ ] Filter button → sheet: sort options, category chips, min/max price, free-only switch
- [ ] Apply category → chip appears above results; tap ✕ on the chip → filter removed and results refresh
- [ ] Price range 100–500 → only designs in range; free-only → only free designs
- [ ] Sort by Price: Low→High and High→Low → order flips correctly
- [ ] "Clear All" resets everything
- [ ] Filters with EMPTY search text still work (filter-only browsing)
- [ ] Heart icon on a result toggles wishlist; tap card → design detail opens
- [ ] Airplane mode + search → error state with Retry button (no crash/silence)
- [ ] Hindi: all labels on the search screen + filter sheet in Hindi

## ✅ B2 — Reviews (user app)

- [ ] On a design you do NOT own: reviews section shows "No reviews yet · Purchase this design to write a review"; NO Write-a-Review button
- [ ] On a design you OWN: "Write a Review" button appears → sheet with star selector + comment → submit disabled until ≥1 star → submit → success toast → review appears in the list
- [ ] Average stars + "N reviews" appear under the design title (may need a screen re-open — the aggregate is written by the Cloud Function)
- [ ] Edit your review (button now says "Edit Review", stars/text prefilled) → changes persist
- [ ] Delete your review (bin icon on your review) → confirm dialog → deleted toast → aggregate count drops
- [ ] Second account that has NOT bought the design: can SEE reviews, cannot write (and even a forced attempt is rejected by rules)
- [ ] Search results / view-all: designs with reviews show the ⭐ badge with the average
- [ ] Firestore spot-check: design doc has `avgRating` + `reviewCount` matching the reviews subcollection
- [ ] Hindi: review sheet, buttons, toasts localized

## ✅ B3 — Order history + invoice (user app)

- [ ] My Purchases now has two tabs: **Designs** | **Orders**; Designs tab unchanged (grid + suggestions)
- [ ] Orders tab lists your orders newest-first: reference (invoice number), date, item count, item names, total, status chip (Paid = green)
- [ ] No orders (fresh account) → empty state; pull-to-refresh works
- [ ] Tap an order → detail: status, date, payment ID, each item with thumbnail + price, totals card (Subtotal / Platform Fee % / GST % / Total) matching what checkout showed
- [ ] **Download Invoice** on a PAID order → share/save sheet with a PDF: app name header, TAX INVOICE, invoice no., date, buyer name/email, items table, fee/GST breakdown, payment id, digital-goods note
- [ ] Amounts in the PDF match the app (₹ shown as "Rs." in the PDF — font limitation, intentional)
- [ ] Test-mode (demo_*) orders and live orders BOTH show correct amounts (the app normalizes the rupee/paise difference)
- [ ] Unpaid/failed order (if any) → no invoice button
- [ ] Make a fresh purchase → it appears in Orders and in Designs

## ✅ B4 — Zoom, notification prefs, connectivity, profile

- [ ] Image viewer on a design you do NOT own → pinch-zoom does nothing (as before)
- [ ] Image viewer on an OWNED design → pinch-zoom works (up to 5×), swiping between images still works
- [ ] Profile → "Notification Preferences" row opens the new screen (was a dead tap)
- [ ] Toggles load; flipping any → "Preferences saved" toast; kill + reopen app → values persisted
- [ ] Master switch OFF → category toggles grey out; admin broadcast no longer arrives on this device (topic unsubscribed); switch back ON → broadcasts arrive again
- [ ] Airplane mode → yellow "No internet connection" banner at the top of the main shell; disappears when back online
- [ ] Profile → About Us → dialog with app name + version
- [ ] Profile: WhatsApp / Contact / Privacy / Terms rows are GONE (return in WS-E3/F with real targets)
- [ ] Hindi pass over the prefs screen + toasts

## ✅ Regression sweep

- [ ] Home feed, view-all, design detail, cart, checkout, wishlist, notifications bell — all unchanged and working
- [ ] Full purchase flow (test mode) still works end-to-end: cart → checkout → pay → download unlocked
- [ ] Admin app: login, session restore, logout, design CRUD, transactions, broadcast — unchanged
- [ ] User app on a 320px-wide device/emulator: search screen, filter sheet, orders list, order detail, prefs screen — no overflows
- [ ] Dark mode: new screens (search, filter sheet, orders, order detail, prefs, reviews) render correctly

---

## Known deferred items (tracked in the master plan)

- Apple sign-in full-flow verification blocked on Task E2 (real bundle ID) + Firebase console toggle — code is ready; platform gating is testable now.
- Category toggles in notification prefs are persisted but not yet enforced server-side for token-targeted pushes (the master switch IS effective for broadcasts/digests via the topic). Send-side enforcement lands with WS-G.
- Search is client-side over a capped fetch (400 docs) — right-sized for the launch catalog; revisit with a keyword index if the catalog outgrows it.
- Invoice PDF is English-only (PDF font has no Devanagari/₹ glyphs) — standard for financial documents.
- Rating filter in search arrives once real review data exists (aggregate field is already populated by the function).

---

## When everything above is checked

Reply **"A and B verified"** (with any failures noted) and we move to **Workstream D (cleanup: hide My Work tab, admin dashboard fixes)** — the quickest one — then **WS-C (designer role)**.
