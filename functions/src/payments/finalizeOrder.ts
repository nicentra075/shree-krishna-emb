/**
 * finalizeOrder — shared, idempotent order-completion core.
 *
 * Called by BOTH verifyRazorpayPayment (callable) and razorpayWebhook (HTTP).
 * It is the single source of truth for turning a `created` order into a `paid`
 * one. Safe to call multiple times for the same order (double-finalize guard):
 * the status transition `created → paid` happens inside a transaction and any
 * subsequent call short-circuits.
 *
 * All money is int paise. Invoice numbers are minted transactionally from
 * `counters/invoice_<year>` as `${invoicePrefix}-${year}-${seq5}`.
 */
import { FieldValue, type Transaction } from "firebase-admin/firestore";

import { Collections, OrderStatus, ActivityType } from "../config/constants";
import { db } from "../lib/firebase";
import { nowIso, todayKey } from "../utils/dates";
import { addActivity } from "../utils/activity";
import type { OrderDoc, OrderItem } from "./types";

export interface FinalizeResult {
  /** true if THIS call performed the finalize; false if it was already paid. */
  finalized: boolean;
  invoiceNumber: string;
  purchasedDesignIds: string[];
}

/**
 * Mints the next invoice number for the current (IST) year inside a running
 * transaction. Format: `${prefix}-${year}-00042`. seq resets when the year
 * rolls over (counter doc is per-year: `counters/invoice_<year>`).
 */
function mintInvoiceNumber(
  tx: Transaction,
  prefix: string,
  year: number,
  counterRef: FirebaseFirestore.DocumentReference,
  counterSnap: FirebaseFirestore.DocumentSnapshot,
): string {
  const current = (counterSnap.data()?.seq as number | undefined) ?? 0;
  const next = current + 1;
  tx.set(
    counterRef,
    { seq: next, year, updatedAt: nowIso() },
    { merge: true },
  );
  const seq5 = String(next).padStart(5, "0");
  return `${prefix}-${year}-${seq5}`;
}

/**
 * @param razorpayOrderId  the order doc id (== Razorpay order id)
 * @param razorpayPaymentId the captured payment id
 * @param invoicePrefix    from config/platform (e.g. 'SKE')
 */
export async function finalizeOrder(
  razorpayOrderId: string,
  razorpayPaymentId: string,
  invoicePrefix: string,
): Promise<FinalizeResult> {
  const orderRef = db.collection(Collections.orders).doc(razorpayOrderId);

  // IST year drives invoice numbering (matches statsDaily IST day keys).
  const year = Number(todayKey().slice(0, 4));
  const counterRef = db
    .collection(Collections.counters)
    .doc(`invoice_${year}`);

  // ---- Phase 1: transactional status transition + invoice minting ----------
  const txResult = await db.runTransaction(async (tx) => {
    const orderSnap = await tx.get(orderRef);
    if (!orderSnap.exists) {
      throw new Error(`Order ${razorpayOrderId} not found`);
    }
    const order = orderSnap.data() as OrderDoc;

    // Idempotency guard: already finalized → no-op, return existing values.
    if (order.status !== OrderStatus.created) {
      return {
        finalized: false,
        order,
        invoiceNumber: order.invoiceNumber ?? "",
      };
    }

    const counterSnap = await tx.get(counterRef);
    const invoiceNumber = mintInvoiceNumber(
      tx,
      invoicePrefix,
      year,
      counterRef,
      counterSnap,
    );

    tx.update(orderRef, {
      status: OrderStatus.paid,
      razorpayPaymentId,
      invoiceNumber,
      paidAt: nowIso(),
    });

    return { finalized: true, order, invoiceNumber };
  });

  const order = txResult.order;
  const purchasedDesignIds = order.items.map((i) => i.designId);

  // Already paid earlier — nothing more to write.
  if (!txResult.finalized) {
    return {
      finalized: false,
      invoiceNumber: txResult.invoiceNumber,
      purchasedDesignIds,
    };
  }

  // ---- Phase 2: batched fan-out (purchases, denorm counters, cart clear) ----
  const batch = db.batch();
  const purchasedAt = nowIso();

  for (const item of order.items as OrderItem[]) {
    // users/{uid}/purchases/{designId} — the keystone purchase index.
    const purchaseRef = db
      .collection(Collections.users)
      .doc(order.userId)
      .collection(Collections.purchases)
      .doc(item.designId);
    batch.set(purchaseRef, {
      designId: item.designId,
      orderId: razorpayOrderId,
      title: item.title,
      thumbUrl: item.thumbUrl,
      fileFormat: item.fileFormat,
      pricePaid: item.price, // int paise
      purchasedAt,
    });

    // designs.salesCount++
    const designRef = db.collection(Collections.designs).doc(item.designId);
    batch.set(
      designRef,
      { salesCount: FieldValue.increment(1) },
      { merge: true },
    );
  }

  // users.purchaseCount++ (denorm for admin user list)
  batch.set(
    db.collection(Collections.users).doc(order.userId),
    { purchaseCount: FieldValue.increment(order.items.length) },
    { merge: true },
  );

  // NOTE: order-derived stats (stats/global, statsDaily revenue/fees/gst) are
  // owned exclusively by the onOrderWrite trigger (aggregates/stats.ts), keyed
  // off the created→paid status transition — so they are never double-counted
  // even if finalizeOrder is retried or also runs via the webhook.

  // Clear the cart — a paid cart can never resurrect.
  batch.delete(db.collection(Collections.carts).doc(order.userId));

  // activity: order_paid
  addActivity(db, batch, {
    type: ActivityType.orderPaid,
    message: `Order ${razorpayOrderId} paid (${order.buyerName})`,
    refId: razorpayOrderId,
    actorId: order.userId,
    actorName: order.buyerName,
    metadata: {
      totalAmount: order.totalAmount,
      invoiceNumber: txResult.invoiceNumber,
      itemCount: order.items.length,
    },
  });

  await batch.commit();

  return {
    finalized: true,
    invoiceNumber: txResult.invoiceNumber,
    purchasedDesignIds,
  };
}
