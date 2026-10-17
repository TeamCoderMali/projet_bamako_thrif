import 'dart:async';

import 'package:bamako_thrift/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:bamako_thrift/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:bamako_thrift/features/notification/domain/repositories/notification_repository.dart';
import 'package:bamako_thrift/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/constants/app_keys.dart';
import 'core/dependency_injection/injection.dart';
import 'core/router/app_router.dart';
import 'core/router/route_names.dart';
import 'core/services/logger_service.dart';
import 'core/services/offers_config_service.dart';
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
  logger.init(isProduction: kReleaseMode);
  logger.info('DANAYA — Démarrage');

  // ── Dependency Injection ─────────────────────────────────────────────────
  await configureDependencies();
  logger.info('Dépendances initialisées');

  // Créé ici (pas dans le builder du BlocProvider) pour pouvoir l'utiliser
  // dès la configuration de Firebase Messaging ci-dessous (enregistrement
  // du jeton dès qu'une session existe déjà au démarrage).
  final authCubit = AuthCubit(sl<FirebaseAuthRepositoryImpl>())
    ..checkAuthStatus();

  // ── Firebase Messaging (notifications push) ─────────────────────────────
  // Désactivé sur le web (2026-10-14) : messaging.getToken() y enregistre un
  // service worker à firebase-messaging-sw.js par défaut ; ce fichier
  // n'existe pas (pas de push web configuré) et la règle de rewrite SPA du
  // Hosting renvoie du HTML à la place, ce que le navigateur refuse
  // ("unsupported MIME type") — exception non interceptée qui bloquait
  // runApp() (splash figé). Aucun push n'est de toute façon possible
  // aujourd'hui, web ou mobile (plan Blaze requis pour l'envoi serveur).
  // Android/iOS inchangés.
  Map<String, dynamic>? pendingNotificationData;
  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    final messaging = FirebaseMessaging.instance;
    final notificationRepo = sl<NotificationRepository>();

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    logger.info('Permission notifications: ${settings.authorizationStatus}');

    // ── Enregistrement du jeton FCM ─────────────────────────────────────
    // Écrit dans users/{uid}/private/data.fcmToken (voir
    // NotificationRepositoryImpl.updateFcmToken, déjà existant mais jamais
    // appelé jusqu'ici) : condition nécessaire pour qu'un envoi serveur
    // puisse un jour cibler cet utilisateur. Nettoyage à la déconnexion
    // géré côté AuthRepositoryImpl.signOut()/deleteAccount().
    Future<void> registerTokenIfAuthenticated() async {
      if (authCubit.state is! AuthAuthenticated) return;
      try {
        final token = await messaging.getToken();
        if (token != null) await notificationRepo.updateFcmToken(token);
      } catch (e) {
        logger.warning('Échec enregistrement jeton FCM', error: e.toString());
      }
    }

    // Au démarrage : la session peut déjà être restaurée (checkAuthStatus
    // ci-dessus est asynchrone) — on réessaie à chaque changement d'état
    // pour couvrir aussi bien une session déjà active qu'une connexion qui
    // vient juste d'avoir lieu (connexion email, inscription, Google).
    await registerTokenIfAuthenticated();
    authCubit.stream.listen((state) {
      if (state is AuthAuthenticated) registerTokenIfAuthenticated();
    });

    // Le jeton peut changer sans reconnexion explicite (réinstallation,
    // restauration d'appareil...) — un seul abonnement pour toute la durée
    // de vie de l'app.
    messaging.onTokenRefresh.listen((newToken) {
      if (authCubit.state is! AuthAuthenticated) return;
      notificationRepo.updateFcmToken(newToken).catchError((e) {
        logger.warning('Échec mise à jour jeton FCM', error: e.toString());
      });
    });

    // Notification reçue pendant que l'app est ouverte (premier plan).
    // Par défaut, iOS/Android n'affichent RIEN automatiquement dans ce cas,
    // il faut donc gérer l'affichage soi-même (SnackBar, dialog, etc.)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      logger.info(
          'Notification reçue (premier plan): ${message.notification?.title}');
      final messengerState = AppKeys.scaffoldMessengerKey.currentState;
      final context = AppKeys.scaffoldMessengerKey.currentContext;
      if (messengerState != null && context != null && message.notification != null) {
        messengerState.showSnackBar(
          SnackBar(
            content: Text(
              '${message.notification!.title}\n${message.notification!.body}',
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    });

    // Notification tapée alors que l'app était en arrière-plan (pas fermée)
    // : le Navigator existe déjà, navigation immédiate.
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      logger.info('Notification ouverte depuis l\'arrière-plan: ${message.data}');
      _navigateFromNotificationData(message.data);
    });

    // Notification tapée alors que l'app était complètement fermée : le
    // Navigator n'existe pas encore à ce stade (avant runApp) — la
    // navigation est différée après le premier frame, plus bas.
    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      logger.info(
          'App ouverte depuis une notif (app fermée): ${initialMessage.data}');
      pendingNotificationData = initialMessage.data;
    }
  }

  // Préchauffe le cache du config "offres" (TTL 5 min, voir
  // OffersConfigService) sans bloquer le démarrage : force un rechargement
  // frais à chaque lancement de l'app, pour qu'un changement fait par
  // l'admin ne soit jamais servi depuis un cache plus vieux que le process.
  unawaited(OffersConfigService.instance.getConfig(forceRefresh: true));

  // ── Localisation ─────────────────────────────────────────────────────────
  await initializeDateFormatting('fr_FR', null);

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>(
          create: (_) => ThemeCubit(),
        ),
        BlocProvider<AuthCubit>.value(
          value: authCubit,
        ),
        // Pas de chargement anticipé ici (audit lenteurs du 2026-10-17) :
        // HomePage déclenche déjà son propre loadProducts(refresh: true)
        // dans son initState, donc cet appel ne faisait que dupliquer la
        // même requête Firestore avant même de savoir si l'utilisateur est
        // connecté ou a déjà vu l'onboarding. Écrans vérifiés : HomePage et
        // CatalogPage ont chacun leur propre chargement dans initState ;
        // BrowsePage n'utilise pas ProductCubit ; ProductDetailPage utilise
        // loadProductDetail (indépendant) ; SearchPage n'a pas de
        // chargement initial propre pour la recherche vide (dépend d'un
        // écran précédent déjà chargé — cas normal puisque Home se charge
        // toujours avant, sauf lien web direct vers /search, cas limite
        // préexistant signalé à Ali, non corrigé ici).
        BlocProvider<ProductCubit>(
          create: (_) => sl<ProductCubit>(),
        ),
      ],
      child: const BamakoThriftApp(),
    ),
  );

  // App fermée puis rouverte via une notification : le Navigator n'existait
  // pas encore quand getInitialMessage() a répondu (avant runApp) — on
  // navigue une fois le premier frame construit.
  if (pendingNotificationData != null) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigateFromNotificationData(pendingNotificationData!);
    });
  }
}

// ── Navigation au tap sur une notification ──────────────────────────────────
// Appelée depuis onMessageOpenedApp (app en arrière-plan) et depuis
// getInitialMessage (app fermée, différé après le premier frame ci-dessus).
// Contrat de données (voir functions/, lot Cloud Functions) : chatId pour un
// nouveau message ou une offre (les offres se négocient dans la
// conversation), orderId pour un changement de statut de commande. Les
// autres types (ex. repairValidation, déjà envoyé par le back-office
// aujourd'hui en Firestore seul, jamais encore par push) retombent sur
// l'écran des notifications, où le signalement concerné reste accessible.
void _navigateFromNotificationData(Map<String, dynamic> data) {
  final chatId = data['chatId'] as String?;
  final orderId = data['orderId'] as String?;
  if (chatId != null && chatId.isNotEmpty) {
    appRouter.push('/messages/$chatId');
    return;
  }
  if (orderId != null && orderId.isNotEmpty) {
    appRouter.push('/orders/$orderId/track');
    return;
  }
  appRouter.push(RouteNames.notifications);
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
