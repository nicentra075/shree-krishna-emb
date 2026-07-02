/**
 * Shared Firebase Admin SDK initialization.
 *
 * The Admin app must be initialized exactly once per function instance.
 * Every module that needs Firestore/Auth imports `db`/`auth` from here
 * instead of calling `admin.initializeApp()` itself.
 */
import { getApps, initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { getFirestore } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";

// Initialize once — guard against double-init in the same process (e.g. when
// multiple function modules are loaded together by the v2 codebase loader).
if (getApps().length === 0) {
  initializeApp();
}

/** Shared Firestore handle (Admin SDK — bypasses security rules). */
export const db = getFirestore();

/** Shared Auth handle (for custom claims, etc.). */
export const auth = getAuth();

/** Shared Cloud Messaging handle (topic sends, etc.). */
export const messaging = getMessaging();
