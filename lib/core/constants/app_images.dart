/// ─── Bamako Thrift — Chemins d'images ─────────────────────────────────────
abstract class AppImages {
  AppImages._();

  static const String _base = 'assets/images';

  // ── Onboarding ─────────────────────────────────────────────────────────
  static const String onboarding1 = '$_base/onboarding_1.png';
  static const String onboarding2 = '$_base/onboarding_2.png';
  static const String onboarding3 = '$_base/onboarding_3.png';

  // ── Branding ───────────────────────────────────────────────────────────
  static const String logo = '$_base/logo.png';
  static const String logoWhite = '$_base/logo_white.png';
  static const String splashBackground = '$_base/splash_bg.png';

  // ── Auth ───────────────────────────────────────────────────────────────
  static const String authBackground = '$_base/auth_bg.png';
  static const String googleLogo = '$_base/google_logo.png';

  // ── Payment ────────────────────────────────────────────────────────────
  static const String orangeMoney = '$_base/orange_money.png';
  static const String wave = '$_base/wave.png';

  // ── Empty states ───────────────────────────────────────────────────────
  static const String emptyCart = '$_base/empty_cart.png';
  static const String emptyOrders = '$_base/empty_orders.png';
  static const String emptySearch = '$_base/empty_search.png';
  static const String emptyNotifications = '$_base/empty_notifications.png';
  static const String emptyFavorites = '$_base/empty_favorites.png';
  static const String noInternet = '$_base/no_internet.png';
  static const String errorGeneric = '$_base/error_generic.png';

  // ── Placeholders ───────────────────────────────────────────────────────
  static const String productPlaceholder = '$_base/product_placeholder.png';
  static const String avatarPlaceholder = '$_base/avatar_placeholder.png';
}
