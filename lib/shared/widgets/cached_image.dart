import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
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
      return _buildError(context, radius);
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
              color: backgroundColor ??
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              child: const Center(child: LoadingIndicator(size: 24)),
            ),
        errorWidget: (context, url, error) => _buildError(context, radius),
      ),
    );
  }

  Widget _buildError(BuildContext context, BorderRadius radius) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: radius,
      ),
      child: errorWidget ??
          Center(
            child: Icon(
              Icons.image_not_supported_outlined,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              size: 32,
            ),
          ),
    );
  }
}
