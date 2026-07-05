/// ─── Bamako Thrift — Thème sombre ─────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_radius.dart';

ThemeData buildDarkTheme() {
  final colorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.darkPrimary,
    onPrimary: AppColors.darkOnPrimary,
    primaryContainer: AppColors.darkPrimaryContainer,
    onPrimaryContainer: AppColors.darkPrimary,
    secondary: AppColors.secondaryLight,
    onSecondary: AppColors.onSecondaryContainer,
    secondaryContainer: AppColors.secondaryDark,
    onSecondaryContainer: AppColors.secondaryLight,
    tertiary: AppColors.tertiaryContainer,
    onTertiary: AppColors.onTertiaryContainer,
    tertiaryContainer: AppColors.tertiary,
    onTertiaryContainer: AppColors.tertiaryContainer,
    error: const Color(0xFFFF6B6B),
    onError: AppColors.black,
    errorContainer: const Color(0xFF93000A),
    onErrorContainer: const Color(0xFFFFDAD6),
    surface: AppColors.darkSurface,
    onSurface: AppColors.darkOnSurface,
    surfaceContainerHighest: AppColors.darkSurfaceVariant,
    onSurfaceVariant: AppColors.darkOutline,
    outline: AppColors.darkOutline,
    outlineVariant: AppColors.darkOutlineVariant,
    shadow: AppColors.shadow,
    scrim: AppColors.overlay,
    inverseSurface: AppColors.darkOnSurface,
    onInverseSurface: AppColors.darkSurface,
    inversePrimary: AppColors.primary,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    fontFamily: AppTextStyles.fontFamily,

    // ── AppBar ──────────────────────────────────────────────────────────
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.darkSurface,
      foregroundColor: AppColors.darkOnSurface,
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: true,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      iconTheme: IconThemeData(color: AppColors.darkOnSurface),
    ),

    // ── Scaffold ────────────────────────────────────────────────────────
    scaffoldBackgroundColor: AppColors.darkBackground,

    // ── Card ────────────────────────────────────────────────────────────
    cardTheme: CardTheme(
      elevation: 0,
      color: AppColors.darkSurfaceVariant,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.lg),
      margin: const EdgeInsets.all(0),
      clipBehavior: Clip.antiAlias,
    ),

    // ── ElevatedButton ──────────────────────────────────────────────────
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.darkPrimary,
        foregroundColor: AppColors.darkOnPrimary,
        minimumSize: const Size(double.infinity, AppSizes.buttonHeight),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.md),
        textStyle: AppTextStyles.button,
        elevation: 0,
      ),
    ),

    // ── OutlinedButton ──────────────────────────────────────────────────
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.darkPrimary,
        minimumSize: const Size(double.infinity, AppSizes.buttonHeight),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.md),
        side: const BorderSide(color: AppColors.darkPrimary, width: 1.5),
        textStyle: AppTextStyles.button,
      ),
    ),

    // ── TextButton ──────────────────────────────────────────────────────
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.darkPrimary,
        textStyle: AppTextStyles.button,
      ),
    ),

    // ── InputDecoration ─────────────────────────────────────────────────
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkSurfaceVariant,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      border: OutlineInputBorder(
        borderRadius: AppRadius.md,
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.md,
        borderSide: const BorderSide(color: AppColors.darkOutlineVariant, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.md,
        borderSide: const BorderSide(color: AppColors.darkPrimary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppRadius.md,
        borderSide: const BorderSide(color: Color(0xFFFF6B6B), width: 1),
      ),
      hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.darkOutline),
    ),

    // ── NavigationBar ───────────────────────────────────────────────────
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.darkSurfaceVariant,
      indicatorColor: AppColors.darkPrimaryContainer,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: AppColors.darkPrimary);
        }
        return const IconThemeData(color: AppColors.darkOutline);
      }),
    ),

    // ── Divider ─────────────────────────────────────────────────────────
    dividerTheme: const DividerThemeData(
      color: AppColors.darkOutlineVariant,
      thickness: 1,
      space: 1,
    ),

    // ── SnackBar ────────────────────────────────────────────────────────
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.darkOnSurface,
      contentTextStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.darkSurface),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.md),
      behavior: SnackBarBehavior.floating,
    ),

    // ── BottomSheet ─────────────────────────────────────────────────────
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.darkSurfaceVariant,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.0),
          topRight: Radius.circular(24.0),
        ),
      ),
    ),

    // ── Dialog ──────────────────────────────────────────────────────────
    dialogTheme: DialogTheme(
      backgroundColor: AppColors.darkSurfaceVariant,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.xl),
    ),

    // ── TextTheme ───────────────────────────────────────────────────────
    textTheme: TextTheme(
      displayLarge: AppTextStyles.displayLarge.copyWith(color: AppColors.darkOnSurface),
      displayMedium: AppTextStyles.displayMedium.copyWith(color: AppColors.darkOnSurface),
      displaySmall: AppTextStyles.displaySmall.copyWith(color: AppColors.darkOnSurface),
      headlineLarge: AppTextStyles.headlineLarge.copyWith(color: AppColors.darkOnSurface),
      headlineMedium: AppTextStyles.headlineMedium.copyWith(color: AppColors.darkOnSurface),
      headlineSmall: AppTextStyles.headlineSmall.copyWith(color: AppColors.darkOnSurface),
      titleLarge: AppTextStyles.titleLarge.copyWith(color: AppColors.darkOnSurface),
      titleMedium: AppTextStyles.titleMedium.copyWith(color: AppColors.darkOnSurface),
      titleSmall: AppTextStyles.titleSmall.copyWith(color: AppColors.darkOnSurface),
      bodyLarge: AppTextStyles.bodyLarge.copyWith(color: AppColors.darkOnSurface),
      bodyMedium: AppTextStyles.bodyMedium.copyWith(color: AppColors.darkOnSurface),
      bodySmall: AppTextStyles.bodySmall.copyWith(color: AppColors.darkOutline),
      labelLarge: AppTextStyles.labelLarge.copyWith(color: AppColors.darkOnSurface),
      labelMedium: AppTextStyles.labelMedium.copyWith(color: AppColors.darkOutline),
      labelSmall: AppTextStyles.labelSmall.copyWith(color: AppColors.darkOutline),
    ),
  );
}
