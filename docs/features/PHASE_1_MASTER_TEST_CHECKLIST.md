# Phase 1 MASTER Test Checklist — All Workstreams (A–G)

**Status:** ALL workstream code is complete. `flutter analyze` clean on both apps; Cloud Functions compile, 12/12 tests pass.
**Date:** 10 July 2026
**Supersedes:** WORKSTREAM_A_TEST_CHECKLIST.md and WORKSTREAM_A_B_TEST_CHECKLIST.md (their items are folded in here).
**Decisions needing your answers are collected at the END (§9) — answer them all at once.**

---

## What got built since your last review (beyond A+B)

| WS                      | Delivered                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| ----------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **D**             | User app: "My Work" Phase-2 tab hidden (3 tabs now). Admin: Approval Queue dead link removed, hardcoded "42 Designs / Payout Cycle" cards deleted, real**Total Users** KPI card added, demo-data seeder now debug-builds-only, orphaned platform-fees view deleted                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| **C**             | **Designer role in the admin panel**: designers log in to the same panel and get a scoped workspace — own Dashboard KPIs/revenue chart, own Designs (create/edit/delete, author locked to self), create-only Categories/Collections, own Transactions (read-only, no refund button), own Payouts row, own Reports + CSV. Hidden for designers: User Management, Home Layout, Broadcast/Notifications, platform Settings tabs. Enforced BOTH in UI (`AccessPolicy`) and server-side (`firestore.rules` designer arms; storage claim from WS-A). Orders now get `ownerIds` + `ownerTotals` stamped by `finalizeOrder` so designer sales/earnings are queryable. **Bonus fix:** admin dashboard revenue previously displayed live (paise) orders 100× too big — now normalized |
| **F**             | `BrandConfig` in core (name, colors, support contacts, legal URLs, store IDs, FCM channel) with the SKE house brand as default; profile rows (WhatsApp/Contact/Privacy/Terms) driven by it — each appears only when configured; `docs/WHITE_LABEL_GUIDE.md` ("new client in a day"). Deferred: F3 icon regeneration + F4 flavors (post-launch, pre-first-client)                                                                                                                                                                                                                                                                                                                                                                                                                                |
| **G**             | Feedback audit of every mutation path in both apps — PASS; one fix (silent wishlist-toggle failures now toast). Findings:`docs/superpowers/plans/feedback-audit-findings.md`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| **E (code-side)** | Android:`key.properties`-based release signing (with dev fallback) + template with keytool commands; `versionCode/Name` now driven from pubspec (`1.0.0+3`); stale debug-signed AAB deleted. iOS: bundle id → `com.nicentra.shreeKrishnaEmb`, display name → "Shree Krishna Embroidery". Privacy + Terms HTML pages created in `shree_krishna_emb_admin/web/` (deploy with hosting; app rows already point at them)                                                                                                                                                                                                                                                                                                                                                                      |

---

## 1. ⚙️ One-time setup YOU must do before testing (in order)

- [ ] **1.1 Deploy ALL functions** (finalizeOrder changed + 3 new ones):
  ```bash
  cd /Applications/Documents/dev/shree-krishna-emb
  firebase deploy --only functions
  ```
- [ ] **1.2 Review rules diffs** (`git diff firestore.rules storage.rules` — new `isDesigner()` arms), then:
  ```bash
  firebase deploy --only firestore:rules,storage
  ```
- [ ] **1.3 Log OUT and back IN on the admin app** (syncs your admin role claim).
- [ ] **1.4 Deploy hosting** (admin panel + privacy/terms pages):
  ```bash
  cd shree_krishna_emb_admin && flutter build web && firebase deploy --only hosting
  ```
- [ ] **1.5 Create a test DESIGNER account:** User Management → edit a test user → role `designer`. (Claim syncs via the deployed trigger.)
- [ ] **1.6 User app:** `flutter pub get`; for iOS also `cd ios && pod install`.
- [ ] **1.7 Firebase console:** enable the **Apple** sign-in provider; and because the iOS bundle id changed, **add an iOS app with `com.nicentra.shreeKrishnaEmb`** and replace `ios/Runner/GoogleService-Info.plist` (the old plist is registered to `com.example.*` — iOS builds keep working for Android-testing purposes but iOS Firebase will misbehave until replaced).

