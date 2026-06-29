/**
 * onOrderWrite — onDocumentWritten('orders/{orderId}') stats aggregator.
 *
 * SINGLE OWNER of order-derived aggregates so they can never be double-counted.
 * It reacts to STATUS TRANSITIONS (before.status → after.status) and applies
 * the matching delta to stats/global and statsDaily/{yyyy-MM-dd}. Because the
 * other payment functions (finalizeOrder / initiateRefund / webhook) only
 * change `status` once per real transition and are themselves idempotent, every
 * transition fires this trigger exactly once with a well-defined delta.
 *
 * Transitions handled:
 *   created        → paid             : +order, +revenue, +platformFees, +gst, +ordersPaid
 *   paid           → refund_initiated : +pendingRefunds
 *   refund_initiated → refunded       : -pendingRefunds, +refundsCount, +refundsAmount
 *
 * stats/global fields:  totalOrders, totalRevenue, totalPlatformFees, pendingRefunds
 * statsDaily fields:    ordersPaid, revenue, platformFees, gst, refundsCount, refundsAmount
 *
 * All money is int paise.
 */
import { FieldValue } from "firebase-admin/firestore";
import { onDocumentWritten } from "firebase-functions/v2/firestore";

import { Collections, Docs, OrderStatus } from "../config/constants";
import { db } from "../lib/firebase";
import { nowIso, todayKey } from "../utils/dates";
import type { OrderDoc } from "../payments/types";

export const onOrderWrite = onDocumentWritten(
  `${Collections.orders}/{orderId}`,
  async (event) => {
    const before = event.data?.before.data() as OrderDoc | undefined;
    const after = event.data?.after.data() as OrderDoc | undefined;

    // Ignore deletes and writes with no real status change.
    if (!after) return;
    const fromStatus = before?.status;
    const toStatus = after.status;
    if (fromStatus === toStatus) return;

    const day = todayKey();
    const globalRef = db.collection(Collections.stats).doc(Docs.statsGlobal);
    const dailyRef = db.collection(Collections.statsDaily).doc(day);

    // created → paid
    if (
      fromStatus === OrderStatus.created &&
      toStatus === OrderStatus.paid
    ) {
      const batch = db.batch();
      batch.set(
        globalRef,
        {
          totalOrders: FieldValue.increment(1),
          totalRevenue: FieldValue.increment(after.totalAmount),
          totalPlatformFees: FieldValue.increment(after.platformFee),
          updatedAt: nowIso(),
        },
        { merge: true },
      );
      batch.set(
        dailyRef,
        {
          date: day,
          ordersPaid: FieldValue.increment(1),
          revenue: FieldValue.increment(after.totalAmount),
          platformFees: FieldValue.increment(after.platformFee),
          gst: FieldValue.increment(after.gstAmount),
        },
        { merge: true },
      );
      await batch.commit();
      return;
    }

    // paid → refund_initiated
    if (
      fromStatus === OrderStatus.paid &&
      toStatus === OrderStatus.refundInitiated
    ) {
      await globalRef.set(
        { pendingRefunds: FieldValue.increment(1), updatedAt: nowIso() },
        { merge: true },
      );
      return;
    }

    // refund_initiated → refunded
    if (
      fromStatus === OrderStatus.refundInitiated &&
      toStatus === OrderStatus.refunded
    ) {
      const refundAmount = after.refund?.amount ?? after.totalAmount;
      const batch = db.batch();
      batch.set(
        globalRef,
        { pendingRefunds: FieldValue.increment(-1), updatedAt: nowIso() },
        { merge: true },
      );
      batch.set(
        dailyRef,
        {
          date: day,
          refundsCount: FieldValue.increment(1),
          refundsAmount: FieldValue.increment(refundAmount),
        },
        { merge: true },
      );
      await batch.commit();
      return;
    }
  },
);
