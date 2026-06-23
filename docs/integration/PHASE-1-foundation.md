# Phase 1 — Foundation, polish & content tooling

**Runs on:** Firebase Spark (free). No Cloud Functions. Firebase Storage used (free tier).
**Goal:** Fix the dark-mode bug, add the quick wins, and give the admin real image management.

---

## 1.1 Admin logout confirmation  *(admin)*

**Why:** Logout currently fires immediately with no confirm.

- [ ] Wrap admin logout (`admin_dashboard_screen.dart`, the `AdminSignOutEvent` trigger ~L484)
      in an `AlertDialog` (themed, localized): title "Log out?", body "You'll need to sign in
      again.", Cancel / Log out.
- [ ] Add strings `logoutConfirmTitle`, `logoutConfirmMessage` (en_US + hi_IN).
- [ ] Log out only on confirm.

**Acceptance:** Clicking Logout shows a confirm; Cancel keeps session; Confirm signs out.

---

## 1.2 Dark mode fix (theme-aware refactor)  *(user app)*

**Root cause (confirmed):** Theme STATE works (toggle → `ThemeCubit` → `MaterialApp.themeMode`
→ real `AppTheme.darkTheme`). Screens **hardcode light colors** (`Colors.white`,
`AppTheme.primaryLight`, `AppTheme.surfaceLight`, `AppTheme.textDark`, …) so nothing visibly
changes. ~19 files / ~116 occurrences under `lib/screens`.

**Fix:** Drive every surface/text/icon color from `Theme.of(context).colorScheme` (and the
adaptive `AppTextStyles`). Work in waves; test each in light + dark.

- [ ] Wave A (most visible): `home_screen.dart`, `home/widgets/section_renderer.dart`,
      `catalog/view_all_screen.dart`, `catalog/design_detail_screen.dart`
