# Phase 1 Integration Plan — Shree Krishna Embroidery (Admin App + User App)

> **This is the master execution plan for Phase 1.** It lives in the repo so every work session
> (human or AI, regardless of context window) can resume from it. Companion docs:
> - [FIRESTORE_SCHEMA.md](FIRESTORE_SCHEMA.md) — the data contract connecting both apps (read before ANY backend work)
> - [PHASE1_PROGRESS.md](PHASE1_PROGRESS.md) — checkbox tracker; **every session starts and ends here**

---

## 1. Goal & scope

Deliver **Phase 1 (Core Platform MVP)** per `docs/features/ShreeKrishnaEMB_Phase_Integration_Roadmap.docx`:
an **Admin-curated design store** where end-users browse, search, and purchase digital embroidery
designs, with full admin management of catalog, transactions, and users.

**In scope (decided with the client/owner):**
- Razorpay **TEST mode** payments with Cloud Functions signature verification (swap to live keys at launch).
- ALL P2 should-haves included: **Wishlist, Invoice PDF (client-side), Admin CSV export, Admin 2FA (email OTP)**.
- Sequencing: **Backend + Admin first**, then User app shopping flows.
- Both apps: **BLoC state management, en_US + hi_IN localization, persistent light/dark theme**.

**Explicitly OUT of scope (later phases):** Work module / job bidding (Phase 2), Designer marketplace
"My Shop" (Phase 3), social/community features & push notifications (Phase 4). The user app's
existing WorkScreen is left untouched. Designer role selection stores the role but shows a
"coming soon" sheet.

## 2. Current state (as of plan creation, 2026-06-12)

| Package | State |
|---|---|
| `shree_krishna_emb_admin/` | splash, login (Firebase email/pwd + role check), dashboard shell (dummy KPIs), full User Management. BLoCs: AdminAuth, Splash, UserList. L10n at `lib/l10n/`. Theme toggle NOT persisted. |
| `shree_krishna_emb_user_app/` (package `shree_krishna_emb`) | splash, walkthrough, full auth (email/Google/OTP/forgot/complete-profile), bottom nav Home\|Work\|Profile, Home on dummy data, Profile skeleton. L10n at `lib/localisations/`. No theme toggle UI. |
| `core/` (`shree_krishna_core`) | UserEntity/Model (dual serialization, ISO-string dates), Either, failures, cache base. Only the User model exists. |
| `design_system/` | 14 components (AppAppBar, AppTextField, AppButton, AppSnackbar, AppLoader, AppShimmer, AppEmptyState, …), bloc-free. |
| Firebase backend | **Greenfield**: no root `firebase.json`, no `firestore.rules`, no `firestore.indexes.json`, no `functions/`. |

## 3. Execution protocol (context-window-safe — IMPORTANT)

- **Every session starts by reading** [PHASE1_PROGRESS.md](PHASE1_PROGRESS.md) → execute ONLY the
  next unchecked step(s) → run that step's verification → `git commit` → tick the checkbox + add a
  1-line session note. Steps are sized for one session each (≈1 BLoC stack or 1–2 screens max).
  Never start a step that can't finish in the session.
- **Hotspot files** (conflict magnets — edit serially, as the LAST action of a step): both
  `service_locator.dart`, both `app_routes.dart`, l10n files (`locale_base.dart`, `en_us.dart`,
  `hi_in.dart` per app), package barrels, `pubspec.yaml`s.
- **Project skills:** invoke where available — `/backend-skill` (data layers), `/design-system-skill`
  (screens), `/auth-skill` (2FA, role selection), `/payment-skill` (Razorpay), `/search-filter-skill`,
  `/image-processing-skill` (watermark/zoom), `/analytics-skill` (dashboard), `/rating-review-skill`,
  `/security-skill` (rules), `/testing-skill`. Contracts are in CLAUDE.md; follow the same patterns
  if a skill isn't loadable in a session.
- **Mandatory per-feature pattern (CLAUDE.md):** Entity → Model (dual serialization) → DataSource
  (abstract + Firebase impl) → Repository interface → Impl (`Either<Failure,T>`) → UseCases →
  service locator → BLoC → Screen. Presentation never imports Firebase. Design-system components
  only (AppAppBar/AppTextField/AppSnackbar). Every user-visible string via `AppLocalization.strings`
  with keys added to locale_base + en_us + hi_in. Every `Text()` has `maxLines` + `overflow`.
  Light+dark theme from AppTheme, responsive from 320px.

