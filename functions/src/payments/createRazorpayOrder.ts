/**
 * createRazorpayOrder — onCall, auth required.
 *
 * Flow (docs/integration/FIRESTORE_SCHEMA.md §8 Purchase):
 *   1. Read the caller's carts/{uid}.
 *   2. Re-read each design server-side from designs/{id} — NEVER trust client
 *      prices. Skip inactive / not-ready designs.
 *   3. Compute itemsSubtotal + platformFee% + gst% from config/platform
 *      (formula in utils/money.ts). All money is int paise.
 *   4. razorpay.orders.create({ amount: totalAmount (paise), currency:'INR' })
 *      using the secret/key for the active mode (test vs live).
 *   5. Write orders/{razorpayOrderId} status 'created' with a frozen
 *      item/price/percent snapshot.
 *   6. Return { razorpayOrderId, amount, currency, keyId, orderDocId }.
 */
import { HttpsError, onCall } from "firebase-functions/v2/https";

import { Collections, DesignStatus, OrderStatus } from "../config/constants";
import {
  RAZORPAY_KEY_SECRET,
  RAZORPAY_KEY_SECRET_LIVE,
  RAZORPAY_KEY_SECRET_TEST,
  SECRETS_ENCRYPTION_KEY,
} from "../config/secrets";
import { db } from "../lib/firebase";
import { buildRazorpayClient, loadPlatformConfig } from "../lib/razorpay";
import { computeOrderAmounts } from "../utils/money";
import { nowIso } from "../utils/dates";
import type { CartDoc, OrderDoc, OrderItem } from "./types";

export const createRazorpayOrder = onCall(
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
    const uid = auth.uid;

    // ---- 1. Read the caller's cart ----------------------------------------
    const cartSnap = await db.collection(Collections.carts).doc(uid).get();
    const cart = (cartSnap.data() as CartDoc | undefined) ?? {};
    const cartItems = cart.items ?? [];
    if (cartItems.length === 0) {
      throw new HttpsError("failed-precondition", "Your cart is empty.");
    }

    // ---- 2. Re-read each design server-side (authoritative prices) ---------
    const platform = await loadPlatformConfig().catch((e: unknown) => {
      throw new HttpsError(
        "failed-precondition",
        `Platform config unavailable: ${(e as Error).message}`,
      );
    });

    // De-dupe designIds (digital goods: one purchase per design).
    const designIds = [...new Set(cartItems.map((i) => i.designId))];
    const designSnaps = await db.getAll(
      ...designIds.map((id) => db.collection(Collections.designs).doc(id)),
    );

    const items: OrderItem[] = [];
    for (const snap of designSnaps) {
      if (!snap.exists) continue;
      const d = snap.data() as Record<string, unknown>;
      // Only active designs are purchasable.
      if (d.status !== DesignStatus.active) continue;
      // Free designs are claimed without payment — never in a paid order.
      if (d.isFree === true) continue;

      // Authoritative price in integer RUPEES. The admin catalog stores
      // price/finalPrice as rupees (see design_model.dart) — finalPrice already
      // accounts for any discount; fall back to price for older docs.
      const price =
        (d.finalPrice as number | undefined) ??
        (d.price as number | undefined);
      if (typeof price !== "number" || price <= 0) continue;

      // Map to the real design schema (name / images[] / designFormats[]).
      const images = d.images as string[] | undefined;
      const formats = d.designFormats as string[] | undefined;
      items.push({
        designId: snap.id,
        title: (d.name as string | undefined) ?? "",
        thumbUrl: images && images.length > 0 ? images[0] : "",
        price, // integer rupees — server-side authoritative
        fileFormat:
          formats && formats.length > 0
            ? formats.join("/")
            : ((d.designFormat as string | undefined) ?? ""),
        categoryId: (d.categoryId as string | undefined) ?? "",
        categoryName: (d.categoryName as string | undefined) ?? "",
      });
    }

    if (items.length === 0) {
      throw new HttpsError(
        "failed-precondition",
        "No purchasable items in cart (designs may be inactive or unavailable).",
      );
    }

    // ---- 3. Compute amounts (integer rupees) ------------------------------
    const itemsSubtotal = items.reduce((sum, i) => sum + i.price, 0);
    const amounts = computeOrderAmounts(
      itemsSubtotal,
      platform.platformFeePercent,
      platform.gstPercent,
    );

    // ---- 4. Create the Razorpay order -------------------------------------
    // Order amounts are integer RUPEES; Razorpay's API expects paise → ×100.
    const razorpay = await buildRazorpayClient(platform);
    let rzpOrder;
    try {
      rzpOrder = await razorpay.orders.create({
        amount: amounts.totalAmount * 100, // rupees → paise
        currency: "INR",
        receipt: `sk_${uid.slice(0, 12)}_${Date.now()}`,
        notes: { uid, itemCount: String(items.length) },
      });
    } catch (e: unknown) {
      throw new HttpsError(
        "internal",
        `Razorpay order creation failed: ${(e as Error).message}`,
      );
    }
    const razorpayOrderId = rzpOrder.id;

    // ---- 5. Write orders/{razorpayOrderId} 'created' (frozen snapshot) -----
    const buyerName = (auth.token.name as string | undefined) ?? "";
    const buyerEmail = (auth.token.email as string | undefined) ?? "";

    const orderDoc: OrderDoc = {
      userId: uid,
      buyerName,
      buyerEmail,
      items,
      itemsSubtotal: amounts.itemsSubtotal,
      platformFee: amounts.platformFee,
      gstAmount: amounts.gstAmount,
      totalAmount: amounts.totalAmount,
      platformFeePercent: platform.platformFeePercent,
      gstPercent: platform.gstPercent,
      currency: "INR",
      status: OrderStatus.created,
      createdAt: nowIso(),
    };

    await db.collection(Collections.orders).doc(razorpayOrderId).set(orderDoc);

    // ---- 6. Response (publishable keyId only — secret stays server-side) ---
    return {
      razorpayOrderId,
      amount: amounts.totalAmount * 100, // rupees → paise (for the Razorpay sheet)
      currency: "INR",
      keyId: platform.keyId,
      orderDocId: razorpayOrderId,
      // Authoritative breakdown for the client to render.
      breakdown: {
        itemsSubtotal: amounts.itemsSubtotal,
        platformFee: amounts.platformFee,
        gstAmount: amounts.gstAmount,
        totalAmount: amounts.totalAmount,
      },
      items,
    };
  },
);
