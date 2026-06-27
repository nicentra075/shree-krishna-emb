# Push Notification Module — Design Spec

- **Date:** 2026-06-27
- **Status:** Approved design (decisions locked) → ready for implementation plan
- **Scope:** Admin app (`shree_krishna_emb_admin`) + User app (`shree_krishna_emb_user_app`) + shared `shree_krishna_core` package + Cloud Functions (`functions/`)
- **Surfaces:** FCM push (device) + in-app notification inbox (Firestore-backed)

---

## 1. Goals & requirements mapping

### Admin app
| # | Requirement | Solution |
|---|---|---|
| A1 | Show an in-app notification when **any user purchases** an item (free or paid) | `onOrderFinalized` Cloud Function writes an `admin_notifications` doc on order → paid. Admin app has a notification bell + inbox screen (real-time Firestore). **In-app only, no FCM to admins.** |
| A2 | A settings section to **configure / enable** Firebase push notifications | New "Notifications" settings tab (replaces the current "Coming Soon" placeholder) writing to `config/notifications`: master toggle, per-type toggles, and up-to-4 daily send-slot times. Credentials handled automatically by the Admin SDK — nothing to paste. |
| A3 | Send a **global notification to all platform users** at once | Broadcast composer → `broadcastNotification` callable: FCM to topic `all_users` + batched fan-out of inbox docs to every user. |

### User app
| # | Requirement | Solution |
|---|---|---|
| U1 | When a **new design is added**, push to users ("new design added — explore"); **max 4/day**, with **admin-configured timing** | `sendNewDesignDigest` scheduled function: runs every ~30 min, fires only at admin-configured `dailySlots` (≤4), sends **one digest push** per slot covering designs activated since the last slot. |
| U2 | List all notifications in a **notification screen** reached from a home **bell icon**, with **unread count** | `users/{uid}/notifications` subcollection → `NotificationCubit` streams it; bell badge shows unread count; `NotificationsScreen` lists items. |
| U3 | **Mark all read** + **delete** options in that screen | Cubit `markAllRead()` + `delete(id)` / swipe-to-delete. |
| U4 | **Notification handler**: tapping a notification navigates to the **specific design screen**, whether app is **open or closed** | `NotificationService` handles foreground / background / terminated via `onMessage` (local notification) + `onMessageOpenedApp` + `getInitialMessage`; deep-links through `GlobalNavigator.navigatorKey` → `AppRoutes.navigateToDesignDetail(designId)`. |
| U5 | **Only logged-in users** receive notifications | FCM token is registered + topic `all_users` subscribed on `AuthAuthenticated`; token deleted + topic unsubscribed + inbox cleared on logout. |

---

## 2. Locked decisions

1. **New-design push = scheduled digest.** Admin sets up to 4 daily slot times; one digest push per slot summarising designs activated since the previous slot. Cap of 4/day is structural (≤4 slots).
2. **Admin purchase alerts = in-app admin inbox only.** No FCM to admins. Real-time Firestore listener + unread badge.
3. **In-app inbox = per-user fan-out.** Each notification is a doc under `users/{uid}/notifications`. Broadcasts/digests fan out via batched Cloud Function writes.
4. **Admin FCM settings = toggles + schedule, credentials automatic.** `config/notifications` holds toggles + `dailySlots`. Cloud Functions use the Firebase Admin SDK default service account — no FCM key entry.

### Derived design decisions
- **Admin app does NOT depend on `firebase_messaging`.** It only *sends* (via the existing `cloud_functions` callable) and *reads* its inbox over Firestore.
- **FCM tokens live in a subcollection** `users/{uid}/fcm_tokens/{token}` (doc id = token → automatic dedupe; supports multiple devices; clean per-token lifecycle).
- **No new secrets.** `config/secrets` stays untouched; FCM uses default Admin SDK credentials.
- **Admin identity = `isAdmin()`** custom claim (`request.auth.token.role == 'admin'`) with `users/{uid}.role` fallback — reused verbatim from existing rules and applied in the broadcast callable.

---

