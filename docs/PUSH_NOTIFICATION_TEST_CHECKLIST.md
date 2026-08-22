# Push Notification Module — Manual Test Checklist

Covers both apps (User + Admin) + Cloud Functions. Tick each box after verifying. Requirement IDs map to the design spec (A1–A3 admin, U1–U5 user).

> Push receipt (device notifications) is **Android-first**. iOS needs APNs setup (Xcode Push capability + APNs key in Firebase) before iOS push will arrive — until then, test push on Android; the in-app inbox still works on iOS/web.

---

## 0. Prerequisites (do once)

- [x] Backend deployed: `firebase deploy --only firestore:rules,firestore:indexes,functions --account nicentra.solutions@gmail.com` (region `asia-south1`)

- [x] All 5 functions show as deployed: `broadcastNotification`, `onOrderFinalized`, `onDesignWritten`, `sendNewDesignDigest`, (+ existing). Check Firebase Console → Functions.

- [x] Composite index `designs (status ASC, activatedAt ASC)` is **Enabled** (Console → Firestore → Indexes). Digest query fails until it finishes building.

- [x] User app installed on a **real Android device** (2 devices ideal for multi-device token test).

- [x] Admin app running (web or device) logged in as an admin account.

- [x] Notification permission will be requested on first login — be ready to **Allow**.

---

## 1. User app — token lifecycle (U5: logged-in only)

- [x] **Login registers token** — log in → Firestore `users/{uid}/fcm_tokens/{token}` doc appears (fields: `token`, `platform`, `createdAt`, `lastSeenAt`).

- [x] **Permission prompt** appears on first login; tapping **Allow** proceeds; tapping **Deny** does NOT crash (app still works, inbox still loads).

