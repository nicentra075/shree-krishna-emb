# Phase E — Future: designer self-service + Blaze single-call (design notes)

> Not built now — captured so Phases A–D stay forward-compatible. See [00-OVERVIEW.md](00-OVERVIEW.md).

**Goal (future):** Designers manage their own Collections / Categories / Designs (subject to admin approval), and the user app fetches the whole Home in a single network call via a Cloud Function — with **no changes** to the user-app UI/blocs because the `HomeFeed` contract is identical.

## Why it's already easy to add

- **`ownerId` / `ownerType`** are on `collections`, `categories`, `designs` from Phase A. Today everything is `ownerId: 'platform'`. Designers simply write their own `uid`.
- **`status`** field already exists on designs (and can be added to collections/categories): designer writes land as `pending`; admin flips to `active`.
- **The home feed contract** (`HomeFeed`/`HomeSection`/`HomeItem`) is the same whether resolved client-side (now) or by a function (later) — only `HomeFeedDataSource` swaps behind `HomeFeedRepository`.

## E1 — Designer self-service (catalog ownership)

- **Rules** ([firestore.rules](../../firestore.rules)):
  - `collections`/`categories`/`designs`: add `allow create, update: if isDesigner() && request.resource.data.ownerId == request.auth.uid && request.resource.data.status == 'pending';` (admin retains full write + the `active` transition).
  - Designers can only edit their own docs; only admin sets `status: 'active'`.
- **Admin app:** a moderation queue (reuse the `approval-workflow-skill`) listing `pending` designer content → approve/reject (sets `status`).
- **User app:** designer self-service screens (My Store → Collections → Categories → Designs) reuse the **same** catalog datasource/repository, scoped by `ownerId == currentUid`. The designer store page reuses `SectionRenderer` with a designer-scoped feed.

## E2 — Blaze single-call (`getHomeFeed`)

- **Function:** `functions/src/home/getHomeFeed.ts` — a callable that reads `config/homeFeed`, resolves every section server-side (Admin SDK), and returns the resolved `HomeFeed` JSON in **one** response. Pin region (asia-south1) per `functions/src/config/constants.ts`.
- **User app:** add `ApiHomeFeedDataSource` implementing `HomeFeedDataSource` that calls the function; swap the registration in `service_locator.dart`. No UI/bloc/repository-interface changes.
- **Benefit:** true single network round-trip + fewer client reads; centralised resolution (e.g. personalisation, A/B layout) becomes possible.
- **Also unblocks** the original sequential-userId counter and admin-set-password flows that were deferred on Spark (see project history) — same Blaze upgrade.

## E3 — Related future enhancements (optional)

- Firebase Storage image upload (replace URL fields) via the `image-processing-skill` + `AppImagePicker`.
- A public `sellers` collection mirroring only public store fields (avoids exposing designer email/phone, which the current authorised-seller read rule does — see the note in `firestore.rules`).
- Aggregated counters (`designCount`, `popularity`) maintained by Firestore-trigger functions instead of client writes.

## Acceptance (when built)
- [ ] A designer creates a design → it's `pending` → admin approves → it appears in the user app.
- [ ] Designers cannot self-approve or edit others' content (emulator rule tests).
- [ ] Swapping to `ApiHomeFeedDataSource` changes only DI; Home renders identically in one call.
