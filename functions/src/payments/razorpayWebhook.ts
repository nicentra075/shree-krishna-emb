/**
 * razorpayWebhook — onRequest (HTTPS), no auth (Razorpay → us).
 *
 * Verifies the `X-Razorpay-Signature` header against the RAW request body
 * using RAZORPAY_WEBHOOK_SECRET (HMAC-SHA256), then handles events:
 *   - payment.captured / order.paid → finalizeOrder() (idempotent source of
 *     truth; safety net if the client dies mid-flow)
 *   - payment.failed               → mark order 'failed'
 *   - refund.processed             → mark order 'refunded' + decrement pending
 * Responds 200 quickly; non-2xx makes Razorpay retry.
 *
 * IMPORTANT: signature must be computed over the EXACT raw bytes Razorpay sent.
 * firebase-functions v2 exposes the unparsed buffer as `request.rawBody`.
 */
import { createHmac, timingSafeEqual } from "node:crypto";

import { onRequest, type Request } from "firebase-functions/v2/https";
import { logger } from "firebase-functions/v2";

import { ActivityType, Collections, OrderStatus } from "../config/constants";
import { RAZORPAY_WEBHOOK_SECRET } from "../config/secrets";
import { db } from "../lib/firebase";
import { loadPlatformConfig } from "../lib/razorpay";
import { nowIso } from "../utils/dates";
import { addActivity } from "../utils/activity";
import { finalizeOrder } from "./finalizeOrder";
import type { OrderDoc } from "./types";

function verifyWebhookSignature(
  rawBody: Buffer,
  signature: string,
  secret: string,
): boolean {
  const expected = createHmac("sha256", secret)
    .update(rawBody)
    .digest("hex");
  const a = Buffer.from(expected, "utf8");
  const b = Buffer.from(signature, "utf8");
  if (a.length !== b.length) return false;
  return timingSafeEqual(a, b);
}

/** Marks an order 'failed' (only from 'created' — never clobber a paid order). */
async function markOrderFailed(orderId: string): Promise<void> {
  const ref = db.collection(Collections.orders).doc(orderId);
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) return;
    const order = snap.data() as OrderDoc;
    if (order.status !== OrderStatus.created) return;
    tx.update(ref, { status: OrderStatus.failed });
  });
}

/**
 * Completes a refund: 'refund_initiated' → 'refunded'. Stats adjustments
 * (pendingRefunds--, statsDaily.refunds*) are owned by the onOrderWrite trigger
 * off this status transition — we only flip the status + log activity here.
 */
async function completeRefund(orderId: string): Promise<void> {
  const ref = db.collection(Collections.orders).doc(orderId);
  const refundedAt = nowIso();

  const order = await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) return null;
    const o = snap.data() as OrderDoc;
    if (o.status !== OrderStatus.refundInitiated) return null; // idempotent
    tx.update(ref, {
      status: OrderStatus.refunded,
      refundedAt,
      "refund.status": OrderStatus.refunded,
    });
    return o;
  });
  if (!order) return;

  const refundAmount = order.refund?.amount ?? order.totalAmount;
  const batch = db.batch();
  addActivity(db, batch, {
    type: ActivityType.refundCompleted,
    message: `Refund completed for order ${orderId}`,
    refId: orderId,
    actorId: order.userId,
    actorName: order.buyerName,
    metadata: { amount: refundAmount },
  });
  await batch.commit();
}

export const razorpayWebhook = onRequest(
  { secrets: [RAZORPAY_WEBHOOK_SECRET] },
  async (req: Request, res) => {
    if (req.method !== "POST") {
      res.status(405).send("Method Not Allowed");
      return;
    }

    const signature = req.headers["x-razorpay-signature"];
    const rawBody = req.rawBody;
    if (typeof signature !== "string" || !rawBody) {
      logger.warn("razorpayWebhook: missing signature or raw body");
      res.status(400).send("Bad Request");
      return;
    }

    const secret = RAZORPAY_WEBHOOK_SECRET.value();
    if (!verifyWebhookSignature(rawBody, signature, secret)) {
      logger.warn("razorpayWebhook: signature verification failed");
      res.status(401).send("Invalid signature");
      return;
    }

    let event: {
      event?: string;
      payload?: {
        payment?: { entity?: { order_id?: string; id?: string } };
        order?: { entity?: { id?: string } };
        refund?: { entity?: { id?: string } };
      };
    };
    try {
      event = JSON.parse(rawBody.toString("utf8"));
    } catch {
      res.status(400).send("Invalid JSON");
      return;
    }

    const eventType = event.event ?? "";
    const paymentEntity = event.payload?.payment?.entity;
    const orderId =
      paymentEntity?.order_id ?? event.payload?.order?.entity?.id;

    try {
      switch (eventType) {
        case "payment.captured":
        case "order.paid": {
          if (orderId && paymentEntity?.id) {
            const platform = await loadPlatformConfig();
            await finalizeOrder(
              orderId,
              paymentEntity.id,
              platform.invoicePrefix,
            );
          }
          break;
        }
        case "payment.failed": {
          if (orderId) {
            await markOrderFailed(orderId);
          }
          break;
        }
        case "refund.processed":
        case "refund.created": {
          if (orderId) {
            await completeRefund(orderId);
          }
          break;
        }
        default:
          // Unhandled event types are acknowledged (200) but ignored.
          logger.info(`razorpayWebhook: ignoring event ${eventType}`);
      }
    } catch (e: unknown) {
      // Log and return 500 so Razorpay retries — finalize is idempotent.
      logger.error(`razorpayWebhook: handler error for ${eventType}`, e);
      res.status(500).send("Handler error");
      return;
    }

    res.status(200).send("ok");
  },
);
