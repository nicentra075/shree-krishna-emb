# Push Notification Module Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship FCM push + in-app notifications across the admin and user apps: admin gets purchase-alert inbox + a notification settings panel + broadcast-to-all; users get scheduled "new design" digests (≤4/day, admin-timed), an in-app notification center with unread count / read-all / delete, and tap-to-deep-link routing in any app state — logged-in users only.

**Architecture:** Shared `shree_krishna_core` carries the notification model/enum/constants used by both Flutter apps. Cloud Functions (v2, `asia-south1`) own all sends: a broadcast callable, an order-finalized trigger (admin inbox), a design-write trigger (stamps `activatedAt`), and a polling scheduler that fires admin-configured daily digest slots. The user app receives FCM + streams its `users/{uid}/notifications` subcollection; the admin app sends via the callable and streams `admin_notifications`.

**Tech Stack:** Flutter (flutter_bloc/Cubit, GetIt, Equatable, Either), Firebase (Firestore, Auth, FCM via `firebase_messaging` + `flutter_local_notifications`), Cloud Functions v2 + firebase-admin v13 (TypeScript, Node 20).

## Global Constraints

- **Region:** all Cloud Functions use `asia-south1` (`setGlobalOptions` already applied in `functions/src/index.ts`). Verbatim.
- **Admin identity:** `isAdmin()` = `request.auth.token.role == 'admin'` with `users/{uid}.role == 'admin'` fallback. Reuse verbatim; callable mirrors this.
- **Firestore writes to notification inboxes are functions-only** (`create: if false` for clients). Admin SDK bypasses rules.
- **No new secrets / no FCM key entry** — Admin SDK default credentials send FCM.
- **Admin app must NOT depend on `firebase_messaging`** — it only sends (callable) + reads inbox (Firestore).
- **Dual serialization:** every core model has `fromFirebaseJson` / `toFirebaseJson` / `fromApiJson` / `toApiJson` / `fromEntity` (match `core/lib/models/design_model.dart`).
- **Localization:** no hardcoded user-visible strings — add getters to `locale_base.dart` + `en_us.dart` + `hi_in.dart` in each app (admin: `lib/l10n/locales/`; user: `lib/localisations/locales/`). Access via `AppLocalization.strings`.
- **Design system:** admin uses `AppAppBar` / `AppTextField` / `AppButton` / `ResponsiveSnackbar(message, context)`; user app uses design-system widgets + `AppSnackbar`. No raw `AppBar`/`TextField`/`ScaffoldMessenger`.
- **Responsive + overflow:** every `Text` has `maxLines` + `overflow: TextOverflow.ellipsis`; layouts adapt at 320/400/600px.
- **Theme-aware:** colors from `Theme.of(context).colorScheme` / `AppTheme`; dark mode must work.
- **Collection/doc names** come only from `FirestoreCollections` (Dart) / `Collections`+`Docs` (TS) constants — never string literals in datasources/functions.
- **`dailySlots` ≤ 4** entries, `"HH:mm"` 24h; timezone default `Asia/Kolkata`.
- **Design field read-tolerance:** functions read `design.name ?? design.title` and image `design.thumbUrl ?? design.previewUrl ?? design.images?.[0]` (the repo has a `name`/`title` schema split — do not "fix" it here, just tolerate it).

---

## File Structure

**Core (`core/lib/`)**
- `enums/app_notification_type.dart` — notification type enum.
- `models/app_notification_model.dart` — inbox item entity+model.
- `models/notification_settings_model.dart` — `config/notifications` entity+model.
- `constants/firestore_collections.dart` — *modify*: add notification names.

**Functions (`functions/src/`)**
- `lib/firebase.ts` — *modify*: export `messaging`.
- `config/constants.ts` — *modify*: add notification names + `NotificationType`.
- `notifications/messaging.ts` — send/fan-out/prune helpers.
- `notifications/digestLogic.ts` — pure slot/cap/cursor selection.
- `notifications/broadcastNotification.ts` — admin callable.
- `notifications/onOrderFinalized.ts` — order→admin inbox trigger.
- `notifications/onDesignWritten.ts` — `activatedAt` stamp trigger.
- `notifications/sendNewDesignDigest.ts` — scheduler.
- `index.ts` — *modify*: export the five functions.

**User app (`shree_krishna_emb_user_app/lib/`)**
- `data/datasources/firebase_fcm_token_datasource.dart`
- `data/datasources/firebase_notifications_datasource.dart`
- `domain/repositories/notifications_repository.dart` + `data/repositories/notifications_repository_impl.dart`
- `data/services/notification_service.dart` — FCM lifecycle + routing.
- `bloc/notifications/notification_cubit.dart` (+ `notification_state.dart`)
- `screens/notifications/notifications_screen.dart`
- `core/di/service_locator.dart`, `main.dart`, `routes/app_routes.dart`, `screens/main/main_screen.dart`, `localisations/locales/*` — *modify*.

**Admin app (`shree_krishna_emb_admin/lib/`)**
- `data/datasources/firebase_notification_settings_datasource.dart`
- `data/datasources/firebase_admin_notifications_datasource.dart`
- `data/services/broadcast_service.dart` — callable wrapper.
- `domain/repositories/notification_settings_repository.dart` + impl; `admin_notifications_repository.dart` + impl.
- `bloc/settings/notification_settings_cubit.dart`, `bloc/notifications/broadcast_cubit.dart`, `bloc/notifications/admin_notifications_cubit.dart`
- `screens/notifications/admin_notifications_screen.dart`, `screens/settings/widgets/notification_settings_form.dart`, `screens/notifications/broadcast_composer_dialog.dart`
- `core/di/service_locator.dart`, `screens/settings/settings_content_view.dart`, `screens/dashboard/admin_dashboard_screen.dart`, `l10n/locales/*` — *modify*.

**Root**
- `firestore.rules`, `firestore.indexes.json` — *modify*.

---

## PHASE 0 — Foundations (core models, constants, rules, indexes)

### Task 1: Core — `AppNotificationType` enum

**Files:**
- Create: `core/lib/enums/app_notification_type.dart`
- Test: `core/test/enums/app_notification_type_test.dart`

**Interfaces:**
- Produces: `enum AppNotificationType { newDesign, purchase, broadcast }`; `String get value`; `static AppNotificationType fromString(String?)` (defaults to `broadcast`).

- [ ] **Step 1: Write the failing test**
```dart
// core/test/enums/app_notification_type_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shree_krishna_core/enums/app_notification_type.dart';

void main() {
  test('value <-> fromString round trips', () {
    for (final t in AppNotificationType.values) {
      expect(AppNotificationType.fromString(t.value), t);
    }
  });
  test('fromString defaults to broadcast on null/unknown', () {
    expect(AppNotificationType.fromString(null), AppNotificationType.broadcast);
    expect(AppNotificationType.fromString('garbage'), AppNotificationType.broadcast);
  });
  test('wire values are stable strings', () {
    expect(AppNotificationType.newDesign.value, 'newDesign');
    expect(AppNotificationType.purchase.value, 'purchase');
    expect(AppNotificationType.broadcast.value, 'broadcast');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd core && flutter test test/enums/app_notification_type_test.dart`
Expected: FAIL — `app_notification_type.dart` does not exist.

- [ ] **Step 3: Write minimal implementation**
```dart
// core/lib/enums/app_notification_type.dart
enum AppNotificationType {
  newDesign('newDesign'),
  purchase('purchase'),
  broadcast('broadcast');

  const AppNotificationType(this.value);
  final String value;

  static AppNotificationType fromString(String? raw) {
    return AppNotificationType.values.firstWhere(
      (t) => t.value == raw,
      orElse: () => AppNotificationType.broadcast,
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd core && flutter test test/enums/app_notification_type_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**
```bash
git add core/lib/enums/app_notification_type.dart core/test/enums/app_notification_type_test.dart
git commit -m "feat(core): add AppNotificationType enum"
```

---

### Task 2: Core — `AppNotificationModel` (inbox item)

**Files:**
- Create: `core/lib/models/app_notification_model.dart`
- Test: `core/test/models/app_notification_model_test.dart`

**Interfaces:**
- Consumes: `AppNotificationType` (Task 1).
- Produces: `AppNotificationEntity` (fields: `id` String, `type` AppNotificationType, `title` String, `body` String, `imageUrl` String?, `data` Map<String,dynamic>, `read` bool, `createdAt` DateTime); `AppNotificationModel.fromFirebaseJson(Map, String id)`, `.toFirebaseJson()`, `.fromApiJson(Map)`, `.toApiJson()`, `.fromEntity()`. `String? get designId => data['designId'] as String?`.

- [ ] **Step 1: Write the failing test**
```dart
// core/test/models/app_notification_model_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shree_krishna_core/enums/app_notification_type.dart';
import 'package:shree_krishna_core/models/app_notification_model.dart';

