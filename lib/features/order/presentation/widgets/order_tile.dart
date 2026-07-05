import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/cached_image.dart';
import '../../../order/domain/entities/order_entity.dart';

/// Tuile de commande dans la liste des commandes.
class OrderTile extends StatelessWidget {
  final OrderEntity order;
  final VoidCallback? onTap;

  const OrderTile({
    super.key,
    required this.order,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.lg,
      child: Container(
        padding: const EdgeInsets.all(AppSizes.paddingMd),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.lg,
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            // ── Product image ───────────────────────────────────────
            CachedImage(
              imageUrl: order.productImageUrl,
              width: 72,
              height: 72,
              borderRadius: AppRadius.md,
            ),
            const SizedBox(width: 12),
            // ── Info ───────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.productTitle,
                    style: AppTextStyles.labelLarge,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${order.amount.toStringAsFixed(0)} FCFA',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _StatusChip(status: order.status),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.outline,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final OrderStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _statusColor.withValues(alpha: 0.12),
        borderRadius: AppRadius.sm,
        border: Border.all(color: _statusColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        _statusLabel,
        style: AppTextStyles.labelSmall.copyWith(color: _statusColor),
      ),
    );
  }

  Color get _statusColor {
    switch (status) {
      case OrderStatus.pending:
        return AppColors.warning;
      case OrderStatus.confirmed:
      case OrderStatus.processing:
        return AppColors.primary;
      case OrderStatus.shipped:
        return AppColors.secondary;
      case OrderStatus.delivered:
        return AppColors.success;
      case OrderStatus.cancelled:
      case OrderStatus.refunded:
      case OrderStatus.disputed:
        return AppColors.error;
    }
  }

  String get _statusLabel {
    switch (status) {
      case OrderStatus.pending:
        return 'En attente';
      case OrderStatus.confirmed:
        return 'Confirmé';
      case OrderStatus.processing:
        return 'En préparation';
      case OrderStatus.shipped:
        return 'Expédié';
      case OrderStatus.delivered:
        return 'Livré';
      case OrderStatus.cancelled:
        return 'Annulé';
      case OrderStatus.refunded:
        return 'Remboursé';
      case OrderStatus.disputed:
        return 'Litige';
    }
  }
}
