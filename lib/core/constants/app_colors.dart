import 'package:flutter/material.dart';

/// ─── DANAYA — Palette de couleurs officielle ───────────────────────────────
abstract class AppColors {
  AppColors._();

  // ── Brand Principal ────────────────────────────────────────────────────
  static const Color primary = Color(0xFF6B7F4D); // Vert Olive
  static const Color primaryLight = Color(0xFF8FAF7A); // Vert Olive clair
  static const Color primaryDark = Color(0xFF4A5C32); // Vert Olive foncé
  static const Color primaryContainer = Color(0xFFD4E4B8); // Vert très clair
  static const Color onPrimary = Color(0xFFFFFFFF);

  // ── Accent Terracotta ──────────────────────────────────────────────────
  static const Color secondary = Color(0xFFC3653D); // Terracotta
  static const Color secondaryLight = Color(0xFFE08A5E); // Terracotta clair
  static const Color secondaryDark = Color(0xFF8F3F1E); // Terracotta foncé
  static const Color secondaryContainer = Color(0xFFFFDCC8);
  static const Color onSecondary = Color(0xFFFFFFFF);

  // ── Doré Doux ──────────────────────────────────────────────────────────
  static const Color tertiary = Color(0xFFD4AF37); // Doré Doux
  static const Color tertiaryContainer = Color(0xFFFFF3C0);
  static const Color onTertiary = Color(0xFFFFFFFF);

  // ── Fond & Surfaces ────────────────────────────────────────────────────
  static const Color background = Color(0xFFF7F4EE); // Beige Clair
  static const Color surface = Color(0xFFF7F4EE); // Beige Clair
  static const Color surfaceVariant = Color(0xFFEDE8DF); // Beige foncé
  static const Color onBackground = Color(0xFF2B2B2B); // Anthracite
  static const Color onSurface = Color(0xFF2B2B2B); // Anthracite

  // ── Textes ─────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF2B2B2B); // Anthracite
  static const Color textSecondary = Color(0xFF6E6E6E); // Gris moyen
  static const Color textHint = Color(0xFFBDBDBD); // Gris clair

  // ── Neutres ────────────────────────────────────────────────────────────
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color greyLight = Color(0xFFF1F1F1);
  static const Color greyMedium = Color(0xFFBDBDBD);
  static const Color greyDark = Color(0xFF6E6E6E);
  static const Color outline = Color(0xFFE6E6E6);
  static const Color divider = Color(0xFFE6E6E6);

  // ── Sémantiques ────────────────────────────────────────────────────────
  static const Color success = Color(0xFF2E7D32);
  static const Color successContainer = Color(0xFFA5D6A7);
  static const Color error = Color(0xFFD32F2F);
  static const Color errorContainer = Color(0xFFFFCDD2);
  static const Color warning = Color(0xFFF57F17);
  static const Color warningContainer = Color(0xFFFFF9C4);
  static const Color info = Color(0xFF0277BD);
  static const Color infoContainer = Color(0xFFB3E5FC);

  // ── Gradients ──────────────────────────────────────────────────────────
  static const List<Color> primaryGradient = [
    Color(0xFF6B7F4D),
    Color(0xFF8FAF7A),
  ];
  static const List<Color> accentGradient = [
    Color(0xFFC3653D),
    Color(0xFFE08A5E),
  ];

  // ── Misc ───────────────────────────────────────────────────────────────
  static const Color shadow = Color(0x1A000000);
  static const Color overlay = Color(0x80000000);
  static const Color transparent = Colors.transparent;
  static const Color shimmerBase = Color(0xFFEEEEEE);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);
  static const Color badge = Color(0xFFE53935);
}
