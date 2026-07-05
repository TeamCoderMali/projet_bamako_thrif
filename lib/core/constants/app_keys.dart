/// ─── Bamako Thrift — Clés globales ────────────────────────────────────────
import 'package:flutter/material.dart';

abstract class AppKeys {
  AppKeys._();

  // ── Navigator ──────────────────────────────────────────────────────────
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'rootNavigator');

  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>(debugLabel: 'scaffoldMessenger');

  // ── Storage keys ───────────────────────────────────────────────────────
  static const String onboardingCompletedKey = 'onboarding_completed';
  static const String themeKey = 'app_theme';
  static const String languageKey = 'app_language';
  static const String userTokenKey = 'user_token';
  static const String userIdKey = 'user_id';
  static const String userDataKey = 'user_data';
  static const String cartKey = 'cart_items';
  static const String favoritesKey = 'favorites';
  static const String searchHistoryKey = 'search_history';
  static const String fcmTokenKey = 'fcm_token';
  static const String lastLoginKey = 'last_login';

  // ── Secure storage keys ────────────────────────────────────────────────
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String biometricEnabledKey = 'biometric_enabled';
  static const String pinCodeKey = 'pin_code';

  // ── Widget keys (tests & accessibility) ───────────────────────────────
  static const Key loginEmailField = Key('login_email_field');
  static const Key loginPasswordField = Key('login_password_field');
  static const Key loginButton = Key('login_button');
  static const Key registerButton = Key('register_button');
  static const Key searchField = Key('search_field');
  static const Key publishButton = Key('publish_button');
  static const Key bottomNav = Key('bottom_nav');
}
