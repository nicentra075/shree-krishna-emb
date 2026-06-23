# Phase A — Content domain (Collections / Categories / Designs) + admin CRUD

> Foundation phase. Everything else needs content to show. Build the data layer + the admin **Design Store** content management UI. See [00-OVERVIEW.md](00-OVERVIEW.md) for the data model, reuse map, and cross-cutting rules.

**Goal:** Admin can create/edit/delete Collections, collection-scoped Categories, and Designs (with all spec fields), stored in Firestore and readable by the user app (active only).

**Template to copy:** User Management feature (list + bloc + datasource + repository + dialogs) and the in-memory cache datasource pattern.

## Files

### Admin app — domain
- [ ] `lib/domain/entities/collection.dart` — `CollectionEntity {id, name, description, imageUrl, ownerId, ownerType, isActive, position, designCount, createdAt}`
- [ ] `lib/domain/entities/category.dart` — `CategoryEntity {id, collectionId, name, imageUrl, isActive, position, createdAt}`
- [ ] `lib/domain/entities/design.dart` — `DesignEntity {id, name, code, images:List<String>, authorId, authorName, description, price:int, discountAmount:int, isFree:bool, finalPrice:int, colorOrNeedleCount, designFormat, stitchCount:int, height:int, width:int, collectionId, categoryId, status, popularity:int, createdAt}`
- [ ] `lib/domain/repositories/catalog_repository.dart` — interface, all methods return `Either<Failure, T>`

### Admin app — data
- [ ] `lib/data/models/collection_model.dart` — dual serialization (`fromFirebaseJson`/`toFirebaseJson` + `fromApiJson`/`toApiJson`)
- [ ] `lib/data/models/category_model.dart` — dual serialization
- [ ] `lib/data/models/design_model.dart` — dual serialization; `toFirebaseJson` writes computed `finalPrice = isFree ? 0 : price - discountAmount`; tolerant int parsing (num→int, string→int)
- [ ] `lib/data/datasources/firebase_catalog_datasource.dart` — abstract + `FirebaseCatalogDataSource`. In-memory cache + `forceRefresh` + `_invalidateCache()` on every mutation (mirror `firebase_user_list_datasource.dart`)
- [ ] `lib/data/repositories/catalog_repository_impl.dart` — maps `ServerException → ServerFailure`, else `UnknownFailure`; logs via `AppLogger.logError`

### Admin app — bloc
- [ ] `lib/bloc/design_store/collections_bloc.dart` (+ `_event.dart`, `_state.dart`)
- [ ] `lib/bloc/design_store/categories_bloc.dart` (+ event/state) — load is scoped by `collectionId`
- [ ] `lib/bloc/design_store/designs_bloc.dart` (+ event/state) — filters: collection, category, status, search, page size; reuse the "restore list on error" pattern

### Admin app — screens
- [ ] `lib/screens/design_store/design_store_content_view.dart` — top-level tabbed view (Collections | Categories | Designs | [Phase B: Home Layout]); embedded in the dashboard content area like `SettingsContentView`
- [ ] `lib/screens/design_store/collections_view.dart` — list + add/edit dialog (name, description, image URL, isActive, position)
- [ ] `lib/screens/design_store/categories_view.dart` — collection picker → category list + add/edit dialog (name, image URL, isActive, position)
- [ ] `lib/screens/design_store/designs_view.dart` — list (User-ID-style table desktop / cards mobile) + filters
- [ ] `lib/screens/design_store/dialogs/design_edit_dialog.dart` — ALL design fields: images (URL list add/remove), name, code, author name, description, price, discountAmount, isFree (toggle → disables price/discount, finalPrice=0), **read-only finalPrice preview**, colorOrNeedleCount, designFormat, stitchCount, height, width, **collection picker → category picker (filtered by selected collection)**, status dropdown. URL validation for images; numeric validation for price/stitch/size.

### Admin app — wiring
- [ ] `lib/core/di/service_locator.dart` — register `CatalogDataSource`, `CatalogRepository` (singletons) and the 3 blocs (per-screen via `BlocProvider`)
- [ ] `lib/screens/dashboard/admin_dashboard_screen.dart` — add `case 'store': return const DesignStoreContentView();` in `_buildContent()`
- [ ] `lib/l10n/locales/locale_base.dart` + `en_us.dart` + `hi_in.dart` — add Design Store strings (collections, categories, designs, addCollection, storeName fields, price, discount, finalPrice, stitchCount, etc.)

### Shared
- [ ] `firestore.rules` — add:
  - `match /collections/{id} { allow read: if isAuthed(); allow create,update,delete: if isAdmin(); }`
  - `match /categories/{id} { allow read: if isAuthed(); allow create,update,delete: if isAdmin(); }`
  - extend existing `designs` admin-write validation to allow the new fields (keep `price is int`, allow `isFree` path)
- [ ] `firestore.indexes.json` — add when the query errors point you to them: `designs (status,collectionId,finalPrice)`, `(status,categoryId,createdAt)`, `(status,popularity)`; `categories (collectionId,position)`

## Task checklist (suggested order)
- [ ] A1 — entities + models + serialization unit tests (round-trip; finalPrice computation; isFree → finalPrice 0)
- [ ] A2 — catalog datasource (CRUD + cache + forceRefresh + invalidate) with fake-firestore tests
- [ ] A3 — repository + DI registration
- [ ] A4 — three blocs + bloc_test (load/create/update/delete, loader + restore-on-error)
- [ ] A5 — Design Store screens + design dialog (theme-aware, localized, responsive, `ResponsiveSnackbar`); wire `case 'store'`
- [ ] A6 — rules + indexes + emulator rule tests

## Acceptance
- [ ] Admin → Design Store shows Collections/Categories/Designs tabs.
- [ ] Create a collection → create a category in it → create a design bound to both; design dialog computes finalPrice live; isFree zeroes price.
- [ ] User app (or emulator query) reads only `status == 'active'` designs and `isActive` collections/categories.
- [ ] `flutter analyze` clean (admin + design_system); dark mode verified; strings localized; lists overflow-safe.