## 3. Architecture overview

```
                       ┌───────────────────────── Cloud Functions (v2, asia-south1) ─────────────────────────┐
                       │                                                                                       │
  Admin app            │   broadcastNotification (onCall, admin-guarded)                                       │
  ─ Settings ────────► │       └─► FCM topic "all_users"  +  fan-out users/{uid}/notifications (batched)       │
  ─ Broadcast composer │                                                                                       │
  ─ Admin inbox  ◄─────│   onOrderFinalized (onDocumentWritten orders/{id})                                    │
        ▲ (Firestore)  │       └─► write admin_notifications/{id}      (NO fcm)                                 │
        │              │                                                                                       │
        │              │   sendNewDesignDigest (onSchedule ~30m)                                               │
        │              │       └─ reads config/notifications.dailySlots; at a due slot:                        │
        │              │            query designs activated since cursor ─► FCM topic "all_users"              │
        │              │            + fan-out users/{uid}/notifications                                        │
        │              │                                                                                       │
        │              │   onDesignWritten (onDocumentWritten designs/{id})  [robustness helper]               │
        │              │       └─ stamps activatedAt when status first becomes "active"                        │
        │              └───────────────────────────────────────────────────────────────────────────────────┘
        │
  User app
  ─ NotificationService (FCM): permission, token reg/refresh, foreground/bg/terminated handlers
  ─ register token + subscribe "all_users" on login; delete + unsubscribe on logout
  ─ NotificationCubit streams users/{uid}/notifications → bell badge + NotificationsScreen
  ─ tap → deep-link to DesignDetailScreen(designId)
```

---

## 4. Data model (Firestore)

All new collection/doc names go into `core/lib/constants/firestore_collections.dart` and are mirrored in `functions/src/config/constants.ts`.

### 4.1 `config/notifications` (single doc) — written by Admin app
```jsonc
{
  "masterEnabled": true,            // global kill-switch for all push
  "purchaseAlertsEnabled": true,    // admin purchase inbox alerts (A1)
  "newDesignAlertsEnabled": true,   // user new-design digests (U1)
  "dailySlots": ["10:00","14:00","18:00","21:00"], // ≤4 "HH:mm" 24h, tz-local
  "timezone": "Asia/Kolkata",
  "newDesignCursor": "<ISO ts>",    // last design activatedAt covered by a digest
  "firedSlots": { "2026-06-27": ["10:00","14:00"] }, // slots already fired per day (cap guard)
  "updatedAt": "<ISO ts>",
  "updatedBy": "<adminUid>"
}
```

### 4.2 `users/{uid}/fcm_tokens/{token}` (doc id = token) — written by User app
```jsonc
{ "token": "<fcmToken>", "platform": "android|ios|web", "createdAt": "<ts>", "lastSeenAt": "<ts>" }
```

### 4.3 `users/{uid}/notifications/{id}` — written by Cloud Functions, mutated by owner
```jsonc
{
  "type": "newDesign|purchase|broadcast",
  "title": "New designs just dropped ✨",
  "body": "3 new designs added — tap to explore",
  "imageUrl": "<thumbUrl|null>",
  "data": { "designId": "<id|null>", "route": "design" },  // deep-link payload
  "read": false,
  "createdAt": "<ts>"
}
```

### 4.4 `admin_notifications/{id}` (top-level, shared admin feed) — written by Cloud Functions
```jsonc
{
  "type": "purchase",
  "title": "New purchase",
  "body": "Lotus Motif — ₹149 by Asha R.",
  "data": { "orderId": "<id>", "designId": "<id>", "userId": "<uid>" },
  "readBy": ["<adminUid>"],   // few admins → array membership = read state
  "createdAt": "<ts>"
}
```

> Admins are few, so a single shared feed with a `readBy` array is cheaper and simpler than per-admin fan-out. Unread = admin uid not in `readBy`.

---

## 5. Shared `shree_krishna_core` additions

