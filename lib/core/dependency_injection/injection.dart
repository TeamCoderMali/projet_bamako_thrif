// ─── Bamako Thrift — Dependency Injection (get_it) ────────────────────────
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
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
import '../services/storage_service.dart';


import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';

import '../../features/product/data/datasources/product_remote_datasource.dart';
import '../../features/product/data/datasources/product_remote_datasource_impl.dart';
import '../../features/product/data/repositories/product_repository_impl.dart';
import '../../features/product/domain/repositories/product_repository.dart';
import '../../features/chat/data/repositories/chat_repository_impl.dart';
import '../../features/chat/domain/repositories/chat_repository.dart';

import '../../features/notification/data/repositories/notification_repository_impl.dart';
import '../../features/notification/domain/repositories/notification_repository.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../features/product/presentation/cubit/product_cubit.dart';

/// Instance globale de GetIt.
final GetIt sl = GetIt.instance;

/// Initialise toutes les dépendances de l'application.
/// Appeler dans main() avant runApp().
Future<void> configureDependencies() async {
  await _registerCore();
  await _registerAuth();
  await _registerProduct();
  await _registerChat();
  await _registerNotification();
}

// ── Core ────────────────────────────────────────────────────────────────────
Future<void> _registerCore() async {
  // Storage
  final localStorage = LocalStorage();
  await localStorage.init();
  sl.registerSingleton<LocalStorage>(localStorage);
  sl.registerSingleton<SecureStorage>(SecureStorage());

  // Firebase instances
  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
  sl.registerLazySingleton<FirebaseStorage>(() => FirebaseStorage.instance);
  sl.registerLazySingleton<FirebaseClient>(() => FirebaseClient(
        auth: sl<FirebaseAuth>(),
        firestore: sl<FirebaseFirestore>(),
      ));
  sl.registerLazySingleton<StorageService>(
    () => StorageService(sl<FirebaseStorage>(), sl<FirebaseAuth>()),
  );

  // Network
  sl.registerLazySingleton<DioClient>(() => DioClient());
  sl.registerLazySingleton<ConnectivityService>(() => ConnectivityService());

  // Services
  sl.registerSingleton<LoggerService>(LoggerService());
  sl.registerSingleton<SnackBarService>(SnackBarService.instance);
  sl.registerSingleton<DialogService>(DialogService.instance);
  sl.registerSingleton<NavigationService>(NavigationService.instance);
  sl.registerSingleton<LoadingService>(LoadingService.instance);
  sl.registerSingleton<PermissionService>(PermissionService.instance);
}

// ── Auth ─────────────────────────────────────────────────────────────────────
Future<void> _registerAuth() async {
  sl.registerLazySingleton<FirebaseAuthRepositoryImpl>(
    () => FirebaseAuthRepositoryImpl(
      sl<FirebaseAuth>(),
      sl<FirebaseFirestore>(),
    ),
  );
  // Enregistrer aussi via l'interface pour les use cases
  sl.registerLazySingleton<AuthRepository>(
    () => sl<FirebaseAuthRepositoryImpl>(),
  );
}

// ── Product ──────────────────────────────────────────────────────────────────
Future<void> _registerProduct() async {
  sl.registerLazySingleton<ProductRemoteDataSource>(
    () => ProductRemoteDataSourceImpl(sl<FirebaseFirestore>()),
  );
  sl.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImpl(
      remoteDataSource: sl<ProductRemoteDataSource>(),
      currentUserId: sl<FirebaseAuth>().currentUser?.uid,
    ),
  );
  sl.registerFactory<ProductCubit>(
    () => ProductCubit(repository: sl<ProductRepository>()),
  );
}

// ── Chat ────────────────────────────────────────────────────────────────────────────────
Future<void> _registerChat() async {
  sl.registerLazySingleton<ChatRepository>(
    () => ChatRepositoryImpl(
      sl<FirebaseFirestore>(),
      sl<FirebaseAuth>(),
    ),
  );
}

// ── Notification ───────────────────────────────────────────────────────────────────
Future<void> _registerNotification() async {
  sl.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(
      sl<FirebaseFirestore>(),
      sl<FirebaseAuth>(),
      FirebaseMessaging.instance,
    ),
  );
}
