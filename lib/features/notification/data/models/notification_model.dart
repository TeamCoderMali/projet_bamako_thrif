// ─── Bamako Thrift — Notification Model (Data Layer) ───────────────────────
import '../../domain/entities/notification_entity.dart';

class NotificationModel extends NotificationEntity {
  const NotificationModel({
    required super.id,
    required super.userId,
    required super.title,
    required super.body,
    required super.type,
    super.isRead,
    super.data,
    required super.createdAt,
  });

  factory NotificationModel.fromFirestore(
    Map<String, dynamic> data,
    String id,
  ) {
    return NotificationModel(
      id: id,
      userId: data['userId'] as String,
      title: data['title'] as String,
      body: data['body'] as String,
      type: _parseType(data['type'] as String?),
      isRead: data['isRead'] as bool? ?? false,
      data: data['data'] as Map<String, dynamic>?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        data['createdAt'] as int? ?? 0,
      ),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'title': title,
        'body': body,
        'type': type.name,
        'isRead': isRead,
        'data': data,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  static NotificationType _parseType(String? value) =>
      NotificationType.values.firstWhere(
        (e) => e.name == value,
        orElse: () => NotificationType.system,
      );
}
