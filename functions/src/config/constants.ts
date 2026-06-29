/**
 * Firestore collection/document name constants.
 *
 * MUST mirror the Dart side exactly:
 *   core/lib/constants/firestore_collections.dart
 * Full schema contract: docs/integration/FIRESTORE_SCHEMA.md
 */
export const Collections = {
  users: "users",
  designs: "designs",
  categories: "categories",
  orders: "orders",
  carts: "carts",
  wishlists: "wishlists",
  config: "config",
  stats: "stats",
  statsDaily: "statsDaily",
  activity: "activity",
  adminOtps: "adminOtps",
  counters: "counters",
  // Subcollections
  purchases: "purchases", // users/{uid}/purchases/{designId}
  reviews: "reviews", // designs/{designId}/reviews/{reviewerUid}
} as const;

export const Docs = {
  configPlatform: "platform",
  configSecrets: "secrets",
  configHomeFeed: "homeFeed",
  statsGlobal: "global",
  countersInvoices: "invoices",
} as const;

/** Mirrors CloudFunctionNames.region in core. */
export const REGION = "asia-south1";

/** Storage path builders — mirror core/lib/constants/storage_paths.dart */
export const StoragePaths = {
  designSource: (designId: string, fileName: string) =>
    `designs/${designId}/source/${fileName}`,
  designOriginal: (designId: string, fileName: string) =>
    `designs/${designId}/original/${fileName}`,
  designPreview: (designId: string) => `designs/${designId}/public/preview.jpg`,
  designThumb: (designId: string) => `designs/${designId}/public/thumb.jpg`,
} as const;

/** Matches Dart UserRole values. */
export const Roles = {
  admin: "admin",
  designer: "designer",
  user: "user",
} as const;

/** Matches Dart OrderStatus values. */
export const OrderStatus = {
  created: "created",
  paid: "paid",
  failed: "failed",
  refundInitiated: "refund_initiated",
  refunded: "refunded",
} as const;

/** Matches Dart DesignStatus / DesignProcessingStatus values. */
export const DesignStatus = {
  draft: "draft",
  active: "active",
  archived: "archived",
} as const;

export const ProcessingStatus = {
  pending: "pending",
  ready: "ready",
  failed: "failed",
} as const;

/** Matches Dart ActivityType values. */
export const ActivityType = {
  userSignup: "user_signup",
  orderPaid: "order_paid",
  designCreated: "design_created",
  designUpdated: "design_updated",
  categoryCreated: "category_created",
  refundInitiated: "refund_initiated",
  refundCompleted: "refund_completed",
} as const;
