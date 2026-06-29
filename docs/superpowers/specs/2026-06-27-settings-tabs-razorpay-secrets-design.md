# Settings Tabs + Razorpay Secret Management — Design

**Date:** 2026-06-27
**Status:** Approved (build UI + backend together)

## Goal

Two related improvements to the admin **Settings** screen:

1. **Tabbed organization** — replace the single scrolling list of section cards
   with tabs: **General**, **Payments**, **Notifications**, **Seed**.
2. **Razorpay secret-key management** — let the admin paste the Razorpay
   **Key Secret** (per mode) directly in the panel, masked/write-only, and have
   the backend store it **encrypted in Firestore** so it can be edited anytime
   and takes effect instantly (no redeploy).

## Decisions (locked)

- **Secret storage:** Encrypted in Firestore (AES-256-GCM), NOT Cloud KMS, NOT
  true Functions secrets. Encryption key is a one-time Functions secret
  `SECRETS_ENCRYPTION_KEY` (set via CLI). Chosen because it takes effect
  instantly, never exposes the secret to the client, and is editable anytime.
- **Notifications tab:** empty-state placeholder for now (no toggles yet).
- **Scope:** UI + backend in one change.

## UI

### Tabs (`settings_content_view.dart`)
- `TabBar` + `TabBarView`, scrollable on narrow widths. All design-system
  components, all strings localized, all `Text` widgets get maxLines+ellipsis.
- **General:** Appearance (theme) + Language + About.
- **Payments:** `PaymentsSection`.
- **Notifications:** `AppEmptyState`-style placeholder (“coming soon”).
- **Seed:** the existing Demo Data controls (localize the hardcoded title).

### Payments section (`payments_section.dart`)
- Mode toggle (Test/Live) unchanged.
- **Per-mode fields:** when Test selected, show **Test Key ID** + **Test Secret
  Key**; when Live selected, show **Live Key ID** + **Live Secret Key**. Fee/GST
  always visible.
- **Secret field:** `obscureText` with show/hide toggle. Write-only — the secret
  is NEVER read back. If already saved, field shows a “saved — leave blank to
  keep” hint (driven by a boolean flag, see below). Typing a value replaces it.
- **Save flow:** Key IDs + fee/gst save to `config/platform` as today. A
  non-empty secret is sent through the `setRazorpaySecret` callable separately.

## Backend

### Encryption (`functions/src/lib/crypto.ts`, new)
- AES-256-GCM. Key = SHA-256 of `SECRETS_ENCRYPTION_KEY` (accepts any-length
  passphrase). Output stored as `iv:authTag:ciphertext` base64 triplet.

### `setRazorpaySecret` callable (`functions/src/payments/setRazorpaySecret.ts`, new)
- `onCall`, admin-only (`request.auth.token.role === 'admin'`).
- Input `{ mode: 'test'|'live', secret: string }`.
- Encrypts the secret, writes to `config/secrets`
  (`razorpayKeySecretTestEnc` / `razorpayKeySecretLiveEnc`).
- Sets a client-readable boolean flag on `config/platform`
  (`razorpayKeySecretTestSet` / `razorpayKeySecretLiveSet`) so the UI shows
  “saved” without exposing the value.
- Binds `secrets: [SECRETS_ENCRYPTION_KEY]`.

### Runtime resolution (`functions/src/lib/razorpay.ts`)
- `resolveKeySecret(testMode)` now: read `config/secrets` →
  decrypt the mode field → use it; fall back to the existing v2 secrets
  (`RAZORPAY_KEY_SECRET_*`) for backward compatibility.
- Becomes async; callers (`buildRazorpayClient`) updated to await.

### Rules (`firestore.rules`)
- `config/secrets`: `allow read, write: if false;` (Admin SDK only).
- `config/platform` stays admin-writable / client-readable; the new `*Set`
  flags are non-sensitive booleans.

### Constants
- `core/lib/constants/firestore_collections.dart`: add
  `CloudFunctionNames.setRazorpaySecret` + `configSecretsDoc = 'secrets'`.
- `functions/src/config/constants.ts`: add `Docs.configSecrets = 'secrets'`.

## Deploy steps (user runs)
```bash
firebase functions:secrets:set SECRETS_ENCRYPTION_KEY   # any strong passphrase
firebase deploy --only functions,firestore:rules
```

## Out of scope
- Real notification settings/toggles.
- Migrating already-set CLI secrets (fallback path keeps them working).
