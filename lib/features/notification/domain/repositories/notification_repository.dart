// ─── Bamako Thrift — Notification Repository (Domain Contract) ─────────────
import '../entities/notification_entity.dart';

abstract class NotificationRepository {
  Future<List<NotificationEntity>> getNotifications({int page = 0});
  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead();
  Future<void> deleteNotification(String notificationId);
  Future<void> clearAll();
  Stream<List<NotificationEntity>> watchNotifications();
  Future<int> getUnreadCount();
  Future<String?> getFcmToken();
  Future<void> updateFcmToken(String token);
}