void main() {
  final json = {
    'type': 'newDesign',
    'title': 'New designs',
    'body': '3 added',
    'imageUrl': 'https://x/thumb.jpg',
    'data': {'designId': 'd1', 'route': 'design'},
    'read': false,
    'createdAt': '2026-06-27T10:00:00.000Z',
  };

  test('fromFirebaseJson parses all fields', () {
    final m = AppNotificationModel.fromFirebaseJson(json, 'n1');
    expect(m.id, 'n1');
    expect(m.type, AppNotificationType.newDesign);
    expect(m.read, false);
    expect(m.designId, 'd1');
    expect(m.createdAt.toUtc().hour, 10);
  });

  test('toFirebaseJson omits id and round-trips type', () {
    final m = AppNotificationModel.fromFirebaseJson(json, 'n1');
    final out = m.toFirebaseJson();
    expect(out.containsKey('id'), false);
    expect(out['type'], 'newDesign');
    expect(out['read'], false);
  });

  test('defaults are safe for missing fields', () {
    final m = AppNotificationModel.fromFirebaseJson({}, 'n2');
    expect(m.title, '');
    expect(m.data, isEmpty);
    expect(m.read, false);
    expect(m.type, AppNotificationType.broadcast);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd core && flutter test test/models/app_notification_model_test.dart`
Expected: FAIL — model missing.

- [ ] **Step 3: Write minimal implementation**
```dart
// core/lib/models/app_notification_model.dart
import 'package:equatable/equatable.dart';
import '../enums/app_notification_type.dart';

class AppNotificationEntity extends Equatable {
  final String id;
  final AppNotificationType type;
  final String title;
  final String body;
  final String? imageUrl;
  final Map<String, dynamic> data;
  final bool read;
  final DateTime createdAt;

  const AppNotificationEntity({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.imageUrl,
    this.data = const {},
    this.read = false,
    required this.createdAt,
  });

  String? get designId => data['designId'] as String?;

  @override
  List<Object?> get props => [id, type, title, body, imageUrl, data, read, createdAt];
}

class AppNotificationModel extends AppNotificationEntity {
  const AppNotificationModel({
    required super.id,
    required super.type,
    required super.title,
    required super.body,
    super.imageUrl,
    super.data,
    super.read,
    required super.createdAt,
  });

  factory AppNotificationModel.fromFirebaseJson(Map<String, dynamic> json, String id) {
    return AppNotificationModel(
      id: id,
      type: AppNotificationType.fromString(json['type'] as String?),
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      data: (json['data'] as Map?)?.cast<String, dynamic>() ?? const {},
      read: json['read'] as bool? ?? false,
      createdAt: _parseTs(json['createdAt']),
    );
  }

  Map<String, dynamic> toFirebaseJson() => {
        'type': type.value,
        'title': title,
        'body': body,
        'imageUrl': imageUrl,
        'data': data,
        'read': read,
        'createdAt': createdAt.toIso8601String(),
      };

  factory AppNotificationModel.fromApiJson(Map<String, dynamic> json) =>
      AppNotificationModel.fromFirebaseJson(json, json['id'] as String? ?? '');

  Map<String, dynamic> toApiJson() => {'id': id, ...toFirebaseJson()};

  factory AppNotificationModel.fromEntity(AppNotificationEntity e) => AppNotificationModel(
        id: e.id, type: e.type, title: e.title, body: e.body,
        imageUrl: e.imageUrl, data: e.data, read: e.read, createdAt: e.createdAt,
      );

  static DateTime _parseTs(dynamic v) {
    if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
    // Firestore Timestamp has toDate(); avoid importing cloud_firestore in core.
    try { return (v as dynamic).toDate() as DateTime; } catch (_) { return DateTime.now(); }
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd core && flutter test test/models/app_notification_model_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**
```bash
git add core/lib/models/app_notification_model.dart core/test/models/app_notification_model_test.dart
git commit -m "feat(core): add AppNotification model"
```

---

### Task 2b: Core — export new symbols from the barrel (if one exists)

**Files:**
- Modify: `core/lib/shree_krishna_core.dart` (only if it re-exports models; otherwise skip — apps import by path).

- [ ] **Step 1:** Open `core/lib/shree_krishna_core.dart`. If it has `export 'models/...';` lines, add:
```dart
export 'enums/app_notification_type.dart';
export 'models/app_notification_model.dart';
export 'models/notification_settings_model.dart';
```
If the file imports models individually elsewhere (no barrel), skip this task.
- [ ] **Step 2: Commit (if changed)**
```bash
git add core/lib/shree_krishna_core.dart
git commit -m "chore(core): export notification symbols from barrel"
```

---

### Task 3: Core — `NotificationSettingsModel` (`config/notifications`)

**Files:**
- Create: `core/lib/models/notification_settings_model.dart`
- Test: `core/test/models/notification_settings_model_test.dart`

**Interfaces:**
- Produces: `NotificationSettingsEntity` (fields: `masterEnabled` bool=true, `purchaseAlertsEnabled` bool=true, `newDesignAlertsEnabled` bool=true, `dailySlots` List<String>, `timezone` String='Asia/Kolkata', `newDesignCursor` DateTime?, `firedSlots` Map<String,List<String>>, `updatedAt` DateTime?, `updatedBy` String?); `copyWith(...)`; `NotificationSettingsModel.fromFirebaseJson(Map)`, `.toFirebaseJson()`, `.fromApiJson`, `.toApiJson`, `.fromEntity`, plus `NotificationSettingsModel.defaults()`.

- [ ] **Step 1: Write the failing test**
```dart
// core/test/models/notification_settings_model_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shree_krishna_core/models/notification_settings_model.dart';

void main() {
  test('defaults() gives sane values', () {
    final s = NotificationSettingsModel.defaults();
    expect(s.masterEnabled, true);
    expect(s.timezone, 'Asia/Kolkata');
    expect(s.dailySlots, isEmpty);
    expect(s.firedSlots, isEmpty);
  });

  test('round-trips dailySlots + firedSlots', () {
    final s = NotificationSettingsModel.fromFirebaseJson({
      'masterEnabled': true,
      'purchaseAlertsEnabled': false,
      'newDesignAlertsEnabled': true,
      'dailySlots': ['10:00', '18:00'],
      'timezone': 'Asia/Kolkata',
      'firedSlots': {'2026-06-27': ['10:00']},
      'newDesignCursor': '2026-06-27T05:00:00.000Z',
    });
    expect(s.dailySlots, ['10:00', '18:00']);
    expect(s.firedSlots['2026-06-27'], ['10:00']);
    expect(s.purchaseAlertsEnabled, false);
    final out = s.toFirebaseJson();
    expect(out['dailySlots'], ['10:00', '18:00']);
    expect((out['firedSlots'] as Map)['2026-06-27'], ['10:00']);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd core && flutter test test/models/notification_settings_model_test.dart`
Expected: FAIL.

- [ ] **Step 3: Write minimal implementation**
```dart
// core/lib/models/notification_settings_model.dart
import 'package:equatable/equatable.dart';

class NotificationSettingsEntity extends Equatable {
  final bool masterEnabled;
  final bool purchaseAlertsEnabled;
  final bool newDesignAlertsEnabled;
  final List<String> dailySlots;     // ["HH:mm"], <=4
  final String timezone;
  final DateTime? newDesignCursor;
  final Map<String, List<String>> firedSlots; // {"YYYY-MM-DD": ["HH:mm"]}
  final DateTime? updatedAt;
  final String? updatedBy;

  const NotificationSettingsEntity({
    this.masterEnabled = true,
    this.purchaseAlertsEnabled = true,
    this.newDesignAlertsEnabled = true,
    this.dailySlots = const [],
    this.timezone = 'Asia/Kolkata',
    this.newDesignCursor,
    this.firedSlots = const {},
    this.updatedAt,
    this.updatedBy,
  });

  NotificationSettingsEntity copyWith({
    bool? masterEnabled,
    bool? purchaseAlertsEnabled,
    bool? newDesignAlertsEnabled,
    List<String>? dailySlots,
    String? timezone,
    DateTime? newDesignCursor,
    Map<String, List<String>>? firedSlots,
    DateTime? updatedAt,
    String? updatedBy,
  }) =>
      NotificationSettingsEntity(
        masterEnabled: masterEnabled ?? this.masterEnabled,
        purchaseAlertsEnabled: purchaseAlertsEnabled ?? this.purchaseAlertsEnabled,
        newDesignAlertsEnabled: newDesignAlertsEnabled ?? this.newDesignAlertsEnabled,
        dailySlots: dailySlots ?? this.dailySlots,
        timezone: timezone ?? this.timezone,
        newDesignCursor: newDesignCursor ?? this.newDesignCursor,
        firedSlots: firedSlots ?? this.firedSlots,
        updatedAt: updatedAt ?? this.updatedAt,
        updatedBy: updatedBy ?? this.updatedBy,
      );

  @override
  List<Object?> get props => [
        masterEnabled, purchaseAlertsEnabled, newDesignAlertsEnabled,
        dailySlots, timezone, newDesignCursor, firedSlots, updatedAt, updatedBy,
      ];
}

class NotificationSettingsModel extends NotificationSettingsEntity {
  const NotificationSettingsModel({
    super.masterEnabled,
    super.purchaseAlertsEnabled,
    super.newDesignAlertsEnabled,
    super.dailySlots,
    super.timezone,
    super.newDesignCursor,
    super.firedSlots,
    super.updatedAt,
    super.updatedBy,
  });

  factory NotificationSettingsModel.defaults() => const NotificationSettingsModel();

  factory NotificationSettingsModel.fromFirebaseJson(Map<String, dynamic> json) {
    final fired = <String, List<String>>{};
    (json['firedSlots'] as Map?)?.forEach((k, v) {
      fired['$k'] = (v as List?)?.cast<String>() ?? const [];
    });
    return NotificationSettingsModel(
      masterEnabled: json['masterEnabled'] as bool? ?? true,
      purchaseAlertsEnabled: json['purchaseAlertsEnabled'] as bool? ?? true,
      newDesignAlertsEnabled: json['newDesignAlertsEnabled'] as bool? ?? true,
      dailySlots: (json['dailySlots'] as List?)?.cast<String>() ?? const [],
      timezone: json['timezone'] as String? ?? 'Asia/Kolkata',
      newDesignCursor: _ts(json['newDesignCursor']),
      firedSlots: fired,
      updatedAt: _ts(json['updatedAt']),
      updatedBy: json['updatedBy'] as String?,
    );
  }

  Map<String, dynamic> toFirebaseJson() => {
        'masterEnabled': masterEnabled,
        'purchaseAlertsEnabled': purchaseAlertsEnabled,
        'newDesignAlertsEnabled': newDesignAlertsEnabled,
        'dailySlots': dailySlots,
        'timezone': timezone,
        'newDesignCursor': newDesignCursor?.toIso8601String(),
        'firedSlots': firedSlots,
        'updatedAt': updatedAt?.toIso8601String(),
        'updatedBy': updatedBy,
      };

  factory NotificationSettingsModel.fromApiJson(Map<String, dynamic> json) =>
      NotificationSettingsModel.fromFirebaseJson(json);
  Map<String, dynamic> toApiJson() => toFirebaseJson();

  factory NotificationSettingsModel.fromEntity(NotificationSettingsEntity e) =>
      NotificationSettingsModel(
        masterEnabled: e.masterEnabled,
        purchaseAlertsEnabled: e.purchaseAlertsEnabled,
        newDesignAlertsEnabled: e.newDesignAlertsEnabled,
        dailySlots: e.dailySlots,
        timezone: e.timezone,
        newDesignCursor: e.newDesignCursor,
        firedSlots: e.firedSlots,
        updatedAt: e.updatedAt,
        updatedBy: e.updatedBy,
      );

  static DateTime? _ts(dynamic v) {
    if (v == null) return null;
    if (v is String) return DateTime.tryParse(v);
    try { return (v as dynamic).toDate() as DateTime; } catch (_) { return null; }
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd core && flutter test test/models/notification_settings_model_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**
```bash
git add core/lib/models/notification_settings_model.dart core/test/models/notification_settings_model_test.dart
git commit -m "feat(core): add NotificationSettings model"
```

---

### Task 4: Core — add notification collection constants

**Files:**
- Modify: `core/lib/constants/firestore_collections.dart`

**Interfaces:**
- Produces (static const String fields on `FirestoreCollections`): `configNotificationsDoc = 'notifications'`, `fcmTokens = 'fcm_tokens'`, `userNotifications = 'notifications'`, `adminNotifications = 'admin_notifications'`.

- [ ] **Step 1:** Open the file, confirm the existing `class FirestoreCollections` shape (e.g. `static const String users = 'users';` and a `configPlatformDoc`). Add, grouped with a comment, near the other `config*`/subcollection constants:
```dart
  // ---- notifications ----
  /// config/notifications (single doc) — admin notification settings.
  static const String configNotificationsDoc = 'notifications';
  /// users/{uid}/fcm_tokens/{token}
  static const String fcmTokens = 'fcm_tokens';
  /// users/{uid}/notifications/{id}
  static const String userNotifications = 'notifications';
  /// admin_notifications/{id} (top-level shared admin feed)
  static const String adminNotifications = 'admin_notifications';
```
- [ ] **Step 2: Verify it compiles**

Run: `cd core && flutter analyze lib/constants/firestore_collections.dart`
Expected: No issues.

- [ ] **Step 3: Commit**
```bash
git add core/lib/constants/firestore_collections.dart
git commit -m "feat(core): add notification collection constants"
```

---

### Task 5: Functions — mirror notification constants (TS)

**Files:**
- Modify: `functions/src/config/constants.ts`

**Interfaces:**
- Produces: `Collections.fcmTokens = 'fcm_tokens'`, `Collections.userNotifications = 'notifications'`, `Collections.adminNotifications = 'admin_notifications'`; `Docs.configNotifications = 'notifications'`; `NotificationType = { newDesign:'newDesign', purchase:'purchase', broadcast:'broadcast' }`.

- [ ] **Step 1:** Add to the `Collections` object: `fcmTokens: "fcm_tokens", userNotifications: "notifications", adminNotifications: "admin_notifications",`. Add to `Docs`: `configNotifications: "notifications",`. Add a new export:
```ts
/** Mirrors Dart AppNotificationType.value. */
export const NotificationType = {
  newDesign: "newDesign",
  purchase: "purchase",
  broadcast: "broadcast",
} as const;

/** FCM topic every logged-in user subscribes to. */
export const TOPIC_ALL_USERS = "all_users";
```
- [ ] **Step 2: Verify build**

Run: `cd functions && npm run build`
Expected: TypeScript compiles, no errors.

- [ ] **Step 3: Commit**
```bash
git add functions/src/config/constants.ts
git commit -m "feat(functions): mirror notification constants + all_users topic"
```

---

### Task 6: Firestore rules — notification access

**Files:**
- Modify: `firestore.rules`

- [ ] **Step 1:** Inside `match /databases/{database}/documents { ... }`, before the final `match /{document=**}` deny block, add the four blocks below (these reuse the existing `isAuthed()`, `isAdmin()`, `isOwner(uid)` helpers):
```
    // ==================== config/notifications (admin) ====================
    match /config/notifications {
      allow read:  if isAdmin();
      allow write: if isAdmin()
        && request.resource.data.dailySlots is list
        && request.resource.data.dailySlots.size() <= 4;
    }

    // ==================== fcm tokens (owner) ====================
    match /users/{uid}/fcm_tokens/{tokenId} {
      allow read: if isOwner(uid) || isAdmin();
      allow create, update, delete: if isOwner(uid);
    }

    // ==================== user inbox (functions write) ====================
    match /users/{uid}/notifications/{id} {
      allow read:   if isOwner(uid) || isAdmin();
      allow create: if false;
      allow update: if isOwner(uid)
        && request.resource.data.diff(resource.data).affectedKeys().hasOnly(['read']);
      allow delete: if isOwner(uid);
    }

    // ==================== admin inbox (functions write) ====================
    match /admin_notifications/{id} {
      allow read:   if isAdmin();
      allow create: if false;
      allow update: if isAdmin()
        && request.resource.data.diff(resource.data).affectedKeys().hasOnly(['readBy']);
      allow delete: if isAdmin();
    }
```
- [ ] **Step 2: Verify rules compile (dry-run via emulator)**

Run: `firebase emulators:exec --only firestore "echo rules-ok"` (or `firebase deploy --only firestore:rules --dry-run` if available in this CLI version).
Expected: rules parse without syntax errors.

- [ ] **Step 3: Commit**
```bash
git add firestore.rules
git commit -m "feat(rules): notification settings, fcm tokens, user + admin inboxes"
```

---

### Task 7: Firestore indexes — digest + inbox ordering

**Files:**
- Modify: `firestore.indexes.json`

- [ ] **Step 1:** Add to the `indexes` array (keep existing entries):
```json
{
  "collectionGroup": "designs",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "status", "order": "ASCENDING" },
    { "fieldPath": "activatedAt", "order": "ASCENDING" }
  ]
},
{
  "collectionGroup": "notifications",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "createdAt", "order": "DESCENDING" }
  ]
},
{
  "collectionGroup": "admin_notifications",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "createdAt", "order": "DESCENDING" }
  ]
}
```
- [ ] **Step 2: Validate JSON**

Run: `cd /Applications/Documents/dev/shree-krishna-emb && node -e "JSON.parse(require('fs').readFileSync('firestore.indexes.json','utf8')); console.log('valid')"`
Expected: prints `valid`.

- [ ] **Step 3: Commit**
```bash
git add firestore.indexes.json
git commit -m "feat(indexes): designs status+activatedAt, notification createdAt"
```

---

## PHASE 1 — User app FCM plumbing

### Task 8: User app — add FCM dependencies

**Files:**
- Modify: `shree_krishna_emb_user_app/pubspec.yaml`

- [ ] **Step 1:** Under `dependencies:`, add (place near other firebase deps):
```yaml
  firebase_messaging: ^15.1.0
  flutter_local_notifications: ^17.2.3
```
> If `flutter pub get` reports a resolver conflict with `firebase_core ^4.8.0`, run `cd shree_krishna_emb_user_app && flutter pub upgrade firebase_messaging` and pin the resolved version; do NOT downgrade `firebase_core`.
- [ ] **Step 2: Resolve**

Run: `cd shree_krishna_emb_user_app && flutter pub get`
Expected: resolves successfully.
- [ ] **Step 3: Android channel prerequisite** — confirm `android/app/src/main/AndroidManifest.xml` allows notifications; add a default channel meta-data if missing:
```xml
<meta-data
  android:name="com.google.firebase.messaging.default_notification_channel_id"
  android:value="ske_default_channel" />
```
- [ ] **Step 4: Commit**
```bash
git add shree_krishna_emb_user_app/pubspec.yaml shree_krishna_emb_user_app/pubspec.lock shree_krishna_emb_user_app/android/app/src/main/AndroidManifest.xml
git commit -m "build(user): add firebase_messaging + flutter_local_notifications"
```

---

### Task 9: User app — FCM token datasource + repository

**Files:**
- Create: `shree_krishna_emb_user_app/lib/data/datasources/firebase_fcm_token_datasource.dart`
- Create: `shree_krishna_emb_user_app/lib/domain/repositories/fcm_token_repository.dart`
- Create: `shree_krishna_emb_user_app/lib/data/repositories/fcm_token_repository_impl.dart`
- Test: `shree_krishna_emb_user_app/test/data/fcm_token_repository_test.dart`

**Interfaces:**
- Produces: `abstract class FcmTokenDataSource { Future<void> registerToken(String uid, String token, String platform); Future<void> deleteToken(String uid, String token); }`; `FirebaseFcmTokenDataSource(FirebaseFirestore)`; `abstract class FcmTokenRepository { Future<Either<Failure,void>> register(...); Future<Either<Failure,void>> remove(...); }`; `FcmTokenRepositoryImpl`.

- [ ] **Step 1: Write the failing test** (repo maps datasource throw → Left)
```dart
// shree_krishna_emb_user_app/test/data/fcm_token_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shree_krishna_core/errors/failures.dart';
import 'package:shree_krishna_emb/data/datasources/firebase_fcm_token_datasource.dart';
import 'package:shree_krishna_emb/data/repositories/fcm_token_repository_impl.dart';

class _ThrowingDs implements FcmTokenDataSource {
  @override
  Future<void> deleteToken(String uid, String token) async => throw Exception('boom');
  @override
  Future<void> registerToken(String uid, String token, String platform) async =>
      throw Exception('boom');
}

class _OkDs implements FcmTokenDataSource {
  String? lastToken;
  @override
  Future<void> deleteToken(String uid, String token) async {}
  @override
  Future<void> registerToken(String uid, String token, String platform) async {
    lastToken = token;
  }
}

void main() {
  test('register success returns Right', () async {
    final ds = _OkDs();
    final repo = FcmTokenRepositoryImpl(dataSource: ds);
    final r = await repo.register('u1', 't1', 'android');
    expect(r.isRight(), true);
    expect(ds.lastToken, 't1');
  });

  test('register failure returns Left(Failure)', () async {
    final repo = FcmTokenRepositoryImpl(dataSource: _ThrowingDs());
    final r = await repo.register('u1', 't1', 'android');
    expect(r.isLeft(), true);
    r.fold((f) => expect(f, isA<Failure>()), (_) => fail('should be Left'));
  });
}
```
> Confirm the user app's `Either` helper import path (it has `isRight()/isLeft()/fold`); if the project uses `dartz`, import `package:dartz/dartz.dart` instead and adjust. Check an existing repo impl (e.g. `firebase_purchases_datasource.dart`'s repository) for the exact `Either`/`Failure` import.

- [ ] **Step 2: Run test to verify it fails**

Run: `cd shree_krishna_emb_user_app && flutter test test/data/fcm_token_repository_test.dart`
Expected: FAIL — classes missing.

- [ ] **Step 3: Write minimal implementation**
```dart
// lib/data/datasources/firebase_fcm_token_datasource.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shree_krishna_core/constants/firestore_collections.dart';

abstract class FcmTokenDataSource {
  Future<void> registerToken(String uid, String token, String platform);
  Future<void> deleteToken(String uid, String token);
}

class FirebaseFcmTokenDataSource implements FcmTokenDataSource {
  final FirebaseFirestore _firestore;
  FirebaseFcmTokenDataSource({required FirebaseFirestore firestore}) : _firestore = firestore;

  CollectionReference<Map<String, dynamic>> _tokens(String uid) => _firestore
      .collection(FirestoreCollections.users)
      .doc(uid)
      .collection(FirestoreCollections.fcmTokens);