## 4. Data contract summary

Full contract in [FIRESTORE_SCHEMA.md](FIRESTORE_SCHEMA.md). Binding conventions:

- **Money = int paise** (`14900` = ₹149.00). **Dates = ISO-8601 UTC strings** (TTL fields are native
  Timestamps, functions-only).
- Roles `'admin' | 'designer' | 'user'` in `users/{uid}.role`, mirrored to **custom claims** by the
  `onUserWrite` function → rules check `request.auth.token.role` (free, no billed read).
- `orders`, `users/*/purchases`, `stats`, `statsDaily`, `adminOtps`, `counters` are written **only by
  Cloud Functions**.
- All collection names come from `FirestoreCollections` in `shree_krishna_core` — **no string
  literals in either app**. Functions mirror them in `src/config/constants.ts`.
- Fee formula (single source `core/lib/utils/money.dart`, mirrored in functions, parity golden tests):
  `platformFee = round(subtotal*feePct/100)`; `gst = round((subtotal+platformFee)*gstPct/100)`;
  `total = subtotal + platformFee + gst`.

## 5. Steps

### M0 — Foundations (shared packages + Firebase scaffold)

**S0.1 — Project integration docs** *(this commit)*
Create `docs/integration/PHASE1_INTEGRATION_PLAN.md`, `FIRESTORE_SCHEMA.md`, `PHASE1_PROGRESS.md`. Commit.

**S0.2 — Core: constants, enums, utils**
CREATE in `core/lib/`: `constants/firestore_collections.dart` (collection/doc-id consts + callable fn names + region), `constants/storage_paths.dart` (path builder fns), `constants/design_techniques.dart`, `enums/user_role.dart`, `enums/order_status.dart`, `enums/design_status.dart`, `enums/activity_type.dart` (each: value string + fromString), `utils/money.dart` (formatPaise ₹, computeOrderAmounts — THE formula), `utils/keyword_builder.dart`. MODIFY: `core/lib/shree_krishna_core.dart` barrel, `core/pubspec.yaml` (+intl). Tests: `core/test/money_test.dart` golden values. Verify: `flutter analyze && flutter test` in core/.

**S0.3 — Core: catalog models** (pattern = `core/lib/models/user_model.dart`: entity+model one file, fromFirebaseJson(Map,id)/toFirebaseJson/fromApiJson/toApiJson, Equatable, copyWith)
CREATE `core/lib/models/`: `category_model.dart`, `design_model.dart`, `banner_model.dart` (+HomeFeedModel wrapper). MODIFY barrel. Verify analyze+test.

**S0.4 — Core: commerce models**
CREATE `core/lib/models/`: `cart_model.dart` (CartItem — digital goods, NO quantity), `wishlist_model.dart`, `order_model.dart` (+OrderItemModel), `purchase_model.dart`, `review_model.dart`, `platform_settings_model.dart`, `stats_model.dart` (GlobalStats+DailyStats), `activity_model.dart`. MODIFY barrel + `core/lib/cache/cache_config.dart` (TTLs: design 30m, designList 15m, category 24h, homeFeed 30m, config 6h, stats 5m; box names: cart_cache, wishlist_cache, recently_viewed, home_feed_cache, order_list_cache). Verify analyze+test.

**S0.5 — ThemeCubit (core) + admin app wiring + admin Settings screen**
CREATE `core/lib/theme/theme_cubit.dart` (Cubit<ThemeMode>, prefs key `app_theme_mode`, toggle/set persists; core pubspec +flutter_bloc +shared_preferences). Admin: CREATE `lib/screens/settings/admin_settings_screen.dart` (theme toggle, language switcher via existing AppLocalization, version row). MODIFY: admin `service_locator.dart` (ThemeCubit), `main.dart` (BlocBuilder<ThemeCubit,ThemeMode> drives themeMode — replaces non-persisted toggle), `app_routes.dart` (+/settings), dashboard sidebar item, l10n ×3 files (`settings*` keys). Verify: theme survives app restart, language switches live.

**S0.6 — User app theme wiring + Settings screen**
Same trio for `shree_krishna_emb_user_app/`: CREATE `lib/screens/settings/settings_screen.dart`; MODIFY `service_locator.dart`, `main.dart`, `app_routes.dart` (settings route case), `profile_screen.dart` (Settings tile), l10n ×3 at `lib/localisations/locales/`. Verify same.

