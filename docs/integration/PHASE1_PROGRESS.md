# Phase 1 Progress Tracker

> **READ THIS FIRST every work session.** Protocol:
> 1. Find the ☐ next unchecked step below → read its full spec in [PHASE1_INTEGRATION_PLAN.md](PHASE1_INTEGRATION_PLAN.md) (+ [FIRESTORE_SCHEMA.md](FIRESTORE_SCHEMA.md) for any backend work).
> 2. Execute ONLY that step (or the few that fit comfortably in the session). Never start a step you can't finish.
> 3. Run the step's verification (`flutter analyze` zero issues + tests + the manual check).
> 4. `git commit` the step atomically (docs/feature prefix per CLAUDE.md git conventions).
> 5. Tick the checkbox, update **Current step**, add a 1-line session-log entry.
>
> Hotspot files (edit serially, LAST action of a step): both `service_locator.dart`, both
> `app_routes.dart`, l10n files, package barrels, `pubspec.yaml`s.

**Current step → S0.9** *(then M1 — S1.1 Category backend; S0.9 console items can run in parallel)*

---

## M0 — Foundations

- [x] **S0.1** Project integration docs (`docs/integration/` plan + schema + this tracker)
- [x] **S0.2** Core: constants (`FirestoreCollections`, `StoragePaths`, `DesignTechniques`), enums (UserRole/OrderStatus/DesignStatus/ActivityType), utils (`money.dart` + golden tests, `keyword_builder.dart`)
- [x] **S0.3** Core: catalog models (CategoryModel, DesignModel, BannerModel+HomeFeedModel)
- [x] **S0.4** Core: commerce models (CartItem, WishlistItem, Order+OrderItem, Purchase, Review, PlatformSettings, GlobalStats+DailyStats, Activity) + CacheConfig TTLs/boxes
- [x] **S0.5** ThemeCubit in core + admin theme wiring (persistent) + admin Settings screen + l10n `settings*`
- [x] **S0.6** User app theme wiring + Settings screen + l10n `settings*`
- [x] **S0.7** Design system additions: AppSearchBar, AppDropdownField, AppDateRangeField, AppChip, AppRatingStars, AppNetworkImage, AppPriceText, AppStatusBadge
- [x] **S0.8** Firebase scaffold: root firebase.json/.firebaserc, firestore.rules, firestore.indexes.json (ALL 14 indexes), storage.rules, functions/ skeleton (TS, builds, 4/4 golden tests pass), seed + backfillClaims scripts. **DEPLOY PENDING — see S0.9 item 0.**
- [ ] **S0.9** Prerequisites (console/client — deploy blocks M1 demo vs live data; payments/OTP block M2/M4 only):
  - [ ] **0. DEPLOY (blocked on login):** CLI is logged in as `instancyinc@gmail.com`, which has NO access to project `shree-krishna-emb`. Run `firebase login:add <owner-account>` (or `firebase login --reauth`), then from repo root: `firebase deploy --only firestore:rules,firestore:indexes,storage --project shree-krishna-emb`. If Storage errors: initialize Storage once in Firebase Console first.
  - [ ] Blaze upgrade (required before ANY functions deploy — S1.4 onward)
  - [ ] Razorpay TEST account: key_id → config/platform doc; key_secret + webhook secret → `firebase functions:secrets:set RAZORPAY_KEY_ID|RAZORPAY_KEY_SECRET|RAZORPAY_WEBHOOK_SECRET`
  - [ ] Razorpay webhook URL registered (payment.captured, refund.processed) — after S4.2 deploy
  - [ ] Gmail app password → `firebase functions:secrets:set SMTP_USER SMTP_PASS`; random `OTP_PEPPER` secret
  - [ ] Service Account Token Creator role on functions runtime SA (signed URLs, S4.4)
  - [ ] Firestore TTL policies on `adminOtps.expireAt` + `activity.expireAt`
  - [ ] Run `npm run seed` (emulator or TEST project) + `npm run backfill-claims` (first admin claim; admin must re-login after)

## M1 — Admin Catalog (gate: category → watermarked design publish → home banner)

- [ ] **S1.1** Category backend (repo interface, usecases, Firebase datasource, impl, SL)
- [ ] **S1.2** Category UI (bloc, responsive screen, form dialog, route /categories, sidebar, l10n `category*`)
- [ ] **S1.3** Design management backend (cursor pagination, uploads via putData, KeywordBuilder, SL, +file_picker +cloud_functions)
- [ ] **S1.4** Watermark pipeline fn (`onDesignAssetUpload`: sharp preview 1200px + thumb 400px) deployed + verified
- [ ] **S1.5** Design list UI (DesignListBloc, screen w/ search+filters+pagination, route /designs, l10n)
- [ ] **S1.6** Design form UI (DesignFormBloc, full-screen form, image uploader, EMB picker tile, technique chips, publish gated on `ready`, route /design-form)
- [ ] **S1.7** Banners + trending manager (config/homeFeed datasource→UI, route /banners, l10n) — **M1 GATE DEMO**

## M2 — Admin Ops (gate: OTP login, live dashboard, transaction filters + CSV, fee config)

- [ ] **S2.1** 2FA functions (requestAdminOtp, verifyAdminOtp, mailer) deployed + verified
- [ ] **S2.2** 2FA admin UI (TwoFactorBloc, screen, login/splash routing, signout clears session, route /two-factor, l10n `twoFactor*`)
- [ ] **S2.3** Transactions backend + initiateRefund fn + webhook refund branch
- [ ] **S2.4** Transactions UI + platform settings screen (routes /transactions, /platform-settings, l10n)
- [ ] **S2.5** Aggregates fns (onUserWrite claims+stats, onDesignWrite, onCategoryWrite, onReviewWrite) + dashboard backend; backfillClaims run
- [ ] **S2.6** Dashboard UI (DashboardBloc, kpi_card, fl_chart revenue, activity feed, l10n `dashboard*`)
- [ ] **S2.7** CSV export (csv_exporter, conditional-import download helper, export events in transaction+user blocs, l10n `export*`) — **M2 GATE**

