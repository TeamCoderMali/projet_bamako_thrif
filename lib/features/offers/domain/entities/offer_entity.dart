// ─── Bamako Thrift — Offer Entity (Domain Layer) ───────────────────────────
// Négociation de prix entre acheteur et vendeur (bouton "Faire une offre").
// Voir PLAN_OFFRES.md à la racine du repo pour le modèle complet ;
// implémentation du socle uniquement (lot A) — pas d'écran encore.
import 'package:equatable/equatable.dart';

enum OfferStatus { pending, accepted, rejected, expired, cancelled }

extension OfferStatusLabel on OfferStatus {
  String get label => switch (this) {
        OfferStatus.pending => 'En attente',
        OfferStatus.accepted => 'Acceptée',
        OfferStatus.rejected => 'Refusée',
        OfferStatus.expired => 'Expirée',
        OfferStatus.cancelled => 'Annulée',
      };
}

/// À qui revient la prochaine action (accepter/refuser/contre-proposer).
enum OfferTurn { seller, buyer }

enum OfferHistoryAction { offer, counter, accept, reject, cancel, expire }

/// Une entrée du journal de négociation (tableau `history` sur le document
/// `offers/{id}`) — jamais modifiée après coup, seulement ajoutée.
class OfferHistoryEntry extends Equatable {
  final int round;
  final OfferTurn by;
  final OfferHistoryAction action;
  final double price;
  final DateTime at;

  const OfferHistoryEntry({
    required this.round,
    required this.by,
    required this.action,
    required this.price,
    required this.at,
  });

  @override
  List<Object?> get props => [round, by, action, price, at];
}

class OfferEntity extends Equatable {
  /// Déterministe : `{productId}_{buyerId}` (voir OfferModel.buildId) — un
  /// seul document par paire acheteur/article, réutilisé à chaque relance
  /// après refus/annulation/expiration, pour garantir nativement qu'une
  /// seule offre "pending" existe à la fois pour cette paire.
  final String id;
  final String productId;
  final String productTitle;
  final String? productImageUrl;
  final String sellerId;
  final String buyerId;

  /// Prix du produit au moment de la création de l'offre — sert de base
  /// fixe pour le seuil des 50 % (ne doit jamais changer si le vendeur
  /// modifie le prix du produit après coup).
  final double originalPrice;

  /// Dernier montant proposé sur la table (évolue à chaque contre-offre).
  final double currentPrice;

  final int round;
  final OfferTurn turn;
  final OfferStatus status;

  /// Conversation existante (acheteur/vendeur) associée à cette offre.
  final String? chatId;

  /// Délai de réponse du tour en cours.
  final DateTime respondBy;

  /// Fixé uniquement quand l'offre est acceptée — délai avant que
  /// l'article réservé ne redevienne disponible si la transaction
  /// n'est pas finalisée.
  final DateTime? reservedUntil;

  final List<OfferHistoryEntry> history;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const OfferEntity({
    required this.id,
    required this.productId,
    required this.productTitle,
    this.productImageUrl,
    required this.sellerId,
    required this.buyerId,
    required this.originalPrice,
    required this.currentPrice,
    this.round = 1,
    this.turn = OfferTurn.seller,
    this.status = OfferStatus.pending,
    this.chatId,
    required this.respondBy,
    this.reservedUntil,
    this.history = const [],
    required this.createdAt,
    this.updatedAt,
  });

  bool get isPending => status == OfferStatus.pending;
  bool get isTerminal => !isPending;

  @override
  List<Object?> get props => [
        id,
        productId,
        productTitle,
        productImageUrl,
        sellerId,
        buyerId,
        originalPrice,
        currentPrice,
        round,
        turn,
        status,
        chatId,
        respondBy,
        reservedUntil,
        history,
        createdAt,
        updatedAt,
      ];
}