**S0.7 — Design system additions** (theme-aware, no hardcoded colors; barrel + pubspec +cached_network_image +intl)
CREATE in `design_system/lib/src/components/`: `inputs/app_search_bar.dart` (debounced), `inputs/app_dropdown_field.dart` (AppDropdownField<T>), `inputs/app_date_range_field.dart`, `chips/app_chip.dart` (choice/filter + count badge), `ratings/app_rating_stars.dart` (display fractional + input mode), `images/app_network_image.dart` (CNI + AppShimmer placeholder + error + memCacheWidth), `text/app_price_text.dart` (paise→₹, strikethrough variant), `badges/app_status_badge.dart` (status→color map). Verify: analyze; quick usage in admin settings screen.

**S0.8 — Firebase backend scaffold + deploy rules/indexes**
CREATE at repo root: `firebase.json` (firestore+storage+functions+emulators; per-app flutterfire firebase.json untouched), `.firebaserc`, `firestore.rules` (full rules per contract: claims-based isAdmin, owner checks, purchase-gated reviews, fn-only collections), `firestore.indexes.json` (ALL indexes in schema doc), `storage.rules`. CREATE `functions/`: package.json (node 20, firebase-functions v2, firebase-admin, razorpay, nodemailer, sharp), tsconfig, `src/index.ts` barrel, `src/config/constants.ts` (mirrors FirestoreCollections — comment links Dart file), `src/config/secrets.ts`, skeleton modules (`payments/`, `downloads/`, `media/`, `aggregates/`, `adminAuth/`, `email/`, `utils/`) compiling as no-ops, `scripts/seed.ts` (3 categories, 10 designs, 25 orders, config docs, stats, activity), `scripts/backfillClaims.ts`. Deploy: `firebase deploy --only firestore:rules,firestore:indexes,storage` + emulators boot check.

**S0.9 — Prerequisites checklist (client/console; async, blocks M2/M4 only)**
Document in PROGRESS file + verify: Blaze upgrade; Razorpay TEST account (key_id → config/platform, key_secret + webhook secret → `firebase functions:secrets:set`); webhook URL registered (payment.captured, refund.processed); Gmail app password → SMTP secrets; OTP_PEPPER secret; Service Account Token Creator role on functions runtime SA (signed URLs); Firestore TTL policies on adminOtps.expireAt + activity.expireAt; run seed.ts + backfillClaims.ts (first admin claim).

### M1 — Admin Catalog (`shree_krishna_emb_admin/`)
*Gate demo: admin creates category → publishes watermarked design with EMB file → sets home banner.*

**S1.1 — Category backend**
CREATE: `lib/domain/repositories/category_repository.dart`, `lib/domain/usecases/category_usecases.dart` (grouped: Get/Create/Update/Archive/Delete-if-empty), `lib/data/datasources/firebase_category_datasource.dart` (abstract+impl, FirestoreCollections consts, icon upload), `lib/data/repositories/category_repository_impl.dart`. MODIFY: service_locator. Verify: analyze + unit test repo impl error mapping.

**S1.2 — Category UI**
CREATE: `lib/bloc/category_management/` (bloc+event+state), `lib/screens/category_management/category_management_screen.dart` (responsive table/cards, clone user_management layout, archived filter), `dialogs/category_form_dialog.dart`. MODIFY: app_routes (/categories), sidebar, l10n ×3 (`category*`). Verify: CRUD against emulator, light/dark, 320px.

**S1.3 — Design management backend**
CREATE: `lib/domain/repositories/design_management_repository.dart` (cursor pagination: search prefix/status/category filters; create/update/setStatus/delete; uploadImage→original path; uploadEmbFile→source path; setTrending), `lib/domain/usecases/design_management_usecases.dart`, `lib/data/datasources/firebase_design_management_datasource.dart` (file_picker bytes → putData; writes titleLower + keywords via core KeywordBuilder; status draft + processingStatus pending on create), `lib/data/repositories/design_management_repository_impl.dart`. MODIFY: service_locator, pubspec (+file_picker, +cloud_functions). Verify analyze + tests.

