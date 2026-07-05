// ─── Bamako Thrift — Chat Repository (Domain Contract) ─────────────────────
import '../entities/message_entity.dart';

abstract class ChatRepository {
  Future<List<ChatEntity>> getMyChats();
  Future<ChatEntity> getChatById(String chatId);
  Future<ChatEntity> createOrGetChat({
    required String otherUserId,
    String? productId,
  });
  Future<MessageEntity> sendMessage({
    required String chatId,
    required String content,
    MessageType type = MessageType.text,
    String? mediaUrl,
  });
  Future<void> markAsRead(String chatId);
  Stream<List<MessageEntity>> watchMessages(String chatId);
  Stream<List<ChatEntity>> watchChats();
  Future<void> deleteChat(String chatId);
}
