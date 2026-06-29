# Dev Status Tracker — Design Store · Phase 2 · Phase 3

A single living doc to validate and fix everything together. **You** set the Status and (if it fails) write what's wrong in **Issue found**. **Claude** reads this doc, fixes failing items, and fills **Fix / Resolution** + flips the status.

## How to use

1. Test an item. Set its **Status**.
2. If it fails or behaves oddly, write a short, specific note in **Issue found (you)** — e.g. *"DB-2: revenue shows ₹0 even though 3 paid orders exist"* or *"C-3: totals don't include GST"*.
3. Tell Claude *"check the tracker"*. Claude fixes every `❌`/`⚠️` row, writes the resolution in **Fix / Resolution (Claude)**, and sets the row to `✅ (fixed)` (you re-verify and confirm).

## Status legend

`🔲 Not tested` · `✅ Pass` · `❌ Fail` · `⚠️ Partial / minor` · `⏭️ Skipped / N/A` · `🔁 Fixed – re-verify`

> Money note: all prices are **integer rupees** (₹998). Razorpay-facing code uses paise (×100) only at the API boundary.

---

## A. Design Store — formats & design-file library *(admin)*

| ID | Item / Check | Status | Issue found (you) | Fix / Resolution (Claude) |
| --- | --- | --- | --- | --- |
| DF-1 | Add/Edit Design → **Design Format** is a multi-select (DST / EMB / DHE) | `🔁` | Multi Select Option is there but it is not looking Good On the UI level and Use may get confused as well. <br><br>Actually can you redesign this full add and edit design form fields for me so that it can give good look and feel. you can reposition the fields correctly and also you can increase the width of the dialoge box so that the user also may don't have to scroll. also currently i can see that alignment issue in the code field and auther field so can you fix that for me. | **Redesigned.** Dialog widened (≤820px) + **2-column responsive** layout (`LayoutBuilder`, single-col under 700px) so no scroll on desktop. Code+Author row top-aligned (fixed). Format multi-select polished (card + checkmarked chips + divider before file slots). Theme-aware. Re-verify. |
| DF-2 | Selecting a format shows a **file slot**; can attach a file per format | `✅` |  |  |
| DF-3 | "Add file" → chooser with **Upload from device** + **Choose from Library** | `🔁` | it is showing me the option to upload the file but when i try to upload it it is giving me the error showing User is not autharised to perform this action. | **Not a code bug — deploy rules.** The `design_files/` Storage rule + `design_files/{id}` Firestore rule are correct in-repo but not deployed. Run `firebase deploy --only firestore:rules,storage`, then re-test. (NEXT-STEPS §0) |
| DF-4 | **Design File Library**: upload (drag-drop + browse), pick, delete, format badge | `🔁` | it is showing me the option to upload the file but when i try to upload it it is giving me the error showing User is not autharised to perform this action. | Same root cause as DF-3 → deploy `firestore:rules,storage`. |
| DF-5 | Library has **pagination + per-page** (12/24/48) | `✅` |  |  |
| DF-6 | Deselecting a format removes its attached file | `✅` |  |  |
| DF-7 | Saved design keeps `designFormats` + `designFiles` on edit/reopen | 🔲 | Not tested because the design upload is not working. and for your information i have added some dummy designs files in the below path so that designs i am going to upload. <br><br>path : docs/designs_file_folder |  |
| DF-8 | User app design detail shows formats + **Download** (free now / locked if paid & unowned) | 🔲 | Not Tested because the design upload is not working. |  |

## B. UX fixes *(admin)*

| ID | Item / Check | Status | Issue found (you) | Fix / Resolution (Claude) |
| --- | --- | --- | --- | --- |
| UX-1 | "Add image" uploading dialog no longer stretches to full height | `✅` |  |  |
| UX-2 | Upload from device = drag-drop area **+** "Select from device" button | `✅` |  |  |
| UX-3 | Delete collection/category dialog has a **stable width** (no resize on checkbox) | `✅` |  |  |
| UX-4 | Media Library multi-select + "Use (N)" works | `✅` |  |  |
| UX-5 | Add/Edit Design accepts **multiple images** via upload / library / URL | `✅` |  |  |
| UX -6 | Add image Dialoge → Add Image URL option→ Add image text field and button Alignment issue | `🔁` | there is still i can see the alignment issue | **Fixed.** Replaced the misaligned Row(field+button) with a stretched Column — URL field full-width, "Add" button below it (tidy in single + multi-line modes). |

