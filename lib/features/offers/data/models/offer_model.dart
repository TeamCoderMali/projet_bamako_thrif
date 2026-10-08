// ─── Bamako Thrift — Offer Model (Data Layer) ──────────────────────────────
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/offer_entity.dart';

class OfferModel extends OfferEntity {
  /// Identifiant déterministe : un seul document `offers/{id}` par paire
  /// (produit, acheteur), pour que "une seule offre en cours par acheteur
  /// et par article" soit garanti nativement par les règles Firestore
  /// (deux tentatives simultanées visent forcément le même document) sans
  /// avoir besoin d'une requête d'existence par filtre, impossible à
  /// exprimer dans les règles. Les relances après refus/annulation/
  /// expiration réutilisent ce même document (voir PLAN_OFFRES.md §2).
  static String buildId({required String productId, required String buyerId}) =>
      '${productId}_$buyerId';

  const OfferModel({
    required super.id,
    required super.productId,
    required super.productTitle,
    super.productImageUrl,
    required super.sellerId,
    required super.buyerId,
    required super.originalPrice,
    required super.currentPrice,
    super.round,
    super.turn,
    super.status,
    super.chatId,
    required super.respondBy,
    super.reservedUntil,
    super.history,
    required super.createdAt,
    super.updatedAt,
  });

  factory OfferModel.fromFirestore(Map<String, dynamic> data, String id) {
    return OfferModel(
      id: id,
      productId: data['productId'] as String,
      productTitle: data['productTitle'] as String? ?? '',
      productImageUrl: data['productImageUrl'] as String?,
      sellerId: data['sellerId'] as String,
      buyerId: data['buyerId'] as String,
      originalPrice: (data['originalPrice'] as num).toDouble(),
      currentPrice: (data['currentPrice'] as num).toDouble(),
      round: data['round'] as int? ?? 1,
      turn: _parseTurn(data['turn'] as String?),
      status: _parseStatus(data['status'] as String?),
      chatId: data['chatId'] as String?,
      respondBy: _toDate(data['respondBy']) ?? DateTime.now(),
      reservedUntil: _toDate(data['reservedUntil']),
      history: ((data['history'] as List?) ?? const [])
          .map((e) => _historyFromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      createdAt: _toDate(data['createdAt']) ?? DateTime.now(),
      updatedAt: _toDate(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'productId': productId,
      'productTitle': productTitle,
      'productImageUrl': productImageUrl,
      'sellerId': sellerId,
      'buyerId': buyerId,
      'originalPrice': originalPrice,
      'currentPrice': currentPrice,
      'round': round,
      'turn': turn.name,
      'status': status.name,
      'chatId': chatId,
      'respondBy': Timestamp.fromDate(respondBy),
      'reservedUntil':
          reservedUntil != null ? Timestamp.fromDate(reservedUntil!) : null,
      'history': history.map(_historyToMap).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  static DateTime? _toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  static OfferTurn _parseTurn(String? value) {
    return OfferTurn.values.firstWhere(
      (e) => e.name == value,
      orElse: () => OfferTurn.seller,
    );
  }

  static OfferStatus _parseStatus(String? value) {
    return OfferStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => OfferStatus.pending,
    );
  }

  static OfferHistoryAction _parseAction(String? value) {
    return OfferHistoryAction.values.firstWhere(
      (e) => e.name == value,
      orElse: () => OfferHistoryAction.offer,
    );
  }

  static OfferHistoryEntry _historyFromMap(Map<String, dynamic> map) {
    return OfferHistoryEntry(
      round: map['round'] as int? ?? 1,
      by: _parseTurn(map['by'] as String?),
      action: _parseAction(map['action'] as String?),
      price: (map['price'] as num).toDouble(),
      at: _toDate(map['at']) ?? DateTime.now(),
    );
  }

  static Map<String, dynamic> _historyToMap(OfferHistoryEntry e) {
    return {
      'round': e.round,
      'by': e.by.name,
      'action': e.action.name,
      'price': e.price,
      'at': Timestamp.fromDate(e.at),
    };
  }
}
