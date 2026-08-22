/**
 * syncRoleClaim — keeps the `role` CUSTOM CLAIM in sync with `users/{uid}.role`.
 *
 * Why: Storage security rules cannot read Firestore, so they can only gate
 * privileged writes (catalog images, EMB files, media) on
 * `request.auth.token.role`. Firestore rules and callables already accept the
 * claim as the fast path (with a Firestore fallback). This module is the single
 * writer of that claim.
 *
 * Two entry points:
 *  - onUserRoleWritten (trigger): fires on every users/{uid} write and mirrors
 *    the doc's `role` into the custom claim when it is a PRIVILEGED role
 *    ('admin' | 'designer'). Plain 'user' accounts get the claim cleared —
 *    tokens stay minimal and a demoted account loses access on next refresh.
 *  - refreshRoleClaim (callable): lets a signed-in client sync ITS OWN claim on
 *    demand and immediately refresh its ID token (the trigger path only takes
 *    effect when the client refreshes its token, which can lag by up to an
 *    hour). The admin app calls this right after sign-in / session restore so
 *    Storage uploads work in the same session. Safe by construction: it only
 *    ever copies the caller's own Firestore role — a value only admins/functions
 *    can set (rules lock `role` edits) — never caller-supplied input.
 */
import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { logger } from "firebase-functions/v2";

import { Collections } from "../config/constants";
import { auth, db } from "../lib/firebase";

/** Roles that are mirrored into the custom claim. Everything else clears it. */
const PRIVILEGED_ROLES = new Set(["admin", "designer"]);

/**
 * Reads users/{uid}.role and sets/clears the `role` custom claim accordingly.
 * Returns the role that ended up in the claim, or null when cleared.
 */
async function syncClaimFromDoc(uid: string): Promise<string | null> {
  const snap = await db.collection(Collections.users).doc(uid).get();
  const role = snap.exists
    ? (snap.data() as Record<string, unknown>).role
    : undefined;

  const privileged =
    typeof role === "string" && PRIVILEGED_ROLES.has(role) ? role : null;

  const user = await auth.getUser(uid);
  const existing = (user.customClaims ?? {}) as Record<string, unknown>;
  if ((existing.role ?? null) === privileged) return privileged; // already in sync

  // Preserve any unrelated claims; only own the `role` key.
  const next: Record<string, unknown> = { ...existing };
  if (privileged) {
    next.role = privileged;
  } else {
    delete next.role;
  }
  await auth.setCustomUserClaims(uid, next);
  logger.info(`role claim for ${uid} -> ${privileged ?? "(cleared)"}`);
  return privileged;
}

/** Trigger: mirror users/{uid}.role changes into the custom claim. */
export const onUserRoleWritten = onDocumentWritten(
  "users/{uid}",
  async (event) => {
    const before = event.data?.before?.data()?.role ?? null;
    const after = event.data?.after?.data()?.role ?? null;
    if (before === after && event.data?.before?.exists) return; // role unchanged

    const uid = event.params.uid;
    try {
      // Doc deleted → after snapshot missing → syncClaimFromDoc clears claim.
      await syncClaimFromDoc(uid);
    } catch (e) {
      // A deleted AUTH user is expected (doc cleanup after account deletion) —
      // nothing to sync onto. Anything else should retry.
      if ((e as { code?: string }).code === "auth/user-not-found") return;
      logger.error(`onUserRoleWritten failed for users/${uid}`, e);
      throw e;
    }
  },
);

/**
 * Callable: sync the CALLER's own role claim now. Returns { role } so the
 * client knows whether it gained a privileged token, then the client must call
 * getIdToken(true) to pick the new claim up.
 */
export const refreshRoleClaim = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Sign in first.");
  }
  const role = await syncClaimFromDoc(uid);
  return { role };
});