## C. Dark mode & cross-cutting *(both apps)*

| ID | Item / Check | Status | Issue found (you) | Fix / Resolution (Claude) |
| --- | --- | --- | --- | --- |
| DM-1 | User app app-bars + text/icons render correctly in **dark mode** | `🔁` | It is working well in the user app but in the admin app in the login screens the text color is not looking in the dark mode so can you check and fix that issue for me. | **Fixed (admin login).** Forced `Colors.white` bg + `AppTheme.textDark` text made AppTextField text invisible in dark. Now theme-aware: `colorScheme.surface` bg + `onSurface`/`onSurfaceVariant` text; branding panel keeps white text on its gradient. |
| DM-2 | All new admin screens render correctly in dark + light | `✅` |  |  |
| DM-3 | Pre-login screens (auth/login/signup, walkthrough, splash) dark mode | `🔁` | Not supporting the dark mode can you add that support for me. | **Done.** Themed login/signup/forgot/otp/complete_profile + walkthrough + pages (theme-aware `colorScheme` roles; raw AppBars → AppAppBar). Brand gradient panels keep white text by design. Splash is a fixed brand-orange gradient (readable in both). |
| DM-4 | New strings localized (EN + HI); no overflow (maxLines/ellipsis) | `✅` |  |  |

---

## D. Phase 2 — Cart *(user app)*

| ID | Item / Check | Status | Issue found (you) | Fix / Resolution (Claude) |
| --- | --- | --- | --- | --- |
| C-1 | **Add to Cart** appears on paid design detail; CTA flips to In-Cart/Go-to-Cart | `✅` |  |  |
| C-2 | Cart **badge** in app bar increments/decrements | `✅` |  |  |
| C-3 | Cart screen: items list, remove, **empty state** | `✅` |  |  |
| C-4 | Totals show **Subtotal + Platform fee% + GST% + Total** matching `config/platform` | `✅` | it is working but how the admin can adjust this Platform Fees and GST percentage from the admin ? currently there is not any way to enable / disable or edit that percentage in the admin app so can you plan that for me and add that functionality in the settings level. ( if needed create the tab wise UI in the settings and in that show this details and actions ). Or we already have that platform fees option in the side bar level so utilise that and give that options there so that user can handele that from there. | **Already built (2 places, both write `config/platform`):** Admin → **Settings → Payments** (fee %, GST %, mode, keys) AND sidebar → **Platform Fees** (PF-1). Changing either updates cart/checkout totals app-wide. If not visible → stale build; full-rebuild the admin web app. (NEXT-STEPS §1) |
| C-5 | Cart **persists** across restart (reads `carts/{uid}`) | `✅` |  |  |
| C-6 | Max 50 items; no duplicate add | `✅` |  |  |

## E. Phase 2 — Checkout (Test mode) *(user app)*

| ID | Item / Check | Status | Issue found (you) | Fix / Resolution (Claude) |
| --- | --- | --- | --- | --- |
| CO-1 | Proceed to Checkout → order summary (items + fee + GST + total) | `✅` |  |  |
| CO-2 | **Mock** path (no Razorpay key) → simulated success | `🔁` | Not working and giving me the server Exception: the coller does not have the permission to access this | **Not a code bug — deploy rules.** The test-mode `orders`/`purchases` create rules aren't deployed. Run `firebase deploy --only firestore:rules,storage`. Test mode is the default when `config/platform` is absent, so checkout writes demo orders after deploy. (NEXT-STEPS §0) |
| CO-3 | **Razorpay Test** path (test key set) → test sheet → test card → success | 🔲 | Not able to test |  |
| CO-4 | On success: `orders/demo_*` + `users/{uid}/purchases/*` written, **cart cleared** | 🔲 | Not able to test |  |
| CO-5 | Cancel/failure → friendly message, **cart kept** | `✅` | No to test |  |

## F. Phase 2 — My Purchases & ownership *(user app)*

