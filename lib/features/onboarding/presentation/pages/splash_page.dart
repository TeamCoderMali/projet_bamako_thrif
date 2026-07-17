// ─── Bamako Thrift — Splash Page ─────────────────────────────────────────────
// Page de chargement affichée au démarrage pendant la vérification auth
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

    // Délai minimal pour que l'animation se joue, puis vérifier l'auth
    Future.delayed(const Duration(milliseconds: 1500), _checkAuth);
  }

  void _checkAuth() {
    if (!mounted) return;
    final state = context.read<AuthCubit>().state;
    if (state is AuthAuthenticated) {
      context.go(RouteNames.home);
    } else if (state is AuthLoading || state is AuthInitial) {
      // Encore en chargement → on réécoute
      _listenUntilResolved();
    } else {
      context.go(RouteNames.login);
    }
  }

  void _listenUntilResolved() {
    final cubit = context.read<AuthCubit>();
    cubit.stream.firstWhere((s) => s is! AuthLoading && s is! AuthInitial).then((state) {
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
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        // Si l'état change pendant le splash (ex: auth très rapide)
        if (state is AuthAuthenticated) {
          context.go(RouteNames.home);
        } else if (state is AuthUnauthenticated || state is AuthError) {
          context.go(RouteNames.login);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF2B2B2B),
        body: Center(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: ScaleTransition(
              scale: _scaleAnim,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Logo / Icône ─────────────────────────────────────────
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8FA85A), Color(0xFF6B7F4D)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6B7F4D).withOpacity(0.4),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        '👗',
                        style: TextStyle(fontSize: 48),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Nom app ───────────────────────────────────────────────
                  const Text(
                    'DANAYA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'La mode malienne d\'occasion',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 14,
                      letterSpacing: 1,
                    ),
                  ),

                  const SizedBox(height: 60),

                  // ── Spinner ───────────────────────────────────────────────
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      color: const Color(0xFF6B7F4D),
                      backgroundColor: Colors.white.withOpacity(0.1),
                      strokeWidth: 2.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
