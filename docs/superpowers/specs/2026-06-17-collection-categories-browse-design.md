# Collection → Categories → Designs browse flow (User App)

**Date:** 2026-06-17
**App:** `shree_krishna_emb_user_app`
**Status:** Approved design, pending implementation

## Goal

When a user taps a Collection (from the Home "New Collections" section **or** the
"Explore Collections" screen), open a screen listing that collection's
**Categories**. Tapping a Category shows the **Designs** in it. Tapping a Design
opens the existing Design Detail screen.

## Current state

- Tapping a collection emits the target string `collection:<id>` from both entry
  points:
  - Home: `section_renderer.dart` → `onNavigate('collection:${c.id}')`
  - Explore Collections grid: `view_all_screen.dart:113` →
    `navigateToViewAll('collection:${c.id}')`
- `collection:<id>` currently loads **designs** directly
  (`_ds.designs(collectionId: id)`), skipping categories.
- `ViewAllScreen` **already** renders `CategoryItem` tiles whose `onTap`
  navigates to `category:<id>` (`view_all_screen.dart:117-120`).
- `category:<id>` **already** loads designs (`_ds.designs(categoryId: id)`).
- `design:<id>` **already** opens Design Detail.

Data model supports the hierarchy: `Category.collectionId` references the parent
collection; `Design.collectionId` / `Design.categoryId` reference both.
Query methods `categories({collectionId})` and `designs({categoryId})` exist.

## Approach (chosen)

**Repurpose the existing `collection:<id>` target** to show the collection's
categories instead of its designs. This requires **no call-site changes and no
new route/screen** — both entry points already point at `collection:<id>`, and
the category → designs → detail chain already works.

### Behavior

In `ViewAllScreen._load()`, the `collection:<id>` branch becomes:

```
final id = t.substring('collection:'.length);
final cats = await _ds.categories(collectionId: id);
items = cats.isNotEmpty
    ? cats                                  // show categories grid
    : await _ds.designs(collectionId: id);  // FALLBACK: no categories → designs
```

- **Categories present:** render the category grid (already implemented). Tapping
  a category → `category:<id>` → designs grid → design detail.
- **No categories (fallback):** show the collection's designs directly, so the
  user never hits a dead end. (Chosen behavior.)

### Title = collection name

The categories screen title shows the actual collection name (e.g.
"Bridal Collection"), for both the categories grid and the designs fallback.

- Add `Future<CollectionItem?> collectionById(String id)` to
  `CatalogQueryDataSource` (single Firestore doc read — no N+1).
- In `ViewAllScreen`, when target is `collection:<id>`, resolve the name via
  `collectionById(id)` and use it as the app-bar title. Fall back to a localized
  generic title if the lookup returns null.
- Convert `_title` from a pure getter to a state field set during `_load()`
  (it now depends on async data).

## Files touched

1. `lib/data/datasources/firebase_catalog_query_datasource.dart`
   — add `collectionById(String id)` (interface + Firebase impl).
2. `lib/screens/catalog/view_all_screen.dart`
   — `collection:<id>` loads categories with designs fallback; resolve + show
     collection name as title.
3. `lib/localisations/locales/locale_base.dart`, `en_us.dart`, `hi_in.dart`
   — add a generic fallback title string (e.g. `categories`) used only when the
     collection name can't be resolved.

## Out of scope

- No new BLoC, route, model, or dedicated screen.
- No changes to the designs grid or design-detail screen (reused as-is).
- Admin app unchanged.

## Verification

- Tap a collection with categories → categories grid titled with collection name.
- Tap a category → its designs → tap a design → detail.
- Tap a collection with **no** categories → its designs directly (titled with
  collection name).
- Both Home "New Collections" and "Explore Collections" entry points behave
  identically.
- `flutter analyze` clean; design-system + localization rules respected
  (AppAppBar, AppLocalization, overflow-safe text already in place).
