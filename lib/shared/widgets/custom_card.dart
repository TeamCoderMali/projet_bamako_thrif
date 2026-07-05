import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_duration.dart';

/// Carte générique réutilisable.
class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final BorderRadius? borderRadius;
  final double? elevation;
  final VoidCallback? onTap;
  final Border? border;
  final double? width;
  final double? height;

  const CustomCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.borderRadius,
    this.elevation,
    this.onTap,
    this.border,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? AppRadius.lg;

    final card = AnimatedContainer(
      duration: AppDuration.fast,
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color ?? AppColors.surface,
        borderRadius: radius,
        border: border,
        boxShadow: elevation != null && elevation! > 0
            ? [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: elevation! * 4,
                  offset: Offset(0, elevation!),
                )
              ]
            : null,
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(AppSizes.paddingMd),
        child: child,
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: card,
        ),
      );
    }

    return card;
  }
}
