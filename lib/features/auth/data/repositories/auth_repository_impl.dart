// ─── Bamako Thrift — Auth Repository Implementation ─────────────────────────
// Implémentation complète Firebase Auth + Firestore
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';

/// Sanction confirmée (banni/suspendu) — seule raison légitime de
/// déconnecter réellement l'utilisateur au démarrage. Distincte de toute
/// autre erreur (réseau, timeout, permission transitoire) pour que
/// getCurrentUser()/authStateChanges sachent QUAND déconnecter pour de bon.
class AccountSanctionedException implements Exception {
  final String message;
  const AccountSanctionedException(this.message);
  @override
  String toString() => 'Exception: $message';
}

class FirebaseAuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  // Sur le web, google_sign_in_web exige un clientId explicite (meta tag ou
  // paramètre) — sans ça : "Null check operator used on a null value" en
  // release (le garde-fou du plugin est un assert(), muet hors debug).
  // Client OAuth "Web" déjà existant du projet bamako-thrif (Firebase
  // Authentication > Google), le même que celui utilisé par Firebase Auth
  // côté serveur — rien de nouveau créé. Android/iOS inchangés : clientId
  // reste null, ils utilisent leur config native (google-services.json /
  // GoogleService-Info.plist).
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb
        ? '84148343844-k6k8d8sv4ppskucc1s7mdjllk2e12buk.apps.googleusercontent.com'
        : null,
  );

  FirebaseAuthRepositoryImpl(this._auth, this._firestore);

  // ── Collection référence ────────────────────────────────────────────────
  CollectionReference<Map<String, dynamic>> get _usersCol =>
      _firestore.collection('users');

  // Champs jamais exposés aux autres utilisateurs (contrairement au reste du
  // profil, public pour la marketplace/le chat) : stockés dans une
  // sous-collection privée, lisible uniquement par le propriétaire (+ admin).
  static const _privateFields = ['email', 'phoneNumber', 'isEmailVerified'];

  DocumentReference<Map<String, dynamic>> _privateDoc(String uid) =>
      _usersCol.doc(uid).collection('private').doc('data');

  /// Crée le document utilisateur (profil public + données privées) en une
  /// seule opération atomique.
  Future<void> _createUserDoc(String uid, UserModel user) async {
    final json = user.toJson()..remove('id');
    final privateData = <String, dynamic>{};
    for (final key in _privateFields) {
      if (json.containsKey(key)) privateData[key] = json.remove(key);
    }
    json['createdAt'] = FieldValue.serverTimestamp();

    final batch = _firestore.batch();
    batch.set(_usersCol.doc(uid), json);
    batch.set(_privateDoc(uid), privateData);
    await batch.commit();
  }

  // ── Stream auth ─────────────────────────────────────────────────────────
  // Le flux natif peut aussi émettre une erreur (pas seulement une valeur),
  // typiquement quand le SDK détecte au rafraîchissement du token que le
  // compte a été désactivé/supprimé côté serveur. On ne déconnecte alors
  // réellement que pour ces codes d'erreur d'authentification explicites —
  // jamais pour une erreur réseau/permission transitoire, qui ne doit rien
  // émettre et laisser le repli getCurrentUser() de checkAuthStatus() agir.
  static const _explicitAuthFailureCodes = {
    'user-disabled',
    'user-not-found',
    'user-token-expired',
  };

  @override
  Stream<UserEntity?> get authStateChanges {
    late StreamController<UserEntity?> controller;
    StreamSubscription<User?>? sub;

    controller = StreamController<UserEntity?>.broadcast(
      onListen: () {
        sub = _auth.authStateChanges().listen(
          (firebaseUser) async {
            if (firebaseUser == null) {
              controller.add(null);
              return;
            }
            try {
              controller.add(await _resolveUser(firebaseUser));
            } on AccountSanctionedException {
              controller.add(null);
            }
          },
          onError: (Object error) async {
            if (error is FirebaseAuthException &&
                _explicitAuthFailureCodes.contains(error.code)) {
              await _auth.signOut();
              controller.add(null);
            }
          },
        );
      },
      onCancel: () => sub?.cancel(),
    );

    return controller.stream;
  }

  // ── Utilisateur courant ──────────────────────────────────────────────────
  @override
  Future<UserEntity?> getCurrentUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;

    try {
      return await _resolveUser(firebaseUser);
    } on AccountSanctionedException {
      return null;
    }
  }

  /// Résout un [UserModel] à partir d'un utilisateur Firebase déjà connecté,
  /// de façon robuste : une panne réseau/Firestore transitoire ne doit
  /// JAMAIS se traduire par une déconnexion ou un retour "non connecté" —
  /// seule une sanction confirmée (banni/suspendu) le fait, en relançant
  /// [AccountSanctionedException] pour que l'appelant sache déconnecter
  /// pour de vrai.
  Future<UserModel> _resolveUser(User firebaseUser) async {
    final uid = firebaseUser.uid;

    try {
      await _enforceSanctions(uid);
    } on AccountSanctionedException {
      rethrow;
    } catch (_) {
      // Sanction non vérifiable (réseau/permission) : on laisse passer,
      // ce n'est pas une preuve de bannissement.
    }

    try {
      final fetched =
          await _fetchUserFromFirestore(uid).timeout(const Duration(seconds: 8));
      if (fetched != null) return fetched;
    } catch (_) {
      // Lecture Firestore indisponible : on continue avec un profil minimal
      // plutôt que de perdre la session.
    }

    // Retente en arrière-plan pour réchauffer le cache Firestore, sans
    // bloquer ni affecter la session en cours.
    unawaited(_retryFetchUserInBackground(uid));

    return UserModel(
      id: uid,
      email: firebaseUser.email ?? '',
      fullName: firebaseUser.displayName ??
          (firebaseUser.email?.split('@').first ?? 'Utilisateur DANAYA'),
      isEmailVerified: firebaseUser.emailVerified,
      isActive: true,
      createdAt: DateTime.now(),
    );
  }

  /// Relance silencieusement la lecture Firestore, résultat ignoré : ne sert
  /// qu'à réchauffer le cache local pour la prochaine tentative.
  Future<void> _retryFetchUserInBackground(String uid) async {
    try {
      await _fetchUserFromFirestore(uid);
    } catch (_) {
      // Ignoré : tentative de confort, pas critique.
    }
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
        await _createUserDoc(uid, newUser);
        return newUser;
      }

      // Vérifie que le compte n'est ni banni ni suspendu avant de laisser entrer
      await _enforceSanctions(uid);

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
      await _createUserDoc(uid, userModel);

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
  Future<UserEntity> signInWithGoogle() async {
    try {
      // 1. Ouvre le sélecteur de compte Google
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // L'utilisateur a annulé la sélection du compte
        throw Exception('Connexion Google annulée.');
      }

      // 2. Récupère les tokens d'authentification Google
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 3. Connecte l'utilisateur à Firebase avec ces tokens
      final userCredential = await _auth.signInWithCredential(credential);
      final firebaseUser = userCredential.user!;
      final uid = firebaseUser.uid;

      // 4. Vérifie si un profil Firestore existe déjà pour cet utilisateur
      UserModel? user = await _fetchUserFromFirestore(uid);

      // 5. Première connexion Google → on crée le profil Firestore
      if (user == null) {
        final now = DateTime.now();
        final newUser = UserModel(
          id: uid,
          email: firebaseUser.email ?? '',
          fullName: firebaseUser.displayName ?? 'Utilisateur DANAYA',
          avatarUrl: firebaseUser.photoURL,
          role: UserRole.buyer,
          isEmailVerified: firebaseUser.emailVerified,
          isActive: true,
          createdAt: now,
        );
        await _createUserDoc(uid, newUser);
        return newUser;
      }

      // Vérifie que le compte n'est ni banni ni suspendu avant de laisser entrer
      await _enforceSanctions(uid);

      return user;
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapFirebaseAuthError(e.code));
    } catch (_) {
      // Jamais le message technique brut à l'écran (ex. "Null check
      // operator used on a null value" côté web) — texte simple, tutoiement.
      throw Exception(
          'Connexion Google impossible pour le moment. Réessaie ou connecte-toi avec ton email.');
    }
  }

  // ── Déconnexion ──────────────────────────────────────────────────────────
  @override
  Future<void> signOut() async {
    // Déconnecte aussi de Google si l'utilisateur s'était connecté ainsi
    // (sinon le sélecteur de compte Google réaffiche le même compte
    // automatiquement à la prochaine tentative, sans laisser le choix).
    if (await _googleSignIn.isSignedIn()) {
      await _googleSignIn.signOut();
    }
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
    String? city,
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
    if (city != null) updates['city'] = city.trim();
    if (avatarUrl != null) updates['avatarUrl'] = avatarUrl;
    await _usersCol.doc(uid).update(updates);

    if (phoneNumber != null) {
      await _privateDoc(uid).set(
        {'phoneNumber': phoneNumber.trim()},
        SetOptions(merge: true),
      );
    }

    // Mettre à jour Firebase Auth displayName si nécessaire
    if (fullName != null) {
      await _auth.currentUser!.updateDisplayName(fullName.trim());
    }

    final updated = await _fetchUserFromFirestore(uid);
    if (updated == null) throw Exception('Profil introuvable.');
    return updated;
  }

  // ── Suppression compte ───────────────────────────────────────────────────
  // Décision (2026-10-16) : on anonymise, on ne supprime jamais les docs
  // Firestore référencés par d'autres personnes (articles, commandes,
  // messages) — supprimer users/{uid} casserait l'affichage du nom/avatar
  // vendeur chez tous ses acheteurs passés, et la suppression de product/
  // casserait l'historique de commande de l'acheteur. Seul le compte
  // Firebase Auth lui-même est réellement supprimé.
  @override
  Future<void> deleteAccount({String? password}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Utilisateur non connecté.');
    final uid = user.uid;

    // Comptes admin/relais (admin_users/{uid}, back-office) : jamais
    // supprimables depuis l'app mobile — distinct de users/{uid}, voir
    // firestore.rules (isAdmin()/isRelayManager()).
    final adminDoc = await _firestore.collection('admin_users').doc(uid).get();
    if (adminDoc.exists) {
      throw Exception(
          'Les comptes administrateur ne peuvent pas être supprimés depuis l\'application.');
    }

    await _reauthenticate(user, password: password);
    await _assertNoPendingActivity(uid);

    // Articles disponibles du vendeur -> masqués (inactive), pas supprimés
    // (gardés pour l'historique des commandes déjà passées sur ces articles).
    final products = await _firestore
        .collection('product')
        .where('sellerId', isEqualTo: uid)
        .where('status', isEqualTo: 'available')
        .get();
    if (products.docs.isNotEmpty) {
      final batch = _firestore.batch();
      for (final doc in products.docs) {
        batch.update(doc.reference, {'status': 'inactive'});
      }
      await batch.commit();
    }

    // Profil anonymisé (pas supprimé) : le nom/avatar affichés chez les
    // autres (commandes, messages passés) deviennent neutres sans casser
    // ces références.
    await _usersCol.doc(uid).set({
      'fullName': 'Utilisateur supprimé',
      'avatarUrl': null,
      'bio': null,
      'isActive': false,
      'deletedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _privateDoc(uid).set({
      'email': null,
      'phoneNumber': null,
    }, SetOptions(merge: true));

    // Compte Firebase Auth réellement supprimé.
    if (await _googleSignIn.isSignedIn()) {
      await _googleSignIn.signOut();
    }
    await user.delete();
  }

  /// Réauthentifie l'utilisateur avant la suppression (Firebase l'exige dès
  /// que la session n'est plus "récente"). Mot de passe si le compte a ce
  /// provider, sinon Google (seul autre provider supporté par l'app).
  Future<void> _reauthenticate(User user, {String? password}) async {
    final hasPasswordProvider =
        user.providerData.any((p) => p.providerId == 'password');
    try {
      if (hasPasswordProvider) {
        if (password == null || password.isEmpty) {
          throw Exception('Mot de passe requis pour confirmer la suppression.');
        }
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: password,
        );
        await user.reauthenticateWithCredential(credential);
      } else {
        final googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          throw Exception('Confirmation Google annulée.');
        }
        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await user.reauthenticateWithCredential(credential);
      }
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapFirebaseAuthError(e.code));
    }
  }

  /// Bloque la suppression si une commande en cours, une offre ouverte ou un
  /// litige ouvert existe encore pour cet utilisateur (acheteur ou vendeur).
  Future<void> _assertNoPendingActivity(String uid) async {
    const blockedMessage =
        'Termine tes commandes en cours avant de supprimer ton compte.';

    // Un seul filtre d'égalité par requête (pas de "where" combiné sur un
    // second champ) : évite de dépendre d'un index composite qui n'existe
    // peut-être pas encore pour cette forme de requête précise (le fichier
    // firestore.indexes.json local s'est déjà révélé désynchronisé des
    // index réellement déployés, même constat que pour firestore.rules).
    const openOrderStatuses = {'pending', 'collecte'};
    final ordersAsBuyer =
        await _firestore.collection('order').where('buyerId', isEqualTo: uid).get();
    if (ordersAsBuyer.docs
        .any((d) => openOrderStatuses.contains(d.data()['status']))) {
      throw Exception(blockedMessage);
    }

    final ordersAsSeller = await _firestore
        .collection('order')
        .where('sellerId', isEqualTo: uid)
        .get();
    if (ordersAsSeller.docs
        .any((d) => openOrderStatuses.contains(d.data()['status']))) {
      throw Exception(blockedMessage);
    }

    final offersAsBuyer =
        await _firestore.collection('offers').where('buyerId', isEqualTo: uid).get();
    if (offersAsBuyer.docs.any((d) => d.data()['status'] == 'pending')) {
      throw Exception(blockedMessage);
    }

    final offersAsSeller = await _firestore
        .collection('offers')
        .where('sellerId', isEqualTo: uid)
        .get();
    if (offersAsSeller.docs.any((d) => d.data()['status'] == 'pending')) {
      throw Exception(blockedMessage);
    }

    // non_conformities n'a pas de statut de clôture consulté par l'app (le
    // back-office traite les litiges dans une collection "disputes" séparée,
    // jamais reliée à non_conformities) — on bloque donc dès qu'un
    // signalement existe pour cet utilisateur, résolu ou non.
    final disputesAsBuyer = await _firestore
        .collection('non_conformities')
        .where('buyerId', isEqualTo: uid)
        .limit(1)
        .get();
    if (disputesAsBuyer.docs.isNotEmpty) throw Exception(blockedMessage);

    final disputesAsSeller = await _firestore
        .collection('non_conformities')
        .where('sellerId', isEqualTo: uid)
        .limit(1)
        .get();
    if (disputesAsSeller.docs.isNotEmpty) throw Exception(blockedMessage);
  }

  // ── Helpers privés ───────────────────────────────────────────────────────

  /// Vérifie que le compte n'est ni banni ni suspendu.
  /// Déconnecte l'utilisateur et lance une exception avec un message clair
  /// si c'est le cas (cahier des charges 2.3 : sanctions automatiques).
  Future<void> _enforceSanctions(String uid) async {
    final DocumentSnapshot<Map<String, dynamic>> doc;
    try {
      doc = await _usersCol.doc(uid).get().timeout(const Duration(seconds: 8));
    } catch (_) {
      // Lecture impossible (réseau, timeout, permission transitoire) : on ne
      // peut pas vérifier le statut de bannissement, mais ça ne prouve rien
      // contre l'utilisateur — on laisse passer plutôt que de le déconnecter.
      return;
    }
    if (!doc.exists) return;
    final data = doc.data();
    if (data == null) return;

    final isBanned = data['isBanned'] as bool? ?? false;
    if (isBanned) {
      await _auth.signOut();
      throw const AccountSanctionedException(
        'Ce compte a été banni suite à plusieurs non-conformités constatées. '
        'Contactez le support pour plus d\'informations.',
      );
    }

    final suspendedUntil = data['suspendedUntil'];
    if (suspendedUntil is Timestamp) {
      final until = suspendedUntil.toDate();
      if (until.isAfter(DateTime.now())) {
        await _auth.signOut();
        final d = until.day.toString().padLeft(2, '0');
        final m = until.month.toString().padLeft(2, '0');
        throw AccountSanctionedException(
          'Ce compte est suspendu jusqu\'au $d/$m/${until.year} '
          'suite à plusieurs non-conformités constatées.',
        );
      }
    }
  }

  /// Récupère le UserModel depuis Firestore par uid (profil public fusionné
  /// avec les données privées — uniquement lisibles par le propriétaire).
  Future<UserModel?> _fetchUserFromFirestore(String uid) async {
    final doc = await _usersCol.doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;

    final data = Map<String, dynamic>.from(doc.data()!);

    final privateSnap = await _privateDoc(uid).get();
    if (privateSnap.exists && privateSnap.data() != null) {
      data.addAll(privateSnap.data()!);
    }

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
        return 'Trop de tentatives. Réessaie plus tard.';
      case 'network-request-failed':
        return 'Erreur réseau. Vérifie ta connexion.';
      default:
        return 'Une erreur est survenue. Réessaie.';
    }
  }
}