## M3 — User Shopping (gate ON DEVICE vs TEST project: browse, search/filter, detail zoom, wishlist, role signup)

- [ ] **S3.1** Catalog data layer (CatalogRepository, usecases, Firebase datasource — all queries status=='active', recently-viewed Hive LRU, SL)
- [ ] **S3.2** Home real data (HomeBloc Future.wait, design_card + carousel + chips + rails widgets, home_screen rewire, l10n `home*`)
- [ ] **S3.3** Search (SearchFilters model, SearchBloc debounced, search screen + filter drawer, route /search, l10n `search*`) — verify all filter/sort combos on device
- [ ] **S3.4** Wishlist backend + app-scoped WishlistBloc (hearts sync everywhere)
- [ ] **S3.5** Design detail (DesignDetailBloc, screen + photo_view fullscreen gallery + metadata + reviews display + related, route /design-detail, +photo_view, l10n)
- [ ] **S3.6** Wishlist screen + role selection at signup (designer → coming-soon sheet) + profile real data — **M3 GATE**

## M4 — Cart, Payments, Orders (gate: full Razorpay test purchase → download → invoice → review → refund revoke)

- [ ] **S4.1** Cart (carts/{uid} single doc, CartBloc app-scoped badge, cart screen w/ breakdown, route /cart, l10n `cart*`)
- [ ] **S4.2** Payment functions (createRazorpayOrder, verifyPayment, finalizeOrder, webhook) deployed + unit-tested (HMAC vector, tamper, idempotency)
- [ ] **S4.3** Checkout + Razorpay UI (CheckoutBloc state machine, razorpay_gateway wrapper, checkout + success screens, +razorpay_flutter, l10n)
- [ ] **S4.4** Secure download + My Orders (getDesignDownloadUrl fn, OrderRepository, file_downloader to app-docs dir, order list/detail screens, +open_filex, l10n)
- [ ] **S4.5** Invoice PDF (invoice_pdf_builder, Noto fonts bundled, share via printing, l10n `invoice*`)
- [ ] **S4.6** Post-purchase review (ReviewRepository purchase-gated, ReviewBloc, review bottom sheet, wiring on order detail + design detail, l10n)
- [ ] **S4.7** Refund e2e (admin refund vs real test payment → webhook → download revoked, stats correct) — **M4 GATE**

## M5 — Polish & Hardening

- [ ] **S5.1** Audit sweep: l10n raw-string grep, dark mode + 320px pass, Text maxLines/overflow
- [ ] **S5.2** Loading/empty/error states everywhere; rules unit tests; fix admin user-list full-collection read → cursor pagination
- [ ] **S5.3** Release gate: analyze+test all 4 packages, functions npm test, admin web + user apk release builds, full purchase regression, docs updated to as-built

---

## Session log

| Date | Step(s) | Notes |
|---|---|---|
| 2026-06-12 | Plan + S0.1 | Phase 1 plan approved (Razorpay test+fns, all P2 in, backend+admin first). Created integration docs. Pre-existing uncommitted changes in admin (service_locator, admin auth datasource, splash, lib/core/constants/) left untouched — belong to user's in-progress work. |
| 2026-06-12 | S0.2–S0.4 | Core package: contract constants + enums + Money/KeywordBuilder (9 golden tests) + all 11 catalog/commerce models with dual serialization + CacheConfig TTLs/boxes. Commits 30cc3dc, d373010, 38153f8. |
| 2026-06-12 | S0.8 | Firebase scaffold committed (35cbac2): rules/indexes/storage + functions TS package (builds clean, money golden tests 4/4 = parity with core). Deploy attempted but 403 — CLI account instancyinc@gmail.com has no access to shree-krishna-emb project; owner must login + deploy (see S0.9 item 0). IMPORTANT for S1.x: admin login currently checks users/{uid}.role=='admin' via Firestore doc, but new rules check custom claims — until backfillClaims runs + admin re-logs-in, admin writes to designs/categories will be DENIED. Run backfill before M1 testing. |
| 2026-06-12 | UAT fix | User-reported issues fixed (52bf6da): settings embedded in dashboard content area via SettingsContentView (sidebar/header switch sections — no route push, kills splash-reload bug); settings UI redesigned (theme cards, language tiles, about card); dashboard fully theme-aware (colorScheme tokens replace hardcoded white/black/brown); sidebar + app bar + KPI labels localized (11 new keys). NOTE: login + user-management views still have hardcoded colors → S5.1 sweep. Requires FULL RESTART to test (not hot reload). |
| 2026-06-12 | S0.7 | 8 DS components added + exported (135f252); design_system +cached_network_image; AppPriceText delegates to core Money. All 4 packages analyze clean (pre-existing warnings only). |
| 2026-06-12 | S0.5–S0.6 | ThemeCubit in core (prefs key `theme_mode` from CacheConfig). Both apps: settings screen (theme light/dark/system + en/hi switcher + version), themeMode wired in main.dart, locale rebuild via AppLocalization.localeNotifier, /settings routes. Admin: dashboard header icon + sidebar entry. User: profile Settings tile + dark-mode switch wired. Both apps `flutter analyze` clean (user app: 36 pre-existing warnings, 0 errors). Commits 5d4965c, 627a3b6. Manual check pending: theme persistence across restart on device/web (S0.7 session can verify while testing DS components). |
