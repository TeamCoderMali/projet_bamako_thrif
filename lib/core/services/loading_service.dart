/// ─── Bamako Thrift — Loading Service ──────────────────────────────────────
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_keys.dart';

class LoadingService {
  LoadingService._();
  static final LoadingService instance = LoadingService._();

  bool _isShowing = false;

  void show({String? message}) {
    final context = AppKeys.navigatorKey.currentContext;
    if (context == null || _isShowing) return;
    _isShowing = true;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: AppColors.overlay,
      builder: (_) => PopScope(
        canPop: false,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 3,
                ),
                if (message != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    message,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void hide() {
    if (!_isShowing) return;
    _isShowing = false;
    AppKeys.navigatorKey.currentState?.pop();
  }
}
