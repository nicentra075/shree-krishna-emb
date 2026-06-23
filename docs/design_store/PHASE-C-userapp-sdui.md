# Phase C — User-app SDUI engine (one fetch + render + refresh)

> The user app fetches the layout once, resolves each section's content, renders via a `type → widget` map, caches it (Hive), and supports pull-to-refresh. Depends on Phases A + B. See [00-OVERVIEW.md](00-OVERVIEW.md) for the home feed contract.

**Goal:** Open Home → ONE load cycle resolves all sections → render. Pull-to-refresh re-fetches. Offline shows the cached feed. Changing the admin config and refreshing updates the Home.

**Package:** `shree_krishna_emb`. Reuse the already-built `AuthorisedSellersCubit`/`SellerRepository` for the sellers section, the Hive `CachedData`/`CacheConfig` pattern, and `AppNetworkImage`/`AppPullToRefresh`.

## Files

### User app — domain
- [ ] `lib/domain/entities/home_feed.dart` — `HomeFeed {version, sections}`; `HomeSection {id, type:HomeSectionType, title, subtitle, viewAll:HomeViewAll, items:List<HomeItem>}`; `HomeSectionType` enum; sealed `HomeItem` family (`BannerItem`, `SellerItem`, `DesignItem`, `CollectionItem`, `CategoryItem`); `HomeViewAll {enabled, target}`
- [ ] `lib/domain/repositories/home_feed_repository.dart` — `Future<Either<Failure, HomeFeed>> load({bool forceRefresh})`

### User app — data
- [ ] `lib/data/models/home_feed_model.dart` — parse `config/homeFeed`: drop `enabled == false`, sort by `position`, map `type`/`source` strings to enums/config; unknown `type` → skipped
- [ ] `lib/data/datasources/firebase_home_feed_datasource.dart` — `getHomeFeed({forceRefresh})`:
  1. read `config/homeFeed` (one doc read)
  2. for each enabled section, resolve `source.kind → items` via **parallel `Future.wait`**:
     - `manual` → banners inline (no read)
     - `authorisedSellers` → reuse seller datasource query
     - `query`/`collection`/`category` → designs/collections/categories query (with sort + limit + onlyActive)
     - `recentlyViewed` → read ids from local box, fetch those designs
  3. return a fully-resolved `HomeFeed`
- [ ] `lib/data/datasources/local_home_feed_cache.dart` — Hive box `home_feed_cache`; store the resolved feed JSON + `version` using the `CachedData`/`CacheConfig` pattern from `local_user_datasource.dart`
- [ ] `lib/data/datasources/local_recently_viewed_store.dart` — append/read recently-opened design ids (capped list) in a Hive box; written from the design detail screen (Phase D)
- [ ] `lib/data/repositories/home_feed_repository_impl.dart` — cache-first: return cached feed if fresh; `forceRefresh` bypasses; on success update cache

### User app — bloc
- [ ] `lib/bloc/home_feed/home_feed_cubit.dart` (+ state) — states `HomeFeedInitial/Loading/Loaded(feed)/Error`; `load()` (cache-first, called once on screen open), `refresh()` (forceRefresh for pull-to-refresh)

### User app — screens
- [ ] `lib/screens/home/widgets/section_renderer.dart` — `Widget render(HomeSection)` switching on `HomeSectionType`; reuse the existing builders refactored to take data:
  - `banner` → carousel (existing `_buildHeroBanner` logic, data-driven)
  - `authorisedSellersHorizontal` → existing seller card row (data-driven; tap → Phase D)
  - `designsHorizontal` → existing trending card row (data-driven `DesignItem`)
  - `designsVertical` → existing saree-style vertical list
  - `collectionsGrid` → existing collections grid
  - `categoriesHorizontal` → new chip/card row
  - `recentlyViewed` → existing recently-viewed row
  - unknown/empty → `SizedBox.shrink()`
  - section header shows `title` + a "View All" button when `viewAll.enabled`
- [ ] `lib/screens/home/home_screen.dart` — **modify**: wrap content in `BlocProvider(create: getIt<HomeFeedCubit>()..load())`; replace the hardcoded `Column` of section builders with `RefreshIndicator`/`AppPullToRefresh` (→ `refresh()`) over a `ListView`/`Column` of `SectionRenderer.render(section)`; keep loading (shimmer) / empty / error states. Remove the now-dead hardcoded builders (or keep them as the data-driven versions used by `SectionRenderer`).

### User app — wiring
- [ ] `lib/core/di/service_locator.dart` — open `home_feed_cache` box; register `HomeFeedDataSource`, `HomeFeedRepository` (singletons) + `HomeFeedCubit` (factory); register recently-viewed store

## Task checklist
- [ ] C1 — home feed contract entities + enums + HomeItem family
- [ ] C2 — `home_feed_model.dart` config parser (disabled dropped, sorted, unknown-type skipped) + unit test
- [ ] C3 — `firebase_home_feed_datasource.dart` parallel resolver + tests (each source kind)
- [ ] C4 — Hive cache + repository (cache-first / forceRefresh) + test
- [ ] C5 — `HomeFeedCubit` + bloc_test (load once, refresh)
- [ ] C6 — `SectionRenderer` (data-driven section widgets) + widget tests
- [ ] C7 — wire `home_screen.dart` (BlocProvider + pull-to-refresh + states) + DI

## Acceptance
- [ ] Home opens → all configured sections render from ONE load cycle (verify read count via logs).
- [ ] Edit the admin Home Layout → pull-to-refresh on Home → updated layout appears.
- [ ] Disabled sections don't render; reordering in admin changes the Home order.
- [ ] Airplane mode → Home shows the cached feed.
- [ ] `flutter analyze` clean (user app + design_system); responsive + localized.
