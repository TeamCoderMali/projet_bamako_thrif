// ─── DANAYA — Notification : nouveau message ───────────────────────────────
// Se déclenche à l'écriture d'un message (chat_repository_impl.dart,
// sendMessage) et notifie l'autre participant de la conversation (jamais
// l'expéditeur lui-même).
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { getFirestore } from "firebase-admin/firestore";
import { sendPushAndStore } from "./sendPush";

function truncate(text: string, max: number): string {
  if (!text) return "";
  return text.length > max ? `${text.slice(0, max - 1)}…` : text;
}

export const onNewMessage = onDocumentCreated(
  "chat/{chatId}/message/{messageId}",
  async (event) => {
    const message = event.data?.data();
    if (!message) return;
    const { chatId } = event.params;

    const chatSnap = await getFirestore().doc(`chat/${chatId}`).get();
    const chat = chatSnap.data();
    if (!chat) return;

    const participantIds: string[] = chat.participantIds ?? [];
    const senderId: string | undefined = message.senderId;
    const recipientId = participantIds.find((id) => id !== senderId);
    if (!recipientId) return;

    const participantNames = (chat.participantNames ?? {}) as Record<
      string,
      string
    >;
    const senderName = participantNames[senderId ?? ""] ?? "Quelqu'un";

    // Bulle d'offre ("Offre : 5000 FCFA", voir make_offer_sheet.dart) déjà
    // courte et explicite -> affichée telle quelle, sans troncature.
    const body =
      message.type === "offer"
        ? (message.content as string)
        : truncate(message.content as string, 100);

    await sendPushAndStore({
      userId: recipientId,
      title: senderName,
      body,
      type: "newMessage",
      data: { chatId },
    });
  }
);
