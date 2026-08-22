/**
 * onReviewWritten — maintains `avgRating` + `reviewCount` on the parent design
 * whenever a review under `designs/{designId}/reviews/{reviewerUid}` is
 * created, updated, or deleted.
 *
 * Recomputes from the full subcollection inside a transaction. A design has at
 * most one review per buyer, so the read stays small at Phase-1 scale; switch
 * to incremental counters if review volume ever makes this expensive.
 */
import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { logger } from "firebase-functions/v2";

import { db } from "../lib/firebase";

export const onReviewWritten = onDocumentWritten(
  "designs/{designId}/reviews/{reviewerUid}",
  async (event) => {
    const { designId } = event.params;
    const designRef = db.collection("designs").doc(designId);
    const reviewsRef = designRef.collection("reviews");

    try {
      await db.runTransaction(async (tx) => {
        const design = await tx.get(designRef);
        if (!design.exists) return; // design deleted — nothing to aggregate

        const reviews = await tx.get(reviewsRef);
        let sum = 0;
        let count = 0;
        reviews.forEach((doc) => {
          const rating = doc.data().rating;
          if (typeof rating === "number" && rating >= 1 && rating <= 5) {
            sum += rating;
            count += 1;
          }
        });

        const avgRating = count === 0 ? 0 : Math.round((sum / count) * 10) / 10;
        const current = design.data() ?? {};
        if (current.avgRating === avgRating && current.reviewCount === count) {
          return; // already in sync — avoid a pointless write
        }
        tx.update(designRef, { avgRating, reviewCount: count });
      });
    } catch (e) {
      logger.error(`onReviewWritten failed for designs/${designId}`, e);
      throw e; // Firebase retries; the recompute is idempotent
    }
  },
);
