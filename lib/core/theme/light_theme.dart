/// ─── Bamako Thrift — Thème clair ──────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_radius.dart';

ThemeData buildLightTheme() {
  final colorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    primaryContainer: AppColors.primaryContainer,
    onPrimaryContainer: AppColors.onPrimaryContainer,
    secondary: AppColors.secondary,
    onSecondary: AppColors.onSecondary,
    secondaryContainer: AppColors.secondaryContainer,
    onSecondaryContainer: AppColors.onSecondaryContainer,
    tertiary: AppColors.tertiary,
    onTertiary: AppColors.onTertiary,
    tertiaryContainer: AppColors.tertiaryContainer,
    onTertiaryContainer: AppColors.onTertiaryContainer,
    error: AppColors.error,
    onError: AppColors.white,
    errorContainer: AppColors.errorContainer,
    onErrorContainer: AppColors.error,
    surface: AppColors.surface,
    onSurface: AppColors.onSurface,
    surfaceContainerHighest: AppColors.surfaceVariant,
    onSurfaceVariant: AppColors.onSurfaceVariant,
    outline: AppColors.outline,
    outlineVariant: AppColors.outlineVariant,
    shadow: AppColors.shadow,
    scrim: AppColors.overlay,
    inverseSurface: AppColors.onSurface,
    onInverseSurface: AppColors.surface,
    inversePrimary: AppColors.primaryLight,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    fontFamily: AppTextStyles.fontFamily,

    // ── AppBar ──────────────────────────────────────────────────────────
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.onSurface,
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: true,
      titleTextStyle: AppTextStyles.titleLarge,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      iconTheme: const IconThemeData(color: AppColors.onSurface),
    ),

    // ── Scaffold ────────────────────────────────────────────────────────
    scaffoldBackgroundColor: AppColors.background,

    // ── Card ────────────────────────────────────────────────────────────
    cardTheme: CardTheme(
      elevation: AppSizes.cardElevation,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.lg),
      margin: const EdgeInsets.all(0),
      clipBehavior: Clip.antiAlias,
    ),

    // ── ElevatedButton ──────────────────────────────────────────────────
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        minimumSize: const Size(double.infinity, AppSizes.buttonHeight),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.md),
        textStyle: AppTextStyles.button,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 14.0),
      ),
    ),

    // ── OutlinedButton ──────────────────────────────────────────────────
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        minimumSize: const Size(double.infinity, AppSizes.buttonHeight),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.md),
        side: const BorderSide(color: AppColors.primary, width: 1.5),
        textStyle: AppTextStyles.button,
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 14.0),
      ),
    ),

    // ── TextButton ──────────────────────────────────────────────────────
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: AppTextStyles.button,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.md),
      ),
    ),

    // ── InputDecoration ─────────────────────────────────────────────────
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceVariant,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      border: OutlineInputBorder(
        borderRadius: AppRadius.md,
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.md,
        borderSide: const BorderSide(color: AppColors.outlineVariant, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.md,
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppRadius.md,
        borderSide: const BorderSide(color: AppColors.error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: AppRadius.md,
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
      hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.outline),
      labelStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
      errorStyle: AppTextStyles.labelSmall.copyWith(color: AppColors.error),
    ),

    // ── BottomNavigationBar ─────────────────────────────────────────────
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.outline,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      showUnselectedLabels: true,
    ),

    // ── NavigationBar (Material 3) ──────────────────────────────────────
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.primaryContainer,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: AppColors.primary);
        }
        return const IconThemeData(color: AppColors.outline);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppTextStyles.labelSmall.copyWith(color: AppColors.primary);
        }
        return AppTextStyles.labelSmall.copyWith(color: AppColors.outline);
      }),
    ),

    // ── Chip ────────────────────────────────────────────────────────────
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surfaceVariant,
      selectedColor: AppColors.primaryContainer,
      labelStyle: AppTextStyles.labelMedium,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.circle),
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
    ),

    // ── Divider ─────────────────────────────────────────────────────────
    dividerTheme: const DividerThemeData(
      color: AppColors.divider,
      thickness: 1,
      space: 1,
    ),

    // ── FloatingActionButton ─────────────────────────────────────────────
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.onPrimary,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.md),
    ),

    // ── SnackBar ────────────────────────────────────────────────────────
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.onSurface,
      contentTextStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.surface),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.md),
      behavior: SnackBarBehavior.floating,
    ),

    // ── BottomSheet ─────────────────────────────────────────────────────
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.0),
          topRight: Radius.circular(24.0),
        ),
      ),
      elevation: 8,
      modalElevation: 16,
    ),

    // ── Dialog ──────────────────────────────────────────────────────────
    dialogTheme: DialogTheme(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.xl),
      elevation: 8,
      titleTextStyle: AppTextStyles.headlineSmall,
      contentTextStyle: AppTextStyles.bodyMedium,
    ),

    // ── ListTile ────────────────────────────────────────────────────────
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
    ),

    // ── Switch ──────────────────────────────────────────────────────────
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.primary;
        return AppColors.outline;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primaryContainer;
        }
        return AppColors.surfaceVariant;
      }),
    ),

    // ── TextTheme ───────────────────────────────────────────────────────
    textTheme: const TextTheme(
      displayLarge: AppTextStyles.displayLarge,
      displayMedium: AppTextStyles.displayMedium,
      displaySmall: AppTextStyles.displaySmall,
      headlineLarge: AppTextStyles.headlineLarge,
      headlineMedium: AppTextStyles.headlineMedium,
      headlineSmall: AppTextStyles.headlineSmall,
      titleLarge: AppTextStyles.titleLarge,
      titleMedium: AppTextStyles.titleMedium,
      titleSmall: AppTextStyles.titleSmall,
      bodyLarge: AppTextStyles.bodyLarge,
      bodyMedium: AppTextStyles.bodyMedium,
      bodySmall: AppTextStyles.bodySmall,
      labelLarge: AppTextStyles.labelLarge,
      labelMedium: AppTextStyles.labelMedium,
      labelSmall: AppTextStyles.labelSmall,
    ),
  );
}
