# White-Label Guide — "New Client in a Day"

How to ship this platform (user app + admin panel + backend) for a new client
brand. Rebranding = configuration + assets + a Firebase project, not code
changes (decision D5).

## Brand touchpoints (already centralized)

| What | Where |
|---|---|
| App name, company, support email/WhatsApp, privacy/terms URLs, store IDs, notification channel, seed colors | `core/lib/config/brand_config.dart` (`BrandConfig`) — install per-brand instance in each app's `main()` |
| Translated display strings (app name shown in UI, welcome copy) | each app's locale files: `appName` getter in `en_us.dart` / `hi_in.dart` |
| Theme colors | `design_system` `AppTheme` (seed values documented in `BrandConfig.primaryColor/secondaryColor`) |
| Watermark text / invoice header | derive from `strings.appName` / `BrandConfig.appName` — no per-screen strings |
| Legal pages | `shree_krishna_emb_admin/web/privacy.html` + `terms.html` (deployed with hosting) |

## Per-client checklist

1. **Firebase project**
   - Create project `<client>-emb`; enable Auth (email, phone, Google, Apple), Firestore, Storage, Functions (Blaze), FCM.
   - `flutterfire configure --project <client>-emb` in BOTH apps (per-flavor dirs once F4 flavors land).
   - Deploy backend from repo root: `firebase deploy --only firestore,storage,functions --project <client>-emb`.
   - Set function secrets: `firebase functions:secrets:set RAZORPAY_KEY_ID RAZORPAY_KEY_SECRET WEBHOOK_SECRET ...`.
2. **Seed data**
   - Create the client's admin account (users doc `role: 'admin'`), log out/in once (syncs the role claim).
   - Seed `config/platform` (fee %, GST %, payment mode + the client's Razorpay keys) and publish a `config/homeFeed` layout from the admin panel.
3. **Brand assets & config**
   - Drop logo/splash/walkthrough images into `assets/brand/<client>/`.
   - Add a `BrandConfig` instance (copy `shreeKrishnaEmb`, change values); install it in `main()`.
   - Override locale `appName` (+ any brand-specific copy) per app.
   - Generate icons with `flutter_launcher_icons` from the client's master icon (add per-brand config).
4. **App identity**
   - Android: new `applicationId` (e.g. `com.<client>.emb`), new upload keystore + `key.properties` (see `android/key.properties.template`), release SHA fingerprints into the client's Firebase project.
   - iOS: new bundle id + App Store Connect record + Sign in with Apple capability; replace `GoogleService-Info.plist`.
   - (Once F4 flavors land, both of these become per-flavor config instead of edits.)
5. **Payments**
   - Client's own Razorpay account (KYC approved), live keys as function secrets, webhook URL configured, `config/platform` → Live.
6. **Legal & stores**
   - Edit `web/privacy.html` + `terms.html` (client name, support email); deploy hosting: `cd shree_krishna_emb_admin && firebase deploy --only hosting --project <client>-emb`.
   - Play Console + App Store Connect records, listings, Data Safety/privacy labels, reviewer demo account.

## Ops notes

- **Isolation:** one Firebase project per client — each client owns its data, billing, and quotas. Never share a project between brands.
- **Costs:** Blaze plan required (Cloud Functions). Razorpay fees are per client account.
- **Pending machinery (Task F4):** Flutter flavors (`--flavor <client> -t lib/main_<client>.dart`) to make step 4 pure configuration. Until then, app-identity changes are one-time edits per client checkout/branch.
