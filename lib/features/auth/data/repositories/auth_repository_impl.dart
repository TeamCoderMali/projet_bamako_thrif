// ─── Bamako Thrift — Auth Repository Implementation (stub) ─────────────────
// TODO: Implémenter avec Firebase Auth + Firestore
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  // TODO: Injecter AuthRemoteDataSource via get_it

  @override
  Future<UserEntity> signInWithEmail({
    required String email,
    required String password,
  }) {
    // TODO: Appeler authRemoteDataSource.signInWithEmail(...)
    throw UnimplementedError('signInWithEmail not yet implemented');
  }

  @override
  Future<UserEntity> registerWithEmail({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
  }) {
    throw UnimplementedError('registerWithEmail not yet implemented');
  }

  @override
  Future<UserEntity> signInWithGoogle() {
    throw UnimplementedError('signInWithGoogle not yet implemented');
  }

  @override
  Future<void> signOut() {
    throw UnimplementedError('signOut not yet implemented');
  }

  @override
  Future<void> sendPasswordResetEmail(String email) {
    throw UnimplementedError('sendPasswordResetEmail not yet implemented');
  }

  @override
  Future<void> sendEmailVerification() {
    throw UnimplementedError('sendEmailVerification not yet implemented');
  }

  @override
  Future<UserEntity?> getCurrentUser() {
    throw UnimplementedError('getCurrentUser not yet implemented');
  }

  @override
  Stream<UserEntity?> get authStateChanges =>
      throw UnimplementedError('authStateChanges not yet implemented');

  @override
  Future<UserEntity> updateProfile({
    String? fullName,
    String? bio,
    String? phoneNumber,
    String? avatarUrl,
  }) {
    throw UnimplementedError('updateProfile not yet implemented');
  }

  @override
  Future<void> deleteAccount() {
    throw UnimplementedError('deleteAccount not yet implemented');
  }
}
