// ─── Bamako Thrift — Offers Repository (Domain Contract) ───────────────────
import '../entities/offer_entity.dart';

/// Offre déjà en cours (pending) ou acceptée : il faut traiter cet état
/// avant de pouvoir soumettre une nouvelle offre (voir [createOrRelance]).
class OfferAlreadyActiveException implements Exception {
  final OfferStatus status;
  const OfferAlreadyActiveException(this.status);
  @override
  String toString() => 'OfferAlreadyActiveException($status)';
}

abstract class OffersRepository {
  /// Lit l'offre existante pour cette paire acheteur/article (null si
  /// aucune négociation n'a jamais eu lieu). L'ID étant déterministe
  /// (`{productId}_{buyerId}`), il ne peut y en avoir qu'une par paire.
  Future<OfferEntity?> getOffer({
    required String productId,
    required String buyerId,
  });

  /// Crée une nouvelle offre, ou relance la négociation existante si son
  /// statut est terminal (refusée/annulée/expirée) — même document,
  /// historique conservé. Lève une exception si une offre est déjà en
  /// cours (pending) ou acceptée : l'appelant doit vérifier l'état via
  /// [getOffer] avant d'afficher le formulaire de saisie.
  Future<void> createOrRelance({
    required String productId,
    required String productTitle,
    String? productImageUrl,
    required String sellerId,
    required String buyerId,
    required double originalPrice,
    required double offerPrice,
  });
}
