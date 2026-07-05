// ─── Bamako Thrift — Auth Remote DataSource (stub) ─────────────────────────
// Implémentation Firebase à développer dans auth_remote_datasource_impl.dart
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  });

  Future<UserModel> registerWithEmail({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
  });

  Future<UserModel> signInWithGoogle();

  Future<void> signOut();

  Future<void> sendPasswordResetEmail(String email);

  Future<void> sendEmailVerification();

  Future<UserModel?> getCurrentUser();

  Stream<UserModel?> get authStateChanges;

  Future<UserModel> updateProfile({
    String? fullName,
    String? bio,
    String? phoneNumber,
    String? avatarUrl,
  });

  Future<void> deleteAccount();
}
