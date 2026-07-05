import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_radius.dart';

/// Bouton secondaire de l'application (OutlinedButton stylisé).
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final double height;
  final Color? borderColor;
  final Color? foregroundColor;

  const SecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = AppSizes.buttonHeight,
    this.borderColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = foregroundColor ?? AppColors.primary;
    final border = borderColor ?? AppColors.primary;

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: border, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.md),
        ),
        child: isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: color,
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: AppSizes.iconSm),
                    const SizedBox(width: 8),
                  ],
                  Text(label, style: AppTextStyles.button.copyWith(color: color)),
                ],
              ),
      ),
    );
  }
}