Follow the existing dual-serialization pattern (see `platform_settings_model.dart`, `design_model.dart`): an `Entity extends Equatable` + a `Model extends Entity` with `fromFirebaseJson` / `toFirebaseJson` / `fromApiJson` / `toApiJson` / `fromEntity`.

- `core/lib/enums/app_notification_type.dart` — `enum AppNotificationType { newDesign, purchase, broadcast }` with `fromString`/`value` (mirror the `DesignStatus.fromString` pattern).
- `core/lib/models/app_notification_model.dart` — `AppNotificationEntity` + `AppNotificationModel` for §4.3 inbox items (used by **both** apps; admin feed reuses the same shape minus `read`).
- `core/lib/models/notification_settings_model.dart` — `NotificationSettingsEntity` + `NotificationSettingsModel` for §4.1 (`config/notifications`).
- `core/lib/constants/firestore_collections.dart` — add:
  - `configNotificationsDoc = 'notifications'` (→ `config/notifications`)
  - `fcmTokens = 'fcm_tokens'` (subcollection of users)
  - `userNotifications = 'notifications'` (subcollection of users)
  - `adminNotifications = 'admin_notifications'` (top-level)
- `functions/src/config/constants.ts` — mirror into `Collections` (`fcmTokens`, `userNotifications`, `adminNotifications`) and `Docs` (`configNotifications: "notifications"`); add `NotificationType` const.

> The `UserModel` is **not** modified — tokens live in a subcollection, and "logged-in only" is enforced by token lifecycle, not a user flag. (YAGNI: no per-user notification-preference fields in this iteration.)

---

## 6. Cloud Functions (`functions/src/notifications/`)

All use the existing v2 API (`firebase-functions/v2`), `asia-south1`, shared `db` from `functions/src/lib/firebase.ts`. Add `export const messaging = getMessaging();` (from `firebase-admin/messaging`) to `functions/src/lib/firebase.ts`. Export all new functions from `functions/src/index.ts`.

### 6.1 `messaging.ts` (helpers)
- `sendToTopic(topic, {title, body, imageUrl, data})` — FCM topic send.
- `fanOutInbox(notification, {filter?})` — page through `users` (status/active filter as needed), `BulkWriter` or batched `set` (≤500/batch) writing one `users/{uid}/notifications` doc each. Returns recipient count.
- `pruneInvalidTokens(uid, failedTokens)` — delete `fcm_tokens` FCM reports `messaging/registration-token-not-registered`.

### 6.2 `broadcastNotification` (`onCall`, admin-guarded) — A3
- Guard: `request.auth.token.role === 'admin'` else `db.doc(users/{uid}).get().data().role === 'admin'`; throw `HttpsError('permission-denied')` otherwise.
- If `config/notifications.masterEnabled === false` → throw `failed-precondition`.
- Validate `title`/`body` (non-empty, length caps).
- `sendToTopic('all_users', {type:'broadcast', title, body})` **and** `fanOutInbox({type:'broadcast', title, body})`.
- Return `{ recipientCount }`.
- **Scale note:** fan-out is batched and paginated; for very large user bases, move fan-out to a Cloud Tasks queue (logged as a follow-up, not in this iteration).

### 6.3 `onOrderFinalized` (`onDocumentWritten("orders/{orderId}")`) — A1
- Fire only on transition **into** a finalized state (`before.status !== 'paid' && after.status === 'paid'`). Reuses existing `OrderStatus.paid`.
- If `config/notifications.purchaseAlertsEnabled === false` → return.
- Build body from order items (`designId`, title/`name`, `totalAmount`, buyer name).
- Write one `admin_notifications/{id}` doc. **No FCM.**
- Separate trigger so payment logic in `finalizeOrder.ts` stays untouched. Handles free items too (status still reaches `paid`/finalized for ₹0 orders).

