# Plan — Système d'offres ("Faire une offre")

Fichier non commité. **Valeurs validées par Fatou le 2026-10-08.** Lot A
(socle : modèle, service de config, règles Firestore, tests) codé et
durci, non déployé. Lots B à E (écrans) pas commencés — en attente
d'accord explicite avant de coder quoi que ce soit.

## Valeurs validées (remplacent les précédentes)

- `responseDeadlineHours` = **72** (délai de réponse du vendeur).
- `acceptDeadlineHours` : **supprimé**. Plus aucun délai pour l'acheteur
  après une contre-offre.
- `maxOffersPerBuyerPerProduct` : **illimité par défaut** (absent du
  document = aucun plafond ; champ optionnel, un admin pourra en fixer
  un plus tard).
- `maxRounds` : **illimité par défaut**, même principe.
- `minOfferRatio` = **0.3** (offre ≥ 30 % du prix affiché **et**
  strictement inférieure au prix).
- Le vendeur peut désactiver les offres par article (`offersEnabled` sur
  `product`, déjà créé en lot A, défaut `true`) : la création d'une
  offre est refusée si `offersEnabled == false`.
- Les frais de service se calculeront sur le **prix accepté** de l'offre
  (pas le prix affiché initial) — voir audit séparé, aucun code encore.

Décisions antérieures toujours valables :
- Blocage de suppression d'une annonce avec offre active géré **côté
  écran uniquement** (pas dans les règles Firestore).
- Offre strictement inférieure au prix (jamais égale/supérieure).

Base réutilisée (pas d'invention) : l'enum `MessageType` dans
`lib/features/chat/domain/entities/message_entity.dart:58` contient déjà
`offer` et `system`, non utilisés jusqu'ici. Le produit a déjà `price`
(double), `ProductStatus` et désormais `offersEnabled` (lot A). Le chat
(`chat`/`messages`) et le carve-out "annuler vendu/réservé" du Lot 5
(déployé) sont réutilisables tels quels.

---

## 1. Modèle de données (lot A — codé)

### `config/offers`
Même pattern que `config/payment` (document unique, repli sûr si absent
ou champ manquant) :
- `responseDeadlineHours`: 72
- `maxOffersPerBuyerPerProduct`: optionnel, absent = illimité
- `maxRounds`: optionnel, absent = illimité
- `minOfferRatio`: 0.3 (strictement inférieur au prix, pas égal/supérieur)

### `offers/{id}`
- `productId`, `productTitle`, `productImageUrl` (dénormalisés, comme sur
  `chat`)
- `sellerId`, `buyerId` (doivent être différents — on ne peut pas faire
  une offre sur son propre article)
- `originalPrice` (prix produit au moment de l'offre — le seuil des 30 %
  se calcule sur celui-ci, pas sur un prix que le vendeur changerait après
  coup)
- `currentPrice` (dernier montant sur la table ; toute contre-offre doit
  rester dans `[originalPrice * minOfferRatio, originalPrice]`)
- `round` (1, puis +1 à chaque contre-offre — pas de plafond par défaut)
- `turn`: `'seller' | 'buyer'` (verrou optimiste : qui doit agir)
- `status`: `'pending' | 'accepted' | 'rejected' | 'expired' | 'cancelled'`
- `chatId` (conversation existante, créée/retrouvée comme le fait déjà
  "Contacter le vendeur")
- `respondBy` (deadline du tour en cours, +72h)
- `reservedUntil` (champ réservé pour une future fenêtre post-acceptation
  — aucune valeur calculée pour l'instant, aucun délai acheteur n'existe
  plus après une contre-offre)
- `history`: tableau `{round, by, action, price, at}` (petit volume, pas
  de sous-collection nécessaire)
- `createdAt`, `updatedAt`

### Intégration messagerie
Chaque action (offre / contre-offre / accepte / refuse / annule / expire)
poste un message `type: offer` dans le chat existant, avec un nouveau
champ `offerId` sur `MessageEntity`/`MessageModel` (seul ajout de schéma
côté message) pour que la bulle s'abonne en direct à `offers/{offerId}`
plutôt que d'afficher un texte figé. Le thread reste un historique
lisible ; les boutons d'action n'apparaissent que sur le dernier message
du bon type, côté dont c'est le tour.

---

## 2. Règles Firestore (lot A — codées et durcies, fichier candidat
   `firestore.rules.chantier-candidat` seulement, non déployées)

- `config/offers` : lecture authentifié, écriture admin (identique à
  `config/payment`).
- `offers/{id}` création : acheteur authentifié, `buyerId == auth.uid`,
  `buyerId != sellerId`, `sellerId` vérifié par `get()` sur le produit,
  `status == 'pending'`, `round == 1`, `turn == 'seller'`,
  `currentPrice >= originalPrice * minOfferRatio` ET `currentPrice <
  originalPrice`, produit `available` ET `offersEnabled != false`.
- Mise à jour : seule la partie dont c'est le `turn` peut écrire ;
  accepter/refuser ne change que `status`/`updatedAt`/`history` (prix et
  tour figés) ; contre-proposer exige un prix dans les bornes et (si une
  limite de rounds est configurée) de ne pas la dépasser ; l'acheteur
  peut aussi annuler tant que c'est encore au vendeur de répondre.
