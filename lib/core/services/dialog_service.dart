/// ─── Bamako Thrift — Dialog Service ───────────────────────────────────────
import 'package:flutter/material.dart';
import '../constants/app_keys.dart';
import '../constants/app_strings.dart';
import '../constants/app_radius.dart';
import '../constants/app_text_styles.dart';

class DialogService {
  DialogService._();
  static final DialogService instance = DialogService._();

  BuildContext? get _context =>
      AppKeys.navigatorKey.currentContext;

  /// Dialog de confirmation simple (Oui/Non).
  Future<bool?> showConfirmation({
    required String title,
    required String message,
    String? confirmLabel,
    String? cancelLabel,
    bool isDanger = false,
  }) async {
    final context = _context;
    if (context == null) return null;

    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xl),
        title: Text(title, style: AppTextStyles.headlineSmall),
        content: Text(message, style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(cancelLabel ?? AppStrings.cancel),
          ),
          ElevatedButton(
            style: isDanger
                ? ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  )
                : null,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(confirmLabel ?? AppStrings.confirm),
          ),
        ],
      ),
    );
  }

  /// Dialog d'information simple.
  Future<void> showInfo({
    required String title,
    required String message,
    String? closeLabel,
  }) async {
    final context = _context;
    if (context == null) return;

    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xl),
        title: Text(title, style: AppTextStyles.headlineSmall),
        content: Text(message, style: AppTextStyles.bodyMedium),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(closeLabel ?? AppStrings.ok),
          ),
        ],
      ),
    );
  }

  /// Bottom sheet générique.
  Future<T?> showBottomSheet<T>({
    required BuildContext context,
    required Widget child,
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.0),
          topRight: Radius.circular(24.0),
        ),
      ),
      builder: (_) => child,
    );
  }
}
