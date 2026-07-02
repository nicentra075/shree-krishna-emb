/**
 * onOrderFinalized — writes one admin_notifications doc when an order
 * transitions into 'paid'. Admin-only inbox item; no FCM push.
 */
import { onDocumentWritten } from "firebase-functions/v2/firestore";

import { Collections, Docs, NotificationType, OrderStatus } from "../config/constants";
import { db } from "../lib/firebase";

export const onOrderFinalized = onDocumentWritten(`${Collections.orders}/{orderId}`, async (event) => {
  const before = event.data?.before.data();
  const after = event.data?.after.data();
  if (!after) return;
  const becamePaid = before?.status !== OrderStatus.paid && after.status === OrderStatus.paid;
  if (!becamePaid) return;

  const settings = await db.collection(Collections.config).doc(Docs.configNotifications).get();
  if (settings.exists && settings.get("purchaseAlertsEnabled") === false) return;

  const items: Array<Record<string, unknown>> = Array.isArray(after.items) ? after.items : [];
  const first = items[0] ?? {};
  const designTitle = (first.title as string) ?? (first.name as string) ?? "an item";
  const buyer = (after.buyerName as string) ?? "A user";
  const total = typeof after.totalAmount === "number" ? after.totalAmount : 0;
  const rupees = (total / 100).toFixed(total % 100 === 0 ? 0 : 2);
  const body =
    total > 0 ? `${designTitle} — ₹${rupees} by ${buyer}` : `${designTitle} (free) claimed by ${buyer}`;

  await db.collection(Collections.adminNotifications).add({
    type: NotificationType.purchase,
    title: "New purchase",
    body,
    data: {
      orderId: event.params.orderId,
      designId: (first.designId as string) ?? "",
      userId: (after.userId as string) ?? "",
    },
    readBy: [],
    createdAt: new Date().toISOString(),
  });
});
