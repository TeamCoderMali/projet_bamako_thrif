// ─── Bamako Thrift — Splash Page ─────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bamako_thrift/core/router/route_names.dart';
import 'package:bamako_thrift/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:go_router/go_router.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _scaleAnim = Tween<double>(begin: 0.75, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _controller.forward();

    Future.delayed(const Duration(milliseconds: 1500), _checkAuth);
  }

  Future<void> _checkAuth() async {
    if (!mounted) return;

    // ── Vérifier si c'est la première fois ──────────────────────────────
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

    if (!hasSeenOnboarding) {
      await prefs.setBool('has_seen_onboarding', true);
      if (mounted) context.go(RouteNames.welcome);
      return;
    }

    // ── Vérifier l'état auth ─────────────────────────────────────────────
    if (!mounted) return;
    final state = context.read<AuthCubit>().state;
    if (state is AuthAuthenticated) {
      context.go(RouteNames.home);
    } else if (state is AuthLoading || state is AuthInitial) {
      _listenUntilResolved();
    } else {
      context.go(RouteNames.login);
    }
  }

  void _listenUntilResolved() {
    final cubit = context.read<AuthCubit>();
    cubit.stream
        .firstWhere((s) => s is! AuthLoading && s is! AuthInitial)
        .then((state) {
      if (!mounted) return;
      if (state is AuthAuthenticated) {
        context.go(RouteNames.home);
      } else {
        context.go(RouteNames.login);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ── Fond crème identique à celui du logo : aucune bordure visible,
    // le logo "fait partie" de l'écran au lieu d'être posé dessus.
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EE),
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Logo (contient déjà le mot "DANAYA" + la signature) ──
                Image.asset(
                  'assets/images/logo_danaya.png',
                  width: 260,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 56),
                SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                    color: const Color(0xFF6B7F4D),
                    backgroundColor: const Color(0xFF6B7F4D).withOpacity(0.12),
                    strokeWidth: 2.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
