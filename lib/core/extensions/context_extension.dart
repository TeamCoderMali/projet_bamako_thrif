/// ─── Bamako Thrift — Context Extensions ────────────────────────────────────
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

extension ContextExtension on BuildContext {
  // ── Theme ─────────────────────────────────────────────────────────────
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  // ── MediaQuery ────────────────────────────────────────────────────────
  Size get screenSize => MediaQuery.sizeOf(this);
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;
  EdgeInsets get safePadding => MediaQuery.paddingOf(this);
  double get topPadding => MediaQuery.paddingOf(this).top;
  double get bottomPadding => MediaQuery.paddingOf(this).bottom;
  double get keyboardHeight => MediaQuery.viewInsetsOf(this).bottom;
  bool get isKeyboardOpen => MediaQuery.viewInsetsOf(this).bottom > 0;

  // ── Responsive ────────────────────────────────────────────────────────
  bool get isSmallScreen => screenWidth < 360;
  bool get isMediumScreen => screenWidth >= 360 && screenWidth < 600;
  bool get isLargeScreen => screenWidth >= 600;
  bool get isTablet => screenWidth >= 600;

  // ── Colors (quick access) ─────────────────────────────────────────────
  Color get primaryColor => AppColors.primary;
  Color get surfaceColor => colorScheme.surface;
  Color get onSurfaceColor => colorScheme.onSurface;

  // ── Navigation ────────────────────────────────────────────────────────
  void pop<T>([T? result]) => Navigator.of(this).pop(result);
  bool canPop() => Navigator.of(this).canPop();

  // ── Snackbar ──────────────────────────────────────────────────────────
  void showSnackBar(String message, {Color? backgroundColor}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ── Focus ─────────────────────────────────────────────────────────────
  void hideKeyboard() => FocusScope.of(this).unfocus();
}
