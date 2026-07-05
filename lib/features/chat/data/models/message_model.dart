// ─── Bamako Thrift — Message Model (Data Layer) ────────────────────────────
import '../../domain/entities/message_entity.dart';

class MessageModel extends MessageEntity {
  const MessageModel({
    required super.id,
    required super.chatId,
    required super.senderId,
    required super.content,
    super.type,
    super.isRead,
    required super.createdAt,
    super.mediaUrl,
  });

  factory MessageModel.fromFirestore(Map<String, dynamic> data, String id) {
    return MessageModel(
      id: id,
      chatId: data['chatId'] as String,
      senderId: data['senderId'] as String,
      content: data['content'] as String,
      type: _parseType(data['type'] as String?),
      isRead: data['isRead'] as bool? ?? false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        data['createdAt'] as int? ?? 0,
      ),
      mediaUrl: data['mediaUrl'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'chatId': chatId,
        'senderId': senderId,
        'content': content,
        'type': type.name,
        'isRead': isRead,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'mediaUrl': mediaUrl,
      };

  static MessageType _parseType(String? value) => MessageType.values
      .firstWhere((e) => e.name == value, orElse: () => MessageType.text);
}

class ChatModel extends ChatEntity {
  const ChatModel({
    required super.id,
    required super.participantIds,
    required super.participantNames,
    required super.participantAvatars,
    super.lastMessage,
    super.lastMessageAt,
    super.productId,
    super.productTitle,
    super.productImageUrl,
    super.unreadCount,
  });

  factory ChatModel.fromFirestore(Map<String, dynamic> data, String id) {
    return ChatModel(
      id: id,
      participantIds: List<String>.from(data['participantIds'] as List? ?? []),
      participantNames: Map<String, String>.from(
        data['participantNames'] as Map? ?? {},
      ),
      participantAvatars: Map<String, String?>.from(
        data['participantAvatars'] as Map? ?? {},
      ),
      lastMessage: data['lastMessage'] as String?,
      lastMessageAt: data['lastMessageAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['lastMessageAt'] as int)
          : null,
      productId: data['productId'] as String?,
      productTitle: data['productTitle'] as String?,
      productImageUrl: data['productImageUrl'] as String?,
      unreadCount: Map<String, int>.from(data['unreadCount'] as Map? ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'participantIds': participantIds,
        'participantNames': participantNames,
        'participantAvatars': participantAvatars,
        'lastMessage': lastMessage,
        'lastMessageAt': lastMessageAt?.millisecondsSinceEpoch,
        'productId': productId,
        'productTitle': productTitle,
        'productImageUrl': productImageUrl,
        'unreadCount': unreadCount,
      };
}
