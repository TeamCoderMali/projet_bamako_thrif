import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import 'loading_indicator.dart';

/// Image réseau avec cache, placeholder et gestion d'erreur.
class CachedImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Color? backgroundColor;

  const CachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? AppRadius.md;
    final url = imageUrl;

    if (url == null || url.isEmpty) {
      return _buildError(radius);
    }

    return ClipRRect(
      borderRadius: radius,
      child: CachedNetworkImage(
        imageUrl: url,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) =>
            placeholder ??
            Container(
              width: width,
              height: height,
              color: backgroundColor ?? AppColors.shimmerBase,
              child: const Center(child: LoadingIndicator(size: 24)),
            ),
        errorWidget: (context, url, error) => _buildError(radius),
      ),
    );
  }

  Widget _buildError(BorderRadius radius) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: radius,
      ),
      child: errorWidget ??
          const Center(
            child: Icon(
              Icons.image_not_supported_outlined,
              color: AppColors.outline,
              size: 32,
            ),
          ),
    );
  }
}
