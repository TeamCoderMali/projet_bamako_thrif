import 'package:bamako_thrift/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:bamako_thrift/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:bamako_thrift/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/constants/app_keys.dart';
import 'core/dependency_injection/injection.dart';
import 'core/router/app_router.dart';
import 'core/services/logger_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'features/product/presentation/cubit/product_cubit.dart';

// ── Handler pour les notifications reçues quand l'app est en arrière-plan
//    ou complètement fermée. Doit être une fonction top-level (pas dans une
//    classe) car elle tourne dans un isolate séparé.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Rien d'autre à faire ici : le système affiche déjà la notif
  // automatiquement à partir du payload "notification".
}

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

  // ── Firebase Messaging (notifications push) ─────────────────────────────
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  final messaging = FirebaseMessaging.instance;

  final settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  logger.info('Permission notifications: ${settings.authorizationStatus}');

  final fcmToken = await messaging.getToken();
  logger.info('FCM Token: $fcmToken');

  // Notification reçue pendant que l'app est ouverte (premier plan).
  // Par défaut, iOS/Android n'affichent RIEN automatiquement dans ce cas,
  // il faut donc gérer l'affichage soi-même (SnackBar, dialog, etc.)
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    logger.info(
        'Notification reçue (premier plan): ${message.notification?.title}');
    final ctx = AppKeys.scaffoldMessengerKey.currentState;
    if (ctx != null && message.notification != null) {
      ctx.showSnackBar(
        SnackBar(
          content: Text(
            '${message.notification!.title}\n${message.notification!.body}',
          ),
          backgroundColor: const Color(0xFF6B7F4D),
        ),
      );
    }
  });

  // Notification cliquée alors que l'app était en arrière-plan (pas fermée)
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    logger.info('Notification ouverte depuis l\'arrière-plan: ${message.data}');
    // TODO: naviguer vers l'écran concerné selon message.data si besoin
  });

  // Notification cliquée alors que l'app était complètement fermée
  final initialMessage = await messaging.getInitialMessage();
  if (initialMessage != null) {
    logger.info(
        'App ouverte depuis une notif (app fermée): ${initialMessage.data}');
    // TODO: naviguer vers l'écran concerné selon initialMessage.data si besoin
  }

  // ── Dependency Injection ─────────────────────────────────────────────────
  await configureDependencies();
  logger.info('Dépendances initialisées');

  // ── Localisation ─────────────────────────────────────────────────────────
  await initializeDateFormatting('fr_FR', null);

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>(
          create: (_) => ThemeCubit(),
        ),
        BlocProvider<AuthCubit>(
          create: (_) =>
              AuthCubit(sl<FirebaseAuthRepositoryImpl>())..checkAuthStatus(),
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

              // ── Theme ────────────────────────────────────────────────────
              theme: buildLightTheme(),
              darkTheme: buildDarkTheme(),
              themeMode: themeMode,

              // ── Navigation ───────────────────────────────────────────────
              routerConfig: appRouter,

              // ── Keys ─────────────────────────────────────────────────────
              scaffoldMessengerKey: AppKeys.scaffoldMessengerKey,

              // ── Builder ──────────────────────────────────────────────────
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