### 6.4 `sendNewDesignDigest` (`onSchedule`, every 30 min) — U1 (the timing engine)
The admin-editable slot times can't be a static cron, so we poll and gate:
```
read config/notifications  → settings
if !masterEnabled || !newDesignAlertsEnabled: return
now = current time in settings.timezone
today = YYYY-MM-DD (in tz)
firedToday = settings.firedSlots[today] ?? []
dueSlot = the latest slot in settings.dailySlots whose time <= now and not in firedToday
if no dueSlot: return
if firedToday.length >= 4: return                 // hard cap guard
designs = query designs where status=='active' && activatedAt > newDesignCursor
          order by activatedAt asc                 // (fallback: createdAt, see §11)
if designs empty:
    mark dueSlot fired (so we don't re-check every 30m) and return  // no spam
count = designs.length; newest = designs.last
title/body = digest copy ("N new designs added — explore now")
imageUrl = newest.thumbUrl ?? newest.previewUrl ?? newest.images?[0]
deepLink data = { route:'design', designId: newest.id }   // newest design (or new-arrivals)
sendToTopic('all_users', ...) ; fanOutInbox(...)
transaction: set newDesignCursor = newest.activatedAt ; append dueSlot to firedSlots[today]
```
- Old `firedSlots` day keys are pruned opportunistically (keep today only).
- Cron cadence (30 min) is an implementation knob; finer cadence = tighter slot accuracy.

### 6.5 `onDesignWritten` (`onDocumentWritten("designs/{id}")`) — robustness helper for U1
- When `status` first becomes `'active'` (and `activatedAt` not yet set), stamp `activatedAt = serverTimestamp()`.
- Guarantees draft→active designs are caught by the digest cursor even though `createdAt` predates activation.
- Idempotent (skip if `activatedAt` already set or status unchanged).

---

## 7. User app (`shree_krishna_emb_user_app`)

### 7.1 Dependencies (`pubspec.yaml`)
- `firebase_messaging` (compatible with `firebase_core ^4.8.0`)
- `flutter_local_notifications` (foreground display + tap routing on Android/iOS)

### 7.2 `main.dart`
- Top-level `@pragma('vm:entry-point') Future<void> _fcmBackgroundHandler(RemoteMessage m)` registered via `FirebaseMessaging.onBackgroundMessage(...)` **before** `runApp`.
- After `setupServiceLocator(prefs)`: initialize `NotificationService` (channel creation, permission request deferred to post-login).

### 7.3 `data/services/notification_service.dart`
- `requestPermission()`, `getToken()`, `onTokenRefresh` stream.
- Foreground `FirebaseMessaging.onMessage` → show a `flutter_local_notifications` banner carrying `data`.
- Tap routing for all three states:
  - **Foreground:** local-notification tap callback → `_route(data)`.
  - **Background (resumed):** `FirebaseMessaging.onMessageOpenedApp` → `_route(data)`.
  - **Terminated (cold start):** `FirebaseMessaging.instance.getInitialMessage()` consumed once after auth + navigator are ready → `_route(data)`.
- `_route(data)` → `GlobalNavigator.navigatorKey…` → `AppRoutes.navigateToDesignDetail(data['designId'])` (guard for null/empty).

### 7.4 Data layer (clean architecture, `Either<Failure, T>`)
- `firebase_fcm_token_datasource.dart` — `registerToken(uid, token, platform)` (set `users/{uid}/fcm_tokens/{token}`), `deleteToken(uid, token)`.
- `firebase_notifications_datasource.dart` — `watch(uid)` (stream ordered by `createdAt desc`), `markRead(uid,id)`, `markAllRead(uid)`, `delete(uid,id)`, derive `unreadCount`.
- Repositories + abstract interfaces in `domain/repositories/`, impls in `data/repositories/`.

### 7.5 `bloc/notifications/notification_cubit.dart` (singleton)
- State: `{ status, List<AppNotificationModel> items, int unreadCount }`.
- `start(uid)` subscribes to the Firestore stream; `stop()` cancels (called on logout, and in `close()`).
- `markAllRead()`, `delete(id)` delegate to repo.

### 7.6 Auth integration (U5)
- Listen to `AuthBloc`: on `AuthAuthenticated` → `requestPermission()`, register token, `subscribeToTopic('all_users')`, `NotificationCubit.start(uid)`, then consume `getInitialMessage()`.
- On logout / `AuthUnauthenticated` → `deleteToken`, `unsubscribeFromTopic('all_users')`, `NotificationCubit.stop()` + clear.

