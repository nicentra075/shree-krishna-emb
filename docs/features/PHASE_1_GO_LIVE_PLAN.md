# Phase 1 Go-Live Master Plan — Play Store & App Store Release

> **STATUS (10 July 2026): ALL workstream DEV work is COMPLETE** — A, B, C, D, F (F1/F2/F5; F3-icons/F4-flavors deferred post-launch), G, and the code side of E. Both apps `flutter analyze` clean; functions build + tests pass. Remaining: owner verification + deploys + store actions — tracked in **[PHASE_1_MASTER_TEST_CHECKLIST.md](PHASE_1_MASTER_TEST_CHECKLIST.md)** (single checklist for everything, decisions DEC-1…DEC-9 at the end).

> **For agentic workers:** This is the MASTER plan. Each workstream below gets its own detailed implementation plan (in `docs/superpowers/plans/`) when we start it, executed via superpowers:subagent-driven-development or superpowers:executing-plans. Track progress with the checkboxes here.

**Generated:** 10 July 2026
**Baseline:** [PHASE_1_GAP_ANALYSIS.md](PHASE_1_GAP_ANALYSIS.md)
**Goal:** Close every Phase 1 gap so the user app ships to Play Store + App Store and the admin panel (web) supports both Admin and Designer roles.

**Architecture:** Existing clean architecture (entities → models → datasources → repositories → use cases → BLoC) with Firebase backend. All new work follows CLAUDE.md rules: dual serialization models, Either error handling, design-system components, full en_US + hi_IN localization, responsive + text-overflow standards.

**Tech Stack:** Flutter, Firebase (Auth/Firestore/Storage/Functions/FCM), Razorpay, `sign_in_with_apple`, `pdf` + `printing` (invoices), Hive cache.

---

## Locked Decisions (from product owner, 10 July 2026)

| #  | Decision                                                                                                                                                                                                                                                                                                                     |
| -- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| D1 | **Pinch-to-zoom:** stays disabled for non-owners. Enabled ONLY when the user has purchased the design (ownership check in image viewer).                                                                                                                                                                               |
| D2 | **No 2FA for admin.** Real forgot-password for admin panel. **Designer role can log in to the admin panel** with scoped access: create designs + categories + collections; see own designs dashboard, own payouts, own reports, own transactions. No access to user management, platform settings, or broadcast. |
| D3 | **Invoice download + invoice details UI** goes into the My Purchases tab (order history + per-order invoice). Build in Phase 1.                                                                                                                                                                                        |
| D4 | **Reviews & ratings** integrated in the user app as an immediate Phase 1 item.                                                                                                                                                                                                                                         |
| D5 | **White-label ready:** the product must be easily rebrandable for resale to clients — all branding (name, logos, colors, contact/support details, Firebase project, package IDs) centralized so a new client build is configuration, not code changes.                                                                |
| D6 | **Consistent success/error feedback:** every user-initiated action — user app, admin, designer — must surface a proper localized success or error toast (`AppSnackbar` in user app, `ResponsiveSnackbar` in admin). No silent failures, no silent successes on mutations.                                        |

**Accepted consequence of D2:** designer-created designs go live in the store immediately (no approval queue until Phase 2). Approval queue remains out of scope for Phase 1.

## Global Constraints

- No Firebase imports in presentation layer; all data access through datasource → repository → use case → BLoC.
- All models: `fromFirebaseJson`/`toFirebaseJson` + `fromApiJson`/`toApiJson`.
- All repository methods return `Either<Failure, T>`.
- All user-visible strings localized in `en_us.dart` + `hi_in.dart` (both apps have their own locale files).
- All UI via design system (`AppAppBar`, `AppTextField`, `AppButton`, `AppSnackbar` — admin uses `ResponsiveSnackbar(message, context)`).
- Every `Text()` has `maxLines` + `overflow: TextOverflow.ellipsis`; screens tested at 320px / 400px / 600px+.
- `designs` docs: rules require `name`, core `DesignModel` uses `title` — read defensively server-side and in rules.
- Before each commit: `dart format lib/` + `flutter analyze` clean.
- Firestore/storage rules changes are written in repo, **reviewed by owner before deploy** — never auto-deployed.
- **(D6)** Every mutation (create/update/delete/purchase/login/etc.) surfaces localized success OR error feedback: `AppSnackbar.show()` in the user app, `ResponsiveSnackbar(message, context)` in the admin app. Every `Left(Failure)` fold branch must reach the UI as a toast — never swallowed. New code written in WS-A…WS-C follows this from day one; WS-G sweeps existing code.
- **(D5)** No new hardcoded brand identity: app/company names via `AppLocalization.strings.appName` or `BrandConfig`, colors via `Theme.of(context).colorScheme`/`AppTheme`, logos/images via `BrandConfig` asset paths, support contacts/URLs via `BrandConfig`. WS-F centralizes what already exists.

