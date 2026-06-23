# Phase D — View All screens + design detail

> Each home section's "View All" opens a full, paginated list; tapping a design opens a detail screen with all fields. Depends on Phase C. See [00-OVERVIEW.md](00-OVERVIEW.md).

**Goal:** Tap a section's "View All" → paginated list of that source's items; tap a design (anywhere) → detail screen showing every field, image gallery, and price/discount/final.

**Package:** `shree_krishna_emb`. Reuse `AppNetworkImage`, `AppPriceText`, `AppEmptyState`, `AppShimmer`, and the routing helpers in `app_routes.dart`.

## Files

### User app — data
- [ ] `lib/data/datasources/firebase_catalog_query_datasource.dart` — **paginated** (cursor / `startAfterDocument`) queries:
  - designs by `{collectionId?, categoryId?, sort, onlyActive}` with page cursor
  - collections (active), categories (active, by collectionId), authorised sellers
- [ ] `lib/domain/entities/` + `lib/data/models/` — reuse/port the design/collection/category/seller entities from the contract (a shared `catalog` entity set; can mirror admin Phase-A entities)
- [ ] `lib/domain/repositories/catalog_query_repository.dart` + impl (`Either<Failure, Page<T>>` where `Page {items, nextCursor, hasMore}`)

### User app — bloc
- [ ] `lib/bloc/view_all/view_all_cubit.dart` (+ state) — `loadFirst(target)`, `loadMore()`; states Initial/Loading/Loaded(items,hasMore)/LoadingMore/Error

### User app — screens
- [ ] `lib/screens/catalog/view_all_screen.dart` — takes a `ViewAllArgs` parsed from `viewAll.target`:
  - `sellers` → seller grid/list
  - `collections` → collections grid
  - `category:<id>` / `collection:<id>` → designs in that category/collection
  - `designs?sort=<popularity|newest|priceAsc|priceDesc>` → all designs sorted
  - infinite scroll (`loadMore` near the end); `AppEmptyState` when empty; shimmer while loading
- [ ] `lib/screens/catalog/design_detail_screen.dart` — image gallery (`AppNetworkImage`, swipe through `images`), name, code, author, description, `AppPriceText` for price/discount/finalPrice (or "Free"), colorOrNeedleCount, designFormat, stitchCount, height×width, collection + category names. On open, append the design id to the recently-viewed store (Phase C). (Buy/cart hook is out of scope here — leave a clear extension point.)

### User app — wiring
- [ ] `lib/routes/app_routes.dart` — add `viewAll` + `designDetail` routes (named, with args) + `navigateToViewAll(target)` / `navigateToDesignDetail(id)` helpers and the `BuildContext` extension methods
- [ ] `lib/screens/home/widgets/section_renderer.dart` — wire section "View All" buttons → `navigateToViewAll(section.viewAll.target)`; wire design/seller/collection/category item taps → detail / view-all; wire banner `ctaTarget` (`collection:<id>` etc.)

## Task checklist
- [ ] D1 — paginated catalog-query datasource + repository (`Page<T>`) + tests
- [ ] D2 — `ViewAllCubit` (loadFirst/loadMore) + bloc_test
- [ ] D3 — `view_all_screen.dart` (target parsing, infinite scroll, empty/loading) + widget test
- [ ] D4 — `design_detail_screen.dart` (gallery + all fields + recently-viewed write)
- [ ] D5 — routes + nav helpers + wire taps in `SectionRenderer` + banner CTA

## Acceptance
- [ ] Each section's "View All" opens the correct paginated list; scrolling loads more.
- [ ] Tapping a design opens detail with every field + image gallery + correct price/discount/final (or "Free").
- [ ] Opening a design adds it to Recently Viewed (visible on Home after refresh).
- [ ] Banner CTA navigates to its `ctaTarget`.
- [ ] `flutter analyze` clean; responsive + localized + theme-aware.
