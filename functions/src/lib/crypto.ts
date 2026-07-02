/**
 * Symmetric encryption for admin-managed secrets stored in Firestore.
 *
 * Used to encrypt the Razorpay key secrets that the admin pastes in the panel
 * before persisting them to `config/secrets` (see payments/setRazorpaySecret).
 * The encryption passphrase is the `SECRETS_ENCRYPTION_KEY` v2 secret; it is
 * hashed to a 32-byte AES-256 key so any passphrase length is accepted.
 *
 * Format: `${ivB64}:${authTagB64}:${cipherB64}` (all base64). AES-256-GCM.
 */
import {
  createCipheriv,
  createDecipheriv,
  createHash,
  randomBytes,
} from "crypto";

const ALGO = "aes-256-gcm";
const IV_BYTES = 12; // GCM standard nonce length

function keyFromPassphrase(passphrase: string): Buffer {
  if (!passphrase) {
    throw new Error("SECRETS_ENCRYPTION_KEY is not set");
  }
  return createHash("sha256").update(passphrase, "utf8").digest();
}

/** Encrypts `plaintext` and returns an `iv:authTag:cipher` base64 triplet. */
export function encryptSecret(plaintext: string, passphrase: string): string {
  const key = keyFromPassphrase(passphrase);
  const iv = randomBytes(IV_BYTES);
  const cipher = createCipheriv(ALGO, key, iv);
  const ciphertext = Buffer.concat([
    cipher.update(plaintext, "utf8"),
    cipher.final(),
  ]);
  const authTag = cipher.getAuthTag();
  return [
    iv.toString("base64"),
    authTag.toString("base64"),
    ciphertext.toString("base64"),
  ].join(":");
}

/** Reverses {@link encryptSecret}. Throws if the payload is malformed/tampered. */
export function decryptSecret(payload: string, passphrase: string): string {
  const key = keyFromPassphrase(passphrase);
  const parts = payload.split(":");
  if (parts.length !== 3) {
    throw new Error("Encrypted secret payload is malformed");
  }
  const [ivB64, tagB64, cipherB64] = parts;
  const decipher = createDecipheriv(
    ALGO,
    key,
    Buffer.from(ivB64, "base64"),
  );
  decipher.setAuthTag(Buffer.from(tagB64, "base64"));
  return Buffer.concat([
    decipher.update(Buffer.from(cipherB64, "base64")),
    decipher.final(),
  ]).toString("utf8");
}