---

## Timeline Overview

| Week | Focus                                               | Workstreams                                                                                                          |
| ---- | --------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------- |
| 1    | Security, auth, cleanup                             | WS-A (rules + forgot password + Apple Sign-In), WS-D (cleanup)                                                       |
| 2    | User app must-have features                         | WS-B1 (search + filters), WS-B2 (reviews) — D6 feedback rules applied as built                                      |
| 3    | User app features + designer role start             | WS-B3 (orders + invoice), WS-B4 (zoom, prefs, connectivity), WS-C start                                              |
| 4    | Designer role + white-label foundation              | WS-C (RBAC, scoped views, rules), WS-F1–F3 (BrandConfig + asset centralization)                                     |
| 5    | Feedback sweep + release engineering                | WS-G (toast consistency sweep, both apps), WS-E (signing, bundle IDs, privacy policy, Razorpay live, store listings) |
| 6    | Internal testing / TestFlight → production rollout | WS-E (buffer + review cycles); WS-F4–F5 (flavors + client guide — launch-parallel, not launch-blocking)            |

Total: **~5–6 weeks** (was 3–4 before D2 added the designer role).

Parallelization: WS-A and WS-D are independent (week 1 together). WS-B workstreams are independent of WS-C. WS-E items 1–4 (signing, bundle ID, privacy hosting) can start any time; final builds wait for feature freeze. **WS-F full flavor infrastructure does not block your own-brand launch** — F1–F3 (centralization) happen pre-launch so nothing new is hardcoded; F4–F5 (per-client build machinery) can complete right after submission.

---

# Workstream A — Security & Auth Foundation (Week 1)

### Task A1: Tighten `storage.rules` (role-based, designer-ready)

**Files:** Modify: `storage.rules` (repo root)

Because of D2, catalog write paths must NOT become admin-only — they become **admin OR designer** (designers upload design images/EMB files). Media/categories/collections config paths follow the same rule. User-app accounts (role `user`) must lose all catalog write access.

- [X] Add `isAdmin()` (custom claim) and `isDesigner()` helpers to `storage.rules` (+ `isStaff()`); claim synced by new `onUserRoleWritten` trigger + `refreshRoleClaim` callable (`functions/src/users/syncRoleClaim.ts`); admin app refreshes claim at sign-in/session restore
- [X] Change `designs/`, `design_files/`, `media/`, `collections/`, `categories/` write rules from `isAuthed()` → `isStaff()`
- [X] Keep 25MB limit; keep public/authed reads as-is
- [ ] Owner reviews the diff → `firebase deploy --only functions:onUserRoleWritten,functions:refreshRoleClaim` then `--only storage` (see WORKSTREAM_A_TEST_CHECKLIST.md)
- [ ] Regression test: admin upload works; a `user`-role account gets permission-denied on upload

### Task A2: Real forgot-password in the admin panel

**Files:** Modify: `shree_krishna_emb_admin/lib/screens/login/forgot_password_screen.dart` (lines ~72–76), `shree_krishna_emb_admin/lib/screens/login/admin_login_screen.dart` (TODO at :545); Modify: `firebase_admin_auth_datasource.dart` + auth repository/bloc to add `sendPasswordResetEmail(String email)`

Serves both admin and designer accounts (D2).

- [X] Add `sendPasswordResetEmail` through datasource → repository → new `PasswordResetCubit` (Either-based; kept out of the session `AdminAuthBloc`)
- [X] Wire forgot-password screen AND login screen's inline reset panel to actually call it; loading spinner + success/failure via `ResponsiveSnackbar`; existing localized strings reused
- [X] Handle `user-not-found` gracefully (treated as success — no account enumeration)
- [ ] Manual test with a real admin email

### Task A3: Apple Sign-In (user app — App Store blocker)

