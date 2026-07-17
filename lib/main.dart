import 'package:bamako_thrift/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:bamako_thrift/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:bamako_thrift/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'core/constants/app_keys.dart';
import 'core/dependency_injection/injection.dart';
import 'core/router/app_router.dart';
import 'core/services/logger_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'features/product/presentation/cubit/product_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Orientation ──────────────────────────────────────────────────────────
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // ── Status bar ───────────────────────────────────────────────────────────
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // ── Firebase ─────────────────────────────────────────────────────────────
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ── Logging ──────────────────────────────────────────────────────────────
  logger.init(isProduction: false);
  logger.info('DANAYA — Démarrage');

  // ── Dependency Injection ─────────────────────────────────────────────────
  await configureDependencies();
  logger.info('Dépendances initialisées');

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>(
          create: (_) => ThemeCubit(),
        ),
        BlocProvider<AuthCubit>(
          create: (_) => AuthCubit(sl<FirebaseAuthRepositoryImpl>())
            ..checkAuthStatus(),
        ),
        BlocProvider<ProductCubit>(
          create: (_) => sl<ProductCubit>()..loadProducts(refresh: true),
        ),
      ],
      child: const BamakoThriftApp(),
    ),
  );
}

class BamakoThriftApp extends StatelessWidget {
  const BamakoThriftApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (context, themeMode) {
            return MaterialApp.router(
              title: 'DANAYA',
              debugShowCheckedModeBanner: false,

              // ── Theme ──────────────────────────────────────────────────────────────
              theme: buildLightTheme(),
              darkTheme: buildDarkTheme(),
              themeMode: themeMode,

              // ── Navigation ──────────────────────────────────────────────────────────
              routerConfig: appRouter,

              // ── Keys ───────────────────────────────────────────────────────────────
              scaffoldMessengerKey: AppKeys.scaffoldMessengerKey,

              // ── Builder ────────────────────────────────────────────────────────────
              builder: (context, child) {
                return MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.noScaling,
                  ),
                  child: child!,
                );
              },
            );
          },
        );
      },
    );
  }
}
