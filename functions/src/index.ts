/**
 * Cloud Functions manifest for Shree Krishna Embroidery.
 *
 * Region: asia-south1 (config/constants.ts — pinned globally below).
 *
 * Phase 3 (production payments) — exported here:
 *   payments/createRazorpayOrder   (onCall)    create a Razorpay order
 *   payments/verifyRazorpayPayment (onCall)    verify signature → finalize
 *   payments/razorpayWebhook       (onRequest) idempotent source of truth
 *   payments/initiateRefund        (onCall)    admin-only refund
 *   aggregates/onOrderWrite        (trigger)   stats/global + statsDaily
 *   users/assignUserId             (trigger)   unique sequential userId
 *   users/onUserRoleWritten        (trigger)   mirror role -> custom claim
 *   users/refreshRoleClaim         (onCall)    self-serve claim sync + token refresh
 *
 * Push notifications — exported here:
 *   notifications/broadcastNotification (onCall)    admin ad-hoc announcement
 *   notifications/onOrderFinalized      (trigger)   admin purchase inbox alert
 *   notifications/onDesignWritten       (trigger)   stamp activatedAt
 *   notifications/sendNewDesignDigest   (scheduled) new-design digest, <=4/day
 *
 * Deploy: see functions/RAZORPAY_SETUP.md for secrets + webhook setup.
 */
import { setGlobalOptions } from "firebase-functions/v2";

import { REGION } from "./config/constants";

setGlobalOptions({ region: REGION, maxInstances: 10 });

// ---- Payments (Phase 3) -----------------------------------------------------
export {
  createRazorpayOrder,
  verifyRazorpayPayment,
  razorpayWebhook,
  initiateRefund,
  setRazorpaySecret,
} from "./payments";

// ---- Aggregates -------------------------------------------------------------
export { onOrderWrite } from "./aggregates/stats";

// ---- Users ------------------------------------------------------------------
export { assignUserId } from "./users/assignUserId";
export { onUserRoleWritten, refreshRoleClaim } from "./users/syncRoleClaim";

// ---- Reviews ----------------------------------------------------------------
export { onReviewWritten } from "./reviews/onReviewWritten";

// ---- Notifications ------------------------------------------------------------------
export { broadcastNotification } from "./notifications/broadcastNotification";
export { onOrderFinalized } from "./notifications/onOrderFinalized";
export { onDesignWritten } from "./notifications/onDesignWritten";
export { sendNewDesignDigest } from "./notifications/sendNewDesignDigest";
