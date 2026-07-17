// ─── Bamako Thrift — Auth Repository Implementation ─────────────────────────
// Implémentation complète Firebase Auth + Firestore
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';

class FirebaseAuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  FirebaseAuthRepositoryImpl(this._auth, this._firestore);

  // ── Collection référence ────────────────────────────────────────────────
  CollectionReference<Map<String, dynamic>> get _usersCol =>
      _firestore.collection('users');

  // ── Stream auth ─────────────────────────────────────────────────────────
  @override
  Stream<UserEntity?> get authStateChanges {
    return _auth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;
      return _fetchUserFromFirestore(firebaseUser.uid);
    });
  }

  // ── Utilisateur courant ──────────────────────────────────────────────────
  @override
  Future<UserEntity?> getCurrentUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;
    return _fetchUserFromFirestore(firebaseUser.uid);
  }

  // ── Connexion email/password ───────────────────────────────────────────
  @override
  Future<UserEntity> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final firebaseUser = credential.user!;
      final uid = firebaseUser.uid;

      // Chercher le profil dans Firestore
      UserModel? user = await _fetchUserFromFirestore(uid);

      // ⚠️ Si le doc n'existe pas (compte créé avant Firestore ou inscription incomplète)
      // → On le crée automatiquement à partir des infos FirebaseAuth
      if (user == null) {
        final now = DateTime.now();
        final newUser = UserModel(
          id: uid,
          email: firebaseUser.email ?? email.trim(),
          fullName: firebaseUser.displayName ?? email.split('@').first,
          role: UserRole.buyer,
          isEmailVerified: firebaseUser.emailVerified,
          isActive: true,
          createdAt: now,
        );
        final data = newUser.toJson()..remove('id');
        data['createdAt'] = FieldValue.serverTimestamp();
        await _usersCol.doc(uid).set(data);
        return newUser;
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapFirebaseAuthError(e.code));
    }
  }

  // ── Inscription ────────────────────────────────────────────────────
  @override
  Future<UserEntity> registerWithEmail({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
    UserRole role = UserRole.buyer,
  }) async {
    String? uid;
    try {
      // 1. Créer le compte Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      uid = credential.user!.uid;

      // 2. Mettre à jour le displayName dans Firebase Auth
      await credential.user!.updateDisplayName(fullName.trim());

      // 3. Construire le modèle utilisateur
      final now = DateTime.now();
      final userModel = UserModel(
        id: uid,
        email: email.trim(),
        fullName: fullName.trim(),
        phoneNumber: phoneNumber?.trim(),
        role: role,
        isEmailVerified: false,
        isActive: true,
        createdAt: now,
      );

      // 4. Écrire dans Firestore (séparé du catch FirebaseAuthException)
      final data = userModel.toJson()..remove('id');
      data['createdAt'] = FieldValue.serverTimestamp();
      await _usersCol.doc(uid).set(data);

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapFirebaseAuthError(e.code));
    } catch (e) {
      // Si l'écriture Firestore échoue après la création Auth,
      // on tente quand même de retourner un utilisateur minimal
      // pour ne pas bloquer l'UX. La synchro se fera au prochain login.
      if (uid != null) {
        return UserModel(
          id: uid,
          email: email.trim(),
          fullName: fullName.trim(),
          phoneNumber: phoneNumber?.trim(),
          role: role,
          isEmailVerified: false,
          isActive: true,
          createdAt: DateTime.now(),
        );
      }
      throw Exception('Erreur lors de la création du compte : ${e.toString()}');
    }
  }

  // ── Connexion Google ─────────────────────────────────────────────────────
  @override
  Future<UserEntity> signInWithGoogle() {
    throw UnimplementedError('Google Sign-In pas encore implémenté.');
  }

  // ── Déconnexion ──────────────────────────────────────────────────────────
  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ── Réinitialisation mot de passe ────────────────────────────────────────
  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapFirebaseAuthError(e.code));
    }
  }

  // ── Vérification email ───────────────────────────────────────────────────
  @override
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  // ── Mise à jour profil ───────────────────────────────────────────────────
  @override
  Future<UserEntity> updateProfile({
    String? fullName,
    String? bio,
    String? phoneNumber,
    String? avatarUrl,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Utilisateur non connecté.');

    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (fullName != null) updates['fullName'] = fullName.trim();
    if (bio != null) updates['bio'] = bio.trim();
    if (phoneNumber != null) updates['phoneNumber'] = phoneNumber.trim();
    if (avatarUrl != null) updates['avatarUrl'] = avatarUrl;

    await _usersCol.doc(uid).update(updates);

    // Mettre à jour Firebase Auth displayName si nécessaire
    if (fullName != null) {
      await _auth.currentUser!.updateDisplayName(fullName.trim());
    }

    final updated = await _fetchUserFromFirestore(uid);
    if (updated == null) throw Exception('Profil introuvable.');
    return updated;
  }

  // ── Suppression compte ───────────────────────────────────────────────────
  @override
  Future<void> deleteAccount() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Utilisateur non connecté.');

    // Supprimer le doc Firestore d'abord
    await _usersCol.doc(uid).delete();

    // Supprimer le compte Firebase Auth
    await _auth.currentUser!.delete();
  }

  // ── Helpers privés ───────────────────────────────────────────────────────

  /// Récupère le UserModel depuis Firestore par uid.
  Future<UserModel?> _fetchUserFromFirestore(String uid) async {
    final doc = await _usersCol.doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;

    final data = doc.data()!;
    // Convertir Timestamp → int pour fromFirestore
    _convertTimestamps(data);

    return UserModel.fromFirestore(data, uid);
  }

  /// Convertit les Timestamp Firestore en millisecondes (int).
  void _convertTimestamps(Map<String, dynamic> data) {
    if (data['createdAt'] is Timestamp) {
      data['createdAt'] =
          (data['createdAt'] as Timestamp).millisecondsSinceEpoch;
    }
    if (data['updatedAt'] is Timestamp) {
      data['updatedAt'] =
          (data['updatedAt'] as Timestamp).millisecondsSinceEpoch;
    }
  }

  /// Traduit les codes d'erreur Firebase en messages français.
  String _mapFirebaseAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Aucun compte trouvé avec cet email.';
      case 'wrong-password':
        return 'Mot de passe incorrect.';
      case 'invalid-credential':
        return 'Email ou mot de passe incorrect.';
      case 'email-already-in-use':
        return 'Cet email est déjà utilisé.';
      case 'weak-password':
        return 'Le mot de passe doit faire au moins 6 caractères.';
      case 'invalid-email':
        return 'Adresse email invalide.';
      case 'user-disabled':
        return 'Ce compte a été désactivé.';
      case 'too-many-requests':
        return 'Trop de tentatives. Réessayez plus tard.';
      case 'network-request-failed':
        return 'Erreur réseau. Vérifiez votre connexion.';
      default:
        return 'Une erreur est survenue. Réessayez.';
    }
  }
}
