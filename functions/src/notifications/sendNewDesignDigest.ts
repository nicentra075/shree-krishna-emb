/**
 * sendNewDesignDigest — scheduled (every 30 min) digest of newly activated
 * designs, sent via FCM topic + inbox fan-out at most once per configured
 * daily slot, capped at 4 sends/day.
 *
 * Cursor seeding (only-designs-after-launch): if config/notifications
 * .newDesignCursor is unset/null, this run seeds it to "now" and returns
 * WITHOUT sending — so the very first run never announces the entire
 * pre-existing catalog as "new". Later runs walk the cursor forward using
 * designs.activatedAt (stamped by onDesignWritten, T22).
 */
import { onSchedule } from "firebase-functions/v2/scheduler";

import { Collections, DesignStatus, Docs, NotificationType, TOPIC_ALL_USERS } from "../config/constants";
import { db } from "../lib/firebase";
import { dayKey, hhmm, selectDueSlot } from "./digestLogic";
import { fanOutInbox, sendToTopic } from "./messaging";

const KOLKATA_OFFSET_MIN = 330;
const MAX_SLOTS_PER_DAY = 4;

export const sendNewDesignDigest = onSchedule("every 30 minutes", async () => {
  const ref = db.collection(Collections.config).doc(Docs.configNotifications);
  const snap = await ref.get();
  if (!snap.exists) return;
  const s = snap.data() as Record<string, unknown>;

  if (s.masterEnabled === false || s.newDesignAlertsEnabled === false) return;

  const slots = (s.dailySlots as string[]) ?? [];
  if (slots.length === 0) return;

  // Only-designs-after-launch: seed the cursor on first-ever run and bail.
  const cursorRaw = s.newDesignCursor as string | null | undefined;
  if (cursorRaw == null) {
    await ref.set({ newDesignCursor: new Date().toISOString() }, { merge: true });
    return;
  }

  const offset = KOLKATA_OFFSET_MIN;
  const now = new Date();
  const today = dayKey(now, offset);
  const firedSlots = (s.firedSlots as Record<string, string[]>) ?? {};
  const firedToday = firedSlots[today] ?? [];
  if (firedToday.length >= MAX_SLOTS_PER_DAY) return;

  const due = selectDueSlot({ slots, firedToday, nowHHmm: hhmm(now, offset) });
  if (!due) return;

  const q = db
    .collection(Collections.designs)
    .where("status", "==", DesignStatus.active)
    .where("activatedAt", ">", new Date(cursorRaw))
    .orderBy("activatedAt", "asc");

  const designs = await q.get();

  const count = designs.size;
  const newest = count > 0 ? designs.docs[designs.docs.length - 1] : undefined;
  const nd = newest?.data() as Record<string, unknown> | undefined;
  const newestActivatedAt = nd?.activatedAt as { toDate?: () => Date } | undefined;
  const newCursorIso =
    typeof newestActivatedAt?.toDate === "function" ? newestActivatedAt.toDate().toISOString() : cursorRaw;

  // Atomically claim the slot (and advance the cursor) so two overlapping
  // scheduler invocations can never both decide the same slot is due.
  const claimed = await claimSlot(ref, { today, due, maxSlotsPerDay: MAX_SLOTS_PER_DAY, newCursorIso });
  if (!claimed) return;

  if (designs.empty) return;

  const image =
    (nd?.thumbUrl as string) ?? (nd?.previewUrl as string) ?? ((nd?.images as string[] | undefined)?.[0]) ?? null;

  const payload = {
    type: NotificationType.newDesign,
    title: count === 1 ? "New design just dropped ✨" : `${count} new designs just dropped ✨`,
    body: "Tap to explore the latest designs.",
    imageUrl: image,
    data: { route: "design", designId: newest!.id },
  };

  await sendToTopic(TOPIC_ALL_USERS, payload);
  await fanOutInbox(payload);
});

interface ClaimSlotArgs {
  today: string;
  due: string;
  maxSlotsPerDay: number;
  newCursorIso: string;
}

/**
 * Atomically re-checks and claims `due` for `today` inside a transaction:
 * re-reads config/notifications, aborts (returns false) if the slot is
 * already fired or the daily cap is already hit, otherwise writes the
 * updated firedSlots + newDesignCursor and returns true.
 *
 * Ordering: the slot is claimed BEFORE the send happens in the caller. A
 * crash between claim and send means a slot is marked fired but no digest
 * went out (users miss one digest) — acceptable, and far safer than the
 * alternative of sending duplicate digests to all users.
 */
async function claimSlot(
  ref: FirebaseFirestore.DocumentReference,
  { today, due, maxSlotsPerDay, newCursorIso }: ClaimSlotArgs,
): Promise<boolean> {
  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const s = (snap.data() as Record<string, unknown>) ?? {};
    const firedSlots = (s.firedSlots as Record<string, string[]>) ?? {};
    const firedToday = firedSlots[today] ?? [];

    if (firedToday.includes(due) || firedToday.length >= maxSlotsPerDay) return false;

    const markFired = { ...firedSlots, [today]: [...firedToday, due] };
    tx.set(ref, { firedSlots: markFired, newDesignCursor: newCursorIso }, { merge: true });
    return true;
  });
}
