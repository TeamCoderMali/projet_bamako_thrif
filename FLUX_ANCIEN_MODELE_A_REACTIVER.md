# Flux de l'ancien modèle — non touchés au Lot 9

Fichier non commité. Ces deux flux supposent un vrai paiement/portefeuille et
n'ont pas été modifiés (ni cachés, ni réécrits) : décision fonctionnelle à
prendre avant de les traiter, pas juste du texte.

## 1. Annulation de vente / remboursement

**Fichier** : `lib/features/order/presentation/pages/order_tracking_page.dart`
**Lignes** : ~505-520 (dialogue "Comment souhaites-tu être remboursé ?") et
~795-812 (bouton "Annuler et être remboursé")

Flux complet : choix "Avoir (3 mois)" vs autre remboursement, frais de
service de 1000 FCFA retenus par la plateforme. Suppose un vrai portefeuille
Danaya qui débite/crédite réellement — n'existe pas en phase de test.

**Atteignabilité actuelle** : reste accessible pour les commandes déjà
existantes (créées avant la désactivation du paiement), puisque
`order_tracking_page.dart` n'est pas gardé par l'interrupteur. Pas bloqué
comme `payment_success_page.dart`.

**Questions à trancher avant d'y toucher** :
- Que doit-il se passer si un acheteur avec une commande historique clique
  "Annuler et être remboursé" pendant la phase de test ?
- Faut-il masquer ce bouton quand le paiement est désactivé (comme la case
  pressing), ou le laisser pour les commandes historiques uniquement ?

## 2. Validation remise en état

**Fichier** : `lib/features/notification/presentation/pages/notifications_page.dart`
**Lignes** : 34-237 (`_RepairValidationSheet`)

Écran complet : montant de remise en état, délai 24h, bouton Accepter,
texte "Montant accepté. L'équipe procède à la remise en état." Câblé sur
`non_conformities.repairCost` / `sellerDeadline` — flux pressing/équipe de
l'ancien modèle, ouvert quand une notification porte un `nonConformityId`.

**Atteignabilité actuelle** : dépend de si des notifications avec
`nonConformityId` sont encore créées quelque part dans le code actuel — à
vérifier avant de décider si c'est du code mort ou un flux encore vivant.

**Questions à trancher avant d'y toucher** :
- Ce flux est-il encore déclenché par quoi que ce soit aujourd'hui, ou
  est-ce un reliquat totalement mort ?
- Faut-il le supprimer, le masquer derrière `pressingEnabled`, ou le
  réécrire pour le nouveau circuit de signalement (`reports`, lot 6) ?

---

À reprendre quand un vrai paiement/portefeuille existera, ou plus tôt si
Fatou/Ali décide que ces flux doivent être traités avant.
