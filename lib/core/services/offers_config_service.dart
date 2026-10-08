// ─── Bamako Thrift — Offers Config Service ─────────────────────────────────
// Lit le document config/offers (back-office > Paramètres, à venir). Toutes
// les valeurs réglables du lot "offres" viennent d'ici, avec un repli en dur
// si le document/champ est absent ou si la lecture échoue — même principe
// que PaymentConfigService.
// Valeurs validées par Fatou le 2026-10-08 (voir PLAN_OFFRES.md) :
// - responseDeadlineHours = 72 (délai de réponse du vendeur).
// - Pas de délai acheteur après une contre-offre (acceptDeadlineHours
//   supprimé — n'existe plus, à ne pas réintroduire).
// - Nombre d'offres et nombre de tours illimités par défaut :
//   maxOffersPerBuyerPerProduct / maxRounds sont null = illimité, aussi
//   bien en repli qu'en valeur explicite dans le document (un admin pourrait
//   vouloir fixer une limite plus tard, d'où le champ optionnel plutôt que
//   suppression complète).
// - minOfferRatio = 0.3 (offre >= 30 % du prix ET strictement < prix).
import 'package:cloud_firestore/cloud_firestore.dart';

class OffersConfig {
  final int responseDeadlineHours;

  /// Null = illimité (pas de plafond). Valeur explicite = limite active.
  final int? maxOffersPerBuyerPerProduct;

  /// Null = illimité (pas de plafond de tours de négociation).
  final int? maxRounds;

  final double minOfferRatio;

  const OffersConfig({
    required this.responseDeadlineHours,
    this.maxOffersPerBuyerPerProduct,
    this.maxRounds,
    required this.minOfferRatio,
  });

  static const fallback = OffersConfig(
    responseDeadlineHours: 72,
    minOfferRatio: 0.3,
  );
}

class OffersConfigService {
  OffersConfigService._();
  static final OffersConfigService instance = OffersConfigService._();

  Future<OffersConfig> getConfig() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('config')
          .doc('offers')
          .get();
      final data = snap.data();
      if (data == null) return OffersConfig.fallback;

      return OffersConfig(
        responseDeadlineHours: (data['responseDeadlineHours'] as num?)
                ?.toInt() ??
            OffersConfig.fallback.responseDeadlineHours,
        // Champ absent = illimité (pas de repli numérique ici, c'est le
        // comportement par défaut voulu).
        maxOffersPerBuyerPerProduct:
            (data['maxOffersPerBuyerPerProduct'] as num?)?.toInt(),
        maxRounds: (data['maxRounds'] as num?)?.toInt(),
        minOfferRatio: (data['minOfferRatio'] as num?)?.toDouble() ??
            OffersConfig.fallback.minOfferRatio,
      );
    } catch (_) {
      return OffersConfig.fallback;
    }
  }
}
