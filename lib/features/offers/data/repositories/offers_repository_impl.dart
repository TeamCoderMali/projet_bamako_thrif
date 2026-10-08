// ─── Bamako Thrift — Offers Repository Implementation ──────────────────────
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/services/offers_config_service.dart';
import '../../domain/entities/offer_entity.dart';
import '../../domain/repositories/offers_repository.dart';
import '../models/offer_model.dart';

class OffersRepositoryImpl implements OffersRepository {
  final FirebaseFirestore _firestore;
  final OffersConfigService _configService;

  OffersRepositoryImpl(this._firestore, [OffersConfigService? configService])
      : _configService = configService ?? OffersConfigService.instance;

  CollectionReference<Map<String, dynamic>> get _offersCol =>
      _firestore.collection('offers');

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
  Future<void> createOrRelance({
    required String productId,
    required String productTitle,
    String? productImageUrl,
    required String sellerId,
    required String buyerId,
    required double originalPrice,
    required double offerPrice,
  }) async {
    final id = OfferModel.buildId(productId: productId, buyerId: buyerId);
    final docRef = _offersCol.doc(id);
    final config = await _configService.getConfig();
    final now = DateTime.now();
    final respondBy =
        now.add(Duration(hours: config.responseDeadlineHours));

    final existing = await docRef.get();

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
        respondBy: respondBy,
        history: [historyEntry],
        createdAt: now,
      );
      await docRef.set(offer.toFirestore());
      return;
    }

    final data = existing.data()!;
    final currentStatus = OfferModel.fromFirestore(data, id).status;
    if (currentStatus != OfferStatus.rejected &&
        currentStatus != OfferStatus.cancelled &&
        currentStatus != OfferStatus.expired) {
      throw OfferAlreadyActiveException(currentStatus);
    }

    final previousHistory = OfferModel.fromFirestore(data, id).history;
    await docRef.update({
      'status': OfferStatus.pending.name,
      'round': 1,
      'turn': OfferTurn.seller.name,
      'currentPrice': offerPrice,
      'respondBy': Timestamp.fromDate(respondBy),
      'updatedAt': Timestamp.fromDate(now),
      'history': [...previousHistory, historyEntry]
          .map((e) => {
                'round': e.round,
                'by': e.by.name,
                'action': e.action.name,
                'price': e.price,
                'at': Timestamp.fromDate(e.at),
              })
          .toList(),
    });
  }
}
