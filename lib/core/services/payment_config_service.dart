// ─── Bamako Thrift — Payment Config Service ────────────────────────────────
// Lit le document config/payment (interrupteur paiement, back-office >
// Paramètres > Paiement). Repli = paiement ACTIVÉ si le document n'existe
// pas encore, si le champ "enabled" est absent/invalide, ou si la lecture
// échoue (règles pas déployées, pas de réseau...) — c'est le comportement
// actuel de l'app, donc ne rien changer tant qu'aucun admin n'a
// explicitement désactivé le paiement. Même repli partout (bouton Acheter,
// bannière, FAQ) pour ne jamais se contredire à l'écran.
// Le document est créé par le back-office au premier bascule de
// l'interrupteur (jamais par l'app mobile, qui ne fait que lire).
import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentConfigService {
  PaymentConfigService._();
  static final PaymentConfigService instance = PaymentConfigService._();

  static const bool fallbackEnabled = true;

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
