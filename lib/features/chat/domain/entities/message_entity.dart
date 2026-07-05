// ─── Bamako Thrift — Message Entity (Domain Layer) ─────────────────────────
import 'package:equatable/equatable.dart';

class MessageEntity extends Equatable {
  final String id;
  final String chatId;
  final String senderId;
  final String content;
  final MessageType type;
  final bool isRead;
  final DateTime createdAt;
  final String? mediaUrl;

  const MessageEntity({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.content,
    this.type = MessageType.text,
    this.isRead = false,
    required this.createdAt,
    this.mediaUrl,
  });

  @override
  List<Object?> get props => [id, chatId, senderId, content, type, createdAt];
}

class ChatEntity extends Equatable {
  final String id;
  final List<String> participantIds;
  final Map<String, String> participantNames;
  final Map<String, String?> participantAvatars;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final String? productId;
  final String? productTitle;
  final String? productImageUrl;
  final Map<String, int> unreadCount;

  const ChatEntity({
    required this.id,
    required this.participantIds,
    required this.participantNames,
    required this.participantAvatars,
    this.lastMessage,
    this.lastMessageAt,
    this.productId,
    this.productTitle,
    this.productImageUrl,
    this.unreadCount = const {},
  });

  @override
  List<Object?> get props => [id, participantIds, lastMessageAt];
}

enum MessageType { text, image, offer, system }
