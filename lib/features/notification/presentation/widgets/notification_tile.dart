import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../domain/entities/notification_entity.dart';

/// Tuile de notification dans la liste des notifications.
class NotificationTile extends StatelessWidget {
  final NotificationEntity notification;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const NotificationTile({
    super.key,
    required this.notification,
    this.onTap,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss?.call(),
      background: Container(
        color: AppColors.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      child: InkWell(
        onTap: onTap,
        child: Container(
          color: notification.isRead
              ? Colors.transparent
              : AppColors.primaryContainer.withValues(alpha: 0.3),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Icon ──────────────────────────────────────────
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _iconColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(_notifIcon, color: _iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              // ── Content ───────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: notification.isRead
                          ? AppTextStyles.bodyMedium
                          : AppTextStyles.labelLarge,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      notification.body,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(notification.createdAt),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.outline,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (!notification.isRead)
                const SizedBox(
                  width: 8,
                  height: 8,
                  child: CircleAvatar(
                    backgroundColor: AppColors.primary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color get _iconColor {
    switch (notification.type) {
      case NotificationType.newMessage:
        return AppColors.primary;
      case NotificationType.orderConfirmed:
      case NotificationType.orderShipped:
      case NotificationType.orderDelivered:
        return AppColors.success;
      case NotificationType.productSold:
        return AppColors.secondary;
      case NotificationType.newOffer:
      case NotificationType.offerAccepted:
        return AppColors.warning;
      case NotificationType.offerRejected:
        return AppColors.error;
      default:
        return AppColors.outline;
    }
  }

  IconData get _notifIcon {
    switch (notification.type) {
      case NotificationType.newMessage:
        return Icons.chat_bubble_outline_rounded;
      case NotificationType.orderConfirmed:
        return Icons.check_circle_outline_rounded;
      case NotificationType.orderShipped:
        return Icons.local_shipping_outlined;
      case NotificationType.orderDelivered:
        return Icons.done_all_rounded;
      case NotificationType.productSold:
        return Icons.sell_outlined;
      case NotificationType.newOffer:
      case NotificationType.offerAccepted:
      case NotificationType.offerRejected:
        return Icons.local_offer_outlined;
      case NotificationType.newReview:
        return Icons.star_outline_rounded;
      case NotificationType.promotion:
        return Icons.campaign_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    if (diff.inDays == 1) return 'Hier';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
