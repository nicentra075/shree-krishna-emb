/**
 * Shared TypeScript shapes for the payment pipeline. These mirror the JSON
 * written to Firestore (the Dart models are the cross-language contract — see
 * docs/integration/FIRESTORE_SCHEMA.md §2.5/§2.6 and core/lib/models/*).
 *
 * All money fields are int paise.
 */

/** Frozen item snapshot stored on the order doc (server-side, never trusted from client). */
export interface OrderItem {
  designId: string;
  title: string;
  thumbUrl: string;
  price: number; // int paise
  fileFormat: string;
  categoryId: string;
  categoryName: string;
}

/** Refund sub-object on a refunded/refund_initiated order. */
export interface OrderRefund {
  refundId: string;
  amount: number; // int paise
  reason: string;
  initiatedBy: string;
  initiatedAt: string; // ISO
  status: string; // 'refund_initiated' | 'refunded'
}

/** The `orders/{razorpayOrderId}` document shape. */
export interface OrderDoc {
  userId: string;
  buyerName: string;
  buyerEmail: string;
  items: OrderItem[];
  itemsSubtotal: number; // int paise
  platformFee: number; // int paise
  gstAmount: number; // int paise
  totalAmount: number; // int paise
  platformFeePercent: number;
  gstPercent: number;
  currency: "INR";
  status: "created" | "paid" | "failed" | "refund_initiated" | "refunded";
  razorpayPaymentId?: string;
  invoiceNumber?: string;
  refund?: OrderRefund;
  createdAt: string; // ISO
  paidAt?: string; // ISO
  refundedAt?: string; // ISO
}

/** Item shape stored inside `carts/{uid}.items`. */
export interface CartItem {
  designId: string;
  title?: string;
  thumbUrl?: string;
  price?: number;
  categoryName?: string;
  addedAt?: string;
}

/** The `carts/{uid}` document shape. */
export interface CartDoc {
  items?: CartItem[];
  updatedAt?: string;
}
