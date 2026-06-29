/**
 * verifyRazorpayPayment — onCall, auth required.
 *
 * Input:  { razorpay_order_id, razorpay_payment_id, razorpay_signature }
 * Output: { success: true, invoiceNumber, purchasedDesignIds }
 *
 * Verifies the Razorpay client-side payment signature:
 *   expected = HMAC_SHA256(`${order_id}|${payment_id}`, KEY_SECRET)
 * compared in constant time against razorpay_signature. On mismatch →
 * HttpsError('failed-precondition'). On success → shared finalizeOrder()
 * (idempotent; the webhook is the parallel safety net).
 */
import { createHmac, timingSafeEqual } from "node:crypto";

import { HttpsError, onCall } from "firebase-functions/v2/https";

import { Collections } from "../config/constants";
import {
  RAZORPAY_KEY_SECRET,
  RAZORPAY_KEY_SECRET_LIVE,
  RAZORPAY_KEY_SECRET_TEST,
  SECRETS_ENCRYPTION_KEY,
} from "../config/secrets";
import { db } from "../lib/firebase";
import { loadPlatformConfig, resolveKeySecret } from "../lib/razorpay";
import { finalizeOrder } from "./finalizeOrder";
import type { OrderDoc } from "./types";

interface VerifyInput {
  razorpay_order_id?: string;
  razorpay_payment_id?: string;
  razorpay_signature?: string;
}

/** Constant-time HMAC-SHA256 signature check. */
function verifySignature(
  orderId: string,
  paymentId: string,
  signature: string,
  keySecret: string,
): boolean {
  const expected = createHmac("sha256", keySecret)
    .update(`${orderId}|${paymentId}`)
    .digest("hex");
  const a = Buffer.from(expected, "utf8");
  const b = Buffer.from(signature, "utf8");
  if (a.length !== b.length) return false;
  return timingSafeEqual(a, b);
}

export const verifyRazorpayPayment = onCall(
  {
    secrets: [
      RAZORPAY_KEY_SECRET,
      RAZORPAY_KEY_SECRET_TEST,
      RAZORPAY_KEY_SECRET_LIVE,
      SECRETS_ENCRYPTION_KEY,
    ],
  },
  async (request) => {
    const auth = request.auth;
    if (!auth) {
      throw new HttpsError("unauthenticated", "Sign in required.");
    }

    const {
      razorpay_order_id: orderId,
      razorpay_payment_id: paymentId,
      razorpay_signature: signature,
    } = (request.data ?? {}) as VerifyInput;

    if (!orderId || !paymentId || !signature) {
      throw new HttpsError(
        "invalid-argument",
        "razorpay_order_id, razorpay_payment_id and razorpay_signature are required.",
      );
    }

    // The order doc id IS the razorpay order id. Confirm ownership.
    const orderRef = db.collection(Collections.orders).doc(orderId);
    const orderSnap = await orderRef.get();
    if (!orderSnap.exists) {
      throw new HttpsError("not-found", "Order not found.");
    }
    const order = orderSnap.data() as OrderDoc;
    if (order.userId !== auth.uid) {
      throw new HttpsError("permission-denied", "Not your order.");
    }

    // Verify signature with the active-mode key secret.
    const platform = await loadPlatformConfig();
    const keySecret = await resolveKeySecret(platform.paymentTestMode);
    const ok = verifySignature(orderId, paymentId, signature, keySecret);
    if (!ok) {
      throw new HttpsError(
        "failed-precondition",
        "Payment signature verification failed.",
      );
    }

    // Idempotent finalize (verify + webhook share this core).
    const result = await finalizeOrder(
      orderId,
      paymentId,
      platform.invoicePrefix,
    );

    return {
      success: true,
      invoiceNumber: result.invoiceNumber,
      purchasedDesignIds: result.purchasedDesignIds,
    };
  },
);
