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

  // Mark fired up-front (so empty windows don't re-poll every 30 min).
  const markFired = { ...firedSlots, [today]: [...firedToday, due] };

  const q = db
    .collection(Collections.designs)
    .where("status", "==", DesignStatus.active)
    .where("activatedAt", ">", new Date(cursorRaw))
    .orderBy("activatedAt", "asc");

  const designs = await q.get();

  if (designs.empty) {
    await ref.set({ firedSlots: markFired }, { merge: true });
    return;
  }

  const count = designs.size;
  const newest = designs.docs[designs.docs.length - 1];
  const nd = newest.data() as Record<string, unknown>;
  const image =
    (nd.thumbUrl as string) ?? (nd.previewUrl as string) ?? ((nd.images as string[] | undefined)?.[0]) ?? null;

  const payload = {
    type: NotificationType.newDesign,
    title: count === 1 ? "New design just dropped ✨" : `${count} new designs just dropped ✨`,
    body: "Tap to explore the latest designs.",
    imageUrl: image,
    data: { route: "design", designId: newest.id },
  };

  await sendToTopic(TOPIC_ALL_USERS, payload);
  await fanOutInbox(payload);

  // Advance cursor + persist fired slot.
  const newestActivatedAt = nd.activatedAt as { toDate?: () => Date } | undefined;
  const cursorIso =
    typeof newestActivatedAt?.toDate === "function" ? newestActivatedAt.toDate().toISOString() : new Date().toISOString();
  await ref.set({ firedSlots: markFired, newDesignCursor: cursorIso }, { merge: true });
});
