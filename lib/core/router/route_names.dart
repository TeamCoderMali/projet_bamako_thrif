/// ─── Bamako Thrift — Noms des routes ─────────────────────────────────────
abstract class RouteNames {
  RouteNames._();

  // ── Splash / Onboarding ───────────────────────────────────────────────
  static const String splash = '/';
  static const String welcome = '/welcome';
  static const String intro = '/intro';

  // ── Auth ──────────────────────────────────────────────────────────────
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String verifyEmail = '/verify-email';

  // ── Main shell ────────────────────────────────────────────────────────
  static const String home = '/home';
  static const String catalog = '/catalog';
  static const String publish = '/publish';
  static const String messages = '/messages';
  static const String profile = '/profile';

  // ── Catalog ───────────────────────────────────────────────────────────
  static const String search = '/search';
  static const String filters = '/filters';
  static const String productDetail = '/product/:id';

  // ── Profile sub-routes ────────────────────────────────────────────────
  static const String editProfile = '/profile/edit';
  static const String wallet = '/profile/wallet';
  static const String history = '/profile/history';

  // ── Payment ───────────────────────────────────────────────────────────
  static const String payment = '/payment';
  static const String paymentSuccess = '/payment/success';
  static const String paymentFailed = '/payment/failed';

  // ── Orders ────────────────────────────────────────────────────────────
  static const String orders = '/orders';
  static const String orderTracking = '/orders/:id/track';

  // ── Chat ──────────────────────────────────────────────────────────────
  static const String chatList = '/messages';
  static const String chat = '/messages/:id';

  // ── Notifications ─────────────────────────────────────────────────────
  static const String notifications = '/notifications';

  // ── Settings ──────────────────────────────────────────────────────────
  static const String settings = '/settings';
  static const String privacy = '/settings/privacy';
  static const String about = '/settings/about';

  // ── Admin ─────────────────────────────────────────────────────────────
  static const String adminDashboard = '/admin/dashboard';
}
