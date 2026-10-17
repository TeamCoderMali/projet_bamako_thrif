// ─── Bamako Thrift — Offers Repository Implementation ──────────────────────
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/services/offers_config_service.dart';
import '../../domain/entities/offer_entity.dart';
import '../../domain/repositories/offers_repository.dart';
import '../models/offer_model.dart';

class OffersRepositoryImpl implements OffersRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final OffersConfigService _configService;

  OffersRepositoryImpl(
    this._firestore, [
    FirebaseAuth? auth,
    OffersConfigService? configService,
  ])  : _auth = auth ?? FirebaseAuth.instance,
        _configService = configService ?? OffersConfigService.instance;

  CollectionReference<Map<String, dynamic>> get _offersCol =>
      _firestore.collection('offers');

  String? get _currentUid => _auth.currentUser?.uid;

  static Map<String, dynamic> _historyEntryToMap(OfferHistoryEntry e) => {
        'round': e.round,
        'by': e.by.name,
        'action': e.action.name,
        'price': e.price,
        'at': Timestamp.fromDate(e.at),
      };

  @override
  Future<OfferEntity?> getOffer({
    required String productId,
    required String buyerId,
  }) async {
    final id = OfferModel.buildId(productId: productId, buyerId: buyerId);
    final snap = await _offersCol.doc(id).get();
    if (!snap.exists || snap.data() == null) return null;
    return OfferModel.fromFirestore(snap.data()!, id);
  }

  @override
  Stream<OfferEntity?> watchOffer(String offerId) {
    return _offersCol.doc(offerId).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return OfferModel.fromFirestore(snap.data()!, offerId);
    });
  }

  @override
  Stream<List<OfferEntity>> watchBuyerOffers(String buyerId) {
    // Tri côté client (pas de orderBy serveur) : évite de dépendre d'un
    // champ (updatedAt) absent sur les offres jamais encore modifiées.
    return _offersCol.where('buyerId', isEqualTo: buyerId).snapshots().map(
        (snap) {
      final list = snap.docs
          .map((d) => OfferModel.fromFirestore(d.data(), d.id))
          .toList();
      list.sort((a, b) =>
          (b.updatedAt ?? b.createdAt).compareTo(a.updatedAt ?? a.createdAt));
      return list;
    });
  }

  @override
  Future<void> createOrRelance({
    required String productId,
    required String productTitle,
    String? productImageUrl,
    required String sellerId,
    required String buyerId,
    required double originalPrice,
    required double offerPrice,
    String? chatId,
  }) async {
    final id = OfferModel.buildId(productId: productId, buyerId: buyerId);
    final docRef = _offersCol.doc(id);

    // La config et l'état existant sont indépendants (audit lenteurs du
    // 2026-10-17) : en parallèle plutôt qu'en série.
    final results = await Future.wait([
      _configService.getConfig(),
      docRef.get(),
    ]);
    final config = results[0] as OffersConfig;
    final existing = results[1] as DocumentSnapshot<Map<String, dynamic>>;

    final now = DateTime.now();
    final respondBy = now.add(Duration(hours: config.responseDeadlineHours));

    final historyEntry = OfferHistoryEntry(
      round: 1,
      by: OfferTurn.buyer,
      action: OfferHistoryAction.offer,
      price: offerPrice,
      at: now,
    );

    if (!existing.exists) {
      final offer = OfferModel(
        id: id,
        productId: productId,
        productTitle: productTitle,
        productImageUrl: productImageUrl,
        sellerId: sellerId,
        buyerId: buyerId,
        originalPrice: originalPrice,
        currentPrice: offerPrice,
        chatId: chatId,
        respondBy: respondBy,
        history: [historyEntry],
        createdAt: now,
      );
      await docRef.set(offer.toFirestore());
      return;
    }

    final data = existing.data()!;
    final currentOffer = OfferModel.fromFirestore(data, id);
    if (currentOffer.status != OfferStatus.rejected &&
        currentOffer.status != OfferStatus.cancelled &&
        currentOffer.status != OfferStatus.expired) {
      throw OfferAlreadyActiveException(currentOffer.status);
    }

    await docRef.update({
      'status': OfferStatus.pending.name,
      'round': 1,
      'turn': OfferTurn.seller.name,
      'currentPrice': offerPrice,
      'respondBy': Timestamp.fromDate(respondBy),
      'updatedAt': Timestamp.fromDate(now),
      'history': [...currentOffer.history, historyEntry]
          .map(_historyEntryToMap)
          .toList(),
    });
  }

  /// Qui agit : compare l'uid courant au couple acheteur/vendeur de
  /// l'offre. Les règles Firestore vérifient déjà que seule la bonne
  /// partie peut écrire ; ceci sert uniquement à renseigner "by" dans
  /// l'historique.
  OfferTurn _actorOf(OfferEntity offer) {
    return _currentUid == offer.buyerId ? OfferTurn.buyer : OfferTurn.seller;
  }

  @override
  Future<void> accept(String offerId) async {
    final docRef = _offersCol.doc(offerId);
    final snap = await docRef.get();
    if (!snap.exists) return;
    final offer = OfferModel.fromFirestore(snap.data()!, offerId);

    final entry = OfferHistoryEntry(
      round: offer.round,
      by: _actorOf(offer),
      action: OfferHistoryAction.accept,
      price: offer.currentPrice,
      at: DateTime.now(),
    );
    await docRef.update({
      'status': OfferStatus.accepted.name,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
      'history': [...offer.history, entry].map(_historyEntryToMap).toList(),
    });
  }

  @override
  Future<void> reject(String offerId) async {
    final docRef = _offersCol.doc(offerId);
    final snap = await docRef.get();
    if (!snap.exists) return;
    final offer = OfferModel.fromFirestore(snap.data()!, offerId);

    final entry = OfferHistoryEntry(
      round: offer.round,
      by: _actorOf(offer),
      action: OfferHistoryAction.reject,
      price: offer.currentPrice,
      at: DateTime.now(),
    );
    await docRef.update({
      'status': OfferStatus.rejected.name,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
      'history': [...offer.history, entry].map(_historyEntryToMap).toList(),
    });
  }

  @override
  Future<void> counter({
    required String offerId,
    required double newPrice,
  }) async {
    final docRef = _offersCol.doc(offerId);
    final snap = await docRef.get();
    if (!snap.exists) return;
    final offer = OfferModel.fromFirestore(snap.data()!, offerId);
    final config = await _configService.getConfig();
    final now = DateTime.now();

    final actor = _actorOf(offer);
    final newTurn = actor == OfferTurn.seller ? OfferTurn.buyer : OfferTurn.seller;

    final entry = OfferHistoryEntry(
      round: offer.round + 1,
      by: actor,
      action: OfferHistoryAction.counter,
      price: newPrice,
      at: now,
    );
    await docRef.update({
      'status': OfferStatus.pending.name,
      'round': offer.round + 1,
      'turn': newTurn.name,
      'currentPrice': newPrice,
      // Nouveau délai complet pour la partie qui doit désormais répondre.
      'respondBy':
          Timestamp.fromDate(now.add(Duration(hours: config.responseDeadlineHours))),
      'updatedAt': Timestamp.fromDate(now),
      'history': [...offer.history, entry].map(_historyEntryToMap).toList(),
    });
  }

  @override
  Future<void> cancel(String offerId) async {
    final docRef = _offersCol.doc(offerId);
    final snap = await docRef.get();
    if (!snap.exists) return;
    final offer = OfferModel.fromFirestore(snap.data()!, offerId);

    final entry = OfferHistoryEntry(
      round: offer.round,
      by: OfferTurn.buyer,
      action: OfferHistoryAction.cancel,
      price: offer.currentPrice,
      at: DateTime.now(),
    );
    await docRef.update({
      'status': OfferStatus.cancelled.name,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
      'history': [...offer.history, entry].map(_historyEntryToMap).toList(),
    });
  }

  @override
  Future<void> expireIfNeeded(OfferEntity offer) async {
    if (offer.status != OfferStatus.pending) return;
    if (!DateTime.now().isAfter(offer.respondBy)) return;

    final entry = OfferHistoryEntry(
      round: offer.round,
      by: offer.turn,
      action: OfferHistoryAction.expire,
      price: offer.currentPrice,
      at: DateTime.now(),
    );
    try {
      await _offersCol.doc(offer.id).update({
        'status': OfferStatus.expired.name,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
        'history':
            [...offer.history, entry].map(_historyEntryToMap).toList(),
      });
    } catch (_) {
      // Une autre partie a peut-être déjà fait expirer l'offre entre
      // temps, ou la lecture a changé : pas bloquant, prochaine ouverture
      // réessaiera.
    }
  }
}
