// ─── Bamako Thrift — Auth Cubit ────────────────────────────────────────────
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/snackbar_service.dart';
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
  // Attend la première émission de authStateChanges (le flux qui reflète
  // fidèlement la restauration de session native de Firebase Auth, souvent
  // asynchrone au tout premier lancement) plutôt que de lire currentUser de
  // façon synchrone — sinon une session pourtant valide peut être lue comme
  // "non connectée" si la lecture arrive avant la fin de la restauration.
  Future<void> checkAuthStatus() async {
    emit(const AuthLoading());
    try {
      bool timedOut = false;
      final user = await _authRepository.authStateChanges.first.timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          timedOut = true;
          return null;
        },
      );

      if (timedOut) {
        // Le flux n'a rien émis à temps : on retombe sur une lecture directe,
        // qui sait elle-même rester tolérante aux erreurs transitoires.
        final fallbackUser = await _authRepository.getCurrentUser();
        emit(fallbackUser != null
            ? AuthAuthenticated(fallbackUser)
            : const AuthUnauthenticated());
        return;
      }

      emit(user != null ? AuthAuthenticated(user) : const AuthUnauthenticated());
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
  // Optimiste : affiche tout de suite la version à jour (copyWith local),
  // sans AuthLoading global (qui ferait clignoter tout écran écoutant ce
  // cubit pour un simple changement de profil). L'écriture Firestore/Auth
  // part en arrière-plan ; en cas d'échec on restaure l'ancienne valeur et
  // on avertit via SnackBarService (pas ScaffoldMessenger.of(context) : la
  // page qui a appelé ceci a pu être quittée avant la fin de l'écriture —
  // sauvegarde optimiste côté edit_profile_page.dart).
  Future<bool> updateProfile({
    String? fullName,
    String? bio,
    String? city,
    String? phoneNumber,
    String? avatarUrl,
  }) async {
    final current = state;
    if (current is! AuthAuthenticated) return false;
    final previousUser = current.user;

    final optimisticUser = previousUser.copyWith(
      fullName: fullName,
      bio: bio,
      city: city,
      phoneNumber: phoneNumber,
      avatarUrl: avatarUrl,
    );
    emit(AuthAuthenticated(optimisticUser));

    try {
      await _authRepository.updateProfile(
        fullName: fullName,
        bio: bio,
        city: city,
        phoneNumber: phoneNumber,
        avatarUrl: avatarUrl,
      );
      return true;
    } catch (e) {
      emit(AuthAuthenticated(previousUser));
      SnackBarService.instance
          .showError('La mise à jour du profil a échoué. Réessaie.');
      return false;
    }
  }

  // ── Suppression de compte ────────────────────────────────────────────────
  Future<bool> deleteAccount({String? password}) async {
    emit(const AuthLoading());
    try {
      await _authRepository.deleteAccount(password: password);
      emit(const AuthUnauthenticated());
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