- [ ] **Logout removes token** — log out → that `fcm_tokens/{token}` doc is deleted (this was a fixed bug — verify the *correct* uid's token is removed, not left orphaned).

- [ ] **Suspended account** (if testable) — an admin-suspended user gets logged out and their token is removed too.

- [ ] **Logged-out device gets nothing** — after logout, trigger a broadcast (section 6); the logged-out device receives **no** push.

- [ ] **Multi-device** (optional) — log in on 2 devices → 2 token docs; a broadcast reaches both.

---

## 2. User app — new-design digest (U1)

> Digest is a scheduled function checking admin-configured slots (\~every 30 min). To test quickly, set a slot 1–2 min in the future (section 5) and wait for the cron tick.

- [ ] **First-run does NOT spam the catalog** — on the very first digest run after deploy, existing designs are **not** announced (cursor seeds to launch time). Confirm no "N new designs" push for your existing catalog.

- [ ] **New design after launch triggers a digest** — admin adds/activates a new design → at the next due slot, one digest push arrives: "N new designs added — explore".

- [ ] **Digest also lands in the in-app inbox** (bell count increments) even if the push is dismissed.

- [ ] **≤4 per day cap** — with 4 slots configured, a 5th same-day digest never fires.

- [ ] **No empty digests** — if no new designs since last slot, no push is sent at that slot.

- [ ] **Draft→active** — a design created as draft then flipped to active is picked up (its `activatedAt` is stamped on activation).

- [ ] **No double-send** — a digest for a slot is sent only once even if the scheduler overlaps/retries.

---

## 3. User app — notification center (U2, U3)

- [x] **Bell badge** on home shows unread count; hidden when 0; shows "9+" above 9.

- [x] **Open inbox** — tap the bell → notifications screen lists items newest-first.

- [x] **Unread styling** — unread items are visually highlighted; reading/opening clears their unread state.

- [x] **Mark all read** — action clears the badge to 0 and un-highlights all.

- [x] **Delete** — swipe (or delete action) removes an item; a confirmation snackbar shows.

- [x] **Empty state** — with no notifications, a friendly empty state renders (not a blank/broken screen).

- [x] **Localization** — switch app language to Hindi; all inbox text (title, empty state, actions, relative timestamps like "अभी"/"5 मि") is translated — no English leakage.

- [x] **Responsive/overflow** — long titles/bodies truncate with "…"; screen looks right on a small (≈320px) and large device.

---

## 4. User app — deep-link on tap (U4) — TEST ALL THREE STATES

Use a notification that carries a `designId` (a new-design digest, or a broadcast you craft with a design payload).

- [ ] **Foreground** — app open on any screen → push arrives as a banner → tap it → lands on the correct **Design Detail** screen.

- [ ] **Background** — app minimized (not killed) → tap the push from the tray → app resumes → Design Detail opens.

- [ ] **Terminated** — **fully swipe-kill the app** → tap the push from the tray → app cold-starts → after splash it lands on the correct Design Detail (this was a fixed race — confirm it does NOT get stuck on Home).

- [ ] **Guard** — a notification with no `designId` (e.g. a plain broadcast) opens the app to Home/inbox without error.

- [ ] **Logged-out tap** — if the user is logged out, tapping does not force a broken navigation.

---

## 5. Admin app — notification settings (A2)

Settings → **Notifications** tab (was "Coming Soon").

- [x] Tab shows the real form (not the placeholder).

- [x] **Master toggle** off → disables the per-type toggles and slot controls; on → re-enables.

- [x] **Per-type toggles** — Purchase alerts and New-design alerts toggle independently and persist after leaving/returning to the tab.

- [x] **Send-time slots** — add times; **cannot add a 5th** (the "Add" control disappears/blocks at 4).

- [x] **Remove** a slot works.

- [x] **Save** — persists to Firestore `config/notifications` (verify doc: `masterEnabled`, `purchaseAlertsEnabled`, `newDesignAlertsEnabled`, `dailySlots` ≤4, `timezone`, `updatedBy`, `updatedAt`); a success snackbar shows.

- [x] **Reload** — reopening the tab shows the saved values.

- [x] **Master OFF kill-switch** — with master off, no digests fire and broadcasts are blocked (section 6).

- [x] **Localization** — Hindi shows translated labels; every text truncates cleanly.

- [x] Note: the **timezone** field currently always behaves as IST (Asia/Kolkata) regardless of value — expected known limitation.

---

## 6. Admin app — broadcast to all (A3)

- [x] **Composer opens**, with Title + Message fields.

- [x] **Validation** — empty title or body is rejected; title over 120 chars is rejected (localized error).

- [x] **Confirm step** before sending.

- [x] **Send** — all logged-in users receive a push AND an inbox item; the admin sees a success snackbar with the **recipient count**.

- [x] **Non-admin cannot broadcast** — calling the function as a non-admin returns permission-denied (rules/guard). (Verify via a non-admin account or Functions logs.)

- [x] **Master OFF blocks it** — with `masterEnabled=false`, broadcast returns a "notifications disabled" error and sends nothing.

---

## 7. Admin app — purchase alerts inbox (A1)

- [x] **Paid order** — a user completes a **paid** purchase → an `admin_notifications` doc is written → the admin dashboard **bell badge** increments and the item appears in the admin inbox (title/body includes design + amount + buyer).

- [x] **Free (₹0) item** — claiming a free item also produces an admin alert (body reflects "free").

- [x] **No duplicate** — re-writing the order doc (same paid status) does **not** create a second alert (fires only on transition into paid).

- [x] **Purchase alerts OFF** — with `purchaseAlertsEnabled=false`, a new purchase produces **no** admin alert.

- [ ] **Read/unread** — opening/mark-read updates the badge; `readBy` array gets the admin's id.

- [ ] **Mark all read** clears the badge; **delete** removes an item.

- [ ] **No FCM to admin** — admins get in-app alerts only (no device push); this is by design.

- [ ] **Localization + overflow** on the admin inbox screen.

---

## 8. Security rules (spot-check via Console/Rules Playground)

- [ ] A normal user **cannot** read `config/notifications` or `admin_notifications`.

- [ ] A user **cannot** create docs in their own `users/{uid}/notifications` (functions-only); can only flip `read` / delete.

- [ ] A user **cannot** read another user's `fcm_tokens` or `notifications`.

- [ ] Only an admin can write `config/notifications`, and only with `dailySlots` a list of size ≤4.

- [ ] Admin inbox update is restricted to the `readBy` field.

---

## 9. Edge cases / regression

- [ ] App with **notifications permission denied** — inbox still works; no crashes anywhere.

- [ ] **Offline** — inbox serves from Firestore cache; a failed broadcast surfaces a snackbar (no crash).

- [ ] **Rapid login/logout** — token registration/cleanup stays consistent (no orphaned tokens).

- [ ] Existing app flows unaffected: **login, catalog browse, cart, checkout/payment, existing screens** all still work (run a quick smoke pass).

- [ ] `flutter analyze` clean on both apps; `npm run build` clean on functions (already verified in CI/sweep, re-confirm after any local change).

---

## Sign-off

- [ ] User app (Android) — all sections pass

- [ ] Admin app — all sections pass

- [ ] Backend functions behave per logs (Console → Functions → Logs)

- Tester: \_____________\_ Date: \___________\_ Build/commit: \___________\_