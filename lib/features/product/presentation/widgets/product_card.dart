import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/cached_image.dart';
import '../../domain/entities/product_entity.dart';

/// Carte produit réutilisable dans le catalogue, la recherche et l'accueil.
class ProductCard extends StatelessWidget {
  final ProductEntity product;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final bool isFavorited;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onFavorite,
    this.isFavorited = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.lg,
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image ────────────────────────────────────────────────
            Stack(
              children: [
                CachedImage(
                  imageUrl: product.mainImageUrl,
                  height: 160,
                  width: double.infinity,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppSizes.radiusLg),
                  ),
                ),
                // ── Condition badge ───────────────────────────────
                Positioned(
                  top: 8,
                  left: 8,
                  child: _ConditionBadge(condition: product.condition),
                ),
                // ── Favorite button ───────────────────────────────
                Positioned(
                  top: 4,
                  right: 4,
                  child: _FavoriteButton(
                    isFavorited: isFavorited,
                    onTap: onFavorite,
                  ),
                ),
              ],
            ),
            // ── Info ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    style: AppTextStyles.labelLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${product.price.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ' ')} FCFA',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (product.sellerName.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      product.sellerName,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
}

// ── Private widgets ─────────────────────────────────────────────────────────
class _ConditionBadge extends StatelessWidget {
  final ProductCondition condition;
  const _ConditionBadge({required this.condition});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _conditionColor.withValues(alpha: 0.9),
        borderRadius: AppRadius.sm,
      ),
      child: Text(
        _conditionLabel,
        style: AppTextStyles.labelSmall.copyWith(color: Colors.white),
      ),
    );
  }

  Color get _conditionColor {
    switch (condition) {
      case ProductCondition.newWithTags:
      case ProductCondition.newWithoutTags:
        return AppColors.success;
      case ProductCondition.veryGood:
        return AppColors.primary;
      case ProductCondition.good:
        return AppColors.secondary;
      case ProductCondition.fair:
        return AppColors.warning;
    }
  }

  String get _conditionLabel {
    switch (condition) {
      case ProductCondition.newWithTags:
        return 'Neuf';
      case ProductCondition.newWithoutTags:
        return 'Neuf';
      case ProductCondition.veryGood:
        return 'Très bon';
      case ProductCondition.good:
        return 'Bon';
      case ProductCondition.fair:
        return 'Correct';
    }
  }
}

class _FavoriteButton extends StatelessWidget {
  final bool isFavorited;
  final VoidCallback? onTap;
  const _FavoriteButton({required this.isFavorited, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.9),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isFavorited ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          color: isFavorited ? AppColors.error : AppColors.outline,
          size: 18,
        ),
      ),
    );
  }
}
