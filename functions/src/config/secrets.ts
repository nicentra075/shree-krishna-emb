import { defineSecret } from "firebase-functions/params";

/**
 * Secrets — set via:
 *   firebase functions:secrets:set RAZORPAY_KEY_ID
 *   firebase functions:secrets:set RAZORPAY_KEY_SECRET
 *   firebase functions:secrets:set RAZORPAY_KEY_SECRET_TEST
 *   firebase functions:secrets:set RAZORPAY_KEY_SECRET_LIVE
 *   firebase functions:secrets:set RAZORPAY_WEBHOOK_SECRET
 *   firebase functions:secrets:set SMTP_USER
 *   firebase functions:secrets:set SMTP_PASS
 *   firebase functions:secrets:set OTP_PEPPER
 *
 * Each function declares which secrets it needs via { secrets: [...] }.
 *
 * Payment mode (test vs live) is chosen at runtime from
 * `config/platform.paymentTestMode` — see lib/razorpay.ts. The publishable
 * key IDs live in `config/platform` (razorpayKeyIdTest / razorpayKeyIdLive),
 * the secrets are NEVER stored in Firestore.
 */
export const RAZORPAY_KEY_ID = defineSecret("RAZORPAY_KEY_ID");
export const RAZORPAY_KEY_SECRET = defineSecret("RAZORPAY_KEY_SECRET");
export const RAZORPAY_KEY_SECRET_TEST = defineSecret("RAZORPAY_KEY_SECRET_TEST");
export const RAZORPAY_KEY_SECRET_LIVE = defineSecret("RAZORPAY_KEY_SECRET_LIVE");
export const RAZORPAY_WEBHOOK_SECRET = defineSecret("RAZORPAY_WEBHOOK_SECRET");
export const SMTP_USER = defineSecret("SMTP_USER");
export const SMTP_PASS = defineSecret("SMTP_PASS");
export const OTP_PEPPER = defineSecret("OTP_PEPPER");

/**
 * Passphrase used to AES-256-GCM encrypt admin-managed secrets (e.g. the
 * Razorpay key secrets) before storing them in Firestore (`config/secrets`).
 * Set once via: `firebase functions:secrets:set SECRETS_ENCRYPTION_KEY`.
 * Any length — the crypto layer hashes it to a 32-byte key.
 */
export const SECRETS_ENCRYPTION_KEY = defineSecret("SECRETS_ENCRYPTION_KEY");