### 7.7 UI
- `screens/notifications/notifications_screen.dart` — `AppAppBar(title)`, list (unread highlighted), **Mark all read** action, **Delete**/swipe-to-dismiss, `AppEmptyState`, tap → deep-link. All `Text` widgets get `maxLines` + `overflow: TextOverflow.ellipsis`; responsive per project standards.
- `screens/main/main_screen.dart` — wire the existing `_buildNotificationAction()` bell: badge bound to `NotificationCubit.unreadCount` (hide at 0, "9+" cap), `onTap` → `Navigator.pushNamed(AppRoutes.notifications)` (replace the `// TODO`).
- `routes/app_routes.dart` — add `notifications` route + `navigateToNotifications`.
- Register `NotificationCubit` as a singleton in `service_locator.dart` and provide it in `MainApp`'s `MultiBlocProvider`.

---

## 8. Admin app (`shree_krishna_emb_admin`)

No `firebase_messaging`. Uses existing `cloud_functions` for the broadcast callable.

### 8.1 Notification settings (A2)
- Replace the "Coming Soon" content in `settings_content_view.dart` (Notifications tab) with a form: master toggle, purchase-alerts toggle, new-design toggle, and up-to-4 time-slot pickers (add/remove, ≤4) + timezone (default `Asia/Kolkata`).
- `data/datasources/firebase_notification_settings_datasource.dart` — read/write `config/notifications` via `NotificationSettingsModel`.
- Repository + interface; `bloc/settings/notification_settings_cubit.dart` (load/save with `Either` fold) registered in `service_locator.dart`.

### 8.2 Broadcast composer (A3)
- Dialog/screen: `AppTextField` title + body, "Send to all users" `AppButton`, confirm step.
- Calls `broadcastNotification` via `FirebaseFunctions.instanceFor(region:'asia-south1').httpsCallable('broadcastNotification')`; result/error via `ResponsiveSnackbar(message, context)`.
- `BroadcastCubit` for submit state.

### 8.3 Admin notification inbox (A1)
- Bell + unread badge in the dashboard app bar (`admin_dashboard_screen.dart`).
- `screens/notifications/admin_notifications_screen.dart` — real-time list of `admin_notifications`, mark-read (append uid to `readBy`), delete; tap → order/design detail where available.
- `data/datasources/firebase_admin_notifications_datasource.dart` (stream/markRead/delete) + repo + `AdminNotificationsCubit` (singleton) registered in `service_locator.dart`.

---

## 9. Security rules (`firestore.rules`)

Add inside the existing `service cloud.firestore` block (reusing `isAuthed()`, `isAdmin()`, `isOwner(uid)`):

```
// config/notifications — admin-managed; user app does not read it
match /config/notifications {
  allow read:  if isAdmin();
  allow write: if isAdmin()
    && request.resource.data.dailySlots is list
    && request.resource.data.dailySlots.size() <= 4;
}

// FCM tokens — owner-only
match /users/{uid}/fcm_tokens/{tokenId} {
  allow read: if isOwner(uid) || isAdmin();
  allow create, update, delete: if isOwner(uid);
}

// User inbox — created by functions; owner mutates read/delete
match /users/{uid}/notifications/{id} {
  allow read:   if isOwner(uid) || isAdmin();
  allow create: if false;                                 // functions only
  allow update: if isOwner(uid)
    && request.resource.data.diff(resource.data).affectedKeys().hasOnly(['read']);
  allow delete: if isOwner(uid);
}

// Admin shared feed — created by functions; admin mutates readBy/delete
match /admin_notifications/{id} {
  allow read:   if isAdmin();
  allow create: if false;                                 // functions only
  allow update: if isAdmin()
    && request.resource.data.diff(resource.data).affectedKeys().hasOnly(['readBy']);
  allow delete: if isAdmin();
}
```

> Cloud Functions write inbox/admin docs via the Admin SDK, which bypasses rules — so `create: if false` for clients is correct.

---

## 10. Firestore indexes (`firestore.indexes.json`)

- `designs`: composite `status (ASC) + activatedAt (ASC)` — digest query. (Add `activatedAt` field; see §11.)
- Collection-group / subcollection `notifications`: `createdAt (DESC)` (single-field; usually auto, declare if the console requires it for the ordered stream).
- `admin_notifications`: `createdAt (DESC)`.

---

## 11. Open items / flags for implementation

1. **`name` vs `title` schema split.** `firestore.rules` (line 98) requires `name` on `designs` create, while core `DesignModel` serialises `title`. The digest + purchase functions must read defensively: `design.name ?? design.title`, image `thumbUrl ?? previewUrl ?? images?.[0]`. Reconciling the two schemas is **out of scope** here but must be tracked; the notification functions only need read-tolerance.
2. **`activatedAt` field.** Not present today. `onDesignWritten` (§6.5) introduces it; until backfilled, the digest falls back to `createdAt > cursor && status == 'active'`. A one-time backfill (set `activatedAt = createdAt` for existing active designs) is recommended before first digest run.
3. **Digest cron cadence** (30 min) vs slot precision — confirm acceptable lag (≤30 min after a slot time).
4. **Web push (admin/user on web).** FCM web requires a VAPID key + service worker; this spec targets mobile FCM first. User-app-web push is a follow-up (the in-app inbox still works on web via Firestore).

---

## 12. Error handling

- All repositories return `Either<Failure, T>` and fold to states (existing pattern).
- FCM permission denied → degrade gracefully: in-app inbox still works; no crash.
- Token write failures are non-fatal (logged, retried on next `onTokenRefresh`).
- Server-side invalid-token pruning keeps the token set clean.
- Offline: Firestore cache serves the inbox; broadcast callable failure surfaces a snackbar.
- Idempotency: `onOrderFinalized` and `onDesignWritten` guard on state transitions to avoid duplicate notifications.

---

## 13. Testing strategy

- **Pure logic (unit):** digest "due-slot + cap + cursor" selection (extract as a pure function), fan-out batching/chunking, model serialization round-trips (`AppNotificationModel`, `NotificationSettingsModel`), repository `Either` fold mapping.
- **Functions (emulator):** `onOrderFinalized` transition → admin doc; `broadcastNotification` admin-guard + fan-out count; `sendNewDesignDigest` cursor advance + cap; `onDesignWritten` `activatedAt` stamping.
- **Widget:** notification center (list/empty/mark-all/delete), bell badge count, admin settings form validation (≤4 slots).
- **Manual e2e:** create design → digest at slot → push → tap (foreground/background/terminated) → design detail; purchase → admin inbox; broadcast → user inbox + push; logout → no further notifications.

---

## 14. Phasing (→ implementation plan)

- **P0 — Foundations:** core enums/models/constants; mirror TS constants; `firestore.rules` blocks; indexes; `activatedAt` + backfill note. *(no behaviour yet)*
- **P1 — User FCM plumbing:** deps, `NotificationService`, background handler, token register/unregister on auth, topic subscribe. *Verify: token doc lands in Firestore on login; deleted on logout.*
- **P2 — User in-app inbox:** datasources/repos/`NotificationCubit`, `NotificationsScreen`, bell badge, deep-link routing, localization.
- **P3 — Cloud Functions:** `messaging.ts`, `broadcastNotification`, `onOrderFinalized`, `onDesignWritten`, `sendNewDesignDigest`; export + deploy.
- **P4 — Admin app:** notification settings tab (config/notifications), broadcast composer, admin inbox + bell, localization.
- **P5 — Integration & tests:** e2e walkthrough, unit/widget/function tests, edge cases (draft→active, free purchase, cap).

---

## 15. Out of scope (future)

- Per-user notification preferences / quiet hours / category mutes.
- Email notifications.
- FCM web push (VAPID/service worker).
- Cloud Tasks queue for very-large-base fan-out (note in §6.2).
- Rich notification actions / images on web.