- **Expiration paresseuse** (pas de Cloud Function) : seulement depuis
  `status == 'pending'` ET `request.time > respondBy` — pas depuis
  `accepted` (pas de fenêtre post-acceptation pour l'instant, voir
  ci-dessus).
- **"Une seule offre pending par acheteur et par article" : RÉSOLU**
  (décision Ali, 2026-10-08) via un **ID de document déterministe**
  `offers/{productId}_{buyerId}` (voir `OfferModel.buildId`, mobile) — un
  seul document possible par paire, donc un seul statut possible à la
  fois, garanti nativement par les règles sans requête d'existence par
  filtre. Une négociation refusée/annulée/expirée se **relance en
  réutilisant ce même document** (branche "relance" de `allow update` :
  acheteur uniquement, seulement depuis un statut terminal, retour à
  `pending`/`round 1`/`turn seller`, mêmes conditions qu'une création).
  L'historique de toutes les négociations successives vit dans le même
  tableau `history`, par choix (pas de nouveau document par tentative).
- Limite de comptage "max offres par acheteur/article" : désormais
  illimitée par défaut, donc plus de plafond à faire respecter tant que
  `config/offers.maxOffersPerBuyerPerProduct` reste absent.

---

## 3. Écrans (lots B/C, pas commencés)

- **Acheteur** : bouton "Faire une offre" sur la fiche article (si
  disponible, pas son propre article, `offersEnabled != false`) → bottom
  sheet (montant + validation ≥ 30 % et < prix) → crée l'offre et ouvre
  le chat. Nouvel onglet/entrée "Mes offres".
- **Vendeur** : même bulle de chat, boutons actifs seulement quand
  `turn == 'seller'`. Toggle "Autoriser les offres" à ajouter à l'écran
  de publication/édition d'article (champ `offersEnabled` déjà créé côté
  modèle, pas encore d'UI).
- **Blocage suppression d'annonce** : géré côté écran si une offre
  `pending` référence l'article.

---

## 4. Frais de service — audit (2026-10-08, aucun code touché)

**Décision de Fatou** : les frais de service doivent se calculer sur le
**prix accepté** d'une offre, pas le prix affiché initial, une fois les
lots B/C en place. **En attente du choix de Fatou sur le modèle de frais
— rien à coder pour l'instant.**

Constat de l'audit : aujourd'hui, **aucun calcul réel de frais n'existe
nulle part**, trois concepts déconnectés coexistent :
1. `payment_page.dart:258-272` affiche un flat "1 000 FCFA" ajouté au
   total à l'écran, mais `_createOrder()` (ligne 119) écrit
   `totalAmount: product.price` **sans jamais y inclure ce montant**.
2. `order_tracking_page.dart:514` répète ce même texte dans un dialogue
   d'annulation ("frais de service... acquis à la plateforme"), mais le
   remboursement/avoir crédite ensuite le **montant total intégral**,
   rien n'est réellement déduit.
3. Back-office : un champ `commissionRate` (%, défaut 5,
   `settings.component.ts:12,26,87`) **jamais lu nulle part** (mobile ou
   back-office) — complètement mort.

Pour utiliser le prix accepté d'une offre, il faudra : choisir un seul
modèle de frais (flat 1000 FCFA vs commission %, décision Fatou), puis
faire en sorte que la future création de commande à partir d'une offre
acceptée (lot B/C, pas construit) utilise `offer.currentPrice` au lieu
de `product.price`. Rappel : le paiement est désactivé actuellement
(phase de test), ce code n'est pas exécutable en pratique aujourd'hui.

---

## 5. Cas limites

- Article vendu/retiré pendant une offre active → expiration lazy dès
  que `product.status != 'available'` (côté écran, pas encore codé).
- Collision si les deux parties agissent presque simultanément : le
  `turn` sert de verrou optimiste, le perdant reçoit un
  `permission-denied` et doit rafraîchir.
- Offre minimale : `>= 30% du prix` ET `< prix` — **validé par Fatou**.
- "Une seule offre pending" : voir §2, décision en attente.

---

## 6. Découpage en lots

- **Lot A** (fait, durci, testé — 27+38 scénarios de règles passés,
  rien déployé) : modèle + `config/offers` + règles Firestore + tests.
- **Lot B** : écran acheteur ("Faire une offre", "Mes offres").
- **Lot C** : écran vendeur + bulle de chat + toggle `offersEnabled`.
- **Lot D** : expiration différée + réconciliation du statut produit.
- **Lot E** (optionnel) : badges, historique enrichi.

---

## 7. Ce qui est fait "sans Blaze"

Aucune Cloud Function, aucun cron : tout passe par des règles Firestore
qui n'autorisent que des transitions valides, plus une vérification côté
client à l'ouverture des écrans concernés (expiration paresseuse).
Aucune notification push — uniquement le badge non-lu du chat existant.

---

## Statut

Valeurs validées par Fatou. Lot A codé, durci, testé (voir commits
dédiés), non déployé. **Question ouverte à trancher avant le Lot B** :
comment appliquer "une seule offre pending par acheteur/article" (§2).
Ne pas commencer les écrans avant accord explicite.
