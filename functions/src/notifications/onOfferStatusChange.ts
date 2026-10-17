// ─── DANAYA — Notification : offre acceptée ou refusée ─────────────────────
// Notifie la partie qui N'A PAS agi (celle qui reçoit la décision de
// l'autre) : si history[last].by == "buyer" (l'acheteur vient d'accepter
// ou de refuser la dernière contre-offre du vendeur), on notifie le
// vendeur, et inversement. Voir OfferHistoryEntry côté app
// (offer_model.dart) pour le format de l'historique.
import { onDocumentUpdated } from "firebase-functions/v2/firestore";
import { sendPushAndStore } from "./sendPush";

export const onOfferStatusChange = onDocumentUpdated(
  "offers/{offerId}",
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;
    const { offerId } = event.params;

    if (before.status === after.status) return;
    if (after.status !== "accepted" && after.status !== "rejected") return;

    const history = (after.history ?? []) as Array<{ by?: string }>;
    const lastEntry = history[history.length - 1];
    const actorRole = lastEntry?.by; // "buyer" | "seller"
    if (actorRole !== "buyer" && actorRole !== "seller") return;

    const recipientId = actorRole === "buyer" ? after.sellerId : after.buyerId;
    if (!recipientId) return;

    const accepted = after.status === "accepted";
    await sendPushAndStore({
      userId: recipientId,
      title: accepted ? "Offre acceptée !" : "Offre refusée",
      body: `Ton offre de ${after.currentPrice} FCFA pour "${after.productTitle}" a été ${
        accepted ? "acceptée" : "refusée"
      }.`,
      type: accepted ? "offerAccepted" : "offerRejected",
      data: { chatId: after.chatId ?? "", offerId },
    });
  }
);
