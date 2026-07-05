/// ─── Bamako Thrift — Durées d'animation ───────────────────────────────────
abstract class AppDuration {
  AppDuration._();

  static const Duration instant = Duration(milliseconds: 50);
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration medium = Duration(milliseconds: 350);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration verySlow = Duration(milliseconds: 800);
  static const Duration pageTransition = Duration(milliseconds: 300);
  static const Duration bottomSheetAnimation = Duration(milliseconds: 350);
  static const Duration snackBarDuration = Duration(seconds: 3);
  static const Duration toastDuration = Duration(seconds: 2);
  static const Duration splashDuration = Duration(seconds: 2);
  static const Duration debounce = Duration(milliseconds: 400);
  static const Duration throttle = Duration(seconds: 1);
}
