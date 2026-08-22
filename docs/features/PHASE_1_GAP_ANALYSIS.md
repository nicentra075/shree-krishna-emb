# Phase 1 Gap Analysis — Go-Live Readiness (Play Store / App Store)

**Generated:** 10 July 2026
**Scope:** Phase 1 per `ShreeKrishnaEMB_Phase_Integration_Roadmap.docx` — Admin-curated design store + End-User browsing & purchasing. Roles: End-User + Admin only.
**Method:** Code audit of `shree_krishna_emb_user_app`, `shree_krishna_emb_admin`, `functions/`, Firebase rules, and Android/iOS release configuration, compared against the Phase 1 feature list.

---

## 1. Executive Summary

The core revenue loop is **fully working end-to-end**: sign-up → browse admin-curated store → cart → Razorpay checkout (server-verified via Cloud Functions) → instant digital download. Admin can manage the entire catalogue, home layout, categories, transactions, fees, users, and broadcasts from the web dashboard.

**What blocks go-live is NOT the core flow.** It is:

1. **Release engineering** — Android release build is signed with debug keys; iOS bundle ID is still `com.example.*`; no privacy policy URL (store-mandatory).
2. **A handful of Phase 1 features that are missing or stubbed** — product search + filters, reviews/ratings, order history + invoice, Apple Sign-In, notification preferences, admin forgot-password.
3. **Security hardening** — `storage.rules` lets any authenticated user write to catalog/media paths (self-documented as "tighten in Phase 3" — must be tightened before public launch).
4. **Cleanup** — the empty Phase-2 "My Work" tab, hardcoded dashboard cards, and dead-end profile rows (TODO taps) must be hidden or wired.

**Estimated remaining effort: ~3–4 focused weeks** (see §6).

---

## 2. User App — Phase 1 Feature Status

| # | Phase 1 Feature | Priority | Status | Notes / Evidence |
|---|---|---|---|---|
| 1 | Email/Phone OTP Sign-up & Login | P1 | ✅ **DONE** | Real Firebase Auth incl. phone OTP, complete-profile flow, forgot password (`firebase_auth_datasource.dart`) |
| 2 | Google Social Login | P2 | ✅ **DONE** | google_sign_in v7, full Firestore user creation |
| 3 | Apple Social Login | P2 | ❌ **MISSING** | No `sign_in_with_apple` package, no code. **Apple REQUIRES it on iOS when Google login is offered** — P2 on paper, but a hard App Store blocker |
| 4 | Home Screen (banner slider, categories, new arrivals, recently viewed) | P1 | ✅ **DONE** | Fully server-driven from Firestore `config/homeFeed`; Hive cache; recently-viewed local store |
| 5 | Category Browse | P1 | ✅ **DONE** | `view_all_screen.dart` with real Firestore queries + sort presets |
| 6 | **Search with autocomplete + filter drawer** (price/category/rating/technique) | P1 | ❌ **MISSING** | Only localization strings exist (`searchProducts`). No search bar, no search screen, no filter drawer anywhere |
| 7 | Design Detail Screen — metadata, gallery, watermark, related designs | P1 | ✅ **DONE** | `design_detail_screen.dart`; watermark overlay; ownership-aware CTA |
| 8 | Design Detail — pinch-to-zoom | P1 | ⚠️ **INTENTIONALLY DISABLED** | `image_viewer_screen.dart:48` — anti-piracy decision. Confirm & document; otherwise done |
| 9 | Design Detail — customer reviews & star ratings | P1 | ❌ **MISSING (UI)** | Backend ready — `firestore.rules:105` has purchase-gated `designs/{id}/reviews` subcollection — but zero Flutter UI to read/write reviews |
| 10 | Wishlist / Save Design | P2 | ✅ **DONE** | Firestore `wishlists/{uid}`, heart widget, favorites screen |
| 11 | Buy Digital Design (payment + instant download) | P1 | ✅ **DONE** | Server-trusted flow: `createRazorpayOrder` → Razorpay sheet → `verifyRazorpayPayment` → purchases written by Functions → download gated on ownership |
| 12 | UPI / Card / Wallet Payment (Razorpay) | P1 | ✅ **DONE** | `razorpay_flutter` + full Cloud Functions lifecycle (create/verify/webhook/finalize/refund). Test-mode safety factory. PhonePe not used (Razorpay covers UPI/cards/wallets) |
| 13 | Cart + checkout summary (platform fee + GST breakdown) | P1 | ✅ **DONE** | Firestore cart, fee/GST % live from `config/platform` |
| 14 | **Order History & Invoice Download** | P2 | ⚠️ **PARTIAL** | "My Purchases" shows owned designs only. No order-history list (orders exist in Firestore but never listed in-app) and **no invoice at all** (zero `invoice` hits in code) |
| 15 | Basic Profile screen | P2 | ⚠️ **PARTIAL** | Screen exists, but rows are dead TODOs: notification settings, WhatsApp, contact, about, **privacy policy, terms** (`profile_screen.dart:308–380`) |
| 16 | **Notification preferences** | P2 | ❌ **MISSING** | No preferences UI; settings screen covers only theme + language |
| 17 | Push notifications + in-app notification center | — | ✅ **DONE** | FCM tokens, topics, foreground/background/terminated deep-linking, live unread badge, notifications screen |
| 18 | Onboarding walkthrough | P1 | ✅ **DONE** | 4-page carousel with persistence (spec said 3 — fine) |
| 19 | Localization en_US + hi_IN | — | ✅ **DONE** | ~304 strings fully translated in both locales, runtime switch |
| 20 | Offline/connectivity handling | — | ⚠️ **PARTIAL** | Hive caching real; but `connectivity_plus` is declared and **never used** — no offline banner |

