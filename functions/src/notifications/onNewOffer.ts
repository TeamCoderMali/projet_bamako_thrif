// ─── DANAYA — Notification : nouvelle offre ────────────────────────────────
// L'ID d'une offre est déterministe ({productId}_{buyerId}, voir
// OfferModel.buildId) : une relance après refus/expiration/annulation
// réutilise le même document via UPDATE, pas CREATE. onDocumentCreated ne
// se déclenche donc que pour la toute première offre d'un acheteur sur un
// article donné — exactement le cas "nouvelle offre" demandé, sans notifier
// à nouveau sur une simple relance (non demandé ici, à ajouter séparément
// via onOfferStatusChange si besoin un jour).
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { getFirestore } from "firebase-admin/firestore";
import { sendPushAndStore } from "./sendPush";

export const onNewOffer = onDocumentCreated(
  "offers/{offerId}",
  async (event) => {
    const offer = event.data?.data();
    if (!offer) return;
    const { offerId } = event.params;

    // offers ne stocke pas le nom de l'acheteur (seulement buyerId) —
    // une lecture supplémentaire, acceptable (peu fréquent, pas de boucle).
    const buyerSnap = await getFirestore().doc(`users/${offer.buyerId}`).get();
    const buyerName = buyerSnap.data()?.fullName ?? "Un acheteur";

    await sendPushAndStore({
      userId: offer.sellerId,
      title: "Nouvelle offre",
      body: `${buyerName} propose ${offer.currentPrice} FCFA pour "${offer.productTitle}"`,
      type: "newOffer",
      data: { chatId: offer.chatId ?? "", offerId },
    });
  }
);
