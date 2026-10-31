// ─── Bamako Thrift — Feature flags ─────────────────────────────────────────
// Interrupteurs de fonctionnalité en dur (pas de lecture Firestore, juste une
// constante compilée). Objectif : pouvoir masquer une fonctionnalité pas
// encore prête pour la cliente sans supprimer le code ni les données.

/// Le partenaire pressing (vérification/remise en état avant publication)
/// n'existe pas encore pour Fatou. Tant que false :
/// - la case "Faire vérifier / remettre à neuf..." est masquée au
///   formulaire de vente (publish_product_page.dart) ;
/// - le badge "✓ Vérifié" est masqué partout où un article s'affiche ;
/// - la question "Qu'est-ce que le badge Vérifié ?" est masquée de la FAQ.
/// Rien n'est supprimé : le champ verifie, le statut
/// enAttenteVerification, la section de modération du back-office et les
/// règles Firestore associées restent inchangés. Remettre à true pour
/// réactiver.
const bool pressingEnabled = false;

/// Le bouton "Se connecter avec Facebook" n'a pas de compte Facebook
/// Developer configuré derrière (voir login_page.dart) : reste en mode
/// "bientôt disponible" (le clic affiche un message, aucun appel réseau).
/// Remasqué brièvement le 2026-10-17 pour les tests testeuses, remis à
/// true le 2026-10-18 sur demande d'Ali — remettre à false si besoin de le
/// masquer à nouveau, sans rien supprimer.
const bool facebookLoginEnabled = true;

/// Verrou de test (demande d'Ali, 2026-10-31) : aucune UI de paiement ne
/// doit être visible pendant cette phase de test, quel que soit l'état de
/// config/payment dans Firestore (back-office) -- garantie au niveau code,
/// pas dépendante d'un interrupteur distant qu'on ne peut pas vérifier
/// depuis l'app. Lu par PaymentConfigService.isPaymentEnabled(), qui
/// gouverne déjà Portefeuille/Paiements/Mes commandes (profile_page.dart),
/// le bouton "Je craque" (product_detail_page.dart), les textes
/// intro/about/privacy, et les boutons "Vendu"/"Annuler" de Mes annonces.
/// Remettre à false pour redonner le contrôle au seul document
/// config/payment quand un vrai paiement existera.
const bool paymentForceDisabledForTesting = true;
