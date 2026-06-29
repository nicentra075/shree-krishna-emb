/**
 * initiateRefund — onCall, ADMIN only (request.auth.token.role === 'admin').
 *
 * Input:  { orderId, reason }
 * Output: { success: true, refundId, status }
 *
 * Order must be 'paid'. Calls Razorpay full-order refund (amount in paise),
 * sets the order to 'refund_initiated' with a `refund` sub-object, DELETES the
 * order's users/{uid}/purchases/{designId} docs (revokes downloads immediately),
 * bumps stats.pendingRefunds, logs activity. Final 'refunded' transition is
 * driven by the webhook (refund.processed).
 */
import { HttpsError, onCall } from "firebase-functions/v2/https";

import { ActivityType, Collections, OrderStatus } from "../config/constants";
import {
  RAZORPAY_KEY_SECRET,
  RAZORPAY_KEY_SECRET_LIVE,
  RAZORPAY_KEY_SECRET_TEST,
  SECRETS_ENCRYPTION_KEY,
} from "../config/secrets";
import { assertAdmin } from "../lib/auth";
import { db } from "../lib/firebase";
import { buildRazorpayClient, loadPlatformConfig } from "../lib/razorpay";
import { nowIso } from "../utils/dates";
import { addActivity } from "../utils/activity";
import type { OrderDoc, OrderRefund } from "./types";

interface RefundInput {
  orderId?: string;
  reason?: string;
}

export const initiateRefund = onCall(
  {
    secrets: [
      RAZORPAY_KEY_SECRET,
      RAZORPAY_KEY_SECRET_TEST,
      RAZORPAY_KEY_SECRET_LIVE,
      SECRETS_ENCRYPTION_KEY,
    ],
  },
  async (request) => {
    await assertAdmin(request.auth);
    const auth = request.auth!;

    const { orderId, reason } = (request.data ?? {}) as RefundInput;
    if (!orderId) {
      throw new HttpsError("invalid-argument", "orderId is required.");
    }
    const refundReason = reason ?? "Refund initiated by admin";

    // ---- Load + validate the order ----------------------------------------
    const orderRef = db.collection(Collections.orders).doc(orderId);
    const orderSnap = await orderRef.get();
    if (!orderSnap.exists) {
      throw new HttpsError("not-found", "Order not found.");
    }
    const order = orderSnap.data() as OrderDoc;
    if (order.status !== OrderStatus.paid) {
      throw new HttpsError(
        "failed-precondition",
        `Only paid orders can be refunded (current status: ${order.status}).`,
      );
    }
    if (!order.razorpayPaymentId) {
      throw new HttpsError(
        "failed-precondition",
        "Order has no captured payment to refund.",
      );
    }

    // ---- Razorpay refund (amount in paise — full order) -------------------
    const platform = await loadPlatformConfig();
    const razorpay = await buildRazorpayClient(platform);
    let refund;
    try {
      refund = await razorpay.payments.refund(order.razorpayPaymentId, {
        amount: order.totalAmount * 100, // rupees → paise
        speed: "normal",
        notes: { reason: refundReason, orderId, initiatedBy: auth.uid },
      });
    } catch (e: unknown) {
      throw new HttpsError(
        "internal",
        `Razorpay refund failed: ${(e as Error).message}`,
      );
    }

    // ---- Mark order refund_initiated + revoke downloads -------------------
    const initiatedAt = nowIso();
    const refundObj: OrderRefund = {
      refundId: refund.id,
      amount: order.totalAmount,
      reason: refundReason,
      initiatedBy: auth.uid,
      initiatedAt,
      status: OrderStatus.refundInitiated,
    };

    const batch = db.batch();
    batch.update(orderRef, {
      status: OrderStatus.refundInitiated,
      refund: refundObj,
    });

    // Delete the order's purchase docs → download rights revoked immediately.
    for (const item of order.items) {
      const purchaseRef = db
        .collection(Collections.users)
        .doc(order.userId)
        .collection(Collections.purchases)
        .doc(item.designId);
      batch.delete(purchaseRef);
    }

    // NOTE: stats.pendingRefunds++ is owned by the onOrderWrite trigger
    // (paid → refund_initiated transition) — not written here, to avoid
    // double-counting.

    addActivity(db, batch, {
      type: ActivityType.refundInitiated,
      message: `Refund initiated for order ${orderId}`,
      refId: orderId,
      actorId: auth.uid,
      actorName: (auth.token.name as string | undefined) ?? "admin",
      metadata: { amount: order.totalAmount, reason: refundReason },
    });

    await batch.commit();

    return {
      success: true,
      refundId: refund.id,
      status: OrderStatus.refundInitiated,
    };
  },
);