**S1.4 — Watermark pipeline (functions)**
IMPLEMENT `functions/src/media/onDesignAssetUpload.ts` (sharp tiled diagonal "Shree Krishna Embroidery" watermark → preview 1200px + thumb 400px + download tokens → design doc ready/failed). Deploy + verify with manual Storage upload: preview visibly watermarked, doc updated.

**S1.5 — Design list UI**
CREATE: `lib/bloc/design_management/design_list_bloc.dart`+event+state (Get/LoadMore/Search/Filter/SetStatus/SetTrending/Delete), `lib/screens/design_management/design_management_screen.dart` (AppSearchBar + status/category AppChips + paginated responsive table/cards: AppNetworkImage thumb, AppPriceText, AppStatusBadge, trending toggle, processing indicator, action menu). MODIFY: service_locator, app_routes (/designs), sidebar, l10n (`design*` list half). Verify on emulator seed data.

**S1.6 — Design form UI**
CREATE: `lib/bloc/design_form/design_form_bloc.dart`+event+state (Load(id?)/ImagesPicked/EmbFilePicked/Save(asDraft)), `lib/screens/design_management/design_form_screen.dart` (full screen: basics, AppDropdownField category, pricing paise, metadata) + `widgets/design_image_uploader.dart` (progress, processing status), `widgets/emb_file_picker_tile.dart` (.emb/.dst/.pes/.jef whitelist, size cap), `widgets/technique_input_chips.dart`. Publish (status→active) blocked until processingStatus==ready. MODIFY: app_routes (/design-form + Args{designId?}), l10n (`design*` form half). Verify: end-to-end create→processing→ready→publish.

**S1.7 — Featured banners + trending manager**
CREATE: `lib/domain/repositories/home_feed_repository.dart` + usecases, `lib/data/datasources/firebase_home_feed_datasource.dart` (config/homeFeed single doc + banner image upload), impl, `lib/bloc/banner_management/`, `lib/screens/banner_management/banner_management_screen.dart` (banner CRUD ≤10, design/category target picker, active toggle, sort). MODIFY: service_locator, app_routes (/banners), sidebar, l10n (`banner*`). Verify. **M1 gate demo + commit tag.**

### M2 — Admin Ops
*Gate demo: login requires OTP; dashboard live numbers; transactions filter + CSV; fee config saved.*

**S2.1 — 2FA functions**
IMPLEMENT `functions/src/adminAuth/requestAdminOtp.ts` + `verifyAdminOtp.ts` + `email/mailer.ts` (nodemailer Gmail SMTP). Deploy; verify with curl/emulator (cooldown, attempts, expiry).

**S2.2 — 2FA admin UI**
CREATE: `lib/domain/repositories/two_factor_repository.dart` + usecases, `lib/data/datasources/firebase_two_factor_datasource.dart` (callables + prefs verified-at), impl, `lib/bloc/two_factor/`, `lib/screens/login/two_factor_screen.dart` (6-digit boxes, resend countdown, masked email). MODIFY: login flow + splash routing (auth success → OTP unless fresh), AdminAuthBloc signout clears OTP session, app_routes (/two-factor), service_locator, l10n (`twoFactor*`). Verify full login.

**S2.3 — Transactions backend + refund fn**
CREATE: `lib/domain/repositories/transaction_repository.dart` (cursor list: dateRange/status/search; getById; initiateRefund callable), `platform_settings_repository.dart`, usecases ×2, datasources ×2, impls ×2. IMPLEMENT `functions/src/payments/refund.ts` (initiateRefund: razorpay refund + purchases revocation + stats + activity) + webhook refund.processed branch skeleton. MODIFY: service_locator. Verify against seeded orders.

**S2.4 — Transactions + platform settings UI**
CREATE: `lib/bloc/transaction_management/` + `lib/bloc/transaction_detail/` + `lib/bloc/platform_settings/`, `lib/screens/transaction_management/transaction_management_screen.dart` (AppDateRangeField + status chips + search + paginated table/cards + totals row), `transaction_detail_dialog.dart` (breakdown via core money, refund confirm + reason), `lib/screens/platform_settings/platform_settings_screen.dart` (fee%, GST%, invoice prefix, live sample breakdown). MODIFY: routes (/transactions, /platform-settings), sidebar, service_locator, l10n (`transaction*`, `platformSettings*`). Verify filters + refund UI on seed.

