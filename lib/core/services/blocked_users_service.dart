// ─── Bamako Thrift — Blocage de vendeurs (acheteur) ───────────────────────
// Stocké dans users/{uid}/blocked_sellers/{sellerId}, lisible/modifiable
// uniquement par le propriétaire (voir firestore.rules) — aucun changement
// de règle sur une autre collection, aucune donnée visible par un tiers.
// Limite connue : un vendeur bloqué peut techniquement encore écrire dans
// une conversation déjà existante (le blocage ne touche pas les règles du
// chat) — seules ses conversations et ses articles disparaissent de
// l'affichage de l'acheteur qui l'a bloqué.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BlockedUsersService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  BlockedUsersService(this._firestore, this._auth);

  CollectionReference<Map<String, dynamic>> _col(String uid) => _firestore
      .collection('users')
      .doc(uid)
      .collection('blocked_sellers');

  String? get _currentUid => _auth.currentUser?.uid;

  /// Flux des sellerId bloqués par l'utilisateur courant — vide si non
  /// connecté (ne devrait pas arriver pour les écrans qui s'en servent).
  Stream<Set<String>> watchBlockedSellerIds() {
    final uid = _currentUid;
    if (uid == null) return Stream.value(const {});
    return _col(uid).snapshots().map((s) => s.docs.map((d) => d.id).toSet());
  }

  Future<Set<String>> getBlockedSellerIds() async {
    final uid = _currentUid;
    if (uid == null) return const {};
    final snap = await _col(uid).get();
    return snap.docs.map((d) => d.id).toSet();
  }

  /// Flux complet (id + nom enregistré au blocage), pour l'écran "Vendeurs
  /// bloqués" — watchBlockedSellerIds() ci-dessus suffit partout ailleurs.
  Stream<List<({String sellerId, String? sellerName})>> watchBlocked() {
    final uid = _currentUid;
    if (uid == null) return Stream.value(const []);
    return _col(uid).snapshots().map((s) => s.docs
        .map((d) => (
              sellerId: d.id,
              sellerName: d.data()['sellerName'] as String?,
            ))
        .toList());
  }

  Future<void> block(String sellerId, {String? sellerName}) async {
    final uid = _currentUid;
    if (uid == null) throw Exception('Utilisateur non connecté.');
    await _col(uid).doc(sellerId).set({
      'sellerName': sellerName,
      'blockedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> unblock(String sellerId) async {
    final uid = _currentUid;
    if (uid == null) throw Exception('Utilisateur non connecté.');
    await _col(uid).doc(sellerId).delete();
  }
}
