/// ─── Bamako Thrift — Navigation Service ────────────────────────────────────
import 'package:flutter/material.dart';
import '../constants/app_keys.dart';
import '../router/app_router.dart';
import '../router/route_names.dart';

/// Service de navigation sans BuildContext pour les cas hors widget tree.
class NavigationService {
  NavigationService._();
  static final NavigationService instance = NavigationService._();

  BuildContext? get context => AppKeys.navigatorKey.currentContext;

  void go(String route) => appRouter.go(route);

  Future<T?> push<T>(String route, {Object? extra}) =>
      appRouter.push(route, extra: extra);

  void pop<T>([T? result]) =>
      AppKeys.navigatorKey.currentState?.pop(result);

  void replace(String route) => appRouter.replace<void>(route);

  bool canPop() => AppKeys.navigatorKey.currentState?.canPop() ?? false;

  void goToHome() => appRouter.go(RouteNames.home);

  void goToLogin() => appRouter.go(RouteNames.login);

  void goToOnboarding() => appRouter.go(RouteNames.welcome);
}
