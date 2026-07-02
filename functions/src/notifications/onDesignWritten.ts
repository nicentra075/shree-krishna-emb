/**
 * onDesignWritten — stamps activatedAt the first time a design's status
 * becomes 'active'. Idempotent: only fires when activatedAt is still unset,
 * so republishing/edits after activation never overwrite it. This timestamp
 * is the cursor sendNewDesignDigest (T23) walks forward from.
 */
import { FieldValue } from "firebase-admin/firestore";
import { onDocumentWritten } from "firebase-functions/v2/firestore";

import { Collections, DesignStatus } from "../config/constants";

export const onDesignWritten = onDocumentWritten(`${Collections.designs}/{designId}`, async (event) => {
  const after = event.data?.after;
  if (!after?.exists) return;
  const data = after.data() as Record<string, unknown>;
  const isActive = data.status === DesignStatus.active;
  const alreadyStamped = data.activatedAt != null;
  if (isActive && !alreadyStamped) {
    await after.ref.update({ activatedAt: FieldValue.serverTimestamp() });
  }
});
