import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_duration.dart';

/// Bouton principal de l'application (ElevatedButton stylisé).
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDisabled;
  final IconData? icon;
  final double? width;
  final double height;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.icon,
    this.width,
    this.height = AppSizes.buttonHeight,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = !isLoading && !isDisabled && onPressed != null;

    return AnimatedOpacity(
      opacity: isActive ? 1.0 : 0.6,
      duration: AppDuration.fast,
      child: SizedBox(
        width: width ?? double.infinity,
        height: height,
        child: ElevatedButton(
          onPressed: isActive ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.md),
            elevation: 0,
          ),
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: AppColors.onPrimary,
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
                    Text(label, style: AppTextStyles.button),
                  ],
                ),
        ),
      ),
    );
  }
}
