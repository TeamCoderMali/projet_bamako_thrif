/// ─── Bamako Thrift — Styles typographiques ────────────────────────────────
import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract class AppTextStyles {
  AppTextStyles._();

  // ── Font families ──────────────────────────────────────────────────────
  static const String fontFamily = 'Inter';
  static const String fontFamilyDisplay = 'Inter';

  // ── Display ────────────────────────────────────────────────────────────
  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 48.0,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.5,
    height: 1.1,
    color: AppColors.onSurface,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 36.0,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.2,
    color: AppColors.onSurface,
  );

  static const TextStyle displaySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28.0,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.25,
    height: 1.2,
    color: AppColors.onSurface,
  );

  // ── Headline ───────────────────────────────────────────────────────────
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24.0,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    height: 1.3,
    color: AppColors.onSurface,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22.0,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.3,
    color: AppColors.onSurface,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18.0,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.3,
    color: AppColors.onSurface,
  );

  // ── Title ──────────────────────────────────────────────────────────────
  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16.0,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.15,
    height: 1.4,
    color: AppColors.onSurface,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14.0,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.4,
    color: AppColors.onSurface,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12.0,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.4,
    color: AppColors.onSurface,
  );

  // ── Body ───────────────────────────────────────────────────────────────
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16.0,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    height: 1.5,
    color: AppColors.onSurface,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14.0,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    height: 1.5,
    color: AppColors.onSurface,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12.0,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.5,
    color: AppColors.onSurface,
  );

  // ── Label ──────────────────────────────────────────────────────────────
  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14.0,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.4,
    color: AppColors.onSurface,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12.0,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.4,
    color: AppColors.onSurface,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10.0,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.4,
    color: AppColors.onSurface,
  );

  // ── Special ────────────────────────────────────────────────────────────
  static const TextStyle price = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18.0,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
    letterSpacing: -0.5,
  );

  static const TextStyle priceLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24.0,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
    letterSpacing: -0.5,
  );

  static const TextStyle badge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10.0,
    fontWeight: FontWeight.w700,
    color: AppColors.white,
    letterSpacing: 0.5,
  );

  static const TextStyle button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15.0,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    height: 1.0,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11.0,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    color: AppColors.onSurfaceVariant,
  );

  static const TextStyle overline = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10.0,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.5,
    color: AppColors.onSurfaceVariant,
  );

  static const TextStyle link = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14.0,
    fontWeight: FontWeight.w500,
    color: AppColors.primary,
    decoration: TextDecoration.underline,
    decorationColor: AppColors.primary,
  );
}
