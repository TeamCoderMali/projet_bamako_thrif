/// ─── Bamako Thrift — Route Generator (utilitaire de navigation) ───────────
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'app_router.dart';

export 'app_router.dart';
export 'route_names.dart';

/// Helper pour naviguer sans BuildContext (via navigatorKey).
class RouteGenerator {
  RouteGenerator._();

  static GoRouter get router => appRouter;

  static void go(String location) => appRouter.go(location);

  static void push(String location) => appRouter.push(location);

  static void pop() => appRouter.routerDelegate.navigatorKey.currentState?.pop();

  static void replace(String location) => appRouter.replace<void>(location);

  static void popUntilHome() => appRouter.go('/home');

  /// Builds a custom page transition.
  static CustomTransitionPage<T> fadeTransition<T>({
    required BuildContext context,
    required GoRouterState state,
    required Widget child,
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 250),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  static CustomTransitionPage<T> slideTransition<T>({
    required BuildContext context,
    required GoRouterState state,
    required Widget child,
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        final tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: Curves.easeInOut),
        );
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }
}
