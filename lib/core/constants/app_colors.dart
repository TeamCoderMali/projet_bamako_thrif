import 'package:flutter/material.dart';

/// ─── Bamako Thrift — Palette de couleurs ───────────────────────────────────
/// Couleurs centralisées pour toute l'application.
abstract class AppColors {
  AppColors._();

  // ── Brand ──────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF1A7A5E);
  static const Color primaryLight = Color(0xFF4CAF85);
  static const Color primaryDark = Color(0xFF0D5C44);
  static const Color primaryContainer = Color(0xFFB2DFCC);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFF00382A);

  static const Color secondary = Color(0xFFF4A261);
  static const Color secondaryLight = Color(0xFFFFD3A3);
  static const Color secondaryDark = Color(0xFFBB7232);
  static const Color secondaryContainer = Color(0xFFFFDDB6);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSecondaryContainer = Color(0xFF2D1600);

  // ── Tertiary ───────────────────────────────────────────────────────────
  static const Color tertiary = Color(0xFF8B5E3C);
  static const Color tertiaryContainer = Color(0xFFFFDCC1);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color onTertiaryContainer = Color(0xFF311300);

  // ── Neutrals ───────────────────────────────────────────────────────────
  static const Color surface = Color(0xFFFAFAF8);
  static const Color surfaceVariant = Color(0xFFEFEFE7);
  static const Color onSurface = Color(0xFF1C1C1A);
  static const Color onSurfaceVariant = Color(0xFF45463F);
  static const Color outline = Color(0xFF75766D);
  static const Color outlineVariant = Color(0xFFC5C6BB);

  // ── Background ─────────────────────────────────────────────────────────
  static const Color background = Color(0xFFFAFAF8);
  static const Color onBackground = Color(0xFF1C1C1A);

  // ── Dark scheme ────────────────────────────────────────────────────────
  static const Color darkSurface = Color(0xFF121210);
  static const Color darkSurfaceVariant = Color(0xFF1E1E1C);
  static const Color darkBackground = Color(0xFF0F0F0E);
  static const Color darkOnSurface = Color(0xFFE4E4DC);
  static const Color darkOutline = Color(0xFF8F9088);
  static const Color darkOutlineVariant = Color(0xFF45463F);
  static const Color darkPrimary = Color(0xFF52C99E);
  static const Color darkPrimaryContainer = Color(0xFF00513D);
  static const Color darkOnPrimary = Color(0xFF00382A);

  // ── Semantic ───────────────────────────────────────────────────────────
  static const Color success = Color(0xFF2E7D32);
  static const Color successContainer = Color(0xFFA5D6A7);
  static const Color error = Color(0xFFD32F2F);
  static const Color errorContainer = Color(0xFFFFCDD2);
  static const Color warning = Color(0xFFF57F17);
  static const Color warningContainer = Color(0xFFFFF9C4);
  static const Color info = Color(0xFF0277BD);
  static const Color infoContainer = Color(0xFFB3E5FC);

  // ── Misc ───────────────────────────────────────────────────────────────
  static const Color divider = Color(0xFFE0E0D8);
  static const Color shadow = Color(0x1A000000);
  static const Color overlay = Color(0x80000000);
  static const Color transparent = Colors.transparent;
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color shimmerBase = Color(0xFFEEEEEE);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);
  static const Color badge = Color(0xFFE53935);
}
