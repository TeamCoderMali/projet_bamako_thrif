// ─── Bamako Thrift — Splash Page ─────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bamako_thrift/core/constants/brand.dart';
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

    _bootstrap();
  }

  // Lance la vérification de session en parallèle du délai d'affichage
  // minimal (1s), au lieu de l'attendre avant de commencer (audit lenteurs
  // du 2026-10-17 : l'ancien délai fixe de 1,5s retardait le démarrage de
  // la vérification elle-même, pas seulement la navigation). On navigue
  // dès que les deux sont terminés — jamais avant 1s, jamais avant que la
  // session soit résolue.
  Future<void> _bootstrap() async {
    final results = await Future.wait([
      Future<void>.delayed(const Duration(seconds: 1)),
      _resolveDestination(),
    ]);
    if (!mounted) return;
    context.go(results[1] as String);
  }

  Future<String> _resolveDestination() async {
    // ── Vérifier si c'est la première fois ──────────────────────────────
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

    if (!hasSeenOnboarding) {
      await prefs.setBool('has_seen_onboarding', true);
      return RouteNames.welcome;
    }

    // ── Vérifier l'état auth ─────────────────────────────────────────────
    if (!mounted) return RouteNames.login;
    final state = context.read<AuthCubit>().state;
    if (state is AuthAuthenticated) {
      return RouteNames.home;
    } else if (state is AuthLoading || state is AuthInitial) {
      return _waitForAuthResolution();
    } else {
      return RouteNames.login;
    }
  }

  Future<String> _waitForAuthResolution() async {
    final cubit = context.read<AuthCubit>();
    final state = await cubit.stream
        .firstWhere((s) => s is! AuthLoading && s is! AuthInitial)
        // Filet de sécurité : si AuthCubit ne se résout jamais (ex. appel
        // réseau bloqué en amont), on ne laisse pas le splash tourner à
        // l'infini — on retombe sur l'écran de connexion.
        .timeout(
          const Duration(seconds: 10),
          onTimeout: () => const AuthUnauthenticated(),
        );
    return state is AuthAuthenticated ? RouteNames.home : RouteNames.login;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Le logo (PNG transparent) s'adapte au fond du theme ambiant.
    return Scaffold(
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Logo (contient le mot "DANAYA", plus le slogan) ──
                Image.asset(
                  'assets/images/logo_danaya_no_tagline.png',
                  width: 260,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 8),
                const Text(
                  danayaSlogan,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6B7F4D),
                  ),
                ),
                const SizedBox(height: 48),
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
