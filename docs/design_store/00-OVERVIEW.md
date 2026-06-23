# Design Store → Server-Driven Home Screen — Overview

> Master doc for the Design Store module. Each phase has its own file with a tickable checklist. Build phases **in order** — each is independently shippable. Follow the cross-cutting rules in every UI task.

## Why

The user app Home ([home_screen.dart](../../shree_krishna_emb_user_app/lib/screens/home/home_screen.dart)) is hardcoded. We want it **fully dynamic and admin-configurable** from the Admin panel **Design Store** menu (already wired as `_selectedSection == 'store'`, currently falling through to the dashboard in [admin_dashboard_screen.dart](../../shree_krishna_emb_admin/lib/screens/dashboard/admin_dashboard_screen.dart)).

Admin defines an **ordered list of sections** (add / remove / reorder / enable), binds each to a **content source**, and the user app fetches the layout **once per visit** and renders it, with per-section **"View All"**. Content is **Collections → Categories → Designs**. The model carries `ownerId` from day one so **designers can own stores** in a future phase without a rewrite.

## Approach — Server-Driven UI (SDUI)

- One Firestore doc `config/homeFeed` holds an ordered `sections[]`.
- Each section has a `type` (how to render) and a `source` (what to pull).
- The user app loads the config once, resolves each section's items, and renders via a `type → widget` map (`SectionRenderer`).
- **One fetch:** on Spark (no Cloud Functions) it's one **client-side load cycle** (config doc + parallel section queries) behind `HomeFeedRepository`; on Blaze a `getHomeFeed` callable returns the identical JSON in one network call — only the datasource swaps.

## Decisions (baked in)

| Topic | Decision |
| --- | --- |
| Single-call | Client aggregation now (Spark); function-ready later (identical contract) |
| Categories | Flat `categories/{id}` with a `collectionId` field |
| Recently viewed | Per-user **local** (Hive) list of design ids, resolved to designs on load |
| Images | **URL** fields, rendered via `AppNetworkImage` (cached). Storage upload is a later add-on |
| `finalPrice` | Computed + stored on write: `isFree ? 0 : price - discountAmount` |
| Launch section types | banner, authorisedSellersHorizontal, designsHorizontal, designsVertical, collectionsGrid, categoriesHorizontal, recentlyViewed |
| Docs | This `docs/design_store/` master + per-phase files |

## Phase map

| Phase | File | Outcome |
| --- | --- | --- |
| A | [PHASE-A-content-domain.md](PHASE-A-content-domain.md) | Collections/Categories/Designs data layer + admin CRUD (Design Store content tab) |
| B | [PHASE-B-home-layout.md](PHASE-B-home-layout.md) | `config/homeFeed` + admin "Home Layout" configurator (reorder/add/remove/enable/bind source) |
| C | [PHASE-C-userapp-sdui.md](PHASE-C-userapp-sdui.md) | User-app one-fetch engine + `SectionRenderer` + Hive cache + pull-to-refresh |
| D | [PHASE-D-viewall-detail.md](PHASE-D-viewall-detail.md) | Per-section View All screens + design detail screen |
| E | [PHASE-E-future-designer.md](PHASE-E-future-designer.md) | (Future) designer self-service + Blaze `getHomeFeed` |

## Firestore data model

### `config/homeFeed` (one document — the layout)
```jsonc
{
  "version": 3,                 // bump on each save; client compares for cache invalidation
  "updatedAt": "2026-06-16T...",
  "sections": [
    { "id": "banner-1", "type": "banner", "title": null, "enabled": true, "position": 0,
      "viewAll": { "enabled": false, "target": null },
      "source": { "kind": "manual", "items": [
        { "imageUrl": "https://...", "label": "Limited Edition",
          "title": "Exclusive Collections", "ctaTarget": "collection:coll_123" } ] } },
    { "id": "sellers-1", "type": "authorisedSellersHorizontal", "title": "Authorised Sellers",
      "enabled": true, "position": 1, "viewAll": { "enabled": true, "target": "sellers" },
      "source": { "kind": "authorisedSellers", "limit": 12 } },
    { "id": "trending-1", "type": "designsHorizontal", "title": "Trending Designs",
      "enabled": true, "position": 2, "viewAll": { "enabled": true, "target": "designs?sort=popularity" },
      "source": { "kind": "query", "collectionId": null, "categoryId": null,
        "sort": "popularity", "onlyActive": true, "limit": 10 } },
    { "id": "saree-1", "type": "designsVertical", "title": "Saree Designs", "position": 3,
      "viewAll": { "enabled": true, "target": "category:cat_saree" },
      "source": { "kind": "category", "categoryId": "cat_saree", "limit": 6 } },
    { "id": "collections-1", "type": "collectionsGrid", "title": "Explore Collections", "position": 4,
      "viewAll": { "enabled": true, "target": "collections" },
      "source": { "kind": "query", "limit": 8 } },
    { "id": "recent-1", "type": "recentlyViewed", "title": "Recently Viewed", "position": 5,
      "viewAll": { "enabled": false }, "source": { "kind": "recentlyViewed", "limit": 10 } }
  ]
}
```
`type` ∈ `banner | authorisedSellersHorizontal | designsHorizontal | designsVertical | collectionsGrid | categoriesHorizontal | recentlyViewed` (additive).
`source.kind` ∈ `manual | query | collection | category | authorisedSellers | recentlyViewed`.