**Files:** Modify: `shree_krishna_emb_user_app/pubspec.yaml` (+`sign_in_with_apple`), `lib/data/datasources/firebase_auth_datasource.dart`, `lib/domain/usecases/auth_usecases.dart`, `lib/bloc/auth/auth_bloc.dart`, `lib/screens/auth/login_screen.dart` + `signup_screen.dart`; Modify: `ios/Runner/Runner.entitlements` (Sign in with Apple capability)

- [X] Add `signInWithApple()` to auth datasource via firebase_auth's native `AppleAuthProvider` + `signInWithProvider` (no extra package, nonce handled internally) → create/load Firestore user mirroring the Google path incl. new-user → complete-profile flow; name/email persisted from first grant
- [X] `SignInWithAppleEvent` in AuthBloc + `SignInWithAppleUseCase` + service locator registration
- [X] Apple button on login/signup — **iOS only** (owner decision, `!kIsWeb && Platform.isIOS`); bonus: fixed dead social buttons + missing complete-profile routing on signup screen
- [X] `Runner.entitlements` created + `CODE_SIGN_ENTITLEMENTS` wired into all 3 build configs
- [ ] Enable Apple provider in Firebase console + Apple Developer capability (fully verifiable after E2 bundle-ID fix)
- [ ] Test on iOS simulator/device: new user, returning user, complete-profile path, cancel path

---

# Workstream B — User App Phase 1 Features (Weeks 2–3)

### Task B1: Product search + filter drawer (P1 — biggest missing feature)