### User app cleanup items (not features, but launch-visible)

- **"My Work" tab (tab 3 of 4) is a Phase-2 stub** — `work_bloc.dart:95,100` return `[]` with TODOs; card builders return `SizedBox.shrink()`. It always renders an empty state. **Hide this tab for Phase 1.**
- Profile rows that navigate nowhere (6 TODO taps) — hide or wire them.
- Commented-out 5th walkthrough page (`walkthrough_screen.dart:84`) — leave or remove.

---

## 3. Admin App — Phase 1 Feature Status

| # | Phase 1 Feature | Priority | Status | Notes / Evidence |
|---|---|---|---|---|
| 1 | Admin Login (secure) | P1 | ⚠️ **PARTIAL** | Real email/password + Firestore `role=='admin'` gate + session restore. **But: no 2FA** (spec asks for it) and **forgot-password is fake** — `forgot_password_screen.dart:72–76` shows a success snackbar without calling `sendPasswordResetEmail`; `admin_login_screen.dart:545` has the TODO |
| 2 | Overview Dashboard with KPIs | P1 | ⚠️ **PARTIAL** | Real Firestore `count()` aggregates + 7-day revenue chart + live activity feed. Gaps: **Total Users computed but not rendered as a card**; revenue = gross order value, not platform-fee revenue; **"42 Designs Awaiting Review" card is HARDCODED** (`admin_dashboard_screen.dart:1248`); "Payout Cycle In 3 Days" system card hardcoded (`:1292`) |
| 3 | Add / Edit / Delete Admin Designs | P1 | ✅ **DONE** | Full CRUD, Firebase Storage image upload, **EMB/DST design-file upload** with file library |
| 4 | Set Featured Banner & Trending Picks | P1 | ✅ **DONE** | `config/homeFeed` layout editor with banner + manual-curation sections, reorder, publish. (No literal "Trending This Week" preset — built via manual sections; acceptable) |
| 5 | Category Manager (Add/Edit/Archive) | P1 | ✅ **DONE** | Full CRUD + `isActive` archive toggle + status filter. (Delete is hard-delete; archive toggle covers spec intent) |
| 6 | Transaction View + filters | P1 | ✅ **DONE** | Real orders list, status filter, date-range picker, search, pagination, detail dialog, refund via callable |
| 7 | Platform Fee Config (fee % + GST) | P1 | ✅ **DONE** | Settings → Payments: fee %, GST % + toggle, Test/Live payment mode, Razorpay keys (secret via callable) |
| 8 | User Management (view/suspend/ban) | P2 | ✅ **DONE** | Paginated list, search/role filters, suspend via `isActive`, edit, create, delete, password reset |
| 9 | CSV / Excel Export of Transactions | P2 | ⚠️ **PARTIAL** | Real CSV browser download — but it lives in **Reports** (sales summary + line items), not the Transactions screen, and there's **no .xlsx**. CSV likely sufficient for launch |
| 10 | Notifications / Broadcast | bonus | ✅ **DONE** | Broadcast callable + composer, admin inbox with live bell/sidebar badges, notification settings (`config/notifications`) |
| 11 | Localization + responsive | — | ✅ **DONE** | en_US + hi_IN, desktop sidebar / mobile drawer, dark/light theme |

### Admin app cleanup items

