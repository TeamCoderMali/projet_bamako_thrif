// ─── Bamako Thrift — Auth Cubit ────────────────────────────────────────────
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../bloc/auth_state.dart';

export '../bloc/auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;

  AuthCubit(AuthRepository authRepository)
      : _authRepository = authRepository,
        super(const AuthInitial());

  // ── Vérification de l'état d'auth au démarrage ──────────────────────────
  Future<void> checkAuthStatus() async {
    emit(const AuthLoading());
    try {
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (_) {
      emit(const AuthUnauthenticated());
    }
  }

  // ── Connexion email ──────────────────────────────────────────────────────
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    emit(const AuthLoading());
    try {
      final user = await _authRepository.signInWithEmail(
        email: email,
        password: password,
      );
      emit(AuthAuthenticated(user));
      return true;
    } catch (e) {
      emit(AuthError(e.toString().replaceFirst('Exception: ', '')));
      return false;
    }
  }

  // ── Inscription ──────────────────────────────────────────────────────────
  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
    UserRole role = UserRole.buyer,
  }) async {
    emit(const AuthLoading());
    try {
      final user = await _authRepository.registerWithEmail(
        email: email,
        password: password,
        fullName: fullName,
        phoneNumber: phoneNumber,
        role: role,
      );
      emit(AuthAuthenticated(user));
      return true;
    } catch (e) {
      emit(AuthError(e.toString().replaceFirst('Exception: ', '')));
      return false;
    }
  }

  // ── Connexion Google ─────────────────────────────────────────────────────
  Future<void> signInWithGoogle() async {
    emit(const AuthLoading());
    try {
      final user = await _authRepository.signInWithGoogle();
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  // ── Déconnexion ──────────────────────────────────────────────────────────
  Future<void> signOut() async {
    emit(const AuthLoading());
    try {
      await _authRepository.signOut();
      emit(const AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  // ── Réinitialisation mot de passe ────────────────────────────────────────
  Future<bool> sendPasswordReset(String email) async {
    emit(const AuthLoading());
    try {
      await _authRepository.sendPasswordResetEmail(email);
      emit(const AuthUnauthenticated());
      return true;
    } catch (e) {
      emit(AuthError(e.toString().replaceFirst('Exception: ', '')));
      return false;
    }
  }

  // ── Mise à jour profil ───────────────────────────────────────────────────
  Future<bool> updateProfile({
    String? fullName,
    String? bio,
    String? phoneNumber,
    String? avatarUrl,
  }) async {
    emit(const AuthLoading());
    try {
      final user = await _authRepository.updateProfile(
        fullName: fullName,
        bio: bio,
        phoneNumber: phoneNumber,
        avatarUrl: avatarUrl,
      );
      emit(AuthAuthenticated(user));
      return true;
    } catch (e) {
      emit(AuthError(e.toString().replaceFirst('Exception: ', '')));
      return false;
    }
  }

  // ── Utilisateur courant (convenience getter) ─────────────────────────────
  UserEntity? get currentUser {
    final s = state;
    return s is AuthAuthenticated ? s.user : null;
  }
}
