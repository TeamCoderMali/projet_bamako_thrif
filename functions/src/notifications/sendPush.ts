// ─── DANAYA — Envoi de notification (push FCM + liste in-app) ──────────────
// Helper partagé par les déclencheurs Firestore (onNewMessage, onNewOffer,
// onOfferStatusChange) : écrit toujours dans la collection "notification"
// (même schéma que l'unique écrivain existant aujourd'hui,
// relay-disputes.component.ts côté back-office — userId/title/body/type/
// data/isRead/createdAt), et envoie en plus un push FCM si l'utilisateur a
// un jeton enregistré (users/{uid}/private/data.fcmToken — voir
// NotificationRepositoryImpl.updateFcmToken côté app, câblé le 2026-10-18).
//
// ⚠️ Nécessite le forfait Firebase "Blaze" pour être déployé — voir
// index.ts et NOTES.md §10. Code écrit mais non déployé.
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import { logger } from "firebase-functions/v2";

export interface PushPayload {
  userId: string;
  title: string;
  body: string;
  type: string;
  /** Données de deep-link (chatId, orderId...) — voir main.dart côté app,
   * _navigateFromNotificationData. Toujours des chaînes (contrainte FCM). */
  data?: Record<string, string>;
}

export async function sendPushAndStore(payload: PushPayload): Promise<void> {
  const db = getFirestore();
  const now = Timestamp.now();

  // Toujours écrit en Firestore, même sans jeton FCM : garde la liste
  // in-app (notifications_page.dart) cohérente dans tous les cas, comme
  // aujourd'hui pour repairValidation.
  await db.collection("notification").add({
    userId: payload.userId,
    title: payload.title,
    body: payload.body,
    type: payload.type,
    data: payload.data ?? {},
    isRead: false,
    createdAt: now,
  });

  const privateSnap = await db
    .doc(`users/${payload.userId}/private/data`)
    .get();
  const fcmToken = privateSnap.data()?.fcmToken as string | undefined;
  if (!fcmToken) return; // pas de jeton enregistré : rien à envoyer en push

  try {
    await getMessaging().send({
      token: fcmToken,
      notification: { title: payload.title, body: payload.body },
      data: { type: payload.type, ...(payload.data ?? {}) },
    });
  } catch (err: unknown) {
    const code = (err as { code?: string } | undefined)?.code;
    if (code === "messaging/registration-token-not-registered") {
      // Jeton invalide/expiré (désinstallation, réinitialisation...) : on
      // le retire pour ne plus réessayer dans le vide à chaque futur envoi.
      await db
        .doc(`users/${payload.userId}/private/data`)
        .set({ fcmToken: null }, { merge: true });
    } else {
      logger.error(`[sendPush] échec envoi pour ${payload.userId}`, err);
    }
  }
}
