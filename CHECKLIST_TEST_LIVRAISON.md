# Checklist de test — Circuit de livraison DANAYA

À utiliser avec Fatou pour valider le nouveau circuit (publication → paiement → collecte → réception → litige). Cocher au fur et à mesure, noter tout écart dans la colonne Observations.

Pré-requis : deux comptes de test (un "vendeur", un "acheteur"), tous deux avec notifications activées et le solde portefeuille du vendeur à 0 au départ.

## 1. Publication (vendeur)

- [ ] Publier un article (titre, prix, état, photos) sans erreur
- [ ] L'article apparaît dans le catalogue avec le bon statut ("available")
- [ ] Aucun badge "Vérifié DANAYA" affiché (retiré avec le pivot)

## 2. Paiement (acheteur, simulé)

- [ ] Ouvrir l'article, lancer le paiement
- [ ] Le récapitulatif affiche : prix, "Frais de service 1 000 FCFA", total, et la ligne "Livraison (à payer au livreur)"
- [ ] Le paiement simulé aboutit (écran de succès)
- [ ] L'article passe au statut "vendu" (n'apparaît plus comme disponible dans le catalogue)
- [ ] Une commande apparaît dans "Mes commandes" côté acheteur avec le statut "Vendu — en attente de collecte"
- [ ] Côté vendeur, le portefeuille affiche le montant de la vente en "en attente" (pas encore dans le solde disponible)

## 3. Collecte (vendeur)

- [ ] Le vendeur voit la commande avec le bouton "Marquer collecté"
- [ ] Après clic, le statut passe à "Collecté — en cours de livraison"
- [ ] La timeline (Vendu → Collecté → Reçu) reflète bien l'étape en cours côté acheteur et vendeur

## 4. Confirmation de réception (acheteur)

- [ ] L'acheteur voit le bouton "Confirmer réception"
- [ ] Après clic, le statut passe à "Reçu"
- [ ] **Vérifier le portefeuille vendeur** : le montant quitte "en attente" et apparaît dans le "Solde disponible"
- [ ] Une transaction "Vente — [titre article]" apparaît dans l'historique du portefeuille vendeur
- [ ] Le bouton "Signaler un problème" apparaît côté acheteur, avec la mention "Disponible pendant 24h après la réception"

## 4bis. Cas particulier — réception sans collecte cochée

- [ ] Refaire un paiement, sauter l'étape "Marquer collecté" côté vendeur, et confirmer directement "Reçu" côté acheteur
- [ ] Vérifier que la commande passe bien à "terminée" quand même (règle métier : jamais bloqué sur l'oubli du vendeur)

## 5. Cas litige (signalement acheteur)

- [ ] Dans la fenêtre de 24h, cliquer "Signaler un problème"
- [ ] Choisir un motif, ajouter une description, ajouter au moins une photo (obligatoire)
- [ ] Tester les deux issues séparément (sur deux commandes différentes si possible) :
  - [ ] "Garder avec dédommagement" → le signalement est envoyé, pas d'annulation de la vente
  - [ ] "Annuler et être remboursé" → choisir "Avoir (3 mois)" puis, sur un autre essai, "Remboursement" ; vérifier que l'article repasse "disponible" et que la commande passe à "Annulée"
- [ ] Vérifier qu'un avoir crédité apparaît bien dans le portefeuille acheteur (cas "Avoir")

## 6. Apparition dans le dashboard back-office

- [ ] Se connecter au dashboard admin/relais (`/relay/disputes`)
- [ ] Le signalement de l'étape 5 apparaît dans la liste
- [ ] La photo de l'annonce et la photo du signalement sont bien visibles côte à côte pour comparaison
- [ ] Le dashboard relais (stats "À évaluer" / "Chez le vendeur" / "Résolus ce mois") reflète le nouveau signalement

## 7. Vérifications transverses

- [ ] Notifications reçues aux bonnes étapes (si applicable) sans doublon ni message incohérent avec l'ancien circuit (pressing/relais)
- [ ] Aucune mention résiduelle du circuit pressing/relais physique dans les écrans testés (dépôt, retrait, frais de garde)
- [ ] Solde du portefeuille toujours cohérent après plusieurs cycles (pas de double-crédit, pas de perte)

## Hors périmètre de ce test (connu, ne pas bloquer dessus)

- Paiement réel Orange Money/Moov/Wave (simulation uniquement pour l'instant)
- Restriction des avis textuels aux "Vendeurs Pro" (en attente du fichier de Skypper)
- Relance des utilisateurs inactifs (en attente de validation finale de Fatou)
