/// ─── Bamako Thrift — Snackbar Service ─────────────────────────────────────
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_keys.dart';
import '../constants/app_radius.dart';
import '../constants/app_text_styles.dart';

enum SnackBarType { success, error, warning, info }

class SnackBarService {
  SnackBarService._();

  static final SnackBarService instance = SnackBarService._();

  void show({
    required String message,
    SnackBarType type = SnackBarType.info,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final messengerState = AppKeys.scaffoldMessengerKey.currentState;
    if (messengerState == null) return;

    messengerState.hideCurrentSnackBar();
    messengerState.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(_iconFor(type), color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white),
              ),
            ),
          ],
        ),
        backgroundColor: _colorFor(type),
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.md),
        margin: const EdgeInsets.all(16),
        action: actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: Colors.white,
                onPressed: onAction ?? () {},
              )
            : null,
      ),
    );
  }

  void showSuccess(String message) =>
      show(message: message, type: SnackBarType.success);

  void showError(String message) =>
      show(message: message, type: SnackBarType.error);

  void showWarning(String message) =>
      show(message: message, type: SnackBarType.warning);

  void showInfo(String message) =>
      show(message: message, type: SnackBarType.info);

  Color _colorFor(SnackBarType type) {
    switch (type) {
      case SnackBarType.success:
        return AppColors.success;
      case SnackBarType.error:
        return AppColors.error;
      case SnackBarType.warning:
        return AppColors.warning;
      case SnackBarType.info:
        return AppColors.info;
    }
  }

  IconData _iconFor(SnackBarType type) {
    switch (type) {
      case SnackBarType.success:
        return Icons.check_circle_outline_rounded;
      case SnackBarType.error:
        return Icons.error_outline_rounded;
      case SnackBarType.warning:
        return Icons.warning_amber_rounded;
      case SnackBarType.info:
        return Icons.info_outline_rounded;
    }
  }
}
