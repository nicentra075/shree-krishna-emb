/**
 * One-off: stamps Firebase Auth custom claims ({ role }) for every existing
 * users/{uid} doc, so security rules can check request.auth.token.role
 * without billed get()s. New/changed users are handled automatically by the
 * onUserWrite trigger (S2.5).
 *
 * Emulator:  FIRESTORE_EMULATOR_HOST=... FIREBASE_AUTH_EMULATOR_HOST=... npm run backfill-claims
 * Test proj: GOOGLE_APPLICATION_CREDENTIALS=<sa.json> npm run backfill-claims
 *
 * NOTE: clients must refresh their ID token (getIdToken(true) or re-login)
 * before new claims take effect.
 */
import { initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { getFirestore } from "firebase-admin/firestore";

import { Collections, Roles } from "../src/config/constants";

initializeApp({ projectId: process.env.GCLOUD_PROJECT ?? "shree-krishna-emb" });
const db = getFirestore();
const auth = getAuth();

async function backfill(): Promise<void> {
  const snapshot = await db.collection(Collections.users).get();
  let updated = 0;
  let skipped = 0;

  for (const doc of snapshot.docs) {
    const role = (doc.data().role as string | undefined) ?? Roles.user;
    try {
      await auth.setCustomUserClaims(doc.id, { role });
      updated += 1;
      // eslint-disable-next-line no-console
      console.log(`  ${doc.id} → role=${role}`);
    } catch (error) {
      // Firestore doc without a matching Auth user (e.g. seed data).
      skipped += 1;
      // eslint-disable-next-line no-console
      console.warn(`  ${doc.id} skipped: ${(error as Error).message}`);
    }
  }

  // eslint-disable-next-line no-console
  console.log(`Claims backfill done: ${updated} updated, ${skipped} skipped.`);
}

backfill().then(
  () => process.exit(0),
  (error) => {
    // eslint-disable-next-line no-console
    console.error("Backfill failed:", error);
    process.exit(1);
  },
);