- **"Approval Queue" sidebar item is a dead link** — no `case 'approval'` in the content switch (`admin_dashboard_screen.dart:188–207`); clicking it re-renders the Dashboard. It's a Phase-2/3 feature — **remove/hide the sidebar item for Phase 1.**
- **Dummy data seeder ships in the production build** — `lib/core/dev/dummy_data_seeder.dart`, invoked from Settings (`settings_content_view.dart:635`). Gate behind `kDebugMode` or remove.
- `platform_fees_content_view.dart` is orphaned dead code (superseded by Settings → Payments) — delete.
- Payouts view exists but is read-only interim earnings (Phase 2 feature) — fine to keep or hide.

---

## 4. Backend & Security Status

| Item | Status | Notes |
|---|---|---|
| Cloud Functions | ✅ **DONE** | Full Razorpay lifecycle (create/verify/webhook/finalize/refund), notifications (broadcast, digests, triggers), `assignUserId`, stats — with tests |
| Function secrets | ✅ Managed | `defineSecret` for Razorpay/SMTP/etc. Must run `firebase functions:secrets:set` with **LIVE Razorpay keys** before launch |
| `firestore.rules` | ✅ Production-safe | Default-deny, function-only writes for orders/purchases, admin custom-claim checks. Public read only on designs catalog (intended) |
| `storage.rules` | 🚨 **MUST FIX** | Catalog/media/design-file **write** paths gated on `isAuthed()` only (self-documented "PHASE 1 — TIGHTEN IN PHASE 3"). Any signed-in user-app account can upload 25MB files into catalog paths. **Tighten to `isAdmin()` before public launch** — do not wait for Phase 3 |
| Admin web hosting | ✅ Ready | `shree_krishna_emb_admin/firebase.json` → Firebase Hosting, SPA rewrite, prior deploy evidence |

---

## 5. Store Release Blockers (Play Store / App Store)

| # | Blocker | Severity | Details |
|---|---|---|---|
| 1 | **Android release signing = debug keys** | 🚨 BLOCKER | `build.gradle.kts` release uses `signingConfigs.getByName("debug")`. No keystore, no `key.properties`. The existing `app-release.aab` (Apr 27) is debug-signed and store-invalid. Create upload keystore → wire `key.properties` → rebuild |
| 2 | **iOS bundle ID is `com.example.shreeKrishnaEmbUserApp`** | 🚨 BLOCKER | Must become a real reverse-domain ID (e.g. `com.nicentra.shreekrishnaemb`) matching an App Store Connect app record. Android is already correct: `com.nicentra.shree_krishna_emb` |
| 3 | **No Privacy Policy URL** | 🚨 BLOCKER | Mandatory for both stores (app uses auth, payments, FCM). Profile row is `// TODO` (`profile_screen.dart:372`). Host a policy page + wire the URL + enter it in both store consoles. Terms of Service row also TODO |
| 4 | **Apple Sign-In missing** | 🚨 BLOCKER (iOS only) | App Store Guideline 4.8: third-party login (Google) requires offering Sign in with Apple |
| 5 | **storage.rules `isAuthed()` writes** | 🚨 BLOCKER (security) | See §4 — tighten before real users exist |
| 6 | Version mismatch | ⚠️ Minor | Android hardcodes `versionCode=2 / 1.0.0`; pubspec says `0.1.0`. Reconcile (drive from pubspec) |
| 7 | iOS display name | ⚠️ Minor | "Shree Krishna Emb User App" → rename to "Shree Krishna Embroidery" |
| 8 | Data Safety / privacy questionnaires | ⚠️ Process | Play Data Safety form + Apple privacy nutrition labels (auth data, purchase data, FCM tokens) |
| 9 | Live Razorpay keys + webhook | ⚠️ Process | Set live key secret, configure webhook URL in Razorpay dashboard, switch `config/platform` to Live mode. KYC/settlement account must be approved by Razorpay |
| 10 | Restrict Firebase API key | ⚠️ Recommended | Android key in committed `google-services.json` is fine to commit, but restrict by package + SHA-1/SHA-256 in GCP console |
| 11 | No CI/CD | ℹ️ Optional | All builds/deploys manual (`buildreleasecommands`). Fine for v1 |

Admin app android/ios folders are still `com.example.*` with debug signing — **irrelevant for Phase 1** since admin ships as web (Firebase Hosting). Only fix if you later ship admin to stores.

---

## 6. Prioritized Pending-Work Plan

### P0 — Cannot ship without these (~1 week)