## 2. ✅ Workstream A — security & auth

- [ ] Admin: design image + EMB file + category/collection/media uploads all still work (fresh login AND after page reload)
- [ ] Storage Rules Playground: authed write to `designs/x.jpg` with no `role` claim → DENIED; with `role: admin` or `role: designer` → allowed
- [ ] Admin forgot-password (inline panel): real email arrives, link works, generic success for unknown emails, error toast offline, Hindi localized
- [ ] Android: NO Apple button on login/signup; iOS: Apple button shows; (after 1.7 + Apple Developer capability) full Apple sign-in → complete-profile → Home; cancel → toast
- [ ] Signup screen: Google button signs in; new social user → Complete Profile; Phone → login OTP flow

## 3. ✅ Workstream B — user-app features

- [ ] **Search:** app-bar icon → search by name AND code; filters (category chip, price range, free-only) + removable chips + Clear All; sort orders correct; empty + error + retry states; wishlist hearts on results; Hindi pass
- [ ] **Reviews:** non-owner sees reviews but no Write button (and rules reject forced writes); owner writes 1–5★ + comment → toast → appears; edit + delete work; avg stars + count under design title; ⭐ badge on search cards; design doc gets `avgRating`/`reviewCount`
- [ ] **Orders + invoice:** My Purchases tabbed Designs|Orders; order list newest-first with status chips; order detail shows items + Subtotal/Fee/GST/Total matching checkout; **Download Invoice** on paid orders → correct PDF (amounts right for BOTH demo_* and live orders); fresh purchase appears in both tabs
- [ ] **B4:** zoom locked on unowned designs, unlocked (5×) on owned; Notification Preferences from profile (persist + master switch stops/starts admin broadcasts); offline banner on airplane mode; About dialog
- [ ] Regression: home feed, view-all, cart, checkout (test mode), wishlist, notifications bell, dark mode, 320px width

## 4. ✅ Workstream C — designer role (test with the 1.5 designer account)

**As the DESIGNER:**

- [ ] Login works; sidebar shows ONLY: Dashboard, Design Store, Transactions, Payouts, Reports, Settings, Logout (no User Management, no Notifications bell/inbox)
- [ ] Dashboard: no Total Users card; design counts are THEIRS only; revenue/orders KPIs show only their share (will be 0 until a post-deploy sale of their design)
- [ ] Design Store: NO Home Layout tab; Designs tab lists only their designs; create a design → author field is LOCKED to themselves; image + EMB upload works; edit + delete own design works
- [ ] The designer's new design (status active) appears in the USER app
- [ ] Categories/Collections tabs: Add button works; **no edit/delete icons** on existing rows
- [ ] Buy the designer's design from the user app (test mode uses the demo writer — see DEC-2 note: designer scoping needs a LIVE/callable-path order, so for full verification make the purchase after functions deploy via the server path, or temporarily flip payment mode) → order appears in the designer's Transactions with **no Refund button**; Payouts shows their earnings row; Reports shows their line items + CSV export
- [ ] Settings: only the General tab (theme/language)
- [ ] Designer CANNOT see other authors' orders/designs (spot-check Firestore rules by direct query if inclined)

**As the ADMIN (regression):**

- [ ] Everything unchanged: all sections visible, all designs listed, author picker free, category/collection edit/delete present, refunds work
- [ ] Dashboard shows 4 KPI cards incl. Total Users; revenue figures now sane for live orders (paise fix)

## 5. ✅ Workstream D — cleanup

- [ ] User app has 3 tabs (Home | My Purchases | Profile); avatar icon in app bar goes to Profile
- [ ] Admin sidebar has NO Approval Queue; dashboard has NO hardcoded "42 Designs"/"Payout Cycle" cards
- [ ] Admin Settings: Seed tab absent in a `flutter build web` (release) build; still present when run with `flutter run` (debug)

## 6. ✅ Workstream F — white-label

- [ ] Profile: Privacy Policy + Terms rows open the hosted pages (after 1.4); WhatsApp/Contact rows HIDDEN (until DEC-3 fills contacts)
- [ ] `docs/WHITE_LABEL_GUIDE.md` reads sensibly to you as the "new client" runbook
- [ ] Grep spot-check: new code takes brand values from `BrandConfig`/locales (nothing new hardcoded)