**Files:** Create: `lib/screens/search/search_screen.dart`, `lib/bloc/search/search_cubit.dart` (+state), filter drawer widget `lib/screens/search/widgets/filter_sheet.dart`; Modify: `core` package — extend `CatalogQueryDataSource` with search + filtered queries; Modify: `main_screen.dart` app bar (add search icon/bar); Modify: `firestore.indexes.json` (composite indexes); locale files (both apps' shared strings already partially exist: `searchProducts`, `enterSearchQuery`)

**Approach (Firestore-native, no Algolia for MVP):**

- Add a `searchKeywords: string[]` field on design docs (lowercased tokens of title/name/code/category) — backfilled by a one-off script/Cloud Function and maintained on write by admin app + `onDesignWritten` function
- Search = `array-contains` on typed token (prefix autocomplete via `name_lower >= q && < q + ''` for single-term)
- Filters: category (chip), price range (min/max), technique — as Firestore `where` clauses; sort presets reused from `view_all_screen.dart`
- Rating filter deferred until B2 aggregates exist (add `avgRating` filter after B2 lands)

- [X] ~~Keyword index~~ → implemented as client-side token matching over a capped fetch (400), consistent with the app's existing index-free catalog queries; live schema uses `name` not `title`. Keyword-index upgrade deferred until catalog scale demands it
- [X] `CatalogQueryDataSource.searchDesigns({query, filters})` + `SearchFilters` (category, min/max price, free-only, sort) — no composite indexes needed
- [X] Search screen: debounced `AppSearchBar`, results grid with wishlist hearts + star badges, empty/error/idle states
- [X] Filter bottom sheet: sort presets, category chips, price range, free-only; removable active-filter chips (technique dropped — no such field in the live schema)
- [X] Entry point: search icon in `main_screen.dart` app bar + `/search` route
- [X] All new strings localized (en + hi)

### Task B2: Reviews & ratings (D4)

**Files:** Create: `core` — `ReviewEntity`/`ReviewModel` (dual serialization), `FirebaseReviewsDataSource`, `ReviewsRepository`(+impl); Create: `lib/bloc/reviews/reviews_cubit.dart`, `lib/screens/catalog/widgets/reviews_section.dart`, write-review dialog/sheet; Modify: `design_detail_screen.dart` (reviews section + avg stars near title), design cards (star badge); Create: `functions/src/reviews/onReviewWritten.ts` (aggregate `avgRating` + `reviewCount` onto the design doc); `firestore.rules` already has purchase-gated `designs/{id}/reviews/{reviewerUid}`

- [X] Review model already existed in core (`ReviewModel`, doc id = uid) — reused as-is
- [X] Datasource + repository + per-design `ReviewsCubit` (list, upsert own, delete own; friendly permission-denied message)
- [X] Cloud Function `onReviewWritten`: transactional recompute of `avgRating`/`reviewCount` on the parent design
- [X] Design detail: average stars + count under the title; reviews section (top 3 + show all); write CTA gated on `PurchasesCubit.isOwned`
- [X] Write-review sheet: `AppRatingStars` input + comment field, edit/delete own review, D6 toasts
- [X] Star badge on search result cards when `reviewCount > 0` (home/view-all cards can adopt the same fields later)
- [X] Localized (en + hi); existing purchase-gated rules confirmed sufficient — no rules change

### Task B3: Order history + invoice in My Purchases (D3)

**Files:** Create: `core` — `OrderEntity`/`OrderModel` read path (orders exist in Firestore, written by Functions), `FirebaseOrdersDataSource` (user-scoped), repository; Create: `lib/bloc/orders/orders_cubit.dart`, `lib/screens/purchases/orders_tab.dart`, `lib/screens/purchases/order_detail_screen.dart`, `lib/services/invoice_pdf_service.dart`; Modify: `my_purchases_screen.dart` → two tabs: **Designs** (current grid) | **Orders**; Modify: `pubspec.yaml` (+`pdf`, `printing`); `firestore.rules` — verify user can read own `orders` (currently function-only write; confirm read rule `resource.data.userId == uid`, add if missing)

- [X] Orders read rule already allowed owner reads (`resource.data.userId == uid`) — no rules change needed
- [X] User-scoped orders datasource (`where userId == uid`, client-side sort → index-free) + repository + cubit
- [X] My Purchases → tabbed: Designs grid (unchanged) + Orders list (invoice ref, date, items, total, status chip)
- [X] Order detail screen: line items, subtotal / platform fee % / GST % / total, payment id, status — normalizes the demo-order (rupees) vs live-order (paise) unit difference
- [X] `InvoicePdfService` via `pdf` + `printing`: branded TAX INVOICE with items table, fee/GST breakdown, digital-goods note; share/save sheet
- [X] "Download Invoice" button on order detail (paid orders only)
- [X] Localized (en + hi); invoice PDF body intentionally English (no Devanagari glyphs in bundled PDF fonts)

### Task B4: Small user-app items

**Files:** Modify: `lib/screens/catalog/image_viewer_screen.dart`; Create: `lib/screens/settings/notification_preferences_screen.dart` (+cubit + datasource for `users/{uid}/settings` or prefs doc); Modify: `profile_screen.dart`, `main.dart`/`main_screen.dart` (connectivity)

- [X] **D1 — Ownership-gated zoom:** `ImageViewerScreen` takes `allowZoom`; detail screen passes `PurchasesCubit.isOwned(designId)`; owners get `InteractiveViewer` (5×), non-owners stay zoom-locked with watermark
- [X] **Notification preferences screen:** master + 3 category toggles persisted to `users/{uid}.notificationPrefs` (owner-writable — no rules change); master switch drives the `all_users` FCM topic; profile row wired; optimistic saves with rollback + toasts. Send-side category enforcement lands in WS-G
- [X] **Connectivity banner:** `AppConnectivityBanner` wraps the main shell body
- [X] **Profile cleanup:** About → app-info dialog; WhatsApp/Contact hidden until BrandConfig (WS-F); Privacy/Terms hidden until E3 — no dead taps (D6)

---

# Workstream C — Designer Role in Admin Panel (Weeks 3–4, D2)

**Scope:** Designers log in to the same admin web app and get a scoped workspace: create/manage **own** designs, create categories + collections, see **own** dashboard KPIs, **own** transactions, **own** payouts, **own** reports. No user management, no platform settings, no broadcast, no home-layout editing.

### Task C1: Role model & auth gate

**Files:** Modify: `firebase_admin_auth_datasource.dart` (accept `role in {admin, designer}`), `admin_auth_bloc.dart` (expose role in state), session persistence; Decide + implement claim mechanism: custom claim `designer` set by a small callable (`functions/src/auth/setUserRole.ts`) invoked from admin User Management, mirroring the existing admin-claim approach

- [ ] Login accepts `role == 'admin' || role == 'designer'`; role carried in auth state + restored on web session restore
- [ ] `AccessPolicy` helper (pure Dart, presentation-safe): `canManageUsers`, `canEditHomeLayout`, `canConfigurePlatform`, `canBroadcast`, `canSeeAllData`, `isOwnerScoped` — driven by role
- [ ] Admin User Management gets "Make Designer" action (sets role + claim via callable) — this is how designer accounts are provisioned in Phase 1 (no self-serve designer signup yet)
- [ ] Designer login end-to-end test (login, refresh/session restore, logout)

### Task C2: Role-based navigation & dashboard

**Files:** Modify: `admin_dashboard_screen.dart` (sidebar built from `AccessPolicy`; content switch respects role); Modify: `firebase_dashboard_stats_datasource.dart` + `dashboard_stats_cubit.dart` (owner-scoped variants)

- [ ] Sidebar for designer: Dashboard, Design Store (own), Transactions (own), Payouts (own), Reports (own), Settings (profile/theme/language only), Logout. Hidden: User Management, Home Layout, Broadcast/Notification settings, Approval Queue
- [ ] Designer dashboard KPIs: own active/pending designs count, own sales count, own gross earnings, recent activity = own designs — computed with `where('ownerId'=='uid')` count/aggregate queries
- [ ] Admin sees everything unchanged

### Task C3: Owner-scoped designs, categories, collections

**Files:** Modify: `firebase_catalog_datasource.dart` (+`ownerId` filter param), `designs_cubit.dart`, `designs_view.dart`, `design_edit_dialog.dart` (stamp `ownerId` + `authorName` on create when designer); categories/collections views (create allowed; edit/delete of others' — admin only)

- [ ] `designs` docs get `ownerId` (uid) + `authorName` on create; admin-created designs get admin's uid (or a global `admin` marker — decide in detailed plan); backfill existing docs with admin owner
- [ ] Designer's Designs view lists ONLY own designs; edit/delete only own; image + EMB file upload works under designer role (storage.rules from A1)
- [ ] Categories/Collections: designer can CREATE; edit/delete/archive restricted to admin (prevents a designer breaking shared taxonomy)
- [ ] `firestore.rules`: designs create/update/delete allowed for designer where `request.resource.data.ownerId == request.auth.uid` (and rules keep requiring `name` — remember title/name duality); categories/collections create for designer, mutate admin-only — owner reviews before deploy

### Task C4: Owner-scoped transactions, payouts, reports

**Files:** Modify: `firebase_orders_datasource.dart`/`orders_cubit.dart`/`transactions_content_view.dart`; `firebase_payouts_datasource.dart`/`payouts_content_view.dart`; `firebase_reports_datasource.dart`/`reports_content_view.dart`

**Schema note:** orders must be filterable by design owner. Add `ownerIds: string[]` (denormalized from line items) to order docs — written by `finalizeOrder`/`onOrderFinalized` in `functions/src/payments/` — plus backfill for existing orders. This is the key enabler; do it first.

- [ ] `functions`: stamp `ownerIds` on order finalize + backfill script; composite index `ownerIds array-contains + createdAt`
- [ ] Transactions view: designer sees orders `where ownerIds array-contains uid`; amounts shown are their line items' totals (compute per-owner subtotal client-side from line items); refund action hidden for designers
- [ ] Payouts view (existing read-only earnings): scope to own earnings for designers
- [ ] Reports + CSV export: designer exports own sales only; admin unchanged
- [ ] `firestore.rules`: allow designer read on orders where `request.auth.uid in resource.data.ownerIds` — owner reviews before deploy

---

# Workstream D — Admin Fixes & Cleanup (Week 1, parallel)

### Task D1: User app cleanup

**Files:** Modify: `shree_krishna_emb_user_app/lib/screens/main/main_screen.dart`

- [ ] Hide "My Work" tab (keep code for Phase 2; remove from tab list + destinations) → 3 tabs: Home | My Purchases | Profile
- [ ] Remove/park unused `work` route references; `flutter analyze` clean

### Task D2: Admin app cleanup & dashboard truth

**Files:** Modify: `admin_dashboard_screen.dart`, `settings_content_view.dart` (:635), delete `platform_fees_content_view.dart`

- [ ] Remove "Approval Queue" sidebar item (Phase 2)
- [ ] Replace hardcoded "42 Designs Awaiting Review" card → real pending-designs count (`designs where status=='pending'` count query) or drop the card for Phase 1
- [ ] Remove hardcoded "Payout Cycle In 3 Days" system-health card
- [ ] Add Total Users KPI card (value already computed in `dashboard_stats_cubit`)
- [ ] Gate `dummy_data_seeder.dart` entry behind `kDebugMode` (or remove from Settings)
- [ ] Delete orphaned `platform_fees_content_view.dart`

---

# Workstream E — Release Engineering & Store Submission (Week 5+; E1–E3 can start immediately)

### Task E1: Android release signing (user app)

**Files:** Create: `android/key.properties` (git-ignored), upload keystore (stored OUTSIDE repo + backed up); Modify: `android/app/build.gradle.kts`, `android/.gitignore`

- [ ] Generate upload keystore (`keytool -genkey ... -validity 10000`); record SHA-1/SHA-256
- [ ] `key.properties` + release `signingConfig` in `build.gradle.kts`; ensure key.properties + *.jks git-ignored
- [ ] Add release SHA-1/SHA-256 fingerprints to Firebase console (Google Sign-In on release builds breaks without this) + re-download `google-services.json`
- [ ] Drive `versionCode`/`versionName` from pubspec (`flutter.versionCode`/`flutter.versionName`); set pubspec `version: 1.0.0+3`
- [ ] Delete stale debug-signed `android/app/release/app-release.aab`; build fresh `flutter build appbundle --release`; verify signature (`jarsigner -verify`)

### Task E2: iOS identity (user app)

**Files:** Modify: `ios/Runner.xcodeproj/project.pbxproj` (bundle id), `ios/Runner/Info.plist` (display name)

- [ ] Bundle ID → `com.nicentra.shreeKrishnaEmb` (register in Apple Developer portal + App Store Connect app record)
- [ ] Display name → "Shree Krishna Embroidery"
- [ ] Add iOS app to Firebase project with new bundle id → new `GoogleService-Info.plist`; verify Google + Apple sign-in config (URL schemes)
- [ ] Archive build succeeds with team `2296GG5SN4`

### Task E3: Privacy policy & terms

**Files:** Create: policy + terms HTML pages (host on Firebase Hosting — e.g., add a `hosting` target or use the admin hosting site under `/privacy`, `/terms`); Modify: `profile_screen.dart` (wire both rows via `url_launcher`)

- [ ] Draft privacy policy (covers: Firebase Auth data, purchase/order data, FCM tokens, Razorpay payment processing, analytics-free statement, data deletion contact) + terms of service — owner reviews content
- [ ] Host both pages; wire Privacy Policy + Terms rows in profile
- [ ] Enter URLs in Play Console + App Store Connect

### Task E4: Payments go-live

- [ ] Razorpay KYC/live account approved; set live secrets: `firebase functions:secrets:set RAZORPAY_KEY_ID/RAZORPAY_KEY_SECRET/WEBHOOK_SECRET`
- [ ] Configure webhook URL (razorpayWebhook function) in Razorpay dashboard; verify signature check
- [ ] Switch `config/platform` to Live mode via admin Settings → Payments
- [ ] Real ₹ test purchase end-to-end on a release build: order → payment → verify → purchase doc → download unlocked → order appears in history → invoice downloads → refund from admin panel works

### Task E5: Firebase production hardening & deploy

- [ ] Deploy final `firestore.rules` + `storage.rules` + `firestore.indexes.json` + all Functions
- [ ] Restrict Android Firebase API key by package + SHA in GCP console
- [ ] Deploy admin web: `firebase deploy --only hosting` from `shree_krishna_emb_admin/`
- [ ] Smoke-test admin + designer logins on the hosted URL

### Task E6: Store listings & submission

- [ ] Play Console: store listing (title, descriptions, screenshots, feature graphic), Data Safety form (auth, purchases, FCM), content rating questionnaire, target-audience declarations
- [ ] App Store Connect: listing, privacy nutrition labels, screenshots (6.7" + 5.5"), review notes + **demo account** (email/password login that bypasses OTP for reviewers)
- [ ] Play internal testing track → fix cycle → production rollout (staged)
- [ ] TestFlight build → App Review submission
- [ ] Post-launch watch: Crashlytics/console errors (note: no crash reporting is integrated — acceptable v1, consider `firebase_crashlytics` fast-follow)

---

# Workstream F — White-Label Readiness (Week 4+, D5)

**Goal:** a new client brand = one config file + one asset folder + one Firebase project + one build command. No code edits.

**Launch-blocking split:** F1–F3 (centralize so nothing stays hardcoded) happen before feature freeze. F4–F5 (flavor machinery + guide) can land right after store submission — they matter when the first client deal happens, not for your own launch.

### Task F1: `BrandConfig` — single source of brand truth

**Files:** Create: `core/lib/src/config/brand_config.dart` (shared by both apps); Modify: both apps' `main.dart` to install a `BrandConfig` instance at startup; Modify: design system `AppTheme` to accept seed colors from `BrandConfig`

- [ ] `BrandConfig` class: `appName`, `companyName`, `logoAsset`, `logoDarkAsset`, `splashAsset`, `primaryColor`, `secondaryColor`, `supportEmail`, `supportWhatsApp`, `privacyPolicyUrl`, `termsUrl`, `playStoreId`, `appStoreId`
- [ ] Default instance = Shree Krishna EMB values (current branding becomes the first "brand")
- [ ] `AppTheme` light/dark schemes derive from `BrandConfig.primaryColor`/`secondaryColor` (via `ColorScheme.fromSeed` or explicit mapping) instead of hardcoded brand colors — verify both apps render identically to today with the default brand
- [ ] Walkthrough copy, profile contact rows (B4), privacy/terms rows (E3), invoice header (B3) all read from `BrandConfig` — retrofit those tasks' outputs

### Task F2: Brand audit & de-hardcoding sweep

**Files:** Modify: wherever the sweep finds hardcoded brand identity (both apps + design system)

- [ ] Sweep both apps for hardcoded brand strings ("Shree Krishna", "SKE", company names) outside locale files/`BrandConfig` — route through `strings.appName`/`BrandConfig`
- [ ] Sweep for hardcoded brand colors (hex values) in screens — route through theme (memory: theme-aware UI rule already mandates this; this sweep verifies)
- [ ] Locale files: brand-dependent strings (`appName`, welcome copy) documented as the per-brand override points
- [ ] FCM notification channel name/id, walkthrough images, watermark text/logo → `BrandConfig`

### Task F3: Asset centralization

**Files:** Move brand assets to `assets/brand/` in each app; Modify: `pubspec.yaml` asset declarations; Create: `flutter_launcher_icons` config per app

- [ ] All brand-identifying images (logo, splash, walkthrough illustrations, watermark) live under `assets/brand/` and are referenced ONLY via `BrandConfig`
- [ ] Adopt `flutter_launcher_icons` (config-driven icon generation from one source image per brand) — replaces manual mipmap management; regenerate current icons to verify parity
- [ ] Splash screen driven by generated assets (`flutter_native_splash` config) if a splash exists

### Task F4: Flutter flavors — per-client builds

**Files:** Modify: `android/app/build.gradle.kts` (productFlavors: `ske` default + template for clients — per-flavor `applicationId`, app label, `google-services.json` dir), iOS schemes + `.xcconfig` per flavor (bundle id, display name, `GoogleService-Info.plist`); Create: `lib/main_<flavor>.dart` entrypoints installing the flavor's `BrandConfig`

- [ ] Android productFlavors with per-flavor applicationId + resValue app_name + `src/<flavor>/google-services.json`
- [ ] iOS: one scheme + xcconfig per flavor (bundle id, display name, plist swap script)
- [ ] `flutter run --flavor ske -t lib/main_ske.dart` and release build commands verified for the default brand
- [ ] Admin app: same pattern (web builds take brand via `main_<flavor>.dart`; hosting target per client)

### Task F5: `WHITE_LABEL_GUIDE.md` — "new client in a day"

**Files:** Create: `docs/WHITE_LABEL_GUIDE.md`

- [ ] Step-by-step checklist: create Firebase project → `flutterfire configure --project <client>` per flavor → deploy rules/functions/indexes → seed `config/platform` + `config/homeFeed` + admin account → drop brand assets in `assets/brand/<client>/` → write `BrandConfig` + locale overrides → icons via flutter_launcher_icons → keystore + bundle id → store listings → Razorpay account per client
- [ ] Include the per-client cost/ops notes (Firebase project isolation = each client owns their data + billing)

---

# Workstream G — Success/Error Feedback Consistency Sweep (Week 5, D6)

**Goal:** no user action in any role ends silently. Every mutation shows a localized success toast on completion and a clear error toast on failure; long operations show progress.

### Task G1: Feedback audit (both apps)

- [ ] Sweep every Bloc/Cubit in both apps: list every state emission for failure (`*Error`, `Left` folds) and success (`*Loaded`/`*Success` after a mutation) and whether a screen surfaces it — grep for `BlocListener`/`listen:` coverage per screen
- [ ] Sweep for raw `ScaffoldMessenger`/`SnackBar` usage (should be ZERO — design-system rule) and for `catch` blocks that swallow errors (empty catch, `print`-only)
- [ ] Output: checklist of gaps per screen (user app + admin), committed as `docs/superpowers/plans/feedback-audit-findings.md`

### Task G2: Standard feedback helpers

**Files:** Verify/extend: design system `AppSnackbar` (success/error/info variants with distinct colors + icons); admin `ResponsiveSnackbar` (same variants); locale files (generic strings: `operationSuccessful`, `somethingWentWrong`, `noInternetConnection`, plus action-specific strings)

- [ ] `AppSnackbar.success(context, msg)` / `.error(context, msg)` (or equivalent variant API) in design system — user app
- [ ] `ResponsiveSnackbar` success/error variants — admin app
- [ ] Failure→message mapper: `Failure.toLocalizedMessage(strings)` so network vs permission vs unknown errors show sensible localized copy instead of raw exception text

### Task G3: Apply across all flows

- [ ] User app: auth (login/signup/OTP/social/reset), cart add/remove, checkout+payment, wishlist toggle, review submit/edit/delete, invoice download, notification prefs save, profile updates
- [ ] Admin: login/forgot-password, design/category/collection CRUD, image+EMB uploads (progress + result), home layout publish, fee/GST save, user suspend/edit/create, refunds, broadcast send, CSV export
- [ ] Designer (WS-C screens): design CRUD, uploads, payout/report views (error surfacing on load failures with retry)
- [ ] Every toast string exists in `en_us.dart` + `hi_in.dart` of the respective app

---

## Go-Live Checklist (final gate — all must be ✅)

- [ ] All WS-A/B/C/D tasks complete; `flutter analyze` clean on both apps
- [ ] Full regression on user app: signup (email/phone/Google/Apple) → browse → search → wishlist → cart → **live** purchase → download → zoom on owned design → review → order history → invoice PDF
- [ ] Full regression on admin: admin login/forgot-password, design CRUD + uploads, home layout publish, categories/collections, transactions + refund, fees config, users, CSV export, broadcast
- [ ] Full regression as designer: login → create design (image + EMB) → design visible in user app → sale → own transaction/payout/report visible → cannot see other data
- [ ] Security spot-check: `user` role cannot write to storage catalog paths or others' Firestore docs; designer cannot read other designers' orders
- [ ] **D6 gate:** feedback-audit findings (G1) all closed — no silent mutation in any role; error toasts verified by forcing failures (airplane mode, permission-denied)
- [ ] **D5 gate:** F1–F3 done — grep for hardcoded brand strings/colors outside `BrandConfig`/locales/theme returns nothing new
- [ ] Rules + Functions + hosting deployed; live payment verified; API key restricted
- [ ] Release AAB uploaded (Play internal) + TestFlight build; store listings + privacy forms complete; demo account provided
- [ ] Owner sign-off 🚀

## Execution Order (recommended)

1. **Week 1:** A1 → A2 → A3 in parallel with D1 → D2. Start E1/E2/E3 paperwork (keystore, Apple portal, policy drafting) since they have external lead times.
2. **Week 2:** B1 (search+filters), then B2 (reviews).
3. **Week 3:** B3 (orders+invoice) + B4 (small items). Start C1/C2.
4. **Week 4:** C3/C4 (designer scoping + rules + `ownerIds` backfill) + F1–F3 (BrandConfig, de-hardcoding sweep, asset centralization).
5. **Week 5:** G1–G3 (feedback sweep) → feature freeze → E4/E5/E6 — live payments, deploys, store submission.
6. **Week 6:** Review-cycle buffer (Apple review, Play policy review) + fixes. F4–F5 (flavors + white-label guide) in parallel — needed before the first client sale, not before your own launch.

## Risks & Watch Items

- **`ownerIds` denormalization (C4)** touches the payment finalize path — needs careful Function change + backfill; test with emulator before deploy.
- **Apple review:** digital-goods purchases via Razorpay may draw scrutiny — embroidery **design files used outside the app** are a real-world good/service edge case, but Apple sometimes forces IAP for digital content consumed in-app. Mitigation: downloads are files used externally (machine embroidery), position them as such in review notes. If rejected, fallback decision needed (IAP or external-purchase link entitlement).
- ~~Search backfill~~ — no longer applicable: search shipped client-side over the live `name`/`code`/`description` fields, so old designs are searchable with no backfill.
- **Google Sign-In on release builds** silently fails without release SHA fingerprints in Firebase (E1 step) — test sign-in on the signed release build, not just debug.
- No crash reporting in v1 — consider adding `firebase_crashlytics` during WS-E if time allows (one-day task).

---

*Each workstream gets a detailed, code-level implementation plan (`docs/superpowers/plans/YYYY-MM-DD-<workstream>.md`) at execution time, per superpowers:writing-plans.*