**S2.5 — Aggregates functions + dashboard backend**
IMPLEMENT `functions/src/aggregates/`: onUserWrite (claims sync + stats + activity), onDesignWrite, onCategoryWrite, onReviewWrite, stats helpers. Deploy + run backfillClaims. CREATE admin: `lib/domain/repositories/dashboard_repository.dart` (stats/global + statsDaily range + count() aggregates + activity limit 20), usecases, datasource, impl. MODIFY service_locator. Verify: stats move when seeding a user/design.

**S2.6 — Dashboard UI**
CREATE: `lib/bloc/dashboard/`, `lib/screens/dashboard/widgets/kpi_card.dart` (extract existing), `widgets/revenue_chart.dart` (fl_chart from statsDaily), `widgets/activity_feed.dart`. MODIFY: admin_dashboard_screen.dart (replace dummy data with DashboardBloc), pubspec (+fl_chart), l10n (`dashboard*`). Verify numbers match seed math.

**S2.7 — CSV export**
CREATE: `lib/core/utils/csv_exporter.dart`, `lib/core/utils/file_download/download_helper.dart` + `_web.dart` (package:web Blob anchor) + `_io.dart` (share_plus) conditional import. MODIFY: transaction screen + user_management screen (+ExportCsvEvent in blocs, capped 5k rows, progress), pubspec (+csv, +share_plus), l10n (`export*`). Verify CSV opens in Sheets. **M2 gate.**