- [ ] Wave B: `auth/*` (login, signup, otp, forgot, complete_profile), `splash`, `walkthrough/*`
- [ ] Wave C: `profile/*`, `settings/*`, remaining screens
- [ ] Replace hardcoded colors with `colorScheme.surface/onSurface/primary/...`; keep brand
      accents via theme extension if needed (don't reintroduce `*Light` constants in screens)
- [ ] Verify `AppAppBar` / bottom nav / cards adapt (design_system components)
- [ ] Add a CI/grep guard: fail if `Colors.white` or `*Light`/`textDark` appear in `lib/screens`

**Acceptance:** Toggling dark mode in the Account section visibly switches the whole app
(backgrounds, text, cards, app bars) and persists across restart.

---

## 1.3 Home screen shimmer  *(user app)*

- [ ] Replace the initial `AppLoader` (circular) in `home_screen.dart` with `AppShimmer`
      skeletons that mirror the section layout (banner block, a horizontal row of design cards,
      a collections grid).
- [ ] Build a `HomeShimmer` widget (banner + 2 section skeletons); show while
      `HomeFeedStatus.loading/initial`.
- [ ] Keep shimmer theme-aware (works in dark mode).

**Acceptance:** First load shows shimmer placeholders, not a spinner; smooth swap to content.

---

## 1.4 Favorites (wishlist) end-to-end  *(user app)*

**Reuse:** `WishlistModel` + `wishlists/{uid}` + rules (exist). Missing = repo + cubit + UI.

- [ ] `domain/repositories/wishlist_repository.dart` (+ impl) — `Either<Failure, …>`
- [ ] `data/datasources/firebase_wishlist_datasource.dart` (read/write `wishlists/{uid}`),
      cache-first (Hive) like recently-viewed
- [ ] `bloc/wishlist/wishlist_cubit.dart` — `load()`, `toggle(designId, …)`, `isFavorite(id)`,
      `remove(id)`; optimistic update; `isClosed` guards
- [ ] Register repo/datasource/cubit in `service_locator.dart`; open Hive box
- [ ] Heart icon (filled/outline) on: design cards in `section_renderer.dart`,
      `view_all_screen.dart`, and the **design detail** screen → add/remove
- [ ] New **My Favorites** screen (reuse the design grid card; empty state via `AppEmptyState`)
- [ ] Entry point from Profile/Account menu + route in `app_routes.dart`
- [ ] Strings (en_US + hi_IN): `favorites`, `addedToFavorites`, `removedFromFavorites`,
      `noFavoritesYet`

**Acceptance:** Tap heart on any design → appears in My Favorites; tap again → removed;
survives app restart and offline (cached).

---

## 1.5 Image upload → Firebase Storage  *(admin)*

**Why:** Collections/categories/designs are URL-only today. Storage is free on Spark.

- [ ] Add `firebase_storage` to admin `pubspec.yaml`; init in Storage rules (`storage.rules`)
      — admin write, public read for catalog images
- [ ] `data/datasources/firebase_image_storage_datasource.dart` — `upload(file, path)`,
      `delete(url)`, returns download URL; compress before upload (reuse image-processing if present)
- [ ] Replace URL `AppTextField` in collection/category dialogs with an **image picker + preview
      + upload progress**; keep manual-URL as a fallback option
- [ ] Design dialog: **multi-image** upload (designs have `images[]`) — add/reorder/remove
- [ ] Store the resulting download URL(s) in the existing model fields (no schema change)
- [ ] Strings + theme-aware UI

**Acceptance:** Admin can upload an image from disk; preview shows; URL saved; image renders in
user app.

---

## 1.6 Media Library (asset gallery)  *(admin)*

**Why:** Centralized assets — upload many at once, reuse, edit, delete; pick at create/edit time.

- [ ] Decide store: Firebase Storage folder `media/` + a `media/{id}` Firestore index doc
      (name, url, path, width/height, sizeBytes, uploadedBy, createdAt, usedBy[])
- [ ] `MediaRepository` + datasource (list, multi-upload, replace, delete)
- [ ] `MediaLibraryCubit` (paginated list, upload queue with progress, delete)
- [ ] **Media Library screen / dialog**: grid of thumbnails, multi-select upload (one shot),
      replace, delete, search by name
- [ ] **Picker mode**: open the library from the collection/category/design dialogs to pick an
      existing asset instead of re-uploading
- [ ] **Drag & drop** (web/desktop, `desktop_drop`): drop many images onto the library at once
      to upload them in one shot
- [ ] Theme-aware, localized, responsive grid; `maxLines`/`ellipsis`

**Acceptance:** Admin uploads 5 images at once; they appear in the library; can pick one when
creating a category; can replace/delete from the library.

---

## 1.5b Image model (decided during build)

- All image uploads (single + multi + Media Library) go to the **Media Library** (`media/`),
  so every uploaded image is reusable and shows up in the library.
- The "Add image" control opens a **chooser** with 3 options: Upload from device · Add image
  URL · Choose from Library.
- **Web display requires bucket CORS** (Flutter web CanvasKit fetches images via `fetch()`):
  ```
  gsutil cors set storage.cors.json gs://<your-bucket>
  ```
  Without this, uploaded Storage images render as broken on the web admin. Also deploy rules:
  `firebase deploy --only storage,firestore:rules`.
- Because images are now shared library assets, deleting a collection/category/design no longer
  deletes the image (it may be reused elsewhere) — manage/delete images in the Media Library.

## 1.7 Delete Storage images on delete  *(admin)*

**Why:** Avoid orphaned Storage files; ties into the cascade-delete already built.

- [ ] On delete collection/category/design (incl. cascade), delete the associated Storage
      object(s) for that item (and its children in cascade)
- [ ] If an image came from the Media Library and is still used elsewhere (`usedBy` > 1),
      do NOT delete the file — just unlink. Plain item images (not library-managed) are deleted.
- [ ] Best-effort: a Storage delete failure must not block the Firestore delete (log via
      `AppLogger.logError`); surface a soft warning
- [ ] Update `cascade_delete_dialog` note to mention images are removed too

**Acceptance:** Deleting a design removes its Storage image(s); deleting a collection with
cascade removes its categories', designs', and their images; shared library assets are preserved.

---

## 1.8 Design detail image gallery — dots + full-screen viewer  *(user app)*

**Why:** Multi-image designs need a page indicator and a zoomable full-screen viewer.

- [ ] In `catalog/design_detail_screen.dart`, add **dot indicators** under the image
      `PageView` when `images.length > 1` (active/inactive dots, theme-aware)
- [ ] Make each image tappable → push a **full-screen image viewer** screen
- [ ] `screens/catalog/image_viewer_screen.dart`: full-screen `PageView` of all images,
      starts at the tapped index, swipeable, with dots/counter (e.g. "2 / 5"), pinch-to-zoom
      (use `photo_view` if available, else `InteractiveViewer`), close button, black backdrop
- [ ] Route in `app_routes.dart` (args: `{images, initialIndex}`); `AppNetworkImage`/cached
- [ ] Single-image designs: no dots; tap still opens the viewer
- [ ] Strings if any (e.g. counter format) localized; `maxLines`/`ellipsis` where text appears

**Acceptance:** A design with multiple images shows dots; tapping opens full-screen; user can
swipe through all images and pinch-zoom; counter/dots update; close returns to detail.

---

## Phase 1 exit criteria
- [ ] Dark mode visibly works across the user app and persists
- [ ] Home shows shimmer on first load
- [ ] Favorites add/remove + My Favorites screen work and persist
- [ ] Admin can upload/replace/delete images and use the Media Library
- [ ] Deleting items cleans up their Storage files (shared assets preserved)
- [ ] Admin logout asks for confirmation
- [ ] Design detail shows image dots + tappable full-screen swipeable viewer
- [ ] `flutter analyze` clean in both apps + `design_system`; manual dark/light pass
