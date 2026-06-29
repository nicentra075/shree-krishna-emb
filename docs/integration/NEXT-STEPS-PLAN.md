# Next-Steps Plan — from QA round 1

Triage of the DEV-STATUS-TRACKER findings, answers to your questions, and the ordered plan.

---

## 0. DO THIS FIRST — deploy rules (fixes 3 failing items with zero code change)

`DF-3`, `DF-4` ("User is not authorised" on design-file upload) and `CO-2` ("caller does not
have permission" on checkout) are **NOT code bugs** — the rules that allow them are correct in the
repo but **not deployed yet**. The `design_files/` Storage rule and the test-mode `orders` /
`purchases` Firestore rules ship only when you deploy.

```bash
firebase deploy --only firestore:rules,storage
```

Pre-checks:
- Your admin account's `users/{uid}` doc must have `role: "admin"` (image/media uploads already
  work for you, so this is already true — the Firestore `design_files/{id}` index write needs it).
- `config/platform` may be absent — that's fine: the rule defaults to **test mode** when the doc or
  `paymentTestMode` field is missing, so client-side demo checkout is allowed until you go Live.

After deploying, re-test **DF-3, DF-4, DF-7, DF-8, CO-2, CO-3, CO-4** (the dummy design files you
placed in `docs/designs_file_folder` can be uploaded once the rule is live).

---

## 1. Your questions — answered

### Q (C-4): How does the admin set Platform Fee % / GST %?
**Already built — two places, both write `config/platform`:**
1. **Settings → Payments** section (fee %, GST %, payment mode, Razorpay keys).
2. **Sidebar → Platform Fees** menu (`PF-1`) — a dedicated fee/GST editor.

Changing either updates cart/checkout totals app-wide (the user app reads `config/platform`).
If you don't see these, you're on a **stale build** — do a full restart/rebuild of the admin web
app (new Dart screens don't hot-reload in). The admin-UI agent is also verifying the Payments
section is wired into Settings.

### Q (Issue-log): Where do I put my Razorpay TEST API key + secret key?
Razorpay gives you two values — they go in **two different places**:

| Value | Example | Where it goes | Why |
|-------|---------|---------------|-----|
| **Key ID** (publishable) | `rzp_test_XXXXXXXX` | **Admin → Settings → Payments → "Razorpay test key"** field (saved to `config/platform.razorpayKeyIdTest`) | Safe on clients; the app needs it to open the Razorpay sheet |
| **Key Secret** | `xxxxxxxxxxxxxxxx` | **Cloud Functions secret** (never the app / never Firestore) | Signs/verifies payments server-side; must stay private |

Set the secret on Functions:
```bash
firebase functions:secrets:set RAZORPAY_KEY_SECRET_TEST
# paste the secret when prompted
firebase deploy --only functions
```
So: **test key id → Settings → Payments**; **secret → functions secret**. (If the key fields aren't
visible in Settings → Payments, it's a stale build — the admin-UI agent is double-checking the
wiring.) Same pattern for Live: `razorpayKeyIdLive` field + `RAZORPAY_KEY_SECRET_LIVE` secret.

---

## 2. In-progress fixes (two background agents)

**Admin UI agent:**
- `DM-1` admin login dark-mode (theme-aware — forced white + dark text was invisible in dark).
- `DF-1` redesign Add/Edit Design dialog (wider, 2-column responsive, fix Code+Author alignment,
  polished format multi-select) — no scrolling on desktop.
- `UX-6` Add-Image-URL field/button alignment.
- **Upload progress %** (issue-log) — real percentage bar in Media Library + Design File Library +
  per-format upload (replaces the bare spinner).
- **Favicon** (issue-log) — admin app icon in the browser tab.
- Verify Settings → Payments (Razorpay key fields) is wired.

**User-app agent:**
- `DM-3` pre-login dark mode (auth / walkthrough / splash themed).
- `P-1` make **My Purchases** prominent on the Account screen (was buried in Settings).

---

## 3. Go-Live (production Razorpay) — ordered checklist
1. `cd functions && npm install && npm run build` (clean).
2. Set secrets: `RAZORPAY_KEY_SECRET_TEST`, `RAZORPAY_KEY_SECRET_LIVE`, `RAZORPAY_WEBHOOK_SECRET`.
3. `firebase deploy --only functions`.
4. Razorpay dashboard → Webhooks → add
   `https://asia-south1-<PROJECT_ID>.cloudfunctions.net/razorpayWebhook` (events: payment.captured,
   order.paid, payment.failed, refund.processed).
5. Admin → Settings → Payments → set test/live key ids; keep **Test** while validating, then flip
   **Live**.
6. Validate section **K** of the tracker (create → verify → finalize → webhook → refund).

---

## 4. Remaining / deferred (decide priority)
| Item | Recommendation |
|------|----------------|
| `OPEN-1` "Get for Free" in **Live** mode | Add a tiny `claimFreeDesign` callable (free claims are gated to test mode by rules). **Do next** if you sell free designs. |
| `OPEN-3` Payouts = full designer wallet | Currently read-only "earnings owed". Build wallet + `requestPayout`/`processPayout` + Razorpay Payouts in a later phase. |
| Profile mock data | Wallet "₹4,250", "Gold plan", phone/email are placeholders — wire to the real user later. |
| Approval Queue sidebar | Still falls through to dashboard — implement when designer onboarding lands. |

---

## 5. Suggested order of work after this round
1. **Deploy rules** (§0) → unblocks DF-3/4 + CO-2. *(you)*
2. Re-test the unblocked rows; confirm the two agents' fixes. *(you + me)*
3. Deploy functions + set Razorpay secrets (§3) → validate Test-mode end-to-end on device.
4. Add `claimFreeDesign` (if needed) + flip to Live and validate section K.
5. Then move to the next feature phase (designer onboarding / payouts wallet / notifications).
