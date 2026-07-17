import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:bamako_thrift/core/router/route_names.dart';
import 'package:bamako_thrift/features/notification/data/repositories/notification_repository_impl.dart';
import 'package:bamako_thrift/features/notification/domain/entities/notification_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:intl/intl.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late final NotificationRepositoryImpl _notifRepo;

  @override
  void initState() {
    super.initState();
    _notifRepo = NotificationRepositoryImpl(
      FirebaseFirestore.instance,
      FirebaseAuth.instance,
      FirebaseMessaging.instance,
    );
    // Marquer tout comme lu
    _notifRepo.markAllAsRead().catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.go(RouteNames.home),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () => _notifRepo.markAllAsRead(),
            child: const Text(
              'Tout lire',
              style: TextStyle(color: Color(0xFF6B7F4D)),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationEntity>>(
        stream: _notifRepo.watchNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF6B7F4D)),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Erreur: ${snapshot.error}',
                  style: const TextStyle(color: Colors.grey)),
            );
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none,
                      size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text(
                    'Aucune notification',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notif = notifications[index];
              return Dismissible(
                key: Key(notif.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade400,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child:
                      const Icon(Icons.delete_outline, color: Colors.white),
                ),
                onDismissed: (_) =>
                    _notifRepo.deleteNotification(notif.id),
                child: _NotifCard(
                  notification: notif,
                  onTap: () => _notifRepo.markAsRead(notif.id),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ── Carte notification ────────────────────────────────────────────────────────
class _NotifCard extends StatelessWidget {
  final NotificationEntity notification;
  final VoidCallback onTap;

  const _NotifCard({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _iconFor(notification.type);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: notification.isRead
              ? Colors.white
              : const Color(0xFF6B7F4D).withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: notification.isRead
              ? null
              : Border.all(
                  color: const Color(0xFF6B7F4D).withOpacity(0.2),
                ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icône
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontWeight: notification.isRead
                                ? FontWeight.normal
                                : FontWeight.bold,
                            fontSize: 13,
                            color: const Color(0xFF2B2B2B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _formatDate(notification.createdAt),
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 10),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style:
                        const TextStyle(color: Colors.grey, fontSize: 12, height: 1.4),
                  ),
                  if (!notification.isRead) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF6B7F4D),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  (IconData, Color) _iconFor(NotificationType type) {
    switch (type) {
      case NotificationType.newMessage:
        return (Icons.message, Colors.blue);
      case NotificationType.orderConfirmed:
        return (Icons.check_circle, Colors.green);
      case NotificationType.orderShipped:
        return (Icons.local_shipping_outlined, Colors.orange);
      case NotificationType.orderDelivered:
        return (Icons.inventory_2_outlined, Colors.green);
      case NotificationType.newOffer:
        return (Icons.sell_outlined, Colors.purple);
      case NotificationType.offerAccepted:
        return (Icons.handshake_outlined, Colors.green);
      case NotificationType.offerRejected:
        return (Icons.cancel_outlined, Colors.red);
      case NotificationType.productSold:
        return (Icons.celebration_outlined, const Color(0xFF6B7F4D));
      case NotificationType.newReview:
        return (Icons.star_outline, Colors.amber);
      case NotificationType.promotion:
        return (Icons.local_offer_outlined, Colors.orange);
      case NotificationType.system:
        return (Icons.info_outline, Colors.grey);
    }
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes}min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    if (diff.inDays == 1) return 'Hier';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays} jours';
    return DateFormat('dd/MM/yyyy').format(dt);
  }
}
