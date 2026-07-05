// ─── Bamako Thrift — Auth Repository (Domain Contract) ─────────────────────
import '../entities/user_entity.dart';

abstract class AuthRepository {
  /// Connexion email/mot de passe.
  Future<UserEntity> signInWithEmail({
    required String email,
    required String password,
  });

  /// Inscription email/mot de passe.
  Future<UserEntity> registerWithEmail({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
  });

  /// Connexion avec Google.
  Future<UserEntity> signInWithGoogle();

  /// Déconnexion.
  Future<void> signOut();

  /// Envoi email de réinitialisation de mot de passe.
  Future<void> sendPasswordResetEmail(String email);

  /// Envoi email de vérification.
  Future<void> sendEmailVerification();

  /// Récupère l'utilisateur actuellement connecté.
  Future<UserEntity?> getCurrentUser();

  /// Stream de l'état de connexion.
  Stream<UserEntity?> get authStateChanges;

  /// Met à jour le profil utilisateur.
  Future<UserEntity> updateProfile({
    String? fullName,
    String? bio,
    String? phoneNumber,
    String? avatarUrl,
  });

  /// Supprime le compte.
  Future<void> deleteAccount();
}