| ID | Item / Check | Status | Issue found (you) | Fix / Resolution (Claude) |
| --- | --- | --- | --- | --- |
| P-1 | **My Purchases** lists owned designs (thumb, title, format, date) + empty state | `🔁` | My purchases Tab is not visible  | **Fixed visibility.** Added a prominent **"My Orders"** section on the Account screen (My Purchases + My Cart cards), high up. (It was only a buried Settings tile.) New screens need a **full restart**, not hot reload. |
| P-2 | Owned design detail: Add-to-Cart hidden, **Download enabled** | `🔁` | Tab is not visible  | Now reachable via Account → My Orders. Functional re-test after deploying rules (so a purchase can be made — CO-2). |
| P-3 | **Free** design → "Get for Free" grants ownership → downloadable | `🔁` | Tab is not visible  | Reachable now; re-test after deploy (free claim writes a purchase in test mode). |
| P-4 | Ownership persists across restart (reads `users/{uid}/purchases`) | `🔁` | Tab is not visible  | Reachable now; re-test after a purchase exists. |

## G. Phase 2 — Admin Transactions

| ID | Item / Check | Status | Issue found (you) | Fix / Resolution (Claude) |
| --- | --- | --- | --- | --- |
| TX-1 | Sidebar **Transactions** opens its own screen (not the dashboard) | 🔲 |  |  |
| TX-2 | Demo/test orders appear (id, buyer, items, ₹ total, status, date) | 🔲 |  |  |
| TX-3 | Filters: status + date range + search; per-page + pagination | 🔲 |  |  |
| TX-4 | **Order detail** dialog: items, fee/GST, payment id, invoice, timeline | 🔲 |  |  |
| TX-5 | **Refund** on paid order (Live/Blaze) → refunded + purchase revoked | 🔲 |  | *(needs functions deployed)* |

## H. Phase 2 — Admin Dashboard (live)

| ID | Item / Check | Status | Issue found (you) | Fix / Resolution (Claude) |
| --- | --- | --- | --- | --- |
| DB-1 | KPI cards show **live** counts (no hardcoded 2,450 / $45,320 / 856) | 🔲 |  |  |
| DB-2 | Revenue **chart** (fl_chart) renders real per-day trend | 🔲 |  |  |
| DB-3 | Counts update as data changes; shimmer while loading; error+retry | 🔲 |  |  |

---

## I. Phase 3 — Payments toggle + Settings *(admin)*

| ID | Item / Check | Status | Issue found (you) | Fix / Resolution (Claude) |
| --- | --- | --- | --- | --- |
| ST-1 | Settings → **Payments**: Test/Live toggle (warning on Live) | 🔲 |  |  |
| ST-2 | Razorpay test/live **key id** fields persist to `config/platform` | 🔲 |  |  |
| ST-3 | Fee % + GST % editable here and/or Platform Fees; 0–100 validated | 🔲 |  |  |
| ST-4 | Changing fee/GST updates **cart/checkout totals** app-wide | 🔲 |  |  |

## J. Phase 3 — Reports + Payouts + Fees *(admin)*

| ID | Item / Check | Status | Issue found (you) | Fix / Resolution (Claude) |
| --- | --- | --- | --- | --- |
| RP-1 | **Reports** opens; date-range picker | 🔲 |  |  |
| RP-2 | Cards: total sales, orders, AOV, top designs, top categories, new users | 🔲 |  |  |
| RP-3 | **Export CSV** downloads (honors date filter) | 🔲 |  |  |
| PO-1 | **Payouts** shows per-designer earnings owed + totals | 🔲 |  |  |
| PF-1 | **Platform Fees** editor saves fee/GST to `config/platform` | 🔲 |  |  |

## K. Phase 3 — Production (Blaze) payment flow *(functions)*

| ID | Item / Check | Status | Issue found (you) | Fix / Resolution (Claude) |
| --- | --- | --- | --- | --- |
| FN-1 | `npm run build` clean; secrets set; `firebase deploy --only functions` ok | 🔲 |  |  |
| FN-2 | Webhook URL set in Razorpay dashboard | 🔲 |  |  |
| FN-3 | Live: checkout → `createRazorpayOrder` (server prices) → sheet → `verifyRazorpayPayment` | 🔲 |  |  |
| FN-4 | Finalize: order `paid`, **invoice minted**, purchases written, cart cleared | 🔲 |  |  |
| FN-5 | **Webhook** reconciles same payment (idempotent — no dup invoice/purchase) | 🔲 |  |  |
| FN-6 | Live mode: direct client write to orders/purchases is **denied** by rules | 🔲 |  |  |
| FN-7 | Admin **Refund** (Live) → Razorpay refund → order refunded → download revoked | 🔲 |  |  |
| FN-8 | Dashboard/Reports revenue reconciles with stats after orders | 🔲 |  |  |

