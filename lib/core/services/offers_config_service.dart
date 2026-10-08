// ─── Bamako Thrift — Offers Config Service ─────────────────────────────────
// Lit le document config/offers (back-office > Paramètres, à venir). Toutes
// les valeurs réglables du lot "offres" viennent d'ici, avec un repli en dur
// si le document/champ est absent ou si la lecture échoue — même principe
// que PaymentConfigService. Valeurs de repli proposées par Fatou, PAS encore
// validées définitivement (voir PLAN_OFFRES.md) : elles doivent rester
// modifiables depuis ce document sans nouveau déploiement de l'app.
import 'package:cloud_firestore/cloud_firestore.dart';

class OffersConfig {
  final int responseDeadlineHours;
  final int acceptDeadlineHours;
  final int maxOffersPerBuyerPerProduct;
  final int maxRounds;
  final double minOfferRatio;

  const OffersConfig({
    required this.responseDeadlineHours,
    required this.acceptDeadlineHours,
    required this.maxOffersPerBuyerPerProduct,
    required this.maxRounds,
    required this.minOfferRatio,
  });

  static const fallback = OffersConfig(
    responseDeadlineHours: 48,
    acceptDeadlineHours: 24,
    maxOffersPerBuyerPerProduct: 3,
    maxRounds: 3,
    minOfferRatio: 0.5,
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
        acceptDeadlineHours: (data['acceptDeadlineHours'] as num?)?.toInt() ??
            OffersConfig.fallback.acceptDeadlineHours,
        maxOffersPerBuyerPerProduct:
            (data['maxOffersPerBuyerPerProduct'] as num?)?.toInt() ??
                OffersConfig.fallback.maxOffersPerBuyerPerProduct,
        maxRounds: (data['maxRounds'] as num?)?.toInt() ??
            OffersConfig.fallback.maxRounds,
        minOfferRatio: (data['minOfferRatio'] as num?)?.toDouble() ??
            OffersConfig.fallback.minOfferRatio,
      );
    } catch (_) {
      return OffersConfig.fallback;
    }
  }
}
