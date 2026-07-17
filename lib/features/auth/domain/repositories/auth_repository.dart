// ─── Bamako Thrift — Auth Repository (Domain Contract) ─────────────────────
import '../entities/user_entity.dart';

abstract class AuthRepository {
  /// Stream de l'état de connexion (UserEntity ou null).
  Stream<UserEntity?> get authStateChanges;

  /// Récupère l'utilisateur actuellement connecté (null si non connecté).
  Future<UserEntity?> getCurrentUser();

  /// Connexion email/mot de passe → retourne le UserEntity.
  Future<UserEntity> signInWithEmail({
    required String email,
    required String password,
  });

  /// Inscription email/mot de passe → crée le doc Firestore → retourne UserEntity.
  Future<UserEntity> registerWithEmail({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
    UserRole role,
  });

  /// Connexion avec Google.
  Future<UserEntity> signInWithGoogle();

  /// Déconnexion.
  Future<void> signOut();

  /// Envoi email de réinitialisation de mot de passe.
  Future<void> sendPasswordResetEmail(String email);

  /// Envoi email de vérification.
  Future<void> sendEmailVerification();

  /// Met à jour le profil utilisateur (Firestore + FirebaseAuth displayName).
  Future<UserEntity> updateProfile({
    String? fullName,
    String? bio,
    String? phoneNumber,
    String? avatarUrl,
  });

  /// Supprime le compte (Firestore + Firebase Auth).
  Future<void> deleteAccount();
}
