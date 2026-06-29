/**
 * assignUserId — Firestore onCreate trigger for `users/{uid}`.
 *
 * The single source of truth for the human-friendly sequential `userId` (int).
 * Both clients (user-app signup + admin createUser) may write a PROVISIONAL
 * userId, but this function overwrites it with an atomic, collision-free
 * sequential value minted from `counters/users.seq` — the `counters` collection
 * is locked to Cloud Functions only (rules deny client reads/writes), and the
 * Admin SDK bypasses rules.
 *
 * Guarantees the user asked for:
 *  - EVERY new user (admin-panel OR app signup) gets a unique sequential userId.
 *  - EXISTING users are never renumbered — the trigger only fires for newly
 *    created docs, and the counter is bootstrapped ABOVE the current max real
 *    userId so new ids never collide with ids already in use.
 *  - Idempotent: a Firebase retry can't double-assign (guarded by
 *    `userIdAssigned`); concurrent first-creates can't collide (the counter
 *    write contends → Firestore retries the loser, which then reads the seeded
 *    counter and increments).
 */
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { logger } from "firebase-functions/v2";

import { Collections } from "../config/constants";
import { db } from "../lib/firebase";
import { nowIso } from "../utils/dates";

// userIds at/above this are timestamp-style PROVISIONAL ids (ms since epoch,
// ~1.7e12) written by older client code — they are NOT real sequence numbers,
// so they're ignored when seeding the counter. A real user count never reaches
// 1e10, and timestamps are always far above it, so the two ranges never mix.
const TIMESTAMP_ID_FLOOR = 10_000_000_000; // 1e10

export const assignUserId = onDocumentCreated("users/{uid}", async (event) => {
  const snap = event.data;
  if (!snap) return;

  const userRef = snap.ref;
  const counterRef = db.collection(Collections.counters).doc("users");

  // First-run bootstrap: if the counter doesn't exist yet, start it ABOVE the
  // current max REAL (non-timestamp) userId so the first new id can't collide
  // with an existing user. Cheap single-doc read; only happens until the
  // counter is seeded, then never again.
  let base = 0;
  const counterPeek = await counterRef.get();
  if (!counterPeek.exists) {
    const maxSnap = await db
      .collection(Collections.users)
      .where("userId", "<", TIMESTAMP_ID_FLOOR)
      .orderBy("userId", "desc")
      .limit(1)
      .get();
    if (!maxSnap.empty) {
      const raw = maxSnap.docs[0].data().userId;
      if (typeof raw === "number") base = Math.floor(raw);
    }
  }

  try {
    await db.runTransaction(async (tx) => {
      const live = await tx.get(userRef);
      if (!live.exists) return; // doc deleted before we ran
      if (live.data()?.userIdAssigned === true) return; // already done (retry)

      const counterSnap = await tx.get(counterRef);
      const current = counterSnap.exists
        ? ((counterSnap.data()?.seq as number | undefined) ?? base)
        : base;
      const seq = current + 1;

      tx.set(counterRef, { seq, updatedAt: nowIso() }, { merge: true });
      tx.update(userRef, { userId: seq, userIdAssigned: true });
    });
  } catch (e) {
    logger.error(`assignUserId failed for users/${event.params.uid}`, e);
    throw e; // let Firebase retry; the userIdAssigned guard prevents duplicates
  }
});
