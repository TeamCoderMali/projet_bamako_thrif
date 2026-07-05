/// ─── Bamako Thrift — Tailles & Espacements ────────────────────────────────
/// Système de design basé sur une grille de 4px.
/// Utiliser flutter_screenutil pour l'adaptation responsive.
abstract class AppSizes {
  AppSizes._();

  // ── Spacing ────────────────────────────────────────────────────────────
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;

  // ── Padding ────────────────────────────────────────────────────────────
  static const double paddingXs = 4.0;
  static const double paddingSm = 8.0;
  static const double paddingMd = 16.0;
  static const double paddingLg = 24.0;
  static const double paddingXl = 32.0;

  // ── Icon sizes ─────────────────────────────────────────────────────────
  static const double iconXs = 12.0;
  static const double iconSm = 16.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;
  static const double iconXl = 48.0;

  // ── Font sizes ─────────────────────────────────────────────────────────
  static const double fontXs = 10.0;
  static const double fontSm = 12.0;
  static const double fontMd = 14.0;
  static const double fontLg = 16.0;
  static const double fontXl = 18.0;
  static const double fontXxl = 22.0;
  static const double fontXxxl = 28.0;
  static const double fontDisplay = 36.0;
  static const double fontHero = 48.0;

  // ── Border radius ──────────────────────────────────────────────────────
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusCircle = 999.0;

  // ── Elevation ──────────────────────────────────────────────────────────
  static const double elevationNone = 0.0;
  static const double elevationXs = 1.0;
  static const double elevationSm = 2.0;
  static const double elevationMd = 4.0;
  static const double elevationLg = 8.0;
  static const double elevationXl = 16.0;

  // ── Button ─────────────────────────────────────────────────────────────
  static const double buttonHeight = 52.0;
  static const double buttonHeightSm = 40.0;
  static const double buttonHeightLg = 60.0;
  static const double buttonMinWidth = 120.0;

  // ── AppBar ─────────────────────────────────────────────────────────────
  static const double appBarHeight = 56.0;
  static const double appBarHeightLg = 80.0;

  // ── Bottom nav ─────────────────────────────────────────────────────────
  static const double bottomNavHeight = 64.0;

  // ── Avatar ─────────────────────────────────────────────────────────────
  static const double avatarXs = 24.0;
  static const double avatarSm = 36.0;
  static const double avatarMd = 48.0;
  static const double avatarLg = 72.0;
  static const double avatarXl = 96.0;

  // ── Card ───────────────────────────────────────────────────────────────
  static const double cardElevation = 2.0;
  static const double cardBorderRadius = 16.0;

  // ── Input ──────────────────────────────────────────────────────────────
  static const double inputHeight = 56.0;
  static const double inputBorderRadius = 12.0;

  // ── Product card ───────────────────────────────────────────────────────
  static const double productCardWidth = 170.0;
  static const double productCardHeight = 240.0;
  static const double productCardImageRatio = 1.2;

  // ── Grid ───────────────────────────────────────────────────────────────
  static const int gridCrossAxisCount = 2;
  static const double gridChildAspectRatio = 0.70;
  static const double gridSpacing = 12.0;
}
