# Push Notifications — How It's Wired to Firebase, and How to Reconfigure

## 1. The key design decision: no server key to paste

Sending FCM push is done **entirely from Cloud Functions using the Firebase Admin
SDK's default service account** (Application Default Credentials). The functions call
`getMessaging().send(...)`. Because the Admin SDK is already authenticated as the
project's service account, **there is no FCM "server key" to store anywhere** — not in
Firestore, not in the app, not in `config/secrets`.

That is why the admin "notification settings" screen only has toggles + send-time slots,
**not** a place to paste credentials. Firebase wiring happens through the
`google-services.json` / `GoogleService-Info.plist` config files and `flutterfire`, not
in the app UI.

## 2. Delivery model: topic-based, not per-token

- On login the **user app** subscribes the device to the FCM topic **`all_users`**
  (`NotificationService.onLogin`), and registers its token doc (see §3).
- Broadcasts and new-design digests are sent to that topic:
  `messaging.send({ topic: "all_users", notification, data })` in
  `functions/src/notifications/messaging.ts`.
- So push delivery does **not** depend on reading token docs — every logged-in device is
  a topic subscriber. On logout the app **unsubscribes** from `all_users`, so logged-out
  devices stop receiving pushes.
- In parallel, each notification is also **fanned out to Firestore**
  (`users/{uid}/notifications`) so the in-app inbox works even if the push is missed.

## 3. What the token docs are for

`users/{uid}/fcm_tokens/{docId}` records the device token (token/platform/timestamps).
Delivery uses the topic, so these are for record-keeping and possible future
**targeted** (per-device) sends. (Stored as **one doc per user**.)

## 4. Where each piece lives

| Concern | Location |
|---|---|
| Admin SDK init (db/auth/messaging) | `functions/src/lib/firebase.ts` |
| Send helpers (topic send, inbox fan-out) | `functions/src/notifications/messaging.ts` |
| Broadcast / digest / order / design functions | `functions/src/notifications/*.ts` |
| Client FCM lifecycle (permission, token, topic, tap routing) | `shree_krishna_emb_user_app/lib/data/services/notification_service.dart` |
| Android default notification channel | `shree_krishna_emb_user_app/android/app/src/main/AndroidManifest.xml` (`ske_default_channel`) |
| Firebase project binding (per platform) | `.../android/app/google-services.json`, `.../ios/Runner/GoogleService-Info.plist`, `lib/firebase_options.dart` |
| Region | `asia-south1` (set globally in `functions/src/index.ts`) |
| Topic | `all_users` (`TOPIC_ALL_USERS` in `functions/src/config/constants.ts`) |

The **admin app does not use `firebase_messaging` at all** — it only calls the
`broadcastNotification` callable and reads `admin_notifications` from Firestore.

---

## 5. If the admin changes / updates the Firebase project

If you point the apps at a **different or new Firebase project**, redo the wiring below.
Note: none of this is done in the app's settings UI — it's Firebase console + config files.

### 5.1 Project prerequisites (Firebase console)
1. Project must be on the **Blaze** plan (Cloud Functions v2 + scheduler require it).
2. **Cloud Messaging API (FCM v1)** is enabled by default — nothing to paste for server
   sends. (Console → Project Settings → Cloud Messaging.)
3. Register the apps in the new project: the Android app (package
   `com.nicentra.shree_krishna_emb`) and, if used, the iOS bundle id.

### 5.2 Re-point the Flutter apps (recommended: one command)
Run FlutterFire in **each** app so it registers the apps and regenerates
`firebase_options.dart` + downloads the platform config files:
```bash
cd shree_krishna_emb_user_app && flutterfire configure --project <NEW_PROJECT_ID>
cd ../shree_krishna_emb_admin && flutterfire configure --project <NEW_PROJECT_ID>
```
This updates `lib/firebase_options.dart`, `android/app/google-services.json`, and
`ios/Runner/GoogleService-Info.plist`. Rebuild the apps afterward.

(Manual alternative: download `google-services.json` and `GoogleService-Info.plist` from
the new project's settings and drop them into those same paths.)

### 5.3 iOS push (only if you ship iOS push)
Android needs nothing extra. For iOS:
1. Apple Developer → create an **APNs Auth Key (.p8)**.
2. Firebase console → Project Settings → Cloud Messaging → **Apple app configuration** →
   upload the .p8 (with Key ID + Team ID).
3. Xcode → Runner target → Signing & Capabilities → add **Push Notifications** and
   **Background Modes → Remote notifications**.

### 5.4 Point the CLI + deploy backend to the new project
```bash
# set default project (or pass --project on each deploy)
firebase use <NEW_PROJECT_ID>            # updates .firebaserc
firebase deploy --only firestore:rules,firestore:indexes,functions --project <NEW_PROJECT_ID>
```
After deploy, in Firebase console confirm the 5 functions exist and the
`designs (status, activatedAt)` composite index finished building.

### 5.5 App-level notification config is per-project data
The `config/notifications` document (master/per-type toggles + send-time slots) lives in
**that project's Firestore**. A fresh project starts at defaults — the admin re-opens the
app's **Settings → Notifications** tab and sets the slots/toggles again.

### 5.6 Web push (currently out of scope)
If you ever want push on the web build: Firebase console → Cloud Messaging → **Web
configuration** → generate a **VAPID key**, add a `firebase-messaging-sw.js` service
worker, and pass the VAPID key to `getToken`. Not wired today; the in-app inbox already
works on web via Firestore.

---

## 6. Quick mental model
> Apps authenticate to a Firebase project via `google-services.json` /
> `GoogleService-Info.plist` (from `flutterfire configure`). Devices subscribe to the
> `all_users` topic on login. Cloud Functions (Admin SDK, no server key) send to that
> topic and fan out Firestore inbox docs. Moving projects = re-run `flutterfire
> configure`, redo iOS APNs, set the CLI project, redeploy. The in-app settings screen
> is only toggles + schedule — never credentials.
