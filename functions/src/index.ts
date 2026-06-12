/**
 * Cloud Functions manifest for Shree Krishna Embroidery — Phase 1.
 *
 * Functions are implemented step-by-step per docs/integration/PHASE1_PROGRESS.md
 * and exported here as they land:
 *
 *   S1.4  export { onDesignAssetUpload } from "./media/onDesignAssetUpload";
 *   S2.1  export { requestAdminOtp, verifyAdminOtp } from "./adminAuth";
 *   S2.3  export { initiateRefund } from "./payments/refund";
 *   S2.5  export { onUserWrite, onDesignWrite, onCategoryWrite, onReviewWrite }
 *           from "./aggregates";
 *   S4.2  export { createRazorpayOrder, verifyRazorpayPayment, razorpayWebhook }
 *           from "./payments";
 *
 * Region: asia-south1 (see config/constants.ts — every function must pin it).
 */
import { setGlobalOptions } from "firebase-functions/v2";

import { REGION } from "./config/constants";

setGlobalOptions({ region: REGION, maxInstances: 10 });

// No functions exported yet — S0.8 deploys only rules/indexes/storage.
export {};
