/**
 * Admin authorization for callable functions.
 *
 * The admin app marks admins by `users/{uid}.role == 'admin'` in Firestore
 * (this is also what firestore.rules `isAdmin()` checks). For backward
 * compatibility we ALSO accept an `admin` custom claim if one is ever set.
 * Callables should use {@link assertAdmin} instead of inlining a claim check,
 * so admin detection stays consistent across rules + functions.
 */
import { HttpsError } from "firebase-functions/v2/https";

import { Collections } from "../config/constants";
import { db } from "./firebase";

/** The subset of a callable request's `auth` that admin checks need. */
interface CallerAuth {
  uid: string;
  token: Record<string, unknown>;
}

/**
 * Throws an HttpsError unless the caller is an authenticated admin. Returns the
 * caller's uid on success. Checks the `admin` custom claim first (cheap), then
 * falls back to the Firestore `users/{uid}.role` field.
 */
export async function assertAdmin(
  auth: CallerAuth | undefined,
): Promise<string> {
  if (!auth) {
    throw new HttpsError(
      "unauthenticated",
      "You are signed out. Please sign in again and retry.",
    );
  }

  // 1) Custom claim (set via Admin SDK setCustomUserClaims, if ever used).
  if (auth.token.role === "admin") return auth.uid;

  // 2) Firestore user role — the mechanism the admin app + rules actually use.
  const userSnap = await db
    .collection(Collections.users)
    .doc(auth.uid)
    .get();
  const role = userSnap.exists
    ? (userSnap.data() as Record<string, unknown>).role
    : undefined;
  if (role === "admin") return auth.uid;

  throw new HttpsError(
    "permission-denied",
    "Your account does not have admin access, so this action was blocked. " +
      "Ask a super-admin to set your account's role to 'admin'.",
  );
}
