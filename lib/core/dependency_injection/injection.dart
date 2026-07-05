// ─── Bamako Thrift — Dependency Injection (get_it) ────────────────────────
//
// Utilisation de get_it + injectable pour l'injection de dépendances.
// Lancer `flutter pub run build_runner build` pour générer injection.config.dart.
//
import 'package:get_it/get_it.dart';

import '../network/dio_client.dart';
import '../network/firebase_client.dart';
import '../network/connectivity_service.dart';
import '../storage/local_storage.dart';
import '../storage/secure_storage.dart';
import '../services/logger_service.dart';
import '../services/snackbar_service.dart';
import '../services/dialog_service.dart';
import '../services/navigation_service.dart';
import '../services/loading_service.dart';
import '../services/permission_service.dart';

/// Instance globale de GetIt.
final GetIt sl = GetIt.instance;

/// Initialise toutes les dépendances de l'application.
/// Appeler cette fonction dans main() avant runApp().
Future<void> configureDependencies() async {
  await _registerCore();
  // TODO: Décommenter après avoir lancé build_runner :
  // await _$configureDependencies();
}

Future<void> _registerCore() async {
  // ── Storage ────────────────────────────────────────────────────────────
  final localStorage = LocalStorage();
  await localStorage.init();
  sl.registerSingleton<LocalStorage>(localStorage);
  sl.registerSingleton<SecureStorage>(SecureStorage());

  // ── Network ────────────────────────────────────────────────────────────
  sl.registerLazySingleton<DioClient>(() => DioClient());
  sl.registerLazySingleton<FirebaseClient>(() => FirebaseClient());
  sl.registerLazySingleton<ConnectivityService>(() => ConnectivityService());

  // ── Services ───────────────────────────────────────────────────────────
  sl.registerSingleton<LoggerService>(LoggerService());
  sl.registerSingleton<SnackBarService>(SnackBarService.instance);
  sl.registerSingleton<DialogService>(DialogService.instance);
  sl.registerSingleton<NavigationService>(NavigationService.instance);
  sl.registerSingleton<LoadingService>(LoadingService.instance);
  sl.registerSingleton<PermissionService>(PermissionService.instance);
}