## 7. ✅ Workstream G — feedback consistency

- [ ] Airplane mode: wishlist heart tap → error toast (was silent before)
- [ ] Skim `docs/superpowers/plans/feedback-audit-findings.md` — agree with the two accepted deferrals

## 8. 🚀 Workstream E — remaining OWNER release actions (dev is done)

- [ ] **E1:** generate upload keystore per `android/key.properties.template` (commands inside); create `key.properties`; add release SHA-1/SHA-256 to Firebase console; re-download `google-services.json`; `flutter build appbundle --release`; verify Google Sign-In works on the RELEASE build
- [ ] **E2:** register `com.nicentra.shreeKrishnaEmb` in Apple Developer portal (+ Sign in with Apple capability) & App Store Connect; complete setup step 1.7 (new plist); archive build
- [ ] **E3:** edit `web/privacy.html` + `terms.html` ([OWNER] markers: date + support email), redeploy hosting, enter URLs in both store consoles
- [ ] **E4:** Razorpay live KYC + `firebase functions:secrets:set RAZORPAY_KEY_ID RAZORPAY_KEY_SECRET WEBHOOK_SECRET`; webhook URL in Razorpay dashboard; `config/platform` → Live; ONE real ₹ purchase end-to-end (order → download → invoice → refund)
- [ ] **E5:** restrict the Android Firebase API key by package+SHA in GCP console
- [ ] **E6:** Play Console (listing, Data Safety, content rating, internal track) + App Store Connect (listing, privacy labels, screenshots, reviewer demo account) → submit

---

## 9. ❓ DECISIONS — answer these all at once

| #               | Decision needed                                                                                                                                                                                                                                                                                                                                  | My default (used in the code)               |
| --------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------- |
| **DEC-1** | Designer ownership rides on the EXISTING`authorId` field (no new field, no backfill). Designs with author `platform`/admin-uid stay house-owned. OK?                                                                                                                                                                                         | Yes — reuse`authorId`                    |
| **DEC-2** | Old orders (before the functions deploy) have no`ownerIds`, so designers see only sales made AFTER deploy. Also, TEST-mode demo orders (client-written) never get `ownerIds` — designer sales tracking is only accurate for server-path (live/callable) orders. Ship as-is, or do you want a one-off backfill script for historical orders? | Ship as-is (designer catalog is new anyway) |
| **DEC-3** | Real support contacts for`BrandConfig` (and the legal pages): support EMAIL + WhatsApp number (with country code). Rows stay hidden until you provide them.                                                                                                                                                                                    | Hidden until provided                       |
| **DEC-4** | Privacy/Terms drafts are at`shree_krishna_emb_admin/web/*.html` with [OWNER] markers. Review/edit the wording (esp. refund policy + data-deletion contact) before store submission. OK to use as base?                                                                                                                                         | Use drafts as base                          |
| **DEC-5** | iOS bundle id set to`com.nicentra.shreeKrishnaEmb` (matches Android's `com.nicentra.*`). Confirm BEFORE creating the App Store Connect record — changing later is painful.                                                                                                                                                                  | Confirm                                     |
| **DEC-6** | Designer accounts are provisioned by the ADMIN (User Management → role designer). No self-serve designer signup in Phase 1 (that's the Phase-2 onboarding flow). OK?                                                                                                                                                                            | Admin-provisioned                           |
| **DEC-7** | Notification category toggles: persisted + master switch functional; per-category server-side enforcement deferred (see G findings). OK for v1?                                                                                                                                                                                                  | Defer                                       |
| **DEC-8** | Flavors (F4) + brand icon pipeline (F3) deferred to post-launch, before the first white-label client sale. OK?                                                                                                                                                                                                                                   | Defer                                       |
| **DEC-9** | Crash reporting (`firebase_crashlytics`) is NOT integrated. Add before launch (~half a day), or ship v1 without?                                                                                                                                                                                                                               | Ship without, fast-follow                   |

---

## When everything above is checked

Reply **"Master checklist verified"** with your DEC answers and any failures. What remains after that is purely §8 (owner store actions) → internal testing track → production. 🚀
