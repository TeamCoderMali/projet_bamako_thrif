// ─── Tests — persistance de la session au redémarrage ──────────────────────
// Reproduit sans Firebase : un faux repository contrôle ce que renvoient
// authStateChanges / getCurrentUser pour vérifier que checkAuthStatus()
// restaure bien la session dans les deux cas qui causaient la déconnexion
// forcée (stream lent à émettre, lecture Firestore en échec).
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:bamako_thrift/features/auth/domain/entities/user_entity.dart';
import 'package:bamako_thrift/features/auth/domain/repositories/auth_repository.dart';
import 'package:bamako_thrift/features/auth/presentation/cubit/auth_cubit.dart';

UserEntity _fakeUser() => UserEntity(
      id: 'uid-1',
      email: 'ali@example.com',
      fullName: 'Ali',
      createdAt: DateTime(2026, 1, 1),
    );

class FakeAuthRepository implements AuthRepository {
  final StreamController<UserEntity?> _authStateController =
      StreamController<UserEntity?>.broadcast();

  UserEntity? currentUserToReturn;
  Object? getCurrentUserError;

  @override
  Stream<UserEntity?> get authStateChanges => _authStateController.stream;

  void emitAuthState(UserEntity? user) => _authStateController.add(user);

  @override
  Future<UserEntity?> getCurrentUser() async {
    if (getCurrentUserError != null) throw getCurrentUserError!;
    return currentUserToReturn;
  }

  @override
  Future<UserEntity> signInWithEmail({
    required String email,
    required String password,
  }) =>
      throw UnimplementedError();

  @override
  Future<UserEntity> registerWithEmail({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
    UserRole role = UserRole.buyer,
  }) =>
      throw UnimplementedError();

  @override
  Future<UserEntity> signInWithGoogle() => throw UnimplementedError();

  @override
  Future<void> signOut() async {}

  @override
  Future<void> sendPasswordResetEmail(String email) => throw UnimplementedError();

  @override
  Future<void> sendEmailVerification() => throw UnimplementedError();

  @override
  Future<UserEntity> updateProfile({
    String? fullName,
    String? bio,
    String? city,
    String? phoneNumber,
    String? avatarUrl,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> deleteAccount({String? password}) => throw UnimplementedError();

  void dispose() => _authStateController.close();
}

void main() {
  group('AuthCubit.checkAuthStatus — persistance de la session', () {
    test(
      'currentUser null puis authStateChanges émet un utilisateur → session restaurée',
      () async {
        final repo = FakeAuthRepository();
        final user = _fakeUser();
        final cubit = AuthCubit(repo);

        final future = cubit.checkAuthStatus();
        // Simule la restauration native de Firebase Auth, légèrement
        // différée par rapport au tout premier instant de runApp().
        await Future<void>.delayed(const Duration(milliseconds: 50));
        repo.emitAuthState(user);
        await future;

        expect(cubit.state, isA<AuthAuthenticated>());
        expect((cubit.state as AuthAuthenticated).user.id, user.id);

        await cubit.close();
        repo.dispose();
      },
    );

    test(
      'échec de lecture Firestore (getCurrentUser) après timeout du stream → '
      'reste quand même authentifié si un fallback existe',
      () async {
        final repo = FakeAuthRepository();
        final user = _fakeUser();
        // Le stream ne reçoit volontairement aucune émission ici, pour
        // forcer checkAuthStatus() vers son repli timeout → getCurrentUser().
        repo.currentUserToReturn = user;
        final cubit = AuthCubit(repo);

        await cubit.checkAuthStatus();

        expect(cubit.state, isA<AuthAuthenticated>());
        expect((cubit.state as AuthAuthenticated).user.id, user.id);

        await cubit.close();
        repo.dispose();
      },
      timeout: const Timeout(Duration(seconds: 12)),
    );
  });
}
