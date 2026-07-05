// ─── Bamako Thrift — Notification Entity (Domain Layer) ────────────────────
import 'package:equatable/equatable.dart';

class NotificationEntity extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final bool isRead;
  final Map<String, dynamic>? data;
  final DateTime createdAt;

  const NotificationEntity({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.isRead = false,
    this.data,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, userId, type, isRead, createdAt];
}

enum NotificationType {
  newMessage,
  orderConfirmed,
  orderShipped,
  orderDelivered,
  newOffer,
  offerAccepted,
  offerRejected,
  productSold,
  newReview,
  promotion,
  system,
}
