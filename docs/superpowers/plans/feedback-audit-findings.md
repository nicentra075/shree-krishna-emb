# WS-G Feedback Audit — Findings (10 July 2026)

Scope: every mutation path in both apps must surface a localized success/error
toast (D6). Audit method: grep sweeps (`ScaffoldMessenger`, empty `catch`,
`BlocListener` coverage) + spot-checks of all mutation flows.

## Result: PASS with 1 fix applied

| Check | Result |
|---|---|
| Raw `ScaffoldMessenger` outside the sanctioned wrappers | ✅ zero (only inside `ResponsiveSnackbar` itself) |
| Admin mutations (design/category/collection CRUD, uploads, layout publish, fees, users, refunds, broadcast) | ✅ 18 screens use `ResponsiveSnackbar` success+error |
| User auth flows (login/signup/OTP/social/reset) | ✅ BlocListeners with `AppSnackbar` |
| Checkout/payment | ✅ success/cancel/failure toasts |
| Cart add | ✅ success + limit-reached toasts |
| Wishlist toggle | 🔧 **FIXED** — failures were silent; `FavoriteHeart` now toasts on failure (heart flip = success feedback) |
| New WS-A/B/C code (reviews, orders, invoice, prefs, forgot-password, designer views) | ✅ built with D6 from day one |
| Empty catch blocks | ✅ all intentional best-effort paths (claim sync, FCM topic, name lookup) with comments; none swallow user-initiated mutations |

## Accepted deferrals

- Notification-preference CATEGORY toggles are persisted but send-side Cloud
  Function enforcement (reading `users/{uid}.notificationPrefs` before token
  sends) is not implemented — the master switch (FCM topic) works today.
- `Failure → localized message` mapper (G2): failures currently surface the
  repository message, which is English. Acceptable v1; revisit with hi_IN
  error copy if Hindi-first users become significant.
