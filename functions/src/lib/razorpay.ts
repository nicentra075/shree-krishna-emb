/**
 * Razorpay client factory + platform-config reader.
 *
 * MODE SELECTION
 * --------------
 * `config/platform.paymentTestMode` (boolean) decides whether we operate in
 * TEST or LIVE mode. The publishable **key id** for the active mode comes from
 * Firestore (`razorpayKeyIdTest` / `razorpayKeyIdLive`, falling back to the
 * legacy single `razorpayKeyId`). The **key secret** for the active mode is
 * resolved in this order:
 *   1. The admin-managed, AES-256-GCM-encrypted secret in `config/secrets`
 *      (`razorpayKeySecretTestEnc` / `razorpayKeySecretLiveEnc`), decrypted with
 *      the `SECRETS_ENCRYPTION_KEY` secret. This is what the settings panel
 *      writes (see payments/setRazorpaySecret) and takes effect with no redeploy.
 *   2. Fallback to the v2 secrets (`RAZORPAY_KEY_SECRET_TEST` /
 *      `RAZORPAY_KEY_SECRET_LIVE`, then legacy `RAZORPAY_KEY_SECRET`) for
 *      installs that still configure secrets via the CLI.
 * Plaintext secrets are NEVER stored in Firestore — only ciphertext.
 *
 * MONEY UNIT
 * ----------
 * All money in this codebase — designs.price, order amounts, Razorpay amounts —
 * is **int paise** (INR minor units; 14900 == ₹149.00). Razorpay's API also
 * uses paise natively, so amounts pass through 1:1 with NO ×100 conversion.
 * (See docs/integration/FIRESTORE_SCHEMA.md §1.) Order docs store paise to
 * match what the apps display.
 */
import Razorpay from "razorpay";

import { Collections, Docs } from "../config/constants";
import {
  RAZORPAY_KEY_SECRET,
  RAZORPAY_KEY_SECRET_LIVE,
  RAZORPAY_KEY_SECRET_TEST,
  SECRETS_ENCRYPTION_KEY,
} from "../config/secrets";
import { decryptSecret } from "./crypto";
import { db } from "./firebase";

/** Shape of the fields we read from `config/platform`. */
export interface PlatformConfig {
  platformFeePercent: number;
  gstPercent: number;
  paymentTestMode: boolean;
  /** Publishable key id for the active mode (resolved). */
  keyId: string;
  invoicePrefix: string;
}

interface PlatformConfigDoc {
  platformFeePercent?: number;
  gstPercent?: number;
  platformFeeEnabled?: boolean;
  gstEnabled?: boolean;
  paymentTestMode?: boolean;
  razorpayKeyId?: string;
  razorpayKeyIdTest?: string;
  razorpayKeyIdLive?: string;
  invoicePrefix?: string;
}

/**
 * Loads and validates `config/platform`. Throws if the doc or any required
 * field is missing — callers translate this into an HttpsError.
 */
export async function loadPlatformConfig(): Promise<PlatformConfig> {
  const snap = await db
    .collection(Collections.config)
    .doc(Docs.configPlatform)
    .get();

  if (!snap.exists) {
    throw new Error("config/platform document is missing");
  }
  const data = snap.data() as PlatformConfigDoc;

  const rawFeePercent = data.platformFeePercent;
  const rawGstPercent = data.gstPercent;
  if (typeof rawFeePercent !== "number" || typeof rawGstPercent !== "number") {
    throw new Error("config/platform is missing fee/gst percentages");
  }

  // A charge applies only when explicitly enabled (default true for older
  // configs) AND its percent is > 0 — mirrors the user app + admin toggles.
  // Effective percents are returned so order math + the frozen snapshot agree.
  const feeEnabled = data.platformFeeEnabled !== false;
  const gstEnabled = data.gstEnabled !== false;
  const platformFeePercent = feeEnabled && rawFeePercent > 0 ? rawFeePercent : 0;
  const gstPercent = gstEnabled && rawGstPercent > 0 ? rawGstPercent : 0;

  const testMode = data.paymentTestMode !== false; // default safe: TEST
  const keyId = testMode
    ? data.razorpayKeyIdTest ?? data.razorpayKeyId
    : data.razorpayKeyIdLive ?? data.razorpayKeyId;
  if (!keyId) {
    throw new Error(
      `config/platform is missing the Razorpay publishable key id for ${
        testMode ? "TEST" : "LIVE"
      } mode`,
    );
  }

  return {
    platformFeePercent,
    gstPercent,
    paymentTestMode: testMode,
    keyId,
    invoicePrefix: data.invoicePrefix ?? "SKE",
  };
}

/**
 * Reads + decrypts the admin-managed key secret for `testMode` from
 * `config/secrets`. Returns null if no secret is stored for that mode (so the
 * caller can fall back to the v2 secrets). Throws only if a stored secret
 * exists but cannot be decrypted (wrong/missing SECRETS_ENCRYPTION_KEY).
 */
async function readEncryptedKeySecret(
  testMode: boolean,
): Promise<string | null> {
  const snap = await db
    .collection(Collections.config)
    .doc(Docs.configSecrets)
    .get();
  if (!snap.exists) return null;
  const data = snap.data() as Record<string, unknown>;
  const field = testMode
    ? "razorpayKeySecretTestEnc"
    : "razorpayKeySecretLiveEnc";
  const ciphertext = data[field];
  if (typeof ciphertext !== "string" || ciphertext.length === 0) return null;
  return decryptSecret(ciphertext, SECRETS_ENCRYPTION_KEY.value());
}

/**
 * Resolves the Razorpay key secret for the active mode. Prefers the
 * admin-managed encrypted secret in Firestore; falls back to the v2 secrets
 * (mode-specific, then legacy single `RAZORPAY_KEY_SECRET`).
 */
export async function resolveKeySecret(testMode: boolean): Promise<string> {
  const encrypted = await readEncryptedKeySecret(testMode);
  if (encrypted) return encrypted;

  const modeSecret = testMode
    ? RAZORPAY_KEY_SECRET_TEST.value()
    : RAZORPAY_KEY_SECRET_LIVE.value();
  const secret = modeSecret || RAZORPAY_KEY_SECRET.value();
  if (!secret) {
    throw new Error(
      `Razorpay key secret for ${testMode ? "TEST" : "LIVE"} mode is not set`,
    );
  }
  return secret;
}

/** Builds a Razorpay SDK client for the active mode. */
export async function buildRazorpayClient(
  cfg: PlatformConfig,
): Promise<Razorpay> {
  return new Razorpay({
    key_id: cfg.keyId,
    key_secret: await resolveKeySecret(cfg.paymentTestMode),
  });
}
