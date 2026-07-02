/**
 * broadcastNotification — admin-only onCall to push an ad-hoc announcement
 * to every user (FCM topic) and write it into every user's inbox.
 */
import { HttpsError, onCall } from "firebase-functions/v2/https";

import { Collections, Docs, NotificationType, TOPIC_ALL_USERS } from "../config/constants";
import { db } from "../lib/firebase";
import { fanOutInbox, sendToTopic } from "./messaging";

const TITLE_MAX_LEN = 120;
const BODY_MAX_LEN = 500;

interface CallableAuth {
  uid: string;
  token: Record<string, unknown>;
}

async function assertAdmin(auth: CallableAuth | undefined): Promise<void> {
  if (!auth) throw new HttpsError("unauthenticated", "Sign in required.");
  if (auth.token?.role === "admin") return;
  const snap = await db.collection(Collections.users).doc(auth.uid).get();
  if (snap.get("role") !== "admin") {
    throw new HttpsError("permission-denied", "Admin only.");
  }
}

export const broadcastNotification = onCall(async (req) => {
  await assertAdmin(req.auth as CallableAuth | undefined);

  const title = String(req.data?.title ?? "").trim();
  const body = String(req.data?.body ?? "").trim();
  if (!title || title.length > TITLE_MAX_LEN) {
    throw new HttpsError("invalid-argument", "Bad title.");
  }
  if (!body || body.length > BODY_MAX_LEN) {
    throw new HttpsError("invalid-argument", "Bad body.");
  }

  const settings = await db.collection(Collections.config).doc(Docs.configNotifications).get();
  if (settings.exists && settings.get("masterEnabled") === false) {
    throw new HttpsError("failed-precondition", "Notifications are disabled.");
  }

  const payload = {
    type: NotificationType.broadcast,
    title,
    body,
    data: { route: "home" },
  };
  await sendToTopic(TOPIC_ALL_USERS, payload);
  const recipientCount = await fanOutInbox(payload);
  return { recipientCount };
});
