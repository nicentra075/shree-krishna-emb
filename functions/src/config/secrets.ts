import { defineSecret } from "firebase-functions/params";

/**
 * Secrets — set via:
 *   firebase functions:secrets:set RAZORPAY_KEY_ID
 *   firebase functions:secrets:set RAZORPAY_KEY_SECRET
 *   firebase functions:secrets:set RAZORPAY_WEBHOOK_SECRET
 *   firebase functions:secrets:set SMTP_USER
 *   firebase functions:secrets:set SMTP_PASS
 *   firebase functions:secrets:set OTP_PEPPER
 *
 * Each function declares which secrets it needs via { secrets: [...] }.
 */
export const RAZORPAY_KEY_ID = defineSecret("RAZORPAY_KEY_ID");
export const RAZORPAY_KEY_SECRET = defineSecret("RAZORPAY_KEY_SECRET");
export const RAZORPAY_WEBHOOK_SECRET = defineSecret("RAZORPAY_WEBHOOK_SECRET");
export const SMTP_USER = defineSecret("SMTP_USER");
export const SMTP_PASS = defineSecret("SMTP_PASS");
export const OTP_PEPPER = defineSecret("OTP_PEPPER");
