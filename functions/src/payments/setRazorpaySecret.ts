/**
 * setRazorpaySecret — onCall, ADMIN only (request.auth.token.role === 'admin').
 *
 * Input:  { mode: 'test' | 'live', secret: string }
 * Output: { success: true }
 *
 * The admin pastes a Razorpay key secret in the settings panel. We encrypt it
 * with AES-256-GCM (SECRETS_ENCRYPTION_KEY) and store the ciphertext in
 * `config/secrets` — a doc that Firestore rules block ALL client access to
 * (only the Admin SDK touches it). A non-sensitive boolean flag is mirrored
 * onto `config/platform` so the UI can show a "saved" state without ever
 * reading the secret back.
 *
 * Takes effect instantly: lib/razorpay.ts reads + decrypts from this doc at
 * runtime (see resolveKeySecret), so no redeploy is needed after a change.
 */
import { HttpsError, onCall } from "firebase-functions/v2/https";

import { Collections, Docs } from "../config/constants";
import { SECRETS_ENCRYPTION_KEY } from "../config/secrets";
import { assertAdmin } from "../lib/auth";
import { encryptSecret } from "../lib/crypto";
import { db } from "../lib/firebase";
import { nowIso } from "../utils/dates";

interface SetSecretInput {
  mode?: string;
  secret?: string;
}

export const setRazorpaySecret = onCall(
  { secrets: [SECRETS_ENCRYPTION_KEY] },
  async (request) => {
    const uid = await assertAdmin(request.auth);

    const { mode, secret } = (request.data ?? {}) as SetSecretInput;
    if (mode !== "test" && mode !== "live") {
      throw new HttpsError("invalid-argument", "mode must be 'test' or 'live'.");
    }
    if (typeof secret !== "string" || secret.trim().length === 0) {
      throw new HttpsError("invalid-argument", "secret is required.");
    }

    const isTest = mode === "test";
    const encField = isTest
      ? "razorpayKeySecretTestEnc"
      : "razorpayKeySecretLiveEnc";
    const flagField = isTest
      ? "razorpayKeySecretTestSet"
      : "razorpayKeySecretLiveSet";

    const ciphertext = encryptSecret(
      secret.trim(),
      SECRETS_ENCRYPTION_KEY.value(),
    );

    // Encrypted secret → locked config/secrets (Admin SDK only).
    await db
      .collection(Collections.config)
      .doc(Docs.configSecrets)
      .set(
        {
          [encField]: ciphertext,
          updatedAt: nowIso(),
          updatedBy: uid,
        },
        { merge: true },
      );

    // Non-sensitive "is set" flag → client-readable config/platform.
    await db
      .collection(Collections.config)
      .doc(Docs.configPlatform)
      .set({ [flagField]: true }, { merge: true });

    return { success: true };
  },
);
