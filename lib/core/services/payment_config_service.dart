// ─── Bamako Thrift — Payment Config Service ────────────────────────────────
// Lit le document config/payment (interrupteur paiement, back-office >
// Paramètres > Paiement). Repli = paiement DÉSACTIVÉ si le document n'existe
// pas encore, si le champ "enabled" est absent/invalide, ou si la lecture
// échoue (règles pas déployées, pas de réseau...). Choix délibéré : la page
// de paiement actuelle est une simulation qui ne débite rien, donc un repli
// "activé" afficherait une fausse sécurité à l'acheteur. Même repli partout
// (bouton Acheter, bannière, FAQ) pour ne jamais se contredire à l'écran, et
// même repli côté règles Firestore (voir paymentDisabled() dans
// firestore.rules) pour ne jamais contredire le serveur non plus.
// Le document est créé par le back-office au premier bascule de
// l'interrupteur (jamais par l'app mobile, qui ne fait que lire).
// À REPASSER à activé par défaut quand un vrai paiement existera.
import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentConfigService {
  PaymentConfigService._();
  static final PaymentConfigService instance = PaymentConfigService._();

  static const bool fallbackEnabled = false;

  Future<bool> isPaymentEnabled() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('config')
          .doc('payment')
          .get();
      final enabled = snap.data()?['enabled'];
      return enabled is bool ? enabled : fallbackEnabled;
    } catch (_) {
      return fallbackEnabled;
    }
  }
}
