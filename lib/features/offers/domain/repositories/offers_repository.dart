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
  ///
  /// [chatId] doit être résolu (créé/retrouvé) par l'appelant AVANT cet
  /// appel : c'est un champ immuable une fois l'offre créée (voir les
  /// règles Firestore), il ne peut pas être ajouté après coup sur une
  /// relance.
  Future<void> createOrRelance({
    required String productId,
    required String productTitle,
    String? productImageUrl,
    required String sellerId,
    required String buyerId,
    required double originalPrice,
    required double offerPrice,
    String? chatId,
  });

  /// Flux en direct d'une offre par son ID — pour la bulle de chat, qui
  /// doit refléter l'état réel sans recharger la page.
  Stream<OfferEntity?> watchOffer(String offerId);

  /// Flux en direct de toutes les offres faites par cet acheteur (écran
  /// "Mes offres"), triées de la plus récente à la plus ancienne.
  Stream<List<OfferEntity>> watchBuyerOffers(String buyerId);

  /// Accepte l'offre : doit être appelé par la partie dont c'est le tour
  /// (vérifié aussi côté règles Firestore).
  Future<void> accept(String offerId);

  /// Refuse l'offre : doit être appelé par la partie dont c'est le tour.
  Future<void> reject(String offerId);

  /// Contre-propose [newPrice] : fait passer le tour à l'autre partie et
  /// incrémente le round. Rafraîchit `respondBy` pour donner un nouveau
  /// délai de réponse complet à la partie qui doit désormais répondre.
  Future<void> counter({required String offerId, required double newPrice});

  /// Annule l'offre — acheteur uniquement, tant que le vendeur n'a pas
  /// encore répondu (vérifié aussi côté règles Firestore).
  Future<void> cancel(String offerId);

  /// Fait passer l'offre à `expired` si elle est encore `pending` et que
  /// le délai de réponse est dépassé. Ne fait rien sinon (expiration
  /// paresseuse, pas de cron serveur).
  Future<void> expireIfNeeded(OfferEntity offer);
}
