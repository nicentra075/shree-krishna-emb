import { Timestamp, type Firestore, type WriteBatch } from "firebase-admin/firestore";

import { Collections } from "../config/constants";
import { nowIso } from "./dates";

const ACTIVITY_TTL_DAYS = 30;

export interface ActivityEntry {
  type: string;
  message: string;
  refId?: string;
  actorId?: string;
  actorName?: string;
  metadata?: Record<string, unknown>;
}

/**
 * Adds an activity-feed entry to a batch. `expireAt` is a native Timestamp
 * (createdAt + 30d) consumed by the Firestore TTL policy — intentionally
 * absent from the Dart ActivityModel.
 */
export function addActivity(
  db: Firestore,
  batch: WriteBatch,
  entry: ActivityEntry,
): void {
  const ref = db.collection(Collections.activity).doc();
  const expireAt = Timestamp.fromMillis(
    Date.now() + ACTIVITY_TTL_DAYS * 24 * 60 * 60 * 1000,
  );
  batch.set(ref, {
    type: entry.type,
    message: entry.message,
    refId: entry.refId ?? null,
    actorId: entry.actorId ?? null,
    actorName: entry.actorName ?? null,
    metadata: entry.metadata ?? {},
    createdAt: nowIso(),
    expireAt,
  });
}