### `collections/{id}`
```jsonc
{ "id": "coll_123", "name": "Bridal Collection", "description": "...", "imageUrl": "https://...",
  "ownerId": "platform", "ownerType": "platform", "isActive": true, "position": 0,
  "designCount": 0, "createdAt": "..." }
```

### `categories/{id}` (flat, with `collectionId`)
```jsonc
{ "id": "cat_saree", "collectionId": "coll_123", "name": "Saree", "imageUrl": "https://...",
  "isActive": true, "position": 0, "createdAt": "..." }
```

### `designs/{id}` (extends existing `designs`)
```jsonc
{ "id": "dsn_1", "name": "Golden Peacock Mandala", "code": "GPM-001",
  "images": ["https://...", "https://..."], "authorId": "platform", "authorName": "Shree Krishna",
  "description": "...", "price": 1249, "discountAmount": 0, "isFree": false, "finalPrice": 1249,
  "colorOrNeedleCount": "9 needle", "designFormat": "DST", "stitchCount": 12000,
  "height": 120, "width": 90, "collectionId": "coll_123", "categoryId": "cat_saree",
  "status": "active", "popularity": 0, "createdAt": "..." }
```

## Home feed contract (app-side — identical for client aggregation now or function later)

```dart
class HomeFeed { final int version; final List<HomeSection> sections; }
class HomeSection {
  final String id; final HomeSectionType type;   // enum, 1:1 with SectionRenderer cases
  final String? title, subtitle; final HomeViewAll viewAll; final List<HomeItem> items;
}
// HomeItem polymorphic family:
//   BannerItem{imageUrl,label,title,ctaTarget}  SellerItem{uid,displayName,storeImageUrl}
//   DesignItem{id,name,finalPrice,isFree,firstImageUrl,tierLabel}
//   CollectionItem{id,name,imageUrl}            CategoryItem{id,name,imageUrl}
```
`SectionRenderer` maps `type → widget`; unknown/empty → `SizedBox.shrink()` (forward-compatible).

## Reuse map (don't reinvent)

| Need | Reuse | Path |
| --- | --- | --- |
| Admin feature template | User Management (list+bloc+datasource+repo+dialogs) | `shree_krishna_emb_admin/lib/{screens/user_management,bloc/user_management,data,domain}` |
| In-memory cache + forceRefresh + invalidate | `FirebaseUserListDataSource` | `.../data/datasources/firebase_user_list_datasource.dart` |
| Design Store entry point | `case 'store':` in `_buildContent()` | `admin_dashboard_screen.dart` (~L94) |
| Cached image / price / dropdown / search / empty / pull-refresh / image-url preview | `AppNetworkImage`, `AppPriceText`, `AppDropdownField`, `AppSearchBar`, `AppEmptyState`, `AppPullToRefresh`, `AppImagePicker` | `design_system` (exported) |
| Reorder UI | Material `ReorderableListView` | — |
| User-app Hive cache (TTL via `CachedData`+`CacheConfig`) | `local_user_datasource.dart` | `shree_krishna_emb_user_app/lib/data/datasources/` |
| User-app routing + `BuildContext` nav extension | `AppRoutes` | `shree_krishna_emb_user_app/lib/routes/app_routes.dart` |
| Sellers section (already built) | `AuthorisedSellersCubit`, `SellerRepository` | `shree_krishna_emb_user_app/lib/{bloc/sellers,domain,data}` |
| Either/Failure/Exception | `shree_krishna_core` | `errors/*`, `utils/either.dart` |
| Admin snackbar / strings / theme | `ResponsiveSnackbar`, `AppLocalization.strings`, `colorScheme` | — |

## Cross-cutting rules (apply to EVERY UI task)

- **Theme-aware:** colors from `Theme.of(context).colorScheme`; verify dark mode. Never hardcode `Colors.white`/`AppTheme.textDark` for surfaces/body text.
- **Localized:** all user-visible strings via `AppLocalization.strings` (en_US + hi_IN). Admin strings live in `lib/l10n/`, user app in `lib/localisations/`.
- **Design system:** `AppTextField`, `AppButton`, `AppAppBar`, `AppDropdownField`, `AppNetworkImage`, `AppEmptyState`; admin notifications via `ResponsiveSnackbar(message, context)` (never `AppSnackbar`/`ScaffoldMessenger`).
- **Responsive + overflow-safe:** every `Text` has `maxLines` + `TextOverflow.ellipsis`; flexible widths; horizontal-scroll/`Wrap` for wide tables.
- **Errors:** caught errors logged via `AppLogger.logError(message, error:, stackTrace:)` before converting to `Failure`.
- **Cost:** in-memory cache for admin lists (mirror user-list datasource); Hive cache for the home feed; Home does ONE load cycle.

## Global verification

`flutter analyze` clean in `shree_krishna_emb_admin`, `shree_krishna_emb_user_app`, and `design_system` after every phase. Per-phase end-to-end checks live in each phase doc.
