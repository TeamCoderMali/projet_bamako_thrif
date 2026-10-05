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
