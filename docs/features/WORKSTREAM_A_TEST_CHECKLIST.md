# Workstream A — Test Checklist (Security & Auth Foundation)

**Status:** Code complete, `flutter analyze` clean on both apps, Cloud Functions build + 12/12 unit tests pass.
**Date:** 10 July 2026

## What was implemented

| Task | Change | Files |
|---|---|---|
| A1 | New Cloud Functions `onUserRoleWritten` (trigger) + `refreshRoleClaim` (callable) that mirror `users/{uid}.role` into the `role` custom claim | `functions/src/users/syncRoleClaim.ts`, `functions/src/index.ts` |
| A1 | `storage.rules`: catalog write paths (`collections/`, `categories/`, `designs/`, `media/`, `design_files/`) tightened from any-authed-user to `isStaff()` (= admin OR designer claim) | `storage.rules` |
| A1 | Admin app syncs the role claim + force-refreshes its token right after sign-in and session restore (best-effort, never blocks login) | `firebase_admin_auth_datasource.dart`, admin `service_locator.dart`, core `firestore_collections.dart` |
| A2 | Real forgot-password: `sendPasswordResetEmail` through datasource → repository → new `PasswordResetCubit`; both the standalone screen AND the login screen's inline reset panel now actually send the email, with loading spinner + success/error toasts. Unknown emails get the generic success message (no account enumeration) | `forgot_password_screen.dart`, `admin_login_screen.dart`, `password_reset_cubit.dart`, `admin_auth_repository(.impl).dart` |
| A3 | Apple Sign-In via `firebase_auth`'s native `AppleAuthProvider` (no new package): full datasource → repo → use case → bloc → UI chain; button renders ONLY on iOS (your decision); new Apple users route to complete-profile (phone) like Google users; iOS entitlement file created + wired into all 3 Xcode build configs | user app auth stack, `login_screen.dart`, `signup_screen.dart`, `ios/Runner/Runner.entitlements`, `project.pbxproj` |
| Bonus | Signup screen's social buttons were dead (`onTap: () {}`) — Google now signs in, Phone routes to the login OTP flow, and the signup screen now handles the new-social-user → complete-profile state | `signup_screen.dart` |

---

## ⚙️ One-time setup YOU must do before testing (in order)

- [ ] **1. Deploy the new functions:**
  ```bash
  cd /Applications/Documents/dev/shree-krishna-emb
  firebase deploy --only functions:onUserRoleWritten,functions:refreshRoleClaim
  ```
- [ ] **2. Review the `storage.rules` diff** (`git diff storage.rules`), then deploy:
  ```bash
  firebase deploy --only storage
  ```
  ⚠️ Deploy functions FIRST and log in to the admin app once (step 3) before deploying storage rules — otherwise admin uploads fail until the claim is synced.
- [ ] **3. Log OUT and back IN on the admin app** (this triggers the claim sync for your admin account).
- [ ] **4. (For A3 device testing later)** In Firebase Console → Authentication → Sign-in method → enable **Apple**. In Apple Developer portal, the app ID needs the "Sign In with Apple" capability — this only fully works after Task E2 (real bundle ID), see note in the A3 section.

---

## ✅ A1 — Storage security (test on deployed rules)

**Admin still works:**
- [ ] Admin app → Design Store → create/edit a design and **upload an image** → succeeds
- [ ] Admin app → upload an **EMB/DST file** via the Design File field → succeeds
- [ ] Admin app → Categories/Collections → create one with an image → succeeds
- [ ] Media Library upload → succeeds
- [ ] Reload the admin web app (session restore, no fresh login) → uploads still succeed

**Normal users are locked out (the actual security fix):**
- [ ] In the USER app, log in as a regular user. Then verify a user token cannot write to catalog storage. Easiest check: Firebase Console → Storage → Rules → **Rules Playground**: simulate `write` to `designs/test.jpg` with an authenticated token WITHOUT the `role` claim → **DENIED**; with `role: admin` → allowed
- [ ] User app still renders all catalog images (public read unchanged)
- [ ] User profile photo upload (if used) still works (`users/{uid}/` path unchanged)

**Claim lifecycle:**
- [ ] Firebase Console → Firestore → change some test user's `role` to `designer`, then check function logs (`onUserRoleWritten`) show the claim update; change back to `user` → claim cleared

## ✅ A2 — Admin forgot-password

- [ ] Admin login screen → "Forgot password" (inline panel) → enter YOUR admin email → button shows spinner → success toast → **a real reset email arrives** (check spam)
- [ ] The email's link opens and lets you set a new password; login works with the new password
- [ ] Enter an email that does NOT exist → still shows the generic success toast (no "user not found" leak)
- [ ] Enter an invalid email format (`abc`) → error toast, nothing sent
- [ ] With Wi-Fi off → error toast appears (no silent failure)
- [ ] Standalone forgot-password screen (if navigated to) behaves the same
- [ ] Switch app language to Hindi → toasts/labels appear in Hindi

## ✅ A3 — Apple Sign-In (user app)

**Platform gating (can test NOW on Android/emulator):**
- [ ] Android device/emulator → login + signup screens show **only Google + Phone** — NO Apple button
- [ ] iOS simulator → login + signup screens show the Apple button below the Google/Phone row

**⚠️ Full sign-in flow needs two prerequisites, so this part moves to Task E2 week if you prefer:**
1. Apple provider enabled in Firebase Console (setup step 4)
2. A real bundle ID + "Sign In with Apple" capability on the Apple Developer app ID (currently `com.example.*` — fixed in Task E2). On a simulator with a signed-in Apple ID it may work before E2; on TestFlight it requires E2.

When ready:
- [ ] iOS → tap Apple button → native Apple sheet appears → authorize → NEW user lands on **Complete Profile** (asks phone) → completes → reaches Home
- [ ] Sign out → Apple sign-in again → existing user goes straight to Home (no complete-profile)
- [ ] Cancel the Apple sheet → error toast "Apple sign in cancelled", app stays on login (no crash, no stuck loading)
- [ ] Firestore `users/{uid}` doc for the Apple user has `loginMethod: 'apple'`, `role: 'user'`, and a sequential `userId` assigned by the function

**Signup screen fixes (test now):**
- [ ] Signup screen → Google button actually starts Google sign-in (was dead before)
- [ ] Signup screen → new Google user routes to Complete Profile (was only handled on login before)
- [ ] Signup screen → Phone button navigates to the login screen's phone/OTP flow

## ✅ Regression sweep (touched areas)

- [ ] Admin: normal email/password login works; wrong password shows error toast
- [ ] Admin: session survives browser reload (web) and app restart
- [ ] Admin: logout works
- [ ] User app: email login, email signup, Google login, phone OTP login all still work
- [ ] User app: suspended-account handling still shows the suspended message (not a generic error)

---

## When everything above is checked

Reply "Workstream A verified" and we move to **Workstream D (cleanup: hide My Work tab, admin dashboard fixes)** — or straight to **WS-B1 (search + filters)** if you want D bundled with it.

**Known deferred items (tracked in the master plan):**
- Apple full-flow verification blocked on E2 (bundle ID) + Firebase console toggle — code is ready.
- `_handleAuthException` may not have a specific message for every Apple error code — generic fallback covers it.
- Designer role end-to-end (claim → designer uploads) is exercised properly in WS-C; the rules + claim plumbing are already designer-ready.