  @override
  Future<void> registerToken(String uid, String token, String platform) async {
    await _tokens(uid).doc(token).set({
      'token': token,
      'platform': platform,
      'createdAt': FieldValue.serverTimestamp(),
      'lastSeenAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> deleteToken(String uid, String token) async {
    await _tokens(uid).doc(token).delete();
  }
}
```
```dart
// lib/domain/repositories/fcm_token_repository.dart
import 'package:shree_krishna_core/errors/failures.dart';
import 'package:shree_krishna_core/utils/either.dart'; // adjust to project Either path

abstract class FcmTokenRepository {
  Future<Either<Failure, void>> register(String uid, String token, String platform);
  Future<Either<Failure, void>> remove(String uid, String token);
}
```
```dart
// lib/data/repositories/fcm_token_repository_impl.dart
import 'package:shree_krishna_core/errors/failures.dart';
import 'package:shree_krishna_core/utils/either.dart'; // adjust path
import '../datasources/firebase_fcm_token_datasource.dart';
import '../../domain/repositories/fcm_token_repository.dart';

class FcmTokenRepositoryImpl implements FcmTokenRepository {
  final FcmTokenDataSource dataSource;
  FcmTokenRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, void>> register(String uid, String token, String platform) async {
    try {
      await dataSource.registerToken(uid, token, platform);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> remove(String uid, String token) async {
    try {
      await dataSource.deleteToken(uid, token);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
```
> Adjust the `Either`/`Right`/`Left`/`ServerFailure` import paths to match the user app's actual error layer (grep `class ServerFailure` and `Right(` in the repo to confirm). Replace the test's stub import paths if needed.

- [ ] **Step 4: Run test to verify it passes**

Run: `cd shree_krishna_emb_user_app && flutter test test/data/fcm_token_repository_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**
```bash
git add shree_krishna_emb_user_app/lib/data/datasources/firebase_fcm_token_datasource.dart shree_krishna_emb_user_app/lib/domain/repositories/fcm_token_repository.dart shree_krishna_emb_user_app/lib/data/repositories/fcm_token_repository_impl.dart shree_krishna_emb_user_app/test/data/fcm_token_repository_test.dart
git commit -m "feat(user): FCM token datasource + repository"
```

---

### Task 10: User app — `NotificationService` (FCM lifecycle + deep-link routing)

**Files:**
- Create: `shree_krishna_emb_user_app/lib/data/services/notification_service.dart`
- Test: `shree_krishna_emb_user_app/test/data/notification_service_routing_test.dart` (pure routing only)

**Interfaces:**
- Consumes: `FcmTokenRepository` (Task 9), `AppRoutes.navigateToDesignDetail` + `GlobalNavigator.navigatorKey` (existing).
- Produces: `class NotificationService` with `Future<void> init()`, `Future<void> onLogin(String uid)`, `Future<void> onLogout(String uid)`, and a pure static `static String? routeTargetFromData(Map<String,dynamic> data)` returning a designId to open (or null). Top-level `@pragma('vm:entry-point') Future<void> fcmBackgroundHandler(RemoteMessage message)`.

- [ ] **Step 1: Write the failing test** (pure routing extraction — no Firebase)
```dart
// shree_krishna_emb_user_app/test/data/notification_service_routing_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shree_krishna_emb/data/services/notification_service.dart';

void main() {
  test('extracts designId from data', () {
    expect(NotificationService.routeTargetFromData({'route': 'design', 'designId': 'd9'}), 'd9');
  });
  test('returns null when no designId', () {
    expect(NotificationService.routeTargetFromData({'route': 'home'}), null);
    expect(NotificationService.routeTargetFromData({}), null);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd shree_krishna_emb_user_app && flutter test test/data/notification_service_routing_test.dart`
Expected: FAIL.

- [ ] **Step 3: Write minimal implementation**
```dart
// lib/data/services/notification_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../core/utils/global_navigator.dart'; // confirm path
import '../../routes/app_routes.dart';
import '../../domain/repositories/fcm_token_repository.dart';

@pragma('vm:entry-point')
Future<void> fcmBackgroundHandler(RemoteMessage message) async {
  // Cold/background data messages: nothing to do here beyond letting the OS
  // display the notification; tap is handled by onMessageOpenedApp/getInitialMessage.
}

const _channel = AndroidNotificationChannel(
  'ske_default_channel', 'General', importance: Importance.high,
);

class NotificationService {
  final FcmTokenRepository tokenRepository;
  final FirebaseMessaging _fm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();
  static const String topicAllUsers = 'all_users';

  NotificationService({required this.tokenRepository});

  /// Pure: which design (if any) a notification payload should open.
  static String? routeTargetFromData(Map<String, dynamic> data) {
    final id = data['designId'];
    return (id is String && id.isNotEmpty) ? id : null;
  }

  Future<void> init() async {
    await _local.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (resp) => _routeFromPayload(resp.payload),
    );
    await _local
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    FirebaseMessaging.onMessage.listen(_showForeground);
    FirebaseMessaging.onMessageOpenedApp.listen((m) => _route(m.data));
  }

  /// Call once auth + navigator are ready, to cover the terminated-tap case.
  Future<void> consumeInitialMessage() async {
    final initial = await _fm.getInitialMessage();
    if (initial != null) _route(initial.data);
  }

  Future<void> onLogin(String uid) async {
    await _fm.requestPermission();
    final token = await _fm.getToken();
    if (token != null) {
      await tokenRepository.register(uid, token, _platform());
    }
    _fm.onTokenRefresh.listen((t) => tokenRepository.register(uid, t, _platform()));
    await _fm.subscribeToTopic(topicAllUsers);
    await consumeInitialMessage();
  }

  Future<void> onLogout(String uid) async {
    try {
      final token = await _fm.getToken();
      if (token != null) await tokenRepository.remove(uid, token);
      await _fm.unsubscribeFromTopic(topicAllUsers);
      await _fm.deleteToken();
    } catch (_) {/* non-fatal */}
  }

  void _showForeground(RemoteMessage m) {
    final n = m.notification;
    _local.show(
      m.hashCode,
      n?.title ?? m.data['title'] as String?,
      n?.body ?? m.data['body'] as String?,
      NotificationDetails(
        android: AndroidNotificationDetails(_channel.id, _channel.name,
            importance: Importance.high, priority: Priority.high),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: m.data['designId'] as String?,
    );
  }

  void _routeFromPayload(String? payload) {
    if (payload != null && payload.isNotEmpty) {
      final ctx = GlobalNavigator.navigatorKey.currentContext;
      if (ctx != null) AppRoutes.navigateToDesignDetail(ctx, payload);
    }
  }

  void _route(Map<String, dynamic> data) {
    final id = routeTargetFromData(data);
    final ctx = GlobalNavigator.navigatorKey.currentContext;
    if (id != null && ctx != null) AppRoutes.navigateToDesignDetail(ctx, id);
  }

  String _platform() => kIsWeb ? 'web' : defaultTargetPlatform.name;
}
```
> Confirm `GlobalNavigator` path (explorer noted `lib/core/utils/global_navigator.dart`) and that `AppRoutes.navigateToDesignDetail(context, designId)` exists. If web push isn't configured yet, `getToken()` may throw on web — wrap in try/catch (already guarded in `onLogout`; add the same guard in `onLogin`).

- [ ] **Step 4: Run test to verify it passes**

Run: `cd shree_krishna_emb_user_app && flutter test test/data/notification_service_routing_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**
```bash
git add shree_krishna_emb_user_app/lib/data/services/notification_service.dart shree_krishna_emb_user_app/test/data/notification_service_routing_test.dart
git commit -m "feat(user): NotificationService FCM lifecycle + deep-link routing"
```

---

### Task 11: User app — wire FCM into main.dart + auth lifecycle + DI

**Files:**
- Modify: `shree_krishna_emb_user_app/lib/main.dart`
- Modify: `shree_krishna_emb_user_app/lib/core/di/service_locator.dart`
- Modify: the auth-state listener (where `AuthBloc` is observed app-wide — likely `splash`/`MainApp`/an auth listener widget)

**Interfaces:**
- Consumes: `NotificationService` (Task 10), `FcmTokenRepository`, `AuthBloc` states `AuthAuthenticated`/`AuthUnauthenticated`.
- Produces: `getIt<NotificationService>()` registered; background handler registered before `runApp`.

- [ ] **Step 1:** In `service_locator.dart`, after Firebase singletons, register the token datasource/repo and service:
```dart
getIt.registerSingleton<FcmTokenDataSource>(
  FirebaseFcmTokenDataSource(firestore: getIt<FirebaseFirestore>()),
);
getIt.registerSingleton<FcmTokenRepository>(
  FcmTokenRepositoryImpl(dataSource: getIt<FcmTokenDataSource>()),
);
getIt.registerSingleton<NotificationService>(
  NotificationService(tokenRepository: getIt<FcmTokenRepository>()),
);
```
(Add the corresponding imports.)
- [ ] **Step 2:** In `main.dart`, register the background handler immediately after `Firebase.initializeApp(...)`:
```dart
FirebaseMessaging.onBackgroundMessage(fcmBackgroundHandler);
```
and after `setupServiceLocator(prefs)` call `await getIt<NotificationService>().init();`. Add imports for `firebase_messaging` and `notification_service.dart`.
- [ ] **Step 3:** In the app-wide `AuthBloc` listener (use a `BlocListener<AuthBloc, AuthState>` high in the tree, e.g. wrapping `MaterialApp` in `MainApp`), call:
```dart
listener: (context, state) async {
  final svc = getIt<NotificationService>();
  if (state is AuthAuthenticated) {
    await svc.onLogin(state.user.uid);
  } else if (state is AuthUnauthenticated) {
    // capture uid before clearing if needed; logout uses current FCM token
    await svc.onLogout(FirebaseAuth.instance.currentUser?.uid ?? '');
  }
}
```
> If a logout clears `currentUser` before this fires, pass the uid via the previous `AuthAuthenticated` state instead. Confirm the exact `AuthState` subclasses (Task baseline: `AuthAuthenticated{user.uid}`, `AuthUnauthenticated`).
- [ ] **Step 4: Manual verification (device/emulator)**

Run the app, log in, and confirm in Firestore console that `users/{uid}/fcm_tokens/{token}` appears; log out and confirm it is removed.
Run: `cd shree_krishna_emb_user_app && flutter analyze`
Expected: no analyzer errors.
- [ ] **Step 5: Commit**
```bash
git add shree_krishna_emb_user_app/lib/main.dart shree_krishna_emb_user_app/lib/core/di/service_locator.dart
git commit -m "feat(user): init FCM, register token on login, remove on logout"
```

---

## PHASE 2 — User in-app notification center

### Task 12: User app — notifications datasource + repository (stream/markRead/markAllRead/delete)

**Files:**
- Create: `shree_krishna_emb_user_app/lib/data/datasources/firebase_notifications_datasource.dart`
- Create: `shree_krishna_emb_user_app/lib/domain/repositories/notifications_repository.dart`
- Create: `shree_krishna_emb_user_app/lib/data/repositories/notifications_repository_impl.dart`
- Test: `shree_krishna_emb_user_app/test/data/notifications_repository_test.dart` (uses `fake_cloud_firestore` if available; else a hand fake datasource)

**Interfaces:**
- Produces: `abstract class NotificationsDataSource { Stream<List<AppNotificationModel>> watch(String uid); Future<void> markRead(String uid, String id); Future<void> markAllRead(String uid); Future<void> delete(String uid, String id); }`; `FirebaseNotificationsDataSource(FirebaseFirestore)`; `NotificationsRepository` with same methods wrapped (`watch` returns `Stream<List<AppNotificationModel>>` directly; mutations return `Future<Either<Failure,void>>`).

- [ ] **Step 1: Write the failing test** (fake datasource → repo mutation maps errors)
```dart
// shree_krishna_emb_user_app/test/data/notifications_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shree_krishna_core/models/app_notification_model.dart';
import 'package:shree_krishna_emb/data/datasources/firebase_notifications_datasource.dart';
import 'package:shree_krishna_emb/data/repositories/notifications_repository_impl.dart';

class _FakeDs implements NotificationsDataSource {
  bool throwOnMutate = false;
  @override
  Future<void> delete(String uid, String id) async { if (throwOnMutate) throw Exception('x'); }
  @override
  Future<void> markAllRead(String uid) async { if (throwOnMutate) throw Exception('x'); }
  @override
  Future<void> markRead(String uid, String id) async { if (throwOnMutate) throw Exception('x'); }
  @override
  Stream<List<AppNotificationModel>> watch(String uid) => const Stream.empty();
}

void main() {
  test('markRead ok -> Right', () async {
    final repo = NotificationsRepositoryImpl(dataSource: _FakeDs());
    expect((await repo.markRead('u', 'n')).isRight(), true);
  });
  test('markRead failure -> Left', () async {
    final repo = NotificationsRepositoryImpl(dataSource: _FakeDs()..throwOnMutate = true);
    expect((await repo.markRead('u', 'n')).isLeft(), true);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd shree_krishna_emb_user_app && flutter test test/data/notifications_repository_test.dart`
Expected: FAIL.

- [ ] **Step 3: Write minimal implementation**
```dart
// lib/data/datasources/firebase_notifications_datasource.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shree_krishna_core/constants/firestore_collections.dart';
import 'package:shree_krishna_core/models/app_notification_model.dart';

abstract class NotificationsDataSource {
  Stream<List<AppNotificationModel>> watch(String uid);
  Future<void> markRead(String uid, String id);
  Future<void> markAllRead(String uid);
  Future<void> delete(String uid, String id);
}

class FirebaseNotificationsDataSource implements NotificationsDataSource {
  final FirebaseFirestore _firestore;
  FirebaseNotificationsDataSource({required FirebaseFirestore firestore}) : _firestore = firestore;

  CollectionReference<Map<String, dynamic>> _col(String uid) => _firestore
      .collection(FirestoreCollections.users)
      .doc(uid)
      .collection(FirestoreCollections.userNotifications);

  @override
  Stream<List<AppNotificationModel>> watch(String uid) => _col(uid)
      .orderBy('createdAt', descending: true)
      .limit(100)
      .snapshots()
      .map((snap) => snap.docs
          .map((d) => AppNotificationModel.fromFirebaseJson(d.data(), d.id))
          .toList());

  @override
  Future<void> markRead(String uid, String id) =>
      _col(uid).doc(id).update({'read': true});

  @override
  Future<void> markAllRead(String uid) async {
    final unread = await _col(uid).where('read', isEqualTo: false).get();
    final batch = _firestore.batch();
    for (final d in unread.docs) {
      batch.update(d.reference, {'read': true});
    }
    await batch.commit();
  }

  @override
  Future<void> delete(String uid, String id) => _col(uid).doc(id).delete();
}
```
```dart
// lib/domain/repositories/notifications_repository.dart
import 'package:shree_krishna_core/errors/failures.dart';
import 'package:shree_krishna_core/utils/either.dart'; // adjust
import 'package:shree_krishna_core/models/app_notification_model.dart';

abstract class NotificationsRepository {
  Stream<List<AppNotificationModel>> watch(String uid);
  Future<Either<Failure, void>> markRead(String uid, String id);
  Future<Either<Failure, void>> markAllRead(String uid);
  Future<Either<Failure, void>> delete(String uid, String id);
}
```
```dart
// lib/data/repositories/notifications_repository_impl.dart
import 'package:shree_krishna_core/errors/failures.dart';
import 'package:shree_krishna_core/utils/either.dart'; // adjust
import 'package:shree_krishna_core/models/app_notification_model.dart';
import '../datasources/firebase_notifications_datasource.dart';
import '../../domain/repositories/notifications_repository.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  final NotificationsDataSource dataSource;
  NotificationsRepositoryImpl({required this.dataSource});

  @override
  Stream<List<AppNotificationModel>> watch(String uid) => dataSource.watch(uid);

  @override
  Future<Either<Failure, void>> markRead(String uid, String id) => _guard(() => dataSource.markRead(uid, id));
  @override
  Future<Either<Failure, void>> markAllRead(String uid) => _guard(() => dataSource.markAllRead(uid));
  @override
  Future<Either<Failure, void>> delete(String uid, String id) => _guard(() => dataSource.delete(uid, id));

  Future<Either<Failure, void>> _guard(Future<void> Function() op) async {
    try { await op(); return const Right(null); }
    catch (e) { return Left(ServerFailure(e.toString())); }
  }
}
```
> Adjust `Either`/`Failure` import paths as in Task 9.

- [ ] **Step 4: Run test to verify it passes**

Run: `cd shree_krishna_emb_user_app && flutter test test/data/notifications_repository_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**
```bash
git add shree_krishna_emb_user_app/lib/data/datasources/firebase_notifications_datasource.dart shree_krishna_emb_user_app/lib/domain/repositories/notifications_repository.dart shree_krishna_emb_user_app/lib/data/repositories/notifications_repository_impl.dart shree_krishna_emb_user_app/test/data/notifications_repository_test.dart
git commit -m "feat(user): notifications datasource + repository"
```

---

### Task 13: User app — `NotificationCubit`

**Files:**
- Create: `shree_krishna_emb_user_app/lib/bloc/notifications/notification_state.dart`
- Create: `shree_krishna_emb_user_app/lib/bloc/notifications/notification_cubit.dart`
- Test: `shree_krishna_emb_user_app/test/bloc/notification_cubit_test.dart`

**Interfaces:**
- Consumes: `NotificationsRepository` (Task 12).
- Produces: `NotificationState{ status, List<AppNotificationModel> items, int unreadCount }` (`unreadCount` derived from `items.where((n)=>!n.read).length`); `NotificationCubit{ start(uid), stop(), markAllRead(), delete(id) }`.

- [ ] **Step 1: Write the failing test**
```dart
// shree_krishna_emb_user_app/test/bloc/notification_cubit_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shree_krishna_core/enums/app_notification_type.dart';
import 'package:shree_krishna_core/models/app_notification_model.dart';
import 'package:shree_krishna_emb/bloc/notifications/notification_cubit.dart';
import 'package:shree_krishna_emb/domain/repositories/notifications_repository.dart';
import 'package:shree_krishna_core/errors/failures.dart';
import 'package:shree_krishna_core/utils/either.dart';

class _Repo implements NotificationsRepository {
  final _ctrl = Stream<List<AppNotificationModel>>.fromIterable([
    [
      AppNotificationModel(id: 'a', type: AppNotificationType.broadcast, title: 't', body: 'b', read: false, createdAt: DateTime(2026)),
      AppNotificationModel(id: 'b', type: AppNotificationType.broadcast, title: 't', body: 'b', read: true, createdAt: DateTime(2026)),
    ]
  ]);
  @override Future<Either<Failure, void>> delete(String uid, String id) async => const Right(null);
  @override Future<Either<Failure, void>> markAllRead(String uid) async => const Right(null);
  @override Future<Either<Failure, void>> markRead(String uid, String id) async => const Right(null);
  @override Stream<List<AppNotificationModel>> watch(String uid) => _ctrl;
}

void main() {
  test('start streams items and computes unreadCount', () async {
    final cubit = NotificationCubit(repository: _Repo());
    cubit.start('u1');
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(cubit.state.items.length, 2);
    expect(cubit.state.unreadCount, 1);
    await cubit.close();
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd shree_krishna_emb_user_app && flutter test test/bloc/notification_cubit_test.dart`
Expected: FAIL.

- [ ] **Step 3: Write minimal implementation**
```dart
// lib/bloc/notifications/notification_state.dart
import 'package:equatable/equatable.dart';
import 'package:shree_krishna_core/models/app_notification_model.dart';

enum NotificationStatus { initial, loading, loaded, error }

class NotificationState extends Equatable {
  final NotificationStatus status;
  final List<AppNotificationModel> items;
  final String? error;

  const NotificationState({
    this.status = NotificationStatus.initial,
    this.items = const [],
    this.error,
  });

  int get unreadCount => items.where((n) => !n.read).length;

  NotificationState copyWith({
    NotificationStatus? status,
    List<AppNotificationModel>? items,
    String? error,
  }) => NotificationState(
        status: status ?? this.status,
        items: items ?? this.items,
        error: error,
      );

  @override
  List<Object?> get props => [status, items, error];
}
```
```dart
// lib/bloc/notifications/notification_cubit.dart
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/notifications_repository.dart';
import 'notification_state.dart';

class NotificationCubit extends Cubit<NotificationState> {
  final NotificationsRepository repository;
  StreamSubscription? _sub;
  String? _uid;

  NotificationCubit({required this.repository}) : super(const NotificationState());

  void start(String uid) {
    _uid = uid;
    _sub?.cancel();
    emit(state.copyWith(status: NotificationStatus.loading));
    _sub = repository.watch(uid).listen(
      (items) => emit(state.copyWith(status: NotificationStatus.loaded, items: items)),
      onError: (e) => emit(state.copyWith(status: NotificationStatus.error, error: e.toString())),
    );
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
    _uid = null;
    emit(const NotificationState());
  }

  Future<void> markAllRead() async {
    final uid = _uid; if (uid == null) return;
    await repository.markAllRead(uid);
  }

  Future<void> delete(String id) async {
    final uid = _uid; if (uid == null) return;
    await repository.delete(uid, id);
  }

  @override
  Future<void> close() { _sub?.cancel(); return super.close(); }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd shree_krishna_emb_user_app && flutter test test/bloc/notification_cubit_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**
```bash
git add shree_krishna_emb_user_app/lib/bloc/notifications/ shree_krishna_emb_user_app/test/bloc/notification_cubit_test.dart
git commit -m "feat(user): NotificationCubit with unread count"
```

---

### Task 14: User app — localization strings for notifications

**Files:**
- Modify: `shree_krishna_emb_user_app/lib/localisations/locales/locale_base.dart`
- Modify: `shree_krishna_emb_user_app/lib/localisations/locales/en_us.dart`
- Modify: `shree_krishna_emb_user_app/lib/localisations/locales/hi_in.dart`

- [ ] **Step 1:** Add getters to `locale_base.dart` (abstract):
```dart
String get notifications;
String get noNotifications;
String get markAllRead;
String get deleteNotification;
String get notificationsEmptyHint;
```
- [ ] **Step 2:** Implement in `en_us.dart`:
```dart
@override String get notifications => 'Notifications';
@override String get noNotifications => 'No notifications yet';
@override String get markAllRead => 'Mark all read';
@override String get deleteNotification => 'Delete';
@override String get notificationsEmptyHint => 'New designs and updates will appear here.';
```
- [ ] **Step 3:** Implement in `hi_in.dart`:
```dart
@override String get notifications => 'सूचनाएं';
@override String get noNotifications => 'अभी कोई सूचना नहीं';
@override String get markAllRead => 'सभी पढ़ी हुई चिह्नित करें';
@override String get deleteNotification => 'हटाएं';
@override String get notificationsEmptyHint => 'नई डिज़ाइन और अपडेट यहाँ दिखेंगे।';
```
- [ ] **Step 4: Verify**

Run: `cd shree_krishna_emb_user_app && flutter analyze lib/localisations/`
Expected: no errors (all abstract getters implemented in both locales).
- [ ] **Step 5: Commit**
```bash
git add shree_krishna_emb_user_app/lib/localisations/locales/
git commit -m "feat(user): notification localization strings"
```

---

### Task 15: User app — `NotificationsScreen`

**Files:**
- Create: `shree_krishna_emb_user_app/lib/screens/notifications/notifications_screen.dart`
- Test: `shree_krishna_emb_user_app/test/screens/notifications_screen_test.dart` (widget)

**Interfaces:**
- Consumes: `NotificationCubit` (provided via GetIt/Provider), `AppLocalization.strings.*` (Task 14), design system widgets.
- Produces: `class NotificationsScreen extends StatelessWidget` (route target).

- [ ] **Step 1: Write the failing widget test** (empty state)
```dart
// shree_krishna_emb_user_app/test/screens/notifications_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shree_krishna_emb/bloc/notifications/notification_cubit.dart';
import 'package:shree_krishna_emb/bloc/notifications/notification_state.dart';
import 'package:shree_krishna_emb/screens/notifications/notifications_screen.dart';
import 'package:shree_krishna_emb/domain/repositories/notifications_repository.dart';
// reuse the _Repo fake pattern or a no-op repo returning empty stream

class _EmptyRepo implements NotificationsRepository {
  @override Future dynamicNoop() async {}
  @override Stream watch(String uid) => const Stream.empty();
  @override Future markAllRead(String uid) async => null;
  @override Future markRead(String uid, String id) async => null;
  @override Future delete(String uid, String id) async => null;
}

void main() {
  testWidgets('renders empty state', (tester) async {
    final cubit = NotificationCubit(repository: _EmptyRepo() as NotificationsRepository);
    await tester.pumpWidget(MaterialApp(
      home: BlocProvider.value(value: cubit, child: const NotificationsScreen()),
    ));
    await tester.pump();
    expect(find.byType(NotificationsScreen), findsOneWidget);
  });
}
```
> Simplify the fake to satisfy the real interface signatures (the snippet is illustrative; match exact return types `Either`/`Stream<List<AppNotificationModel>>`). Keep the assertion minimal (screen builds) to avoid brittle text matching across locales.

- [ ] **Step 2: Run test to verify it fails**

Run: `cd shree_krishna_emb_user_app && flutter test test/screens/notifications_screen_test.dart`
Expected: FAIL — screen missing.

- [ ] **Step 3: Write minimal implementation**
```dart
// lib/screens/notifications/notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';
import '../../bloc/notifications/notification_cubit.dart';
import '../../bloc/notifications/notification_state.dart';
import '../../localisations/app_localization.dart';
import '../../routes/app_routes.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppLocalization.strings;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.notifications, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          BlocBuilder<NotificationCubit, NotificationState>(
            builder: (context, state) => state.items.any((n) => !n.read)
                ? TextButton(
                    onPressed: () => context.read<NotificationCubit>().markAllRead(),
                    child: Text(s.markAllRead, maxLines: 1, overflow: TextOverflow.ellipsis),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
      body: BlocBuilder<NotificationCubit, NotificationState>(
        builder: (context, state) {
          if (state.items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.notifications_none, size: 56, color: scheme.outline),
                    const SizedBox(height: 12),
                    Text(s.noNotifications,
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Text(s.notificationsEmptyHint,
                        textAlign: TextAlign.center, maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            itemCount: state.items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final n = state.items[i];
              return Dismissible(
                key: ValueKey(n.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: scheme.errorContainer,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Icon(Icons.delete_outline, color: scheme.onErrorContainer),
                ),
                onDismissed: (_) => context.read<NotificationCubit>().delete(n.id),
                child: ListTile(
                  leading: Icon(
                    n.read ? Icons.notifications_none : Icons.notifications_active,
                    color: n.read ? scheme.outline : scheme.primary,
                  ),
                  title: Text(n.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(n.body, maxLines: 2, overflow: TextOverflow.ellipsis),
                  tileColor: n.read ? null : scheme.primaryContainer.withValues(alpha: 0.18),
                  onTap: () {
                    context.read<NotificationCubit>().delete; // no-op placeholder removed below
                    final id = n.designId;
                    context.read<NotificationCubit>(); // mark read then route
                    _open(context, n.id, id);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _open(BuildContext context, String notifId, String? designId) {
    context.read<NotificationCubit>().markRead(notifId);
    if (designId != null && designId.isNotEmpty) {
      AppRoutes.navigateToDesignDetail(context, designId);
    }
  }
}
```
> Add `markRead(String id)` to `NotificationCubit` (mirror `delete`): `Future<void> markRead(String id) async { final uid=_uid; if(uid==null) return; await repository.markRead(uid,id); }`. Remove the two stray placeholder lines in `onTap` — final `onTap` should be just `onTap: () => _open(context, n.id, n.designId)`. Use `AppAppBar` if the user app exposes it (explorer showed user app uses a custom `AppBar` in `main_screen`; check design system — if `AppAppBar` exists, prefer it).

- [ ] **Step 4: Clean up + run test**

Edit `onTap` to `onTap: () => _open(context, n.id, n.designId)` and delete the two placeholder statements above it. Add `markRead` to the cubit.
Run: `cd shree_krishna_emb_user_app && flutter test test/screens/notifications_screen_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**
```bash
git add shree_krishna_emb_user_app/lib/screens/notifications/ shree_krishna_emb_user_app/lib/bloc/notifications/notification_cubit.dart shree_krishna_emb_user_app/test/screens/notifications_screen_test.dart
git commit -m "feat(user): notification center screen with mark-read/delete/deep-link"
```

---

### Task 16: User app — bell badge + route + provider wiring

**Files:**
- Modify: `shree_krishna_emb_user_app/lib/routes/app_routes.dart`
- Modify: `shree_krishna_emb_user_app/lib/screens/main/main_screen.dart`
- Modify: `shree_krishna_emb_user_app/lib/core/di/service_locator.dart`
- Modify: `shree_krishna_emb_user_app/lib/main.dart` (MultiBlocProvider)

**Interfaces:**
- Consumes: `NotificationCubit`, `NotificationsScreen`.
- Produces: `AppRoutes.notifications` const + `navigateToNotifications(context)`; bell badge bound to `unreadCount`.

- [ ] **Step 1:** In `service_locator.dart`, register the notifications datasource/repo/cubit (singleton cubit, app-wide):
```dart
getIt.registerSingleton<NotificationsDataSource>(
  FirebaseNotificationsDataSource(firestore: getIt<FirebaseFirestore>()),
);
getIt.registerSingleton<NotificationsRepository>(
  NotificationsRepositoryImpl(dataSource: getIt<NotificationsDataSource>()),
);
getIt.registerSingleton<NotificationCubit>(
  NotificationCubit(repository: getIt<NotificationsRepository>()),
);
```
- [ ] **Step 2:** In `main.dart` `MainApp.build`, add to `MultiBlocProvider.providers`:
```dart
BlocProvider<NotificationCubit>.value(value: getIt<NotificationCubit>()),
```
And in the `AuthBloc` listener (Task 11 Step 3) add: on `AuthAuthenticated` → `getIt<NotificationCubit>().start(state.user.uid)`; on `AuthUnauthenticated` → `getIt<NotificationCubit>().stop()`.
- [ ] **Step 3:** In `app_routes.dart`, add the route:
```dart
static const String notifications = '/notifications';
// in onGenerateRoute switch:
case notifications:
  return _buildRoute(
    settings: settings,
    builder: (_) => const NotificationsScreen(),
  );
// helper:
static void navigateToNotifications(BuildContext context) =>
    Navigator.of(context).pushNamed(notifications);
```
(Import `NotificationsScreen`. Match the existing `_buildRoute`/transition signature.)
- [ ] **Step 4:** In `main_screen.dart`, replace `_buildNotificationAction` body so the dot becomes a live count and tap navigates:
```dart
Widget _buildNotificationAction(BuildContext context) {
  return BlocBuilder<NotificationCubit, NotificationState>(
    builder: (context, state) {
      final count = state.unreadCount;
      return GestureDetector(
        onTap: () => AppRoutes.navigateToNotifications(context),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(Icons.notifications_outlined,
                color: Theme.of(context).colorScheme.onSurface, size: 24),
            if (count > 0)
              Positioned(
                right: -4, top: -4,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    count > 9 ? '9+' : '$count',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onError,
                      fontSize: 9, fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
}
```
(Add imports for `flutter_bloc`, `NotificationCubit`, `NotificationState`, `AppRoutes`.)
- [ ] **Step 5: Verify + commit**

Run: `cd shree_krishna_emb_user_app && flutter analyze && flutter test`
Expected: analyzer clean; tests pass.
```bash
git add shree_krishna_emb_user_app/lib/routes/app_routes.dart shree_krishna_emb_user_app/lib/screens/main/main_screen.dart shree_krishna_emb_user_app/lib/core/di/service_locator.dart shree_krishna_emb_user_app/lib/main.dart
git commit -m "feat(user): bell badge unread count + notifications route + cubit lifecycle"
```

---

## PHASE 3 — Cloud Functions

### Task 17: Functions — export `messaging`

**Files:**
- Modify: `functions/src/lib/firebase.ts`

- [ ] **Step 1:** Add:
```ts
import { getMessaging } from "firebase-admin/messaging";
// ...after initializeApp guard...
export const messaging = getMessaging();
```
- [ ] **Step 2: Build**

Run: `cd functions && npm run build`
Expected: compiles.
- [ ] **Step 3: Commit**
```bash
git add functions/src/lib/firebase.ts
git commit -m "feat(functions): export admin messaging()"
```

---

### Task 18: Functions — `messaging.ts` helpers

**Files:**
- Create: `functions/src/notifications/messaging.ts`
- Test: `functions/src/notifications/__tests__/messaging.fanout.test.ts` (pure chunking only — see note)

**Interfaces:**
- Produces: `sendToTopic(topic, payload)`, `fanOutInbox(db, notification, opts?)` returns `Promise<number>`, `chunk<T>(arr, size)`, `pruneInvalidTokens(db, uid, tokens[])`.

- [ ] **Step 1: Write the failing test** (pure `chunk`)
```ts
// functions/src/notifications/__tests__/messaging.fanout.test.ts
import { chunk } from "../messaging";
import assert from "node:assert";

const out = chunk([1, 2, 3, 4, 5], 2);
assert.deepStrictEqual(out, [[1, 2], [3, 4], [5]]);
console.log("chunk ok");
```
> The functions package has no jest harness configured; run pure tests with `npx tsx`. If `tsx` is unavailable, compile and run with `node lib/...` after `npm run build`. (This keeps us honest — trigger/IO behavior is verified via the emulator in later tasks.)

- [ ] **Step 2: Run test to verify it fails**

Run: `cd functions && npx tsx src/notifications/__tests__/messaging.fanout.test.ts`
Expected: FAIL — `chunk` not exported / module missing.

- [ ] **Step 3: Write minimal implementation**
```ts
// functions/src/notifications/messaging.ts
import { Firestore } from "firebase-admin/firestore";
import { messaging } from "../lib/firebase";
import { Collections } from "../config/constants";

export function chunk<T>(arr: T[], size: number): T[][] {
  const out: T[][] = [];
  for (let i = 0; i < arr.length; i += size) out.push(arr.slice(i, i + size));
  return out;
}

export interface InboxPayload {
  type: string;
  title: string;
  body: string;
  imageUrl?: string | null;
  data?: Record<string, string>;
}

export async function sendToTopic(topic: string, p: InboxPayload): Promise<void> {
  await messaging.send({
    topic,
    notification: { title: p.title, body: p.body, imageUrl: p.imageUrl ?? undefined },
    data: p.data ?? {},
    android: { priority: "high" },
  });
}

/** Writes one inbox doc per user. Returns recipient count. */
export async function fanOutInbox(
  db: Firestore,
  p: InboxPayload,
): Promise<number> {
  const usersSnap = await db.collection(Collections.users).get();
  const writer = db.bulkWriter();
  let count = 0;
  for (const u of usersSnap.docs) {
    const ref = u.ref.collection(Collections.userNotifications).doc();
    writer.set(ref, {
      type: p.type,
      title: p.title,
      body: p.body,
      imageUrl: p.imageUrl ?? null,
      data: p.data ?? {},
      read: false,
      createdAt: new Date().toISOString(),
    });
    count++;
  }
  await writer.close();
  return count;
}

export async function pruneInvalidTokens(
  db: Firestore,
  uid: string,
  tokens: string[],
): Promise<void> {
  await Promise.all(
    tokens.map((t) =>
      db
        .collection(Collections.users)
        .doc(uid)
        .collection(Collections.fcmTokens)
        .doc(t)
        .delete()
        .catch(() => undefined),
    ),
  );
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd functions && npx tsx src/notifications/__tests__/messaging.fanout.test.ts`
Expected: prints `chunk ok`.

- [ ] **Step 5: Commit**
```bash
git add functions/src/notifications/messaging.ts functions/src/notifications/__tests__/messaging.fanout.test.ts
git commit -m "feat(functions): messaging helpers (topic send, inbox fan-out, token prune)"
```

---

### Task 19: Functions — `digestLogic.ts` (pure slot/cap/cursor selection)

**Files:**
- Create: `functions/src/notifications/digestLogic.ts`
- Test: `functions/src/notifications/__tests__/digestLogic.test.ts`

**Interfaces:**
- Produces: `selectDueSlot({ slots, firedToday, nowHHmm }): string | null` — returns the latest slot `<= nowHHmm` not in `firedToday`, or null; `dayKey(date, tzOffsetMinutes): string` (YYYY-MM-DD); `hhmm(date, tzOffsetMinutes): string`.

- [ ] **Step 1: Write the failing test**
```ts
// functions/src/notifications/__tests__/digestLogic.test.ts
import { selectDueSlot } from "../digestLogic";
import assert from "node:assert";

// 14:30 now, slots 10:00/14:00/18:00, 10:00 already fired -> 14:00 is due
assert.strictEqual(
  selectDueSlot({ slots: ["10:00", "14:00", "18:00"], firedToday: ["10:00"], nowHHmm: "14:30" }),
  "14:00",
);
// nothing due before first slot
assert.strictEqual(
  selectDueSlot({ slots: ["10:00"], firedToday: [], nowHHmm: "09:00" }),
  null,
);
// all due slots already fired
assert.strictEqual(
  selectDueSlot({ slots: ["10:00", "14:00"], firedToday: ["10:00", "14:00"], nowHHmm: "23:00" }),
  null,
);
console.log("digestLogic ok");
```

- [ ] **Step 2: Run to verify it fails**

Run: `cd functions && npx tsx src/notifications/__tests__/digestLogic.test.ts`
Expected: FAIL.

- [ ] **Step 3: Write minimal implementation**
```ts
// functions/src/notifications/digestLogic.ts
export interface SlotInput {
  slots: string[];      // ["HH:mm"]
  firedToday: string[]; // ["HH:mm"] already sent today
  nowHHmm: string;      // "HH:mm" in target tz
}

/** Latest slot whose time <= now and not already fired today. */
export function selectDueSlot(i: SlotInput): string | null {
  const due = i.slots
    .filter((s) => s <= i.nowHHmm && !i.firedToday.includes(s))
    .sort(); // lexical sort works for zero-padded HH:mm
  return due.length ? due[due.length - 1] : null;
}

/** Shift a UTC date by tz offset minutes and format helpers. */
function shifted(d: Date, tzOffsetMinutes: number): Date {
  return new Date(d.getTime() + tzOffsetMinutes * 60_000);
}

export function dayKey(d: Date, tzOffsetMinutes: number): string {
  const x = shifted(d, tzOffsetMinutes);
  return x.toISOString().slice(0, 10);
}

export function hhmm(d: Date, tzOffsetMinutes: number): string {
  const x = shifted(d, tzOffsetMinutes);
  return x.toISOString().slice(11, 16);
}
```
> `Asia/Kolkata` offset is +330 minutes; pass `330` from the scheduler. (If DST-aware zones are ever needed, swap to a tz library; India has no DST so a fixed offset is correct here.)

- [ ] **Step 4: Run to verify it passes**

Run: `cd functions && npx tsx src/notifications/__tests__/digestLogic.test.ts`
Expected: prints `digestLogic ok`.

- [ ] **Step 5: Commit**
```bash
git add functions/src/notifications/digestLogic.ts functions/src/notifications/__tests__/digestLogic.test.ts
git commit -m "feat(functions): pure digest slot/cursor selection logic"
```

---

### Task 20: Functions — `broadcastNotification` callable

**Files:**
- Create: `functions/src/notifications/broadcastNotification.ts`
- Modify: `functions/src/index.ts` (export)

**Interfaces:**
- Consumes: `sendToTopic`, `fanOutInbox`, `TOPIC_ALL_USERS`, `NotificationType`, `db`.
- Produces: callable `broadcastNotification({ title, body })` → `{ recipientCount }`; admin-guarded.

- [ ] **Step 1:** Write the implementation:
```ts
// functions/src/notifications/broadcastNotification.ts
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { db } from "../lib/firebase";
import { Collections, Docs, NotificationType, TOPIC_ALL_USERS } from "../config/constants";
import { fanOutInbox, sendToTopic } from "./messaging";

async function assertAdmin(auth: { uid: string; token: Record<string, unknown> } | undefined) {
  if (!auth) throw new HttpsError("unauthenticated", "Sign in required.");
  if (auth.token?.role === "admin") return;
  const snap = await db.collection(Collections.users).doc(auth.uid).get();
  if (snap.get("role") !== "admin") {
    throw new HttpsError("permission-denied", "Admin only.");
  }
}

export const broadcastNotification = onCall(async (req) => {
  await assertAdmin(req.auth as never);

  const title = String(req.data?.title ?? "").trim();
  const body = String(req.data?.body ?? "").trim();
  if (!title || title.length > 120) throw new HttpsError("invalid-argument", "Bad title.");
  if (!body || body.length > 500) throw new HttpsError("invalid-argument", "Bad body.");

  const settings = await db.collection(Collections.config).doc(Docs.configNotifications).get();
  if (settings.exists && settings.get("masterEnabled") === false) {
    throw new HttpsError("failed-precondition", "Notifications are disabled.");
  }

  const payload = {
    type: NotificationType.broadcast,
    title,
    body,
    data: { route: "home" },
  };
  await sendToTopic(TOPIC_ALL_USERS, payload);
  const recipientCount = await fanOutInbox(db, payload);
  return { recipientCount };
});
```
- [ ] **Step 2:** In `index.ts` add: `export { broadcastNotification } from "./notifications/broadcastNotification";`
- [ ] **Step 3: Build + emulator smoke test**

Run: `cd functions && npm run build`
Expected: compiles.
Then (manual, emulator): `firebase emulators:start --only functions,firestore`, seed a `users/{uid}` doc with `role:'admin'`, call `broadcastNotification` from the Functions shell with `{title:'Hi',body:'There'}`, confirm `{recipientCount:N}` and inbox docs appear. Confirm a non-admin call throws `permission-denied`.
- [ ] **Step 4: Commit**
```bash
git add functions/src/notifications/broadcastNotification.ts functions/src/index.ts
git commit -m "feat(functions): admin broadcastNotification callable (topic + fan-out)"
```

---

### Task 21: Functions — `onOrderFinalized` (admin purchase inbox)

**Files:**
- Create: `functions/src/notifications/onOrderFinalized.ts`
- Modify: `functions/src/index.ts`

**Interfaces:**
- Consumes: `db`, `Collections`, `Docs`, `NotificationType`, `OrderStatus`.
- Produces: trigger `onOrderFinalized` (onDocumentWritten `orders/{orderId}`) writing one `admin_notifications` doc on transition into `paid`.

- [ ] **Step 1:** Implementation:
```ts
// functions/src/notifications/onOrderFinalized.ts
import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { db } from "../lib/firebase";
import { Collections, Docs, NotificationType, OrderStatus } from "../config/constants";

export const onOrderFinalized = onDocumentWritten(
  `${Collections.orders}/{orderId}`,
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!after) return;
    const becamePaid = before?.status !== OrderStatus.paid && after.status === OrderStatus.paid;
    if (!becamePaid) return;

    const settings = await db.collection(Collections.config).doc(Docs.configNotifications).get();
    if (settings.exists && settings.get("purchaseAlertsEnabled") === false) return;

    const items: Array<Record<string, unknown>> = Array.isArray(after.items) ? after.items : [];
    const first = items[0] ?? {};
    const designTitle = (first.title as string) ?? (first.name as string) ?? "an item";
    const buyer = (after.buyerName as string) ?? "A user";
    const total = typeof after.totalAmount === "number" ? after.totalAmount : 0;
    const rupees = (total / 100).toFixed(total % 100 === 0 ? 0 : 2);
    const body =
      total > 0
        ? `${designTitle} — ₹${rupees} by ${buyer}`
        : `${designTitle} (free) claimed by ${buyer}`;

    await db.collection(Collections.adminNotifications).add({
      type: NotificationType.purchase,
      title: "New purchase",
      body,
      data: {
        orderId: event.params.orderId,
        designId: (first.designId as string) ?? "",
        userId: (after.userId as string) ?? "",
      },
      readBy: [],
      createdAt: new Date().toISOString(),
    });
  },
);
```
- [ ] **Step 2:** `index.ts`: `export { onOrderFinalized } from "./notifications/onOrderFinalized";`
- [ ] **Step 3: Build + emulator test**

Run: `cd functions && npm run build` (compiles), then in the emulator write an `orders/{id}` doc transitioning `status` `created`→`paid` and confirm exactly one `admin_notifications` doc is created; a second write with `status` still `paid` creates none (idempotency).
- [ ] **Step 4: Commit**
```bash
git add functions/src/notifications/onOrderFinalized.ts functions/src/index.ts
git commit -m "feat(functions): admin purchase alert on order finalized"
```

---

### Task 22: Functions — `onDesignWritten` (stamp `activatedAt`)

**Files:**
- Create: `functions/src/notifications/onDesignWritten.ts`
- Modify: `functions/src/index.ts`

**Interfaces:**
- Produces: trigger setting `activatedAt = serverTimestamp()` when `status` first becomes `active` and `activatedAt` is unset. Idempotent.

- [ ] **Step 1:** Implementation:
```ts
// functions/src/notifications/onDesignWritten.ts
import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { FieldValue } from "firebase-admin/firestore";
import { Collections, DesignStatus } from "../config/constants";

export const onDesignWritten = onDocumentWritten(
  `${Collections.designs}/{designId}`,
  async (event) => {
    const after = event.data?.after;
    if (!after?.exists) return;
    const data = after.data() as Record<string, unknown>;
    const isActive = data.status === DesignStatus.active;
    const alreadyStamped = data.activatedAt != null;
    if (isActive && !alreadyStamped) {
      await after.ref.update({ activatedAt: FieldValue.serverTimestamp() });
    }
  },
);
```
- [ ] **Step 2:** `index.ts`: `export { onDesignWritten } from "./notifications/onDesignWritten";`
- [ ] **Step 3: Build + emulator test**

Run: `cd functions && npm run build`; in emulator create a `designs/{id}` doc with `status:'active'` and confirm `activatedAt` gets stamped once; subsequent updates don't re-stamp.
- [ ] **Step 4: Commit**
```bash
git add functions/src/notifications/onDesignWritten.ts functions/src/index.ts
git commit -m "feat(functions): stamp activatedAt when a design becomes active"
```

---

### Task 23: Functions — `sendNewDesignDigest` scheduler

**Files:**
- Create: `functions/src/notifications/sendNewDesignDigest.ts`
- Modify: `functions/src/index.ts`

**Interfaces:**
- Consumes: `selectDueSlot`, `dayKey`, `hhmm` (Task 19), `sendToTopic`, `fanOutInbox`, `db`.
- Produces: scheduled function (every 30 min) that fires at most one digest per due slot, ≤4/day.

- [ ] **Step 1:** Implementation:
```ts
// functions/src/notifications/sendNewDesignDigest.ts
import { onSchedule } from "firebase-functions/v2/scheduler";
import { db } from "../lib/firebase";
import { Collections, Docs, DesignStatus, NotificationType, TOPIC_ALL_USERS } from "../config/constants";
import { fanOutInbox, sendToTopic } from "./messaging";
import { selectDueSlot, dayKey, hhmm } from "./digestLogic";

const KOLKATA_OFFSET_MIN = 330;

export const sendNewDesignDigest = onSchedule("every 30 minutes", async () => {
  const ref = db.collection(Collections.config).doc(Docs.configNotifications);
  const snap = await ref.get();
  if (!snap.exists) return;
  const s = snap.data() as Record<string, unknown>;

  if (s.masterEnabled === false || s.newDesignAlertsEnabled === false) return;

  const slots = (s.dailySlots as string[]) ?? [];
  if (slots.length === 0) return;
  const offset = typeof s.timezone === "string" && s.timezone === "Asia/Kolkata" ? KOLKATA_OFFSET_MIN : KOLKATA_OFFSET_MIN;

  const now = new Date();
  const today = dayKey(now, offset);
  const firedSlots = (s.firedSlots as Record<string, string[]>) ?? {};
  const firedToday = firedSlots[today] ?? [];
  if (firedToday.length >= 4) return;

  const due = selectDueSlot({ slots, firedToday, nowHHmm: hhmm(now, offset) });
  if (!due) return;

  // Mark fired up-front (so empty windows don't re-poll every 30 min).
  const markFired = { ...firedSlots, [today]: [...firedToday, due] };

  const cursorRaw = s.newDesignCursor as string | undefined;
  let q = db
    .collection(Collections.designs)
    .where("status", "==", DesignStatus.active)
    .orderBy("activatedAt", "asc");
  if (cursorRaw) {
    q = q.where("activatedAt", ">", new Date(cursorRaw));
  }
  const designs = await q.get();

  if (designs.empty) {
    await ref.set({ firedSlots: markFired }, { merge: true });
    return;
  }

  const count = designs.size;
  const newest = designs.docs[designs.docs.length - 1];
  const nd = newest.data() as Record<string, unknown>;
  const image =
    (nd.thumbUrl as string) ?? (nd.previewUrl as string) ??
    ((nd.images as string[] | undefined)?.[0]) ?? null;

  const payload = {
    type: NotificationType.newDesign,
    title: count === 1 ? "New design just dropped ✨" : `${count} new designs just dropped ✨`,
    body: "Tap to explore the latest designs.",
    imageUrl: image,
    data: { route: "design", designId: newest.id },
  };

  await sendToTopic(TOPIC_ALL_USERS, payload);
  await fanOutInbox(db, payload);

  // Advance cursor + persist fired slot.
  const newestActivatedAt = nd.activatedAt;
  const cursorIso =
    typeof (newestActivatedAt as { toDate?: () => Date })?.toDate === "function"
      ? (newestActivatedAt as { toDate: () => Date }).toDate().toISOString()
      : new Date().toISOString();
  await ref.set({ firedSlots: markFired, newDesignCursor: cursorIso }, { merge: true });
});
```
> If the `activatedAt` index isn't deployed yet, the `orderBy('activatedAt')` query errors — deploy Task 7 indexes first (`firebase deploy --only firestore:indexes`). Old `firedSlots` day keys can be pruned later; they're harmless small data.
- [ ] **Step 2:** `index.ts`: `export { sendNewDesignDigest } from "./notifications/sendNewDesignDigest";`
- [ ] **Step 3: Build + emulator test**

Run: `cd functions && npm run build`; with the Firestore emulator, set `config/notifications` `dailySlots` to a slot just passed (in IST), seed an active design with `activatedAt` after the cursor, trigger the schedule (emulator scheduler or invoke handler directly), and confirm: one fan-out batch written, `newDesignCursor` advanced, `firedSlots[today]` includes the slot, and a re-run in the same window sends nothing.
- [ ] **Step 4: Commit**
```bash
git add functions/src/notifications/sendNewDesignDigest.ts functions/src/index.ts
git commit -m "feat(functions): scheduled new-design digest (admin slots, <=4/day)"
```

---

### Task 23b: Functions — deploy + one-time `activatedAt` backfill

**Files:**
- Create: `functions/scripts/backfillActivatedAt.ts`

- [ ] **Step 1:** Write a one-shot backfill (sets `activatedAt = createdAt` for existing `status=='active'` designs so the first digest has a sane cursor baseline):
```ts
// functions/scripts/backfillActivatedAt.ts
import { initializeApp } from "firebase-admin/app";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { Collections, DesignStatus } from "../src/config/constants";

initializeApp();
const db = getFirestore();

(async () => {
  const snap = await db.collection(Collections.designs).where("status", "==", DesignStatus.active).get();
  const writer = db.bulkWriter();
  let n = 0;
  for (const d of snap.docs) {
    if (d.get("activatedAt") == null) {
      writer.update(d.ref, { activatedAt: d.get("createdAt") ?? FieldValue.serverTimestamp() });
      n++;
    }
  }
  await writer.close();
  console.log(`backfilled ${n} designs`);
})();
```
- [ ] **Step 2:** Deploy indexes + functions, then run the backfill against the project (requires service-account/admin credentials configured locally):
```bash
cd functions
firebase deploy --only firestore:indexes
npm run build && firebase deploy --only functions
npx tsx scripts/backfillActivatedAt.ts   # one-time; uses GOOGLE_APPLICATION_CREDENTIALS
```
Expected: indexes built; functions deployed; backfill prints a count. Then set `config/notifications.newDesignCursor` to the current time so the first digest doesn't blast the entire backlog.
- [ ] **Step 3: Commit**
```bash
git add functions/scripts/backfillActivatedAt.ts
git commit -m "chore(functions): one-time activatedAt backfill script"
```

---

## PHASE 4 — Admin app

### Task 24: Admin — notification settings datasource + repository

**Files:**
- Create: `shree_krishna_emb_admin/lib/data/datasources/firebase_notification_settings_datasource.dart`
- Create: `shree_krishna_emb_admin/lib/domain/repositories/notification_settings_repository.dart`
- Create: `shree_krishna_emb_admin/lib/data/repositories/notification_settings_repository_impl.dart`
- Test: `shree_krishna_emb_admin/test/data/notification_settings_repository_test.dart`

**Interfaces:**
- Produces: `abstract class NotificationSettingsDataSource { Future<NotificationSettingsModel> get(); Future<void> save(NotificationSettingsModel, String adminUid); }`; `FirebaseNotificationSettingsDataSource(FirebaseFirestore)` reading/writing `config/notifications`; repository wrapping with `Either`.

- [ ] **Step 1: Write the failing test** (repo fold)
```dart
// shree_krishna_emb_admin/test/data/notification_settings_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shree_krishna_core/models/notification_settings_model.dart';
import 'package:shree_krishna_emb_admin/data/datasources/firebase_notification_settings_datasource.dart';
import 'package:shree_krishna_emb_admin/data/repositories/notification_settings_repository_impl.dart';

class _Ds implements NotificationSettingsDataSource {
  bool boom = false;
  NotificationSettingsModel? saved;
  @override
  Future<NotificationSettingsModel> get() async {
    if (boom) throw Exception('x');
    return NotificationSettingsModel.defaults();
  }
  @override
  Future<void> save(NotificationSettingsModel m, String adminUid) async {
    if (boom) throw Exception('x');
    saved = m;
  }
}

void main() {
  test('load success -> Right', () async {
    final repo = NotificationSettingsRepositoryImpl(dataSource: _Ds());
    expect((await repo.load()).isRight(), true);
  });
  test('save failure -> Left', () async {
    final repo = NotificationSettingsRepositoryImpl(dataSource: _Ds()..boom = true);
    final r = await repo.save(NotificationSettingsModel.defaults(), 'admin1');
    expect(r.isLeft(), true);
  });
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `cd shree_krishna_emb_admin && flutter test test/data/notification_settings_repository_test.dart`
Expected: FAIL.

- [ ] **Step 3: Write minimal implementation**
```dart
// lib/data/datasources/firebase_notification_settings_datasource.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shree_krishna_core/constants/firestore_collections.dart';
import 'package:shree_krishna_core/models/notification_settings_model.dart';

abstract class NotificationSettingsDataSource {
  Future<NotificationSettingsModel> get();
  Future<void> save(NotificationSettingsModel settings, String adminUid);
}

class FirebaseNotificationSettingsDataSource implements NotificationSettingsDataSource {
  final FirebaseFirestore _firestore;
  FirebaseNotificationSettingsDataSource({required FirebaseFirestore firestore}) : _firestore = firestore;

  DocumentReference<Map<String, dynamic>> get _doc => _firestore
      .collection(FirestoreCollections.config)
      .doc(FirestoreCollections.configNotificationsDoc);

  @override
  Future<NotificationSettingsModel> get() async {
    final snap = await _doc.get();
    if (!snap.exists) return NotificationSettingsModel.defaults();
    return NotificationSettingsModel.fromFirebaseJson(snap.data()!);
  }

  @override
  Future<void> save(NotificationSettingsModel settings, String adminUid) async {
    final json = settings.toFirebaseJson()
      ..['updatedAt'] = DateTime.now().toIso8601String()
      ..['updatedBy'] = adminUid;
    await _doc.set(json, SetOptions(merge: true));
  }
}
```
> Confirm the admin core constant name for the `config` collection (`FirestoreCollections.config`). If the admin app references config via a different constant, use it.
```dart
// lib/domain/repositories/notification_settings_repository.dart
import 'package:shree_krishna_core/errors/failures.dart';
import 'package:shree_krishna_core/utils/either.dart'; // adjust to admin app's Either path
import 'package:shree_krishna_core/models/notification_settings_model.dart';

abstract class NotificationSettingsRepository {
  Future<Either<Failure, NotificationSettingsModel>> load();
  Future<Either<Failure, void>> save(NotificationSettingsModel settings, String adminUid);
}
```
```dart
// lib/data/repositories/notification_settings_repository_impl.dart
import 'package:shree_krishna_core/errors/failures.dart';
import 'package:shree_krishna_core/utils/either.dart'; // adjust
import 'package:shree_krishna_core/models/notification_settings_model.dart';
import '../datasources/firebase_notification_settings_datasource.dart';
import '../../domain/repositories/notification_settings_repository.dart';

class NotificationSettingsRepositoryImpl implements NotificationSettingsRepository {
  final NotificationSettingsDataSource dataSource;
  NotificationSettingsRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, NotificationSettingsModel>> load() async {
    try { return Right(await dataSource.get()); }
    catch (e) { return Left(ServerFailure(e.toString())); }
  }

  @override
  Future<Either<Failure, void>> save(NotificationSettingsModel s, String adminUid) async {
    try { await dataSource.save(s, adminUid); return const Right(null); }
    catch (e) { return Left(ServerFailure(e.toString())); }
  }
}
```
> Match the admin app's actual `Either`/`Failure` import (grep an existing admin repo impl, e.g. `media_repository_impl.dart`).

- [ ] **Step 4: Run to verify it passes**

Run: `cd shree_krishna_emb_admin && flutter test test/data/notification_settings_repository_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**
```bash
git add shree_krishna_emb_admin/lib/data/datasources/firebase_notification_settings_datasource.dart shree_krishna_emb_admin/lib/domain/repositories/notification_settings_repository.dart shree_krishna_emb_admin/lib/data/repositories/notification_settings_repository_impl.dart shree_krishna_emb_admin/test/data/notification_settings_repository_test.dart
git commit -m "feat(admin): notification settings datasource + repository"
```

---

### Task 25: Admin — `NotificationSettingsCubit`

**Files:**
- Create: `shree_krishna_emb_admin/lib/bloc/settings/notification_settings_state.dart`
- Create: `shree_krishna_emb_admin/lib/bloc/settings/notification_settings_cubit.dart`
- Test: `shree_krishna_emb_admin/test/bloc/notification_settings_cubit_test.dart`

**Interfaces:**
- Consumes: `NotificationSettingsRepository`.
- Produces: state `{ status, NotificationSettingsModel settings }`; cubit `load()`, `toggleMaster(bool)`, `togglePurchase(bool)`, `toggleNewDesign(bool)`, `addSlot(String)`, `removeSlot(String)`, `save(String adminUid)`. `addSlot` rejects when already 4 slots or duplicate; keeps slots sorted.

- [ ] **Step 1: Write the failing test**
```dart
// shree_krishna_emb_admin/test/bloc/notification_settings_cubit_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shree_krishna_core/errors/failures.dart';
import 'package:shree_krishna_core/utils/either.dart';
import 'package:shree_krishna_core/models/notification_settings_model.dart';
import 'package:shree_krishna_emb_admin/bloc/settings/notification_settings_cubit.dart';
import 'package:shree_krishna_emb_admin/domain/repositories/notification_settings_repository.dart';

class _Repo implements NotificationSettingsRepository {
  @override Future<Either<Failure, NotificationSettingsModel>> load() async =>
      Right(NotificationSettingsModel.defaults());
  @override Future<Either<Failure, void>> save(NotificationSettingsModel s, String a) async =>
      const Right(null);
}

void main() {
  test('addSlot caps at 4 and dedupes + sorts', () async {
    final c = NotificationSettingsCubit(repository: _Repo());
    await c.load();
    c.addSlot('18:00'); c.addSlot('10:00'); c.addSlot('10:00'); // dup ignored
    c.addSlot('14:00'); c.addSlot('21:00'); c.addSlot('23:00'); // 5th rejected
    expect(c.state.settings.dailySlots, ['10:00', '14:00', '18:00', '21:00']);
  });
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `cd shree_krishna_emb_admin && flutter test test/bloc/notification_settings_cubit_test.dart`
Expected: FAIL.

- [ ] **Step 3: Write minimal implementation**
```dart
// lib/bloc/settings/notification_settings_state.dart
import 'package:equatable/equatable.dart';
import 'package:shree_krishna_core/models/notification_settings_model.dart';

enum NotifSettingsStatus { initial, loading, ready, saving, saved, error }

class NotificationSettingsState extends Equatable {
  final NotifSettingsStatus status;
  final NotificationSettingsModel settings;
  final String? error;
  const NotificationSettingsState({
    this.status = NotifSettingsStatus.initial,
    this.settings = const NotificationSettingsModel(),
    this.error,
  });
  NotificationSettingsState copyWith({
    NotifSettingsStatus? status,
    NotificationSettingsModel? settings,
    String? error,
  }) => NotificationSettingsState(
        status: status ?? this.status,
        settings: settings ?? this.settings,
        error: error,
      );
  @override
  List<Object?> get props => [status, settings, error];
}
```
```dart
// lib/bloc/settings/notification_settings_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shree_krishna_core/models/notification_settings_model.dart';
import '../../domain/repositories/notification_settings_repository.dart';
import 'notification_settings_state.dart';

class NotificationSettingsCubit extends Cubit<NotificationSettingsState> {
  final NotificationSettingsRepository repository;
  NotificationSettingsCubit({required this.repository}) : super(const NotificationSettingsState());

  Future<void> load() async {
    emit(state.copyWith(status: NotifSettingsStatus.loading));
    final r = await repository.load();
    r.fold(
      (f) => emit(state.copyWith(status: NotifSettingsStatus.error, error: f.message)),
      (s) => emit(state.copyWith(status: NotifSettingsStatus.ready,
          settings: NotificationSettingsModel.fromEntity(s))),
    );
  }

  void _update(NotificationSettingsModel s) =>
      emit(state.copyWith(status: NotifSettingsStatus.ready, settings: s));

  void toggleMaster(bool v) => _update(
      NotificationSettingsModel.fromEntity(state.settings.copyWith(masterEnabled: v)));
  void togglePurchase(bool v) => _update(
      NotificationSettingsModel.fromEntity(state.settings.copyWith(purchaseAlertsEnabled: v)));
  void toggleNewDesign(bool v) => _update(
      NotificationSettingsModel.fromEntity(state.settings.copyWith(newDesignAlertsEnabled: v)));

  void addSlot(String hhmm) {
    final slots = [...state.settings.dailySlots];
    if (slots.length >= 4 || slots.contains(hhmm)) return;
    slots..add(hhmm)..sort();
    _update(NotificationSettingsModel.fromEntity(state.settings.copyWith(dailySlots: slots)));
  }

  void removeSlot(String hhmm) {
    final slots = [...state.settings.dailySlots]..remove(hhmm);
    _update(NotificationSettingsModel.fromEntity(state.settings.copyWith(dailySlots: slots)));
  }

  Future<void> save(String adminUid) async {
    emit(state.copyWith(status: NotifSettingsStatus.saving));
    final r = await repository.save(state.settings, adminUid);
    r.fold(
      (f) => emit(state.copyWith(status: NotifSettingsStatus.error, error: f.message)),
      (_) => emit(state.copyWith(status: NotifSettingsStatus.saved)),
    );
  }
}
```
> Confirm `Failure.message` getter name in the admin app.

- [ ] **Step 4: Run to verify it passes**

Run: `cd shree_krishna_emb_admin && flutter test test/bloc/notification_settings_cubit_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**
```bash
git add shree_krishna_emb_admin/lib/bloc/settings/ shree_krishna_emb_admin/test/bloc/notification_settings_cubit_test.dart
git commit -m "feat(admin): NotificationSettingsCubit (toggles + slots, cap 4)"
```

---

### Task 26: Admin — localization strings (settings + broadcast + inbox)

**Files:**
- Modify: `shree_krishna_emb_admin/lib/l10n/locales/locale_base.dart`
- Modify: `shree_krishna_emb_admin/lib/l10n/locales/en_us.dart`
- Modify: `shree_krishna_emb_admin/lib/l10n/locales/hi_in.dart`

- [ ] **Step 1:** Add getters to `locale_base.dart`:
```dart
String get notifications;
String get enablePushNotifications;
String get purchaseAlerts;
String get newDesignAlerts;
String get dailySendTimes;
String get addSendTime;
String get maxFourSlots;
String get sendBroadcast;
String get broadcastTitle;
String get broadcastBody;
String get sendToAllUsers;
String get broadcastSent;
String get markAllRead;
String get noAdminNotifications;
```
- [ ] **Step 2:** Implement English in `en_us.dart`:
```dart
@override String get notifications => 'Notifications';
@override String get enablePushNotifications => 'Enable push notifications';
@override String get purchaseAlerts => 'Purchase alerts';
@override String get newDesignAlerts => 'New-design alerts to users';
@override String get dailySendTimes => 'Daily send times (max 4)';
@override String get addSendTime => 'Add send time';
@override String get maxFourSlots => 'You can set up to 4 send times per day.';
@override String get sendBroadcast => 'Send broadcast';
@override String get broadcastTitle => 'Title';
@override String get broadcastBody => 'Message';
@override String get sendToAllUsers => 'Send to all users';
@override String get broadcastSent => 'Notification sent to all users';
@override String get markAllRead => 'Mark all read';
@override String get noAdminNotifications => 'No notifications yet';
```
- [ ] **Step 3:** Implement Hindi in `hi_in.dart`:
```dart
@override String get notifications => 'सूचनाएं';
@override String get enablePushNotifications => 'पुश सूचनाएं सक्षम करें';
@override String get purchaseAlerts => 'खरीद अलर्ट';
@override String get newDesignAlerts => 'उपयोगकर्ताओं को नई डिज़ाइन अलर्ट';
@override String get dailySendTimes => 'दैनिक भेजने का समय (अधिकतम 4)';
@override String get addSendTime => 'समय जोड़ें';
@override String get maxFourSlots => 'आप प्रतिदिन 4 समय तक सेट कर सकते हैं।';
@override String get sendBroadcast => 'ब्रॉडकास्ट भेजें';
@override String get broadcastTitle => 'शीर्षक';
@override String get broadcastBody => 'संदेश';
@override String get sendToAllUsers => 'सभी उपयोगकर्ताओं को भेजें';
@override String get broadcastSent => 'सभी उपयोगकर्ताओं को सूचना भेजी गई';
@override String get markAllRead => 'सभी पढ़ी हुई चिह्नित करें';
@override String get noAdminNotifications => 'अभी कोई सूचना नहीं';
```
- [ ] **Step 4: Verify + commit**

Run: `cd shree_krishna_emb_admin && flutter analyze lib/l10n/`
Expected: no errors.
```bash
git add shree_krishna_emb_admin/lib/l10n/locales/
git commit -m "feat(admin): notification/broadcast localization strings"
```

---

### Task 27: Admin — notification settings form (replace "Coming Soon")

**Files:**
- Create: `shree_krishna_emb_admin/lib/screens/settings/widgets/notification_settings_form.dart`
- Modify: `shree_krishna_emb_admin/lib/screens/settings/settings_content_view.dart` (Notifications tab — the `case 2` placeholder)
- Modify: `shree_krishna_emb_admin/lib/core/di/service_locator.dart` (register datasource/repo/cubit)

**Interfaces:**
- Consumes: `NotificationSettingsCubit`, `AdminAuthBloc` (for `adminId`), `AppLocalization.strings.*`.

- [ ] **Step 1:** Register in `service_locator.dart`:
```dart
getIt.registerSingleton<NotificationSettingsDataSource>(
  FirebaseNotificationSettingsDataSource(firestore: getIt<FirebaseFirestore>()),
);
getIt.registerSingleton<NotificationSettingsRepository>(
  NotificationSettingsRepositoryImpl(dataSource: getIt<NotificationSettingsDataSource>()),
);
getIt.registerFactory<NotificationSettingsCubit>(
  () => NotificationSettingsCubit(repository: getIt<NotificationSettingsRepository>()),
);
```
- [ ] **Step 2:** Implement the form:
```dart
// lib/screens/settings/widgets/notification_settings_form.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';
import '../../../bloc/admin_auth/admin_auth_bloc.dart';
import '../../../bloc/settings/notification_settings_cubit.dart';
import '../../../bloc/settings/notification_settings_state.dart';
import '../../../core/di/service_locator.dart';
import '../../../l10n/app_localization.dart'; // confirm admin localization import path

class NotificationSettingsForm extends StatelessWidget {
  const NotificationSettingsForm({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<NotificationSettingsCubit>(
      create: (_) => getIt<NotificationSettingsCubit>()..load(),
      child: const _FormBody(),
    );
  }
}

class _FormBody extends StatelessWidget {
  const _FormBody();

  @override
  Widget build(BuildContext context) {
    final s = AppLocalization.strings;
    return BlocConsumer<NotificationSettingsCubit, NotificationSettingsState>(
      listener: (context, state) {
        if (state.status == NotifSettingsStatus.saved) {
          ResponsiveSnackbar(s.success, context);
        } else if (state.status == NotifSettingsStatus.error) {
          ResponsiveSnackbar(state.error ?? s.error, context);
        }
      },
      builder: (context, state) {
        final cubit = context.read<NotificationSettingsCubit>();
        final cfg = state.settings;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile(
                value: cfg.masterEnabled,
                onChanged: cubit.toggleMaster,
                title: Text(s.enablePushNotifications, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              SwitchListTile(
                value: cfg.purchaseAlertsEnabled,
                onChanged: cfg.masterEnabled ? cubit.togglePurchase : null,
                title: Text(s.purchaseAlerts, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              SwitchListTile(
                value: cfg.newDesignAlertsEnabled,
                onChanged: cfg.masterEnabled ? cubit.toggleNewDesign : null,
                title: Text(s.newDesignAlerts, maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(height: 16),
              Text(s.dailySendTimes, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: [
                  for (final slot in cfg.dailySlots)
                    Chip(
                      label: Text(slot, maxLines: 1, overflow: TextOverflow.ellipsis),
                      onDeleted: () => cubit.removeSlot(slot),
                    ),
                  if (cfg.dailySlots.length < 4)
                    ActionChip(
                      avatar: const Icon(Icons.add, size: 18),
                      label: Text(s.addSendTime, maxLines: 1, overflow: TextOverflow.ellipsis),
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: context, initialTime: const TimeOfDay(hour: 10, minute: 0),
                        );
                        if (picked != null) {
                          cubit.addSlot(
                              '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}');
                        }
                      },
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(s.maxFourSlots, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  label: s.save,
                  isLoading: state.status == NotifSettingsStatus.saving,
                  onPressed: () {
                    final auth = context.read<AdminAuthBloc>().state;
                    final uid = auth is AdminAuthAuthenticated ? auth.adminId : '';
                    cubit.save(uid);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
```
> Confirm: `AppButton` parameter names (`label`/`onPressed`/`isLoading`) against the design system; `ResponsiveSnackbar(message, context)` signature (per memory); `AdminAuthAuthenticated.adminId`; admin localization import path; `s.success`/`s.save`/`s.error` exist (they do per the admin l10n explorer).
- [ ] **Step 3:** In `settings_content_view.dart`, replace the Notifications-tab placeholder (the "Coming Soon" `case 2` content, ~line 160) with `const NotificationSettingsForm()` (import it).
- [ ] **Step 4: Verify + commit**

Run: `cd shree_krishna_emb_admin && flutter analyze && flutter test`
Expected: clean.
```bash
git add shree_krishna_emb_admin/lib/screens/settings/widgets/notification_settings_form.dart shree_krishna_emb_admin/lib/screens/settings/settings_content_view.dart shree_krishna_emb_admin/lib/core/di/service_locator.dart
git commit -m "feat(admin): notification settings form (toggles + send-time slots)"
```

---

### Task 28: Admin — broadcast service + `BroadcastCubit`

**Files:**
- Create: `shree_krishna_emb_admin/lib/data/services/broadcast_service.dart`
- Create: `shree_krishna_emb_admin/lib/bloc/notifications/broadcast_cubit.dart`
- Test: `shree_krishna_emb_admin/test/bloc/broadcast_cubit_test.dart`

**Interfaces:**
- Produces: `abstract class BroadcastService { Future<int> send(String title, String body); }`; `FunctionsBroadcastService(FirebaseFunctions)` calling `broadcastNotification`; `BroadcastCubit{ send(title, body) }` with state `{ status, recipientCount, error }`.

- [ ] **Step 1: Write the failing test**
```dart
// shree_krishna_emb_admin/test/bloc/broadcast_cubit_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shree_krishna_emb_admin/bloc/notifications/broadcast_cubit.dart';
import 'package:shree_krishna_emb_admin/data/services/broadcast_service.dart';

class _OkSvc implements BroadcastService {
  @override Future<int> send(String t, String b) async => 42;
}
class _ErrSvc implements BroadcastService {
  @override Future<int> send(String t, String b) async => throw Exception('nope');
}

void main() {
  test('send success exposes recipientCount', () async {
    final c = BroadcastCubit(service: _OkSvc());
    await c.send('Hi', 'There');
    expect(c.state.status, BroadcastStatus.sent);
    expect(c.state.recipientCount, 42);
  });
  test('send failure -> error', () async {
    final c = BroadcastCubit(service: _ErrSvc());
    await c.send('Hi', 'There');
    expect(c.state.status, BroadcastStatus.error);
  });
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `cd shree_krishna_emb_admin && flutter test test/bloc/broadcast_cubit_test.dart`
Expected: FAIL.

- [ ] **Step 3: Write minimal implementation**
```dart
// lib/data/services/broadcast_service.dart
import 'package:cloud_functions/cloud_functions.dart';

abstract class BroadcastService {
  Future<int> send(String title, String body);
}

class FunctionsBroadcastService implements BroadcastService {
  final FirebaseFunctions _functions;
  FunctionsBroadcastService({required FirebaseFunctions functions}) : _functions = functions;

  @override
  Future<int> send(String title, String body) async {
    final callable = _functions.httpsCallable('broadcastNotification');
    final res = await callable.call<Map<String, dynamic>>({'title': title, 'body': body});
    return (res.data['recipientCount'] as num?)?.toInt() ?? 0;
  }
}
```
```dart
// lib/bloc/notifications/broadcast_cubit.dart
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/services/broadcast_service.dart';

enum BroadcastStatus { initial, sending, sent, error }

class BroadcastState extends Equatable {
  final BroadcastStatus status;
  final int recipientCount;
  final String? error;
  const BroadcastState({this.status = BroadcastStatus.initial, this.recipientCount = 0, this.error});
  BroadcastState copyWith({BroadcastStatus? status, int? recipientCount, String? error}) =>
      BroadcastState(status: status ?? this.status,
          recipientCount: recipientCount ?? this.recipientCount, error: error);
  @override
  List<Object?> get props => [status, recipientCount, error];
}

class BroadcastCubit extends Cubit<BroadcastState> {
  final BroadcastService service;
  BroadcastCubit({required this.service}) : super(const BroadcastState());

  Future<void> send(String title, String body) async {
    emit(state.copyWith(status: BroadcastStatus.sending));
    try {
      final n = await service.send(title, body);
      emit(state.copyWith(status: BroadcastStatus.sent, recipientCount: n));
    } catch (e) {
      emit(state.copyWith(status: BroadcastStatus.error, error: e.toString()));
    }
  }
}
```

- [ ] **Step 4: Run to verify it passes**

Run: `cd shree_krishna_emb_admin && flutter test test/bloc/broadcast_cubit_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**
```bash
git add shree_krishna_emb_admin/lib/data/services/broadcast_service.dart shree_krishna_emb_admin/lib/bloc/notifications/broadcast_cubit.dart shree_krishna_emb_admin/test/bloc/broadcast_cubit_test.dart
git commit -m "feat(admin): broadcast service + BroadcastCubit"
```

---

### Task 29: Admin — broadcast composer dialog

**Files:**
- Create: `shree_krishna_emb_admin/lib/screens/notifications/broadcast_composer_dialog.dart`
- Modify: `shree_krishna_emb_admin/lib/core/di/service_locator.dart` (register `FirebaseFunctions` with region + service + cubit)
- Modify: an entry point (settings Notifications tab or dashboard action) to open the dialog.

**Interfaces:**
- Consumes: `BroadcastCubit`, `AppLocalization.strings.*`, `AppTextField`, `AppButton`, `ResponsiveSnackbar`.

- [ ] **Step 1:** Register dependencies in `service_locator.dart` (region per Global Constraints):
```dart
getIt.registerSingleton<FirebaseFunctions>(
  FirebaseFunctions.instanceFor(region: 'asia-south1'),
);
getIt.registerSingleton<BroadcastService>(
  FunctionsBroadcastService(functions: getIt<FirebaseFunctions>()),
);
getIt.registerFactory<BroadcastCubit>(() => BroadcastCubit(service: getIt<BroadcastService>()));
```
> If `FirebaseFunctions` is already registered elsewhere, reuse it; don't double-register.
- [ ] **Step 2:** Implement the dialog:
```dart
// lib/screens/notifications/broadcast_composer_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_ui_toolbox/flutter_ui_toolbox.dart' hide AppTextField;
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';
import '../../bloc/notifications/broadcast_cubit.dart';
import '../../core/di/service_locator.dart';
import '../../l10n/app_localization.dart'; // confirm path

Future<void> showBroadcastComposer(BuildContext context) {
  return showDialog(
    context: context,
    builder: (_) => BlocProvider<BroadcastCubit>(
      create: (_) => getIt<BroadcastCubit>(),
      child: const _BroadcastDialog(),
    ),
  );
}

class _BroadcastDialog extends StatefulWidget {
  const _BroadcastDialog();
  @override
  State<_BroadcastDialog> createState() => _BroadcastDialogState();
}

class _BroadcastDialogState extends State<_BroadcastDialog> {
  final _title = TextEditingController();
  final _body = TextEditingController();

  @override
  void dispose() { _title.dispose(); _body.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalization.strings;
    return BlocConsumer<BroadcastCubit, BroadcastState>(
      listener: (context, state) {
        if (state.status == BroadcastStatus.sent) {
          Navigator.of(context).pop();
          ResponsiveSnackbar('${s.broadcastSent} (${state.recipientCount})', context);
        } else if (state.status == BroadcastStatus.error) {
          ResponsiveSnackbar(state.error ?? s.error, context);
        }
      },
      builder: (context, state) {
        final sending = state.status == BroadcastStatus.sending;
        return AlertDialog(
          title: Text(s.sendBroadcast, maxLines: 1, overflow: TextOverflow.ellipsis),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(controller: _title, label: s.broadcastTitle, hint: s.broadcastTitle),
                const SizedBox(height: 12),
                AppTextField(controller: _body, label: s.broadcastBody, hint: s.broadcastBody, maxLines: 4),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: sending ? null : () => Navigator.of(context).pop(),
              child: Text(s.cancel, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            AppButton(
              label: s.sendToAllUsers,
              isLoading: sending,
              onPressed: () {
                if (_title.text.trim().isEmpty || _body.text.trim().isEmpty) return;
                context.read<BroadcastCubit>().send(_title.text.trim(), _body.text.trim());
              },
            ),
          ],
        );
      },
    );
  }
}
```
> Confirm `AppTextField` supports `maxLines`; if not, use the design-system multiline variant. Confirm `s.cancel`/`s.error` exist.
- [ ] **Step 3:** Add a "Send broadcast" button — e.g. in the Notifications settings tab below the form, or as a dashboard app-bar action — calling `showBroadcastComposer(context)`.
- [ ] **Step 4: Verify + commit**

Run: `cd shree_krishna_emb_admin && flutter analyze && flutter test`
Expected: clean.
```bash
git add shree_krishna_emb_admin/lib/screens/notifications/broadcast_composer_dialog.dart shree_krishna_emb_admin/lib/core/di/service_locator.dart
git commit -m "feat(admin): broadcast composer dialog -> broadcastNotification callable"
```

---

### Task 30: Admin — admin notifications datasource + repo + `AdminNotificationsCubit`

**Files:**
- Create: `shree_krishna_emb_admin/lib/data/datasources/firebase_admin_notifications_datasource.dart`
- Create: `shree_krishna_emb_admin/lib/domain/repositories/admin_notifications_repository.dart`
- Create: `shree_krishna_emb_admin/lib/data/repositories/admin_notifications_repository_impl.dart`
- Create: `shree_krishna_emb_admin/lib/bloc/notifications/admin_notifications_cubit.dart` (+ `_state.dart`)
- Test: `shree_krishna_emb_admin/test/bloc/admin_notifications_cubit_test.dart`

**Interfaces:**
- Produces: `AdminNotificationsDataSource { Stream<List<AppNotificationModel>> watch(); Future<void> markRead(String id, String adminUid); Future<void> delete(String id); }` (reads `admin_notifications`, unread = `adminUid` not in `readBy`); repo with `Either`; `AdminNotificationsCubit{ start(adminUid), markRead(id), delete(id) }` with `unreadCount`.

- [ ] **Step 1: Write the failing test** (unread computed against adminUid)
```dart
// shree_krishna_emb_admin/test/bloc/admin_notifications_cubit_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shree_krishna_core/enums/app_notification_type.dart';
import 'package:shree_krishna_core/models/app_notification_model.dart';
import 'package:shree_krishna_emb_admin/bloc/notifications/admin_notifications_cubit.dart';
import 'package:shree_krishna_emb_admin/domain/repositories/admin_notifications_repository.dart';
import 'package:shree_krishna_core/errors/failures.dart';
import 'package:shree_krishna_core/utils/either.dart';

class _Repo implements AdminNotificationsRepository {
  @override Stream<List<AppNotificationModel>> watch() => Stream.value([
        AppNotificationModel(id: '1', type: AppNotificationType.purchase, title: 't', body: 'b',
            data: const {'readBy': []}, createdAt: DateTime(2026)),
      ]);
  @override Future<Either<Failure, void>> delete(String id) async => const Right(null);
  @override Future<Either<Failure, void>> markRead(String id, String adminUid) async => const Right(null);
}

void main() {
  test('start streams admin feed', () async {
    final c = AdminNotificationsCubit(repository: _Repo());
    c.start('admin1');
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(c.state.items.length, 1);
    await c.close();
  });
}
```
> The admin feed reuses `AppNotificationModel`; `readBy` lives in Firestore but `AppNotificationModel` has no `readBy` field. For unread computation, the datasource maps each admin doc into `AppNotificationModel` with `read = readBy.contains(adminUid)` (compute at the datasource boundary). Keep that mapping in the datasource; the cubit then uses the same `unreadCount = items.where((n)=>!n.read).length`.

- [ ] **Step 2: Run to verify it fails**

Run: `cd shree_krishna_emb_admin && flutter test test/bloc/admin_notifications_cubit_test.dart`
Expected: FAIL.

- [ ] **Step 3: Write minimal implementation**
```dart
// lib/data/datasources/firebase_admin_notifications_datasource.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shree_krishna_core/constants/firestore_collections.dart';
import 'package:shree_krishna_core/models/app_notification_model.dart';

abstract class AdminNotificationsDataSource {
  Stream<List<AppNotificationModel>> watch(String adminUid);
  Future<void> markRead(String id, String adminUid);
  Future<void> delete(String id);
}

class FirebaseAdminNotificationsDataSource implements AdminNotificationsDataSource {
  final FirebaseFirestore _firestore;
  FirebaseAdminNotificationsDataSource({required FirebaseFirestore firestore}) : _firestore = firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(FirestoreCollections.adminNotifications);

  @override
  Stream<List<AppNotificationModel>> watch(String adminUid) => _col
      .orderBy('createdAt', descending: true)
      .limit(100)
      .snapshots()
      .map((snap) => snap.docs.map((d) {
            final data = d.data();
            final readBy = (data['readBy'] as List?)?.cast<String>() ?? const [];
            return AppNotificationModel.fromFirebaseJson(
              {...data, 'read': readBy.contains(adminUid)},
              d.id,
            );
          }).toList());

  @override
  Future<void> markRead(String id, String adminUid) =>
      _col.doc(id).update({'readBy': FieldValue.arrayUnion([adminUid])});

  @override
  Future<void> delete(String id) => _col.doc(id).delete();
}
```
```dart
// lib/domain/repositories/admin_notifications_repository.dart
import 'package:shree_krishna_core/errors/failures.dart';
import 'package:shree_krishna_core/utils/either.dart'; // adjust
import 'package:shree_krishna_core/models/app_notification_model.dart';

abstract class AdminNotificationsRepository {
  Stream<List<AppNotificationModel>> watch();          // bound to adminUid by impl
  Future<Either<Failure, void>> markRead(String id, String adminUid);
  Future<Either<Failure, void>> delete(String id);
}
```
```dart
// lib/data/repositories/admin_notifications_repository_impl.dart
import 'package:shree_krishna_core/errors/failures.dart';
import 'package:shree_krishna_core/utils/either.dart'; // adjust
import 'package:shree_krishna_core/models/app_notification_model.dart';
import '../datasources/firebase_admin_notifications_datasource.dart';
import '../../domain/repositories/admin_notifications_repository.dart';

class AdminNotificationsRepositoryImpl implements AdminNotificationsRepository {
  final AdminNotificationsDataSource dataSource;
  final String adminUid;
  AdminNotificationsRepositoryImpl({required this.dataSource, required this.adminUid});

  @override
  Stream<List<AppNotificationModel>> watch() => dataSource.watch(adminUid);

  @override
  Future<Either<Failure, void>> markRead(String id, String a) async {
    try { await dataSource.markRead(id, a); return const Right(null); }
    catch (e) { return Left(ServerFailure(e.toString())); }
  }

  @override
  Future<Either<Failure, void>> delete(String id) async {
    try { await dataSource.delete(id); return const Right(null); }
    catch (e) { return Left(ServerFailure(e.toString())); }
  }
}
```
> Because the repo needs `adminUid` for the stream, register it lazily after auth (Step in Task 31), or pass `adminUid` into `watch()` instead. Simpler: give the cubit the datasource directly and pass `adminUid` in `start()`. Adjust the cubit accordingly (below).
```dart
// lib/bloc/notifications/admin_notifications_cubit.dart
import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shree_krishna_core/models/app_notification_model.dart';
import '../../data/datasources/firebase_admin_notifications_datasource.dart';

class AdminNotificationsState extends Equatable {
  final List<AppNotificationModel> items;
  const AdminNotificationsState({this.items = const []});
  int get unreadCount => items.where((n) => !n.read).length;
  AdminNotificationsState copyWith({List<AppNotificationModel>? items}) =>
      AdminNotificationsState(items: items ?? this.items);
  @override
  List<Object?> get props => [items];
}

class AdminNotificationsCubit extends Cubit<AdminNotificationsState> {
  final AdminNotificationsDataSource dataSource;
  StreamSubscription? _sub;
  String? _adminUid;
  AdminNotificationsCubit({required this.dataSource}) : super(const AdminNotificationsState());

  void start(String adminUid) {
    _adminUid = adminUid;
    _sub?.cancel();
    _sub = dataSource.watch(adminUid).listen((items) => emit(state.copyWith(items: items)));
  }

  Future<void> markRead(String id) async {
    final a = _adminUid; if (a == null) return;
    await dataSource.markRead(id, a);
  }

  Future<void> delete(String id) async => dataSource.delete(id);

  @override
  Future<void> close() { _sub?.cancel(); return super.close(); }
}
```
> This cubit talks to the datasource directly (the `_Repo` in the test is illustrative for the stream shape — if you keep the repository, mirror its `watch(adminUid)`). Update the test import to match whichever you ship; keep the assertion (streams 1 item).

- [ ] **Step 4: Run to verify it passes**

Run: `cd shree_krishna_emb_admin && flutter test test/bloc/admin_notifications_cubit_test.dart`
Expected: PASS (after aligning the test's fake to the shipped cubit constructor).

- [ ] **Step 5: Commit**
```bash
git add shree_krishna_emb_admin/lib/data/datasources/firebase_admin_notifications_datasource.dart shree_krishna_emb_admin/lib/domain/repositories/admin_notifications_repository.dart shree_krishna_emb_admin/lib/data/repositories/admin_notifications_repository_impl.dart shree_krishna_emb_admin/lib/bloc/notifications/admin_notifications_cubit.dart shree_krishna_emb_admin/test/bloc/admin_notifications_cubit_test.dart
git commit -m "feat(admin): admin notifications feed datasource + cubit"
```

---

### Task 31: Admin — inbox screen + dashboard bell

**Files:**
- Create: `shree_krishna_emb_admin/lib/screens/notifications/admin_notifications_screen.dart`
- Modify: `shree_krishna_emb_admin/lib/screens/dashboard/admin_dashboard_screen.dart` (bell + badge in the app bar)
- Modify: `shree_krishna_emb_admin/lib/core/di/service_locator.dart` (register datasource + cubit singleton)

**Interfaces:**
- Consumes: `AdminNotificationsCubit`, `AdminAuthBloc`.

- [ ] **Step 1:** Register in `service_locator.dart`:
```dart
getIt.registerSingleton<AdminNotificationsDataSource>(
  FirebaseAdminNotificationsDataSource(firestore: getIt<FirebaseFirestore>()),
);
getIt.registerSingleton<AdminNotificationsCubit>(
  AdminNotificationsCubit(dataSource: getIt<AdminNotificationsDataSource>()),
);
```
And where the admin becomes authenticated (the `AdminAuthBloc` listener / dashboard init), call `getIt<AdminNotificationsCubit>().start(adminId)`.
- [ ] **Step 2:** Implement the screen:
```dart
// lib/screens/notifications/admin_notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';
import '../../bloc/notifications/admin_notifications_cubit.dart';
import '../../core/di/service_locator.dart';
import '../../l10n/app_localization.dart'; // confirm path

class AdminNotificationsScreen extends StatelessWidget {
  const AdminNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppLocalization.strings;
    final scheme = Theme.of(context).colorScheme;
    return BlocProvider<AdminNotificationsCubit>.value(
      value: getIt<AdminNotificationsCubit>(),
      child: Scaffold(
        appBar: AppAppBar(title: s.notifications, onBack: () => Navigator.of(context).pop()),
        body: BlocBuilder<AdminNotificationsCubit, AdminNotificationsState>(
          builder: (context, state) {
            if (state.items.isEmpty) {
              return Center(
                child: Text(s.noAdminNotifications,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium),
              );
            }
            return ListView.separated(
              itemCount: state.items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final n = state.items[i];
                return Dismissible(
                  key: ValueKey(n.id),
                  direction: DismissDirection.endToStart,
                  background: Container(color: scheme.errorContainer),
                  onDismissed: (_) => context.read<AdminNotificationsCubit>().delete(n.id),
                  child: ListTile(
                    leading: Icon(Icons.shopping_bag_outlined,
                        color: n.read ? scheme.outline : scheme.primary),
                    title: Text(n.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(n.body, maxLines: 2, overflow: TextOverflow.ellipsis),
                    tileColor: n.read ? null : scheme.primaryContainer.withValues(alpha: 0.18),
                    onTap: () => context.read<AdminNotificationsCubit>().markRead(n.id),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
```
> Confirm `AppAppBar(title:, onBack:)` signature (per CLAUDE.md it exists in the design system).
- [ ] **Step 3:** In `admin_dashboard_screen.dart`, add a bell action to the app bar bound to `AdminNotificationsCubit.unreadCount` (same badge pattern as user Task 16, theme-aware), navigating to `AdminNotificationsScreen`:
```dart
BlocBuilder<AdminNotificationsCubit, AdminNotificationsState>(
  bloc: getIt<AdminNotificationsCubit>(),
  builder: (context, state) => Stack(
    clipBehavior: Clip.none,
    children: [
      IconButton(
        icon: const Icon(Icons.notifications_outlined),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AdminNotificationsScreen()),
        ),
      ),
      if (state.unreadCount > 0)
        Positioned(
          right: 6, top: 6,
          child: Container(
            padding: const EdgeInsets.all(2),
            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.error, shape: BoxShape.circle),
            child: Text(state.unreadCount > 9 ? '9+' : '${state.unreadCount}',
                textAlign: TextAlign.center, maxLines: 1,
                style: TextStyle(color: Theme.of(context).colorScheme.onError, fontSize: 9)),
          ),
        ),
    ],
  ),
)
```
- [ ] **Step 4: Verify + commit**

Run: `cd shree_krishna_emb_admin && flutter analyze && flutter test`
Expected: clean.
```bash
git add shree_krishna_emb_admin/lib/screens/notifications/admin_notifications_screen.dart shree_krishna_emb_admin/lib/screens/dashboard/admin_dashboard_screen.dart shree_krishna_emb_admin/lib/core/di/service_locator.dart
git commit -m "feat(admin): purchase-alert inbox screen + dashboard bell badge"
```

---

## PHASE 5 — Integration & verification

### Task 32: End-to-end verification + analyzer/test sweep

**Files:** none (verification) — fix-ups committed as found.

- [ ] **Step 1: Static sweep both apps + core + functions**

Run:
```bash
cd core && flutter analyze && flutter test
cd ../shree_krishna_emb_user_app && flutter analyze && flutter test
cd ../shree_krishna_emb_admin && flutter analyze && flutter test
cd ../functions && npm run build
```
Expected: all clean / all pass.

- [ ] **Step 2: Design-system + localization guardrails (per CLAUDE.md)**

Run in each app:
```bash
grep -rn "ScaffoldMessenger" shree_krishna_emb_admin/lib/screens/notifications shree_krishna_emb_admin/lib/screens/settings/widgets || echo "ok: no ScaffoldMessenger"
grep -rn "AppBar(" shree_krishna_emb_admin/lib/screens/notifications || echo "ok: uses AppAppBar"
```
Expected: no raw `ScaffoldMessenger`; admin uses `AppAppBar`/`ResponsiveSnackbar`. Fix any hits.

- [ ] **Step 3: Deploy backend (if not done in Task 23b)**

Run:
```bash
cd functions
firebase deploy --only firestore:rules,firestore:indexes
npm run build && firebase deploy --only functions
```
Expected: rules + indexes + 5 notification functions deploy successfully.

- [ ] **Step 4: Manual E2E checklist (real devices, logged-in user)**
  - Log in on user device → confirm `users/{uid}/fcm_tokens/{token}` created; subscribed to `all_users`.
  - Admin → Settings → Notifications: toggle on, set a slot a few minutes ahead, Save → confirm `config/notifications` doc.
  - Admin create a design with `status:active` → after the slot, user receives a digest push; tap (app foreground / background / killed) → lands on the newest design detail.
  - User buys a free + a paid design → admin inbox shows one purchase alert each; admin bell badge increments; mark-read clears it.
  - Admin → Send broadcast → all logged-in users get a push + an inbox row; unread count increments; "Mark all read" clears; swipe deletes.
  - Log out → confirm token removed; no further pushes for that device.

- [ ] **Step 5: Commit any fix-ups**
```bash
git add -A
git commit -m "test(notifications): e2e verification fix-ups + guardrail cleanup"
```

---

## Self-Review (completed)

- **Spec coverage:** A1 → Task 21 + 30/31; A2 → Tasks 3/24/25/27; A3 → Tasks 20/28/29; U1 → Tasks 19/22/23/23b; U2 → Tasks 12/13/15/16; U3 → Tasks 12/13/15; U4 → Tasks 10/11/15/16; U5 → Tasks 9/10/11. Core/constants/rules/indexes → Tasks 1–7. Localization → Tasks 14/26. All spec sections map to tasks.
- **Type consistency:** `AppNotificationModel` field/`designId` getter, `NotificationSettingsModel.copyWith`/`fromEntity`, cubit `unreadCount`, `selectDueSlot`/`fanOutInbox`/`sendToTopic`, constant names (`configNotificationsDoc`/`fcmTokens`/`userNotifications`/`adminNotifications`, TS `Collections.*`/`Docs.configNotifications`/`TOPIC_ALL_USERS`/`NotificationType`) are used identically across producing and consuming tasks.
- **Known adaptation points (flagged inline, not placeholders):** exact `Either`/`Failure` import paths per app, `AppButton`/`AppTextField` parameter names, `AppAppBar` availability in the user app, and the admin-feed test fake aligning to the shipped cubit constructor. These are "confirm against existing code" notes, not missing content — each task ships complete, runnable code with a named file to grep for the local convention.
