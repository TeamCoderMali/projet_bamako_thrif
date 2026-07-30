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

  // ── Ouvre la fiche de validation remise en état (montant + 24h) ──────────
  void _openRepairValidation(NotificationEntity notif) {
    final ncId = notif.data?['nonConformityId'] as String?;
    if (ncId == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _RepairValidationSheet(nonConformityId: ncId),
    );
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
                  child: const Icon(Icons.delete_outline, color: Colors.white),
                ),
                onDismissed: (_) => _notifRepo.deleteNotification(notif.id),
                child: _NotifCard(
                  notification: notif,
                  onTap: () {
                    _notifRepo.markAsRead(notif.id);
                    if (notif.type == NotificationType.repairValidation) {
                      _openRepairValidation(notif);
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ── Fiche "Validation remise en état" (montant + 24h + Accepter) ───────────
class _RepairValidationSheet extends StatelessWidget {
  final String nonConformityId;
  const _RepairValidationSheet({required this.nonConformityId});

  String _fmt(dynamic amount) {
    final v = (amount is num) ? amount.toDouble() : 0.0;
    return '${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ' ')} FCFA';
  }

  Future<void> _accept(BuildContext context) async {
    await FirebaseFirestore.instance
        .collection('non_conformities')
        .doc(nonConformityId)
        .update({
      'status': 'seller_accepted',
      'sellerAcceptedAt': FieldValue.serverTimestamp(),
    });
    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Montant accepté. L\'équipe procède à la remise en état.'),
          backgroundColor: Color(0xFF6B7F4D),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('non_conformities')
          .doc(nonConformityId)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || !snap.data!.exists) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(
                child: CircularProgressIndicator(color: Color(0xFF6B7F4D))),
          );
        }

        final data = snap.data!.data() as Map<String, dynamic>;
        final status = data['status'] as String? ?? '';
        final repairCost = data['repairCost'];
        final productTitle = data['productTitle'] as String? ?? 'Article';
        final deadline = (data['sellerDeadline'] as Timestamp?)?.toDate();
        final alreadyAccepted = status == 'seller_accepted';
        final expired = deadline != null &&
            DateTime.now().isAfter(deadline) &&
            !alreadyAccepted;

        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'Remise en état',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(productTitle,
                  style: const TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F4EE),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    const Text('Montant à votre charge',
                        style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 6),
                    Text(
                      _fmt(repairCost),
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6B7F4D),
                      ),
                    ),
                    if (deadline != null && !alreadyAccepted) ...[
                      const SizedBox(height: 6),
                      Text(
                        expired
                            ? 'Délai expiré'
                            : 'À accepter avant le ${DateFormat('dd/MM à HH:mm').format(deadline)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: expired ? Colors.red : Colors.grey,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (alreadyAccepted)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Text('✓ Déjà accepté',
                        style: TextStyle(
                            color: Colors.green, fontWeight: FontWeight.bold)),
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => _accept(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6B7F4D),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Accepter',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
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
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 12, height: 1.4),
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
      case NotificationType.repairValidation:
        return (Icons.build_outlined, Colors.deepOrange);
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