---

## L. Open / follow-ups (known)

| ID | Item | Status | Notes |
| --- | --- | --- | --- |
| OPEN-1 | "Get for Free" in **Live** mode needs a `claimFreeDesign` callable (test mode works) | 🔲 | Decide if needed now |
| OPEN-2 | Pre-login dark mode (DM-3) | `🔁` | Done this round. |
| OPEN-3 | Payouts is interim read-only (no wallet/payout functions yet) | 🔲 | Later phase |

---

### Issue log (free-form — for anything that doesn't fit a row)

> Add `- [ID or area] description…` lines here; Claude will triage + fix.

- **[USERID] Guarantee unique sequential `userId` for every user (admin + app)** → `🔁` **Built (Cloud Function).** New `assignUserId` Firestore `onCreate(users/{uid})` trigger mints an atomic, collision-free sequential `userId` from `counters/users.seq` (Admin SDK bypasses the deny rule), overriding whatever a client wrote — so both flows are guaranteed-unique + sequential. Idempotent; concurrent creates can't collide. **Existing users untouched** (trigger fires only on new docs; the counter bootstraps ABOVE the current max real id). Requires `firebase deploy --only functions`. *(`functions/src/users/assignUserId.ts`.)*
- **[PLACEHOLDER] Show a placeholder image where collection/category/design has no image** → `🔁` **Done.** Upgraded `AppNetworkImage` (design system) — null/empty/error now renders a branded, size-scaling placeholder (was a tiny grey icon). Covers every image site app-wide. Also fixed two cards (View-All `_tileCard`, home collections grid) that **skipped** the image when the URL was null — they now always render the placeholder. *(`design_system/.../app_network_image.dart`, `view_all_screen.dart`, `section_renderer.dart`.)*
- **[AUTH] User-app signup/login permission error** → `🔁` **Fixed (2 code bugs):** (1) signup called `_generateSequentialUserId()` which read/wrote `counters/user_id_counter` — but `counters/` is Cloud-Functions-only (`allow read,write: if false`), so every signup threw permission-denied. Now the display user-id is a client timestamp (no `counters` access). (2) `UserModel.toFirebaseJson()` wrote no `role`, but the `users` create rule requires `role in ['user','designer']` → the doc write was denied. Now signup writes `role: 'user'` (email + Google + phone paths). Sign-in had no permission bug — it failed only because no user doc existed (signup never completed). Deploy rules + retry signup. *(File: `firebase_auth_datasource.dart`.)*

- In the Design tab level and in any Uploading cases currently we are just showing that common loader and with that it is not giving any idea to the user like how much content or image or design has been uploaded so for that an you show any progress loader for me with the percentage so that the user can get idea about it instead of that Common Loader. can you add that functionality for me.
  → `🔁` **Fixed.** Real percentage via Storage `snapshotEvents` threaded datasource→repo→cubit→UI; Media Library + Design File Library + per-format chooser show a determinate bar + "Uploading X/N · 42%". Re-verify after rebuild.
- In the Admin Web app level it is not showing the app icon in the crome level on that tab level so can you fix that issue for me. ( it should show the admin app icon in the tab level )
  → `🔁` **Fixed.** `web/index.html` `<link rel="icon">` + manifest icons now point at `icons/Icon-192/512.png`; tab title → "Shree Krishna Admin". Re-verify after a web rebuild (hard-refresh to bust the favicon cache).
- I Have logged in in to that razor pay and now i have that razor pay test APi key and test Secrate key so were do i add that ? in the web admin panel it is not showing that options in that payment mode options fields. so can you check and give me that perfect fields.
  → ✅ **Answer:** the **Key ID** (`rzp_test_…`) goes in **Admin → Settings → Payments → "Razorpay test key"** (saved to `config/platform.razorpayKeyIdTest`). The **Secret** does NOT go in the app — set it on Cloud Functions: `firebase functions:secrets:set RAZORPAY_KEY_SECRET_TEST` then `firebase deploy --only functions`. If the key fields aren't visible in Settings → Payments, it's a stale build (full-rebuild) — the admin agent is also verifying the section is wired. (NEXT-STEPS §1)