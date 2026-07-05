/// ─── Bamako Thrift — Service Locator ──────────────────────────────────────
///
/// Raccourcis pour accéder aux dépendances enregistrées dans get_it.
/// Utiliser `locator<Type>()` ou les accesseurs nommés.
///
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

export 'injection.dart';

/// Alias pour GetIt.instance.
final GetIt locator = GetIt.instance;

/// Accesseur typé générique.
T get<T extends Object>() => locator<T>();

// ── Accesseurs nommés (pratique et type-safe) ────────────────────────────────
LocalStorage get localStorage => locator<LocalStorage>();
SecureStorage get secureStorage => locator<SecureStorage>();
DioClient get dioClient => locator<DioClient>();
FirebaseClient get firebaseClient => locator<FirebaseClient>();
ConnectivityService get connectivityService => locator<ConnectivityService>();
LoggerService get loggerService => locator<LoggerService>();
SnackBarService get snackBarService => locator<SnackBarService>();
DialogService get dialogService => locator<DialogService>();
NavigationService get navigationService => locator<NavigationService>();
LoadingService get loadingService => locator<LoadingService>();
PermissionService get permissionService => locator<PermissionService>();
