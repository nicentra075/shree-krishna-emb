/**
 * Messaging helpers — FCM topic sends and Firestore inbox fan-out.
 *
 * Used by broadcastNotification (T20) and sendNewDesignDigest (T23) to
 * deliver a push notification via topic AND write a per-user inbox doc.
 */
import type { Query, QueryDocumentSnapshot } from "firebase-admin/firestore";

import { Collections } from "../config/constants";
import { db, messaging } from "../lib/firebase";

/** Splits an array into chunks of at most `size` (pure, no I/O). */
export function chunk<T>(arr: T[], size: number): T[][] {
  const out: T[][] = [];
  for (let i = 0; i < arr.length; i += size) out.push(arr.slice(i, i + size));
  return out;
}

export interface InboxPayload {
  type: string;
  title: string;
  body: string;
  imageUrl?: string | null;
  data?: Record<string, string>;
}

/** Sends a push notification to every device subscribed to `topic`. */
export async function sendToTopic(topic: string, p: InboxPayload): Promise<void> {
  await messaging.send({
    topic,
    notification: { title: p.title, body: p.body, imageUrl: p.imageUrl ?? undefined },
    data: p.data ?? {},
    android: { priority: "high" },
  });
}

export interface FanOutOptions {
  /** Optional predicate to skip specific user docs (e.g. muted users). */
  filter?: (user: QueryDocumentSnapshot) => boolean;
}

const FIRESTORE_BATCH_LIMIT = 500;

/**
 * Writes one inbox doc per user under users/{uid}/notifications, paginated
 * and batched at <=500 writes per commit. Returns the recipient count.
 */
export async function fanOutInbox(
  p: InboxPayload,
  opts: FanOutOptions = {},
): Promise<number> {
  let count = 0;
  let query: Query = db.collection(Collections.users).orderBy("__name__").limit(FIRESTORE_BATCH_LIMIT);
  let lastDoc: QueryDocumentSnapshot | undefined;

  for (;;) {
    const pageQuery = lastDoc ? query.startAfter(lastDoc) : query;
    const page = await pageQuery.get();
    if (page.empty) break;

    const docs = opts.filter ? page.docs.filter(opts.filter) : page.docs;
    for (const batchDocs of chunk(docs, FIRESTORE_BATCH_LIMIT)) {
      const batch = db.batch();
      for (const u of batchDocs) {
        const ref = u.ref.collection(Collections.userNotifications).doc();
        batch.set(ref, {
          type: p.type,
          title: p.title,
          body: p.body,
          imageUrl: p.imageUrl ?? null,
          data: p.data ?? {},
          read: false,
          createdAt: new Date().toISOString(),
        });
        count++;
      }
      await batch.commit();
    }

    lastDoc = page.docs[page.docs.length - 1];
    if (page.docs.length < FIRESTORE_BATCH_LIMIT) break;
  }

  return count;
}

/** Best-effort removal of FCM tokens that failed delivery (invalid/unregistered). */
export async function pruneInvalidTokens(uid: string, failedTokens: string[]): Promise<void> {
  await Promise.all(
    failedTokens.map((t) =>
      db
        .collection(Collections.users)
        .doc(uid)
        .collection(Collections.fcmTokens)
        .doc(t)
        .delete()
        .catch(() => undefined),
    ),
  );
}
