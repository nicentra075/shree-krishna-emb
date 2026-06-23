# Phase B — Home layout configurator (`config/homeFeed` + admin UI)

> Admin builds and orders the Home sections and binds each to a content source. Depends on Phase A (so source pickers have collections/categories to choose). See [00-OVERVIEW.md](00-OVERVIEW.md) for the `config/homeFeed` schema.

**Goal:** Under Design Store → **Home Layout**, an admin can add/remove/reorder/enable sections and edit each section's title + source, then Save — persisting to `config/homeFeed`.

## Files

### Admin app — domain
- [ ] `lib/domain/entities/home_section.dart` — `HomeSectionConfig {id, type, title, subtitle, enabled, position, viewAll:HomeViewAll, source:HomeSource}`; `HomeViewAll {enabled, target}`; `HomeSource {kind, ...optional fields}` (manual items, collectionId, categoryId, sort, onlyActive, limit)
- [ ] `lib/domain/repositories/home_config_repository.dart` — `Future<Either<Failure, HomeFeedConfig>> read()`, `Future<Either<Failure, void>> save(HomeFeedConfig)`

### Admin app — data
- [ ] `lib/data/models/home_feed_config_model.dart` — `HomeFeedConfig {version, updatedAt, sections}` + `HomeSectionConfigModel`; `fromFirebaseJson`/`toFirebaseJson`; `HomeFeedConfig.defaultConfig()` factory returning the 6 launch sections from the overview
- [ ] `lib/data/datasources/firebase_home_config_datasource.dart` — `read()` returns `config/homeFeed` (seed + return `defaultConfig()` if the doc is missing); `save(config)` writes with `version+1` and `updatedAt`
- [ ] `lib/data/repositories/home_config_repository_impl.dart`

### Admin app — bloc
- [ ] `lib/bloc/design_store/home_layout_bloc.dart` (+ event/state) — events: `LoadLayout`, `AddSection(type)`, `RemoveSection(id)`, `ReorderSections(oldIndex,newIndex)`, `ToggleSection(id)`, `EditSection(updatedSection)`, `SaveLayout`. State holds working `sections` + `dirty` flag.

### Admin app — screens
- [ ] `lib/screens/design_store/home_layout_view.dart` — added as a tab in `DesignStoreContentView`:
  - `ReorderableListView` of section cards: drag handle, `Switch` (enabled), type chip, title, edit + delete buttons. `onReorder` → `ReorderSections`.
  - **Add Section** via `AppBottomSheet`: pick a `type`, then a per-type **source editor**:
    - `banner` → list editor of `{imageUrl, label, title, ctaTarget}` (add/remove rows)
    - `authorisedSellersHorizontal` → limit field + viewAll toggle
    - `designsHorizontal` / `designsVertical` / `collectionsGrid` → `query` builder: optional collection picker → category picker (reuse Phase-A blocs), sort (`AppDropdownField`: popularity/newest/priceAsc/priceDesc), `onlyActive`, limit; or `collection`/`category` kind via the pickers
    - `categoriesHorizontal` → collection picker + limit
    - `recentlyViewed` → limit
    - All editors: `viewAll {enabled, target}` toggle + target field
  - **Save** button → `SaveLayout`; success via `ResponsiveSnackbar`.

### Admin app — wiring
- [ ] `lib/core/di/service_locator.dart` — register `HomeConfigDataSource`, `HomeConfigRepository`, `HomeLayoutBloc`
- [ ] `lib/l10n/locales/*` — Home Layout strings (addSection, reorder, sectionType labels, source, viewAll, save, etc.)

### Shared
- [ ] `firestore.rules` — relax `config/homeFeed` write: `allow write: if isAdmin() && request.resource.data.sections is list && request.resource.data.sections.size() <= 50;`

## Task checklist
- [ ] B1 — HomeFeedConfig entity + model + `defaultConfig()` + round-trip test
- [ ] B2 — datasource (read/seed/save with version bump) + repository + DI
- [ ] B3 — `HomeLayoutBloc` + bloc_test (add/remove/reorder/toggle/edit/save → dirty + persistence)
- [ ] B4 — `home_layout_view.dart` reorderable list + add-section sheet + per-type source editors (theme-aware, localized, responsive)
- [ ] B5 — relax `config/homeFeed` rule + emulator test (admin-only write; >50 sections rejected)

## Acceptance
- [ ] Admin reorders / adds / removes / toggles / edits sections and Saves → re-opening Home Layout shows the persisted order from `config/homeFeed`.
- [ ] A non-admin cannot write `config/homeFeed` (emulator rule test).
- [ ] Section source editors only offer valid collections/categories (pulled from Phase-A blocs).
- [ ] `flutter analyze` clean; dark mode + localized + responsive.
