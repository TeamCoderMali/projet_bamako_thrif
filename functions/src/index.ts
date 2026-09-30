// ─── DANAYA — Cloud Functions ───────────────────────────────────────────────
// ⚠️ Nécessite le forfait Firebase "Blaze" (payant à l'usage) pour être
// déployées — le projet est vraisemblablement encore sur "Spark" (gratuit).
// Ne pas déployer avant validation définitive de la cliente (voir NOTES.md §10).
import { onSchedule } from "firebase-functions/v2/scheduler";
import { initializeApp } from "firebase-admin/app";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import { logger } from "firebase-functions/v2";

initializeApp();

const INACTIVITY_DAYS = 30;
const RENOTIFY_COOLDOWN_DAYS = 30;
const DAY_MS = 24 * 60 * 60 * 1000;

// Relance les utilisateurs inactifs avec un message adapté à leur profil
// (vendeur ou acheteur habituel), une fois par jour.
export const relanceUtilisateursInactifs = onSchedule(
  { schedule: "every day 09:00", timeZone: "Africa/Bamako" },
  async () => {
    const db = getFirestore();
    const messaging = getMessaging();
    const now = Timestamp.now();
    const inactivityThreshold = Timestamp.fromMillis(
      now.toMillis() - INACTIVITY_DAYS * DAY_MS
    );
    const renotifyThreshold = now.toMillis() - RENOTIFY_COOLDOWN_DAYS * DAY_MS;

    const snap = await db
      .collection("users")
      .where("lastActivityAt", "<", inactivityThreshold)
      .get();

    let sent = 0;

    for (const doc of snap.docs) {
      const user = doc.data();
      const fcmToken = user.fcmToken as string | undefined;
      if (!fcmToken) continue;

      const totalSales = (user.totalSales as number | undefined) ?? 0;
      const totalPurchases = (user.totalPurchases as number | undefined) ?? 0;
      // Jamais vendu ni acheté : pas un utilisateur "de retour", pas concerné.
      if (totalSales === 0 && totalPurchases === 0) continue;

      const lastNotif = user.lastReactivationNotifAt as Timestamp | undefined;
      if (lastNotif && lastNotif.toMillis() > renotifyThreshold) continue;

      const isSellerProfile = totalSales >= totalPurchases;
      const title = isSellerProfile
        ? "Tes articles t'attendent"
        : "De nouvelles pépites sur DANAYA";
      const body = isSellerProfile
        ? "Ça fait un moment ! Remets tes articles en vente et retrouve tes acheteurs sur DANAYA."
        : "De nouveaux articles sont arrivés depuis ta dernière visite. Jette un œil !";

      try {
        await messaging.send({
          token: fcmToken,
          notification: { title, body },
          data: { type: "promotion" },
        });

        await doc.ref.update({ lastReactivationNotifAt: now });

        await db.collection("notification").add({
          userId: doc.id,
          title,
          body,
          type: "promotion",
          isRead: false,
          createdAt: now,
        });

        sent++;
      } catch (err) {
        logger.error(`[relance] échec envoi pour ${doc.id}`, err);
      }
    }

    logger.info(`[relance] ${sent} notification(s) envoyée(s) sur ${snap.size} utilisateur(s) inactif(s)`);
  }
);