| Task | App | Est. |
|---|---|---|
| Create Android upload keystore, `key.properties`, real release `signingConfig`; rebuild AAB | User | 0.5 d |
| Set real iOS bundle ID + display name; App Store Connect app record; test archive | User | 0.5–1 d |
| Add **Sign in with Apple** (`sign_in_with_apple` + Firebase Apple provider + datasource/bloc/button) | User | 1–2 d |
| Host Privacy Policy + Terms pages; wire profile rows; add URLs to store consoles | Both | 1 d |
| **Tighten `storage.rules`** catalog/media/design-file writes to `isAdmin()`; deploy; regression-test admin uploads | Backend | 0.5 d |
| **Hide "My Work" tab** in user app main navigation | User | 0.5 d |
| Hide/remove **Approval Queue** sidebar item; gate/remove **dummy data seeder** from Settings | Admin | 0.5 d |
| Set live Razorpay secrets, webhook URL, switch to Live mode; end-to-end ₹1 test purchase | Backend | 0.5 d |

### P1 — Phase 1 features still owed (per roadmap "Must Have") (~1.5–2 weeks)

| Task | App | Est. |
|---|---|---|
| **Product search** (search bar on Home/app bar, results screen, autocomplete on design title/code) | User | 2–3 d |
| **Filter drawer** (price range, category, technique; rating once reviews exist) + wire to catalog queries; add composite indexes | User | 2 d |
| **Reviews & ratings on design detail** — write review (purchase-gated, rules already exist), list reviews, average star display | User | 2–3 d |
| **Order history screen** — list `orders/` for the user (date, items, amount, status) | User | 1–2 d |
| Fix admin **forgot-password** — call `sendPasswordResetEmail` (screen + login TODO) | Admin | 0.5 d |
| Dashboard fixes: wire pending-approvals card to real count (or remove for Phase 1), remove hardcoded payout/system card, add Total Users KPI card | Admin | 1 d |

### P2 — Should-have, can trail the first release (~1 week)

| Task | App | Est. |
|---|---|---|
| **Invoice download** (PDF per order — order data + fee/GST breakdown; generate client-side or via Function) | User | 2–3 d |
| **Notification preferences screen** (category toggles; respect in Functions when sending) | User | 1–2 d |
| Offline/connectivity banner (use the already-declared `connectivity_plus`) or remove the dep | User | 0.5 d |
| Wire remaining profile rows (about, contact/WhatsApp) or hide them | User | 0.5 d |
| Admin 2FA (Firebase `multiFactor` / TOTP) — spec'd but reasonable to defer with a strong password policy | Admin | 2 d |
| CSV export button on the Transactions screen itself (currently Reports-only); .xlsx if accounting needs it | Admin | 0.5–1 d |
| Distinguish gross revenue vs platform-fee revenue on dashboard | Admin | 1 d |
| Reconcile version: drive `versionCode/versionName` from pubspec | User | 0.25 d |
| Restrict Firebase Android API key by package + SHA | Backend | 0.25 d |

### Store-submission process checklist (parallel to dev work)

- [ ] Play Console: app record, Data Safety form, content rating, store listing (screenshots, feature graphic, descriptions)
- [ ] App Store Connect: app record, privacy labels, screenshots (6.7" + 5.5" or generated), review notes with a demo account
- [ ] Demo/test account for store reviewers (email+password login that bypasses OTP)
- [ ] Deploy latest `firestore.rules` + tightened `storage.rules` + all Functions to production
- [ ] Deploy admin web to Firebase Hosting (`firebase deploy --only hosting` from `shree_krishna_emb_admin/`)
- [ ] Internal testing track (Play) / TestFlight round before production rollout

---

## 7. Decisions Needed From You

1. **Pinch-to-zoom** is disabled on purpose (anti-piracy). The Phase 1 doc lists it as a feature — keep disabled? (Recommended: keep disabled; watermark + no-zoom is a coherent protection stance.)
2. **Admin 2FA** — spec says "Must Have", but Firebase email/password + admin custom-claim is functional. Ship v1 without 2FA? (Recommended: defer to fast-follow.)
3. **Invoice download** — required at launch or fast-follow? (Order history alone may satisfy v1; GST invoices matter once real sales volume starts.)
4. **Reviews** — ship at launch or fast-follow? It's listed under P1 design-detail features, but the store works without it. Search/filters, by contrast, should NOT be skipped — a store without search is a poor first impression.

---

*Sources: full audits of `shree_krishna_emb_user_app/lib`, `shree_krishna_emb_admin/lib`, `functions/src`, `firestore.rules`, `storage.rules`, Android/iOS build configs. Feature baseline: `docs/features/ShreeKrishnaEMB_Full_Feature_List.docx` and `ShreeKrishnaEMB_Phase_Integration_Roadmap.docx`.*
