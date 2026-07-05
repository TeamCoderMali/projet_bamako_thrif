import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'core/constants/app_keys.dart';
import 'core/dependency_injection/injection.dart';
import 'core/router/app_router.dart';
import 'core/services/logger_service.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Orientation ────────────────────────────────────────────────────────
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // ── Status bar ─────────────────────────────────────────────────────────
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // ── Logging ────────────────────────────────────────────────────────────
  logger.init(isProduction: false);
  logger.info('Bamako Thrift — Démarrage');

  // ── Dependency Injection ───────────────────────────────────────────────
  await configureDependencies();
  logger.info('Dépendances initialisées');

  // ── Firebase (à décommenter après configuration) ───────────────────────
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );

  runApp(const BamakoThriftApp());
}

class BamakoThriftApp extends StatelessWidget {
  const BamakoThriftApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844), // iPhone 15 Pro reference
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          // ── Identity ──────────────────────────────────────────────────
          title: 'Bamako Thrift',
          debugShowCheckedModeBanner: false,

          // ── Theme ─────────────────────────────────────────────────────
          theme: buildLightTheme(),
          darkTheme: buildDarkTheme(),
          themeMode: ThemeMode.system,

          // ── Navigation ────────────────────────────────────────────────
          routerConfig: appRouter,

          // ── Keys ──────────────────────────────────────────────────────
          scaffoldMessengerKey: AppKeys.scaffoldMessengerKey,

          // ── Builder ───────────────────────────────────────────────────
          builder: (context, child) {
            // Prevent font scaling from accessibility settings
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
  }
}