### M3 — User Shopping (`shree_krishna_emb_user_app/`)
*Gate demo ON DEVICE against TEST project (emulator doesn't enforce composite indexes): browse M1 catalog, search/filter, detail with pinch-zoom, wishlist, signup with role.*

**S3.1 — Catalog data layer**
CREATE: `lib/domain/repositories/catalog_repository.dart` (getHomeFeed, getCategories, getNewArrivals, getTrending, getDesignById, getRelated, suggest, filterDesigns(SearchFilters,cursor), getReviews, getPlatformSettings), `lib/domain/usecases/catalog_usecases.dart`, `lib/data/datasources/firebase_catalog_datasource.dart` (ALL queries filter status=='active'), `lib/data/datasources/local_recently_viewed_datasource.dart` (Hive LRU 20, toApiJson snapshots), `lib/data/repositories/catalog_repository_impl.dart`. MODIFY: service_locator (+box). Verify analyze+tests.

**S3.2 — Home real data**
CREATE: `lib/bloc/home/` (GetHomeContent — Future.wait parallel fetch; Refresh), `lib/screens/home/widgets/`: `design_card.dart` (THE shared card: AppNetworkImage + title + AppPriceText + AppRatingStars + wishlist heart — reused by search/wishlist/related), `home_banner_carousel.dart`, `category_chips_row.dart`, `design_horizontal_list.dart`, `recently_viewed_section.dart`. MODIFY: home_screen.dart (replace dummy sections, AppPullToRefresh, appbar: search/wishlist/cart icons), service_locator, l10n (`home*`). Verify on device.

**S3.3 — Search**
CREATE: `lib/models/search_filters.dart` (priceMin/Max paise, categoryIds, minRating, techniques, sort enum), `lib/bloc/search/` (QueryChanged debounced → suggestions; ApplyFilters; LoadMore; Clear), `lib/screens/search/search_screen.dart` (AppSearchBar autofocus, suggestions, results grid of design_card, sort dropdown), `widgets/filter_drawer.dart` (price RangeSlider, category/technique AppChips, min-rating stars; technique↔text mutual exclusion enforced). MODIFY: routes (/search), home wiring, service_locator, l10n (`search*`). Verify every filter/sort combo on device (index errors surface here).

**S3.4 — Wishlist backend + app-scoped bloc**
CREATE: `lib/domain/repositories/wishlist_repository.dart` + usecases, `lib/data/datasources/firebase_wishlist_datasource.dart` (wishlists/{uid} single doc, cap 100), impl, `lib/bloc/wishlist/` (Watch + Toggle; app-scoped singleton so hearts sync everywhere; stream cancelled in close()). MODIFY: service_locator, main.dart MultiBlocProvider. Verify toggle syncs across screens.

**S3.5 — Design Detail**
CREATE: `lib/bloc/design_detail/` (GetDesignDetail: design + reviews p1 + related, records recently-viewed; LoadMoreReviews), `lib/screens/design_detail/design_detail_screen.dart` (gallery PageView, title/price/rating header, metadata table, description, reviews section, related rail, bottom bar: heart + Add to Cart + Buy Now), `widgets/design_gallery.dart`, `widgets/fullscreen_gallery_screen.dart` (photo_view pinch-zoom on watermarked previews, hero), `widgets/metadata_section.dart`, `widgets/review_tile.dart`, `widgets/related_designs_section.dart`. MODIFY: routes (/design-detail + Args), card taps, service_locator, pubspec (+photo_view), l10n (`designDetail*`, `review*` display). Verify zoom + recently-viewed persistence.

**S3.6 — Wishlist screen + role selection + profile real data**
CREATE: `lib/screens/wishlist/wishlist_screen.dart` (grid of design_card, AppEmptyState), `lib/screens/profile/widgets/designer_coming_soon_sheet.dart`. MODIFY: signup/complete-profile screens (role cards "I want to buy designs" / "I want to sell my work" → users.role, default user; designer → coming-soon sheet, WorkScreen untouched), auth_bloc/event + firebase_auth_datasource (role in payload), profile_screen.dart (real user data via GetUserUseCase, tiles: My Orders, Saved Designs, Settings, Logout), routes (/wishlist), l10n (`wishlist*`, `role*`, `profile*`). Verify signup→Firestore role; profile renders. **M3 gate.**

### M4 — Cart, Payments, Orders
*Gate demo: full Razorpay test purchase → EMB downloads → invoice PDF → review appears → admin refund revokes download.*

**S4.1 — Cart**
CREATE: `lib/domain/repositories/cart_repository.dart` + usecases, `lib/data/datasources/firebase_cart_datasource.dart` (carts/{uid} single doc; already-purchased guard via purchases doc read), impl, `lib/bloc/cart/` (Watch/Add/Remove; app-scoped for badge), `lib/screens/cart/cart_screen.dart` (tiles, breakdown card via core computeOrderAmounts + cached config/platform, Checkout btn). MODIFY: routes (/cart), detail bottom bar + appbar badge, service_locator, l10n (`cart*`). Verify cross-device cart restore.

**S4.2 — Payment functions**
IMPLEMENT `functions/src/payments/`: createRazorpayOrder.ts, verifyPayment.ts, finalizeOrder.ts (shared idempotent core), webhook.ts (raw-body HMAC). Deploy. Verify: unit tests (HMAC known-vector, amount-tamper rejection, idempotent re-verify) + curl happy path with Razorpay test keys.

**S4.3 — Checkout + Razorpay UI**
CREATE: `lib/domain/repositories/checkout_repository.dart` + usecases, `lib/data/datasources/firebase_checkout_datasource.dart` (callables), impl, `lib/core/utils/razorpay_gateway.dart` (thin razorpay_flutter wrapper exposing streams — plugin stays out of bloc), `lib/bloc/checkout/` (StartCheckout(cart|buyNow)/PaymentSucceeded/Failed/Cancelled → CreatingOrder/AwaitingPayment/Verifying/Success/Failed), `lib/screens/checkout/checkout_screen.dart` (AUTHORITATIVE server breakdown render, Pay), `lib/screens/checkout/order_success_screen.dart` (invoice number, Download Now, View Orders). MODIFY: routes (/checkout + Args{buyNowDesignId?}, /order-success), Buy Now + cart wiring, service_locator, pubspec (+razorpay_flutter — Android minSdk≥21 check + proguard), l10n (`checkout*`, `payment*`). Verify: test card success, cancel mid-payment → order stays 'created'.

**S4.4 — Secure download + My Orders**
IMPLEMENT `functions/src/downloads/getDesignDownloadUrl.ts`. CREATE: `lib/domain/repositories/order_repository.dart` (myOrders cursor, getOrder, getDownloadUrl, hasPurchased) + usecases, datasource, impl, `lib/core/utils/file_downloader.dart` (dio → app documents dir — zero permissions; open_filex/share_plus), `lib/bloc/orders/order_list_bloc.dart` + `lib/bloc/order_detail/` (Download(progress)/GenerateInvoice), `lib/screens/orders/my_orders_screen.dart`, `order_detail_screen.dart` (per-item download w/ progress, payment info). MODIFY: routes, profile + success wiring, service_locator, pubspec (+open_filex), l10n (`orders*`, `download*`). Verify: downloaded file byte-identical, URL expires, unauthenticated call rejected.

**S4.5 — Invoice PDF**
CREATE: `lib/core/utils/invoice_pdf_builder.dart` (pdf pkg; bundled NotoSans + NotoSansDevanagari under assets/fonts/; A4: seller block from config/platform, items, fee+GST lines, invoice number; share via printing/share_plus). MODIFY: order detail (Invoice button), pubspec (+pdf +printing, fonts), l10n (`invoice*`). Verify totals match order doc.

**S4.6 — Post-purchase review**
CREATE: `lib/domain/repositories/review_repository.dart` (canReview = purchase exists && !alreadyReviewed; submit upsert to reviews/{uid}) + usecases, datasource, impl, `lib/bloc/review/`, `lib/screens/orders/widgets/review_bottom_sheet.dart` (AppRatingStars input + AppTextField + submit). MODIFY: order detail (Rate button), design detail (Write Review when eligible), service_locator, l10n (`review*` submit). Verify: gated until purchase; aggregate updates on detail (onReviewWrite fn from S2.5).

**S4.7 — Refund e2e + reconciliation**
Wire admin refund (S2.3/S2.4) against a real test payment: refund → webhook refund.processed → order refunded, purchases deleted (download now denied), stats/pendingRefunds correct, activity logged. **M4 gate.**

### M5 — Polish & Hardening

**S5.1 — Audit sweep**: l10n (grep raw string literals in all new screens; every key in 3 locale files per app), dark-mode + 320px pass on every new screen, every Text() has maxLines+overflow.
**S5.2 — States + rules tests**: every list has AppShimmerListSkeleton/AppEmptyState/error+retry; `functions/test/rules.test.ts` with @firebase/rules-unit-testing (owner/admin/anon matrix); fix admin user-list datasource full-collection read → cursor pagination (role+createdAt index exists).
**S5.3 — Release gate**: `flutter analyze` + `flutter test` all 4 packages, functions `npm test`, release builds (admin web build, user app apk), full purchase regression on TEST project, update docs/integration/ docs to "as-built".

---

## 6. Verification (per milestone gates)

- Every step: `flutter analyze` (zero issues) + package tests + manual check listed in the step.
- M1: publish flow leaves correct Storage layout (source/original/public), preview visibly watermarked, keywords present.
- M2: OTP cooldown/lockout, dashboard numbers = seed math, CSV in Sheets, GST config persists.
- M3: ON DEVICE vs TEST project — all filter/sort combos run without index errors; wishlist hearts sync; recently-viewed survives restart.
- M4: Razorpay test card + UPI succeed; cancel leaves order 'created'; signed URL expires ~15 min; refund revokes download; invoice totals correct.
- Emulators: `firebase emulators:start` + seed.ts for M1/M2 dev; `bool useEmulators` flag in each app's app_constants.

## 7. Risks

| Risk | Mitigation |
|---|---|
| Razorpay quirks (signature, cancel callbacks; no web support) | Server-side HMAC only; idempotent finalize + webhook safety net; gateway wrapper isolates plugin; payments mobile-only (admin refunds via callable) |
| Watermark leakage | Watermark server-side at upload; design docs carry ONLY preview URLs; source/original denied in storage rules; downloads only via ownership-checked signed URL |
| Composite index lag | All indexes in firestore.indexes.json deployed at S0.8; M3 verified on TEST project not emulator |
| Client/server fee drift | One formula in core money.dart mirrored in functions + shared golden tests; server breakdown authoritative |
| Context-window resets mid-execution | PHASE1_PROGRESS.md protocol — any session resumes from the tracker |
| Hotspot file conflicts | service_locator/routes/l10n/pubspec edited serially as last action of each step |
| OTP email deliverability | Gmail app-password SMTP (500/day ≫ admin volume); emulator prints mail; kDebugMode-gated bypass code |
| Scope creep (designer/work module) | Frozen to this list; designer path = coming-soon sheet; WorkScreen untouched (Phase 2) |

## 8. New dependencies

- **core:** intl, flutter_bloc, shared_preferences (ThemeCubit)
- **design_system:** cached_network_image, intl
- **admin:** cloud_functions, file_picker, csv, fl_chart, share_plus
- **user app:** cloud_functions, razorpay_flutter, photo_view, pdf, printing, open_filex, share_plus (+dio/path_provider present)
- **functions (npm):** firebase-admin, firebase-functions v2, razorpay, nodemailer, sharp
- **dev (apps+core):** bloc_test, mocktail
