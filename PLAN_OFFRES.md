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

## 4. Frais de service — décision de Fatou (2026-10-09)

**Modèle retenu** : frais de service = **8 % du prix, minimum 200 FCFA**,
**payés par l'acheteur** (ajoutés au prix affiché — le vendeur reçoit
intégralement le prix qu'il a fixé). Prix libres (pas de plancher/plafond
produit lié aux frais). Pour une offre acceptée, les frais se calculent
sur le **prix négocié** (`offer.currentPrice`), pas le prix affiché
initial (`product.price`).

**Rien codé maintenant — le paiement reste désactivé.** Cette décision
remplace la question ouverte posée dans l'audit du 2026-10-08 (ci-dessous,
conservé pour mémoire) ; le modèle "commission %" est donc le bon, pas le
flat 1000 FCFA.

### Audit (2026-10-08, toujours valable comme état des lieux du code)

Aujourd'hui, **aucun calcul réel de frais n'existe nulle part**, trois
concepts déconnectés coexistent :
1. `payment_page.dart:258-272` affiche un flat "1 000 FCFA" ajouté au
   total à l'écran, mais `_createOrder()` (ligne 119) écrit
   `totalAmount: product.price` **sans jamais y inclure ce montant**.
2. `order_tracking_page.dart:514` répète ce même texte dans un dialogue
   d'annulation ("frais de service... acquis à la plateforme"), mais le
   remboursement/avoir crédite ensuite le **montant total intégral**,
   rien n'est réellement déduit.
3. Back-office : un champ `commissionRate` (%, défaut 5,
   `settings.component.ts:12,26,87`) **jamais lu nulle part** (mobile ou
   back-office) — complètement mort, mais c'est le bon CONCEPT (commission
   %) — à réutiliser/corriger avec la valeur 8 %, pas à remplacer par un
   autre champ.

### À faire avant de réactiver le paiement (pas maintenant)

1. Calculer les frais avec la formule validée : `max(prix * 0.08, 200)`,
   où "prix" = `offer.currentPrice` si la commande vient d'une offre
   acceptée, sinon `product.price`.
2. Remplacer le `commissionRate` mort du back-office (`settings.component.ts`)
   par ce calcul (ou le réutiliser avec la valeur 8 %, au lieu de 5 et
   jamais lu) — à trancher à l'implémentation.
3. Aligner `payment_page.dart` : le texte affiché ("Frais de service :
   1 000 FCFA") doit utiliser le vrai calcul, pas le flat actuel.
4. Aligner `_createOrder()` : `totalAmount` doit inclure le prix réel
   (négocié ou affiché) **et** les frais calculés, de façon cohérente
   avec ce qui est montré à l'écran — le total affiché à l'acheteur doit
   être exactement le montant enregistré en base (c'est la source de
   l'incohérence trouvée dans l'audit : écran et données divergent déjà
   aujourd'hui avec le flat 1000 FCFA).
5. Vérifier `order_tracking_page.dart` (annulation/remboursement) pour
   que le montant remboursé reflète lui aussi la bonne base (frais
   déduits ou non, à confirmer avec Fatou au moment de l'implémentation).
6. Garder réserver/déréserver libres (découpler `reserved` de
   `paymentDisabled()` dans `productOwnerEditAllowed()`,
   `firestore.rules`) — décision Fatou du lot « Mes annonces »
   (2026-10-12) : le vendeur doit garder la main sur réserver/déréserver
   même une fois le paiement réactivé. Ne pas toucher `sold`, qui doit
   continuer à passer par le flux commande une fois le paiement actif.

### Autre tâche notée ici (sans rapport avec le paiement)

- Passer le thème en Poppins : ajouter Poppins-Bold.ttf dans
  assets/fonts + pubspec, changer app_text_styles.dart (2 lignes), puis
  QA écran par écran (boutons à hauteur fixe, titres AppBar), avec
  accord de Fatou.

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

## 8. Lot D — réservation 24h après offre acceptée (audit, 2026-10-09)

**Décision Fatou (2026-10-09) :** une offre acceptée réserve l'article à
l'acheteur pendant **24h**, puis il redevient disponible automatiquement ;
notification in-app aux deux parties. Phase de test limitée à ~20
vendeuses. **Rien codé, rien déployé — audit seul, en attente d'accord.**

### 1. Réservation à l'acceptation (règle `product`)

`ProductEntity` n'a aujourd'hui **aucun champ de réservation**
(`lib/features/product/domain/entities/product_entity.dart:4-69`) : seul
`ProductStatus.reserved` existe comme valeur d'enum, posée manuellement
par le vendeur (voir §4). Il faut ajouter deux champs nullables,
`reservedUntil` (Timestamp) et `reservedFor` (uid acheteur) — même
pattern que `offers.reservedUntil`, déjà présent mais jamais rempli
(`lib/features/offers/domain/entities/offer_entity.dart:78`,
`lib/features/offers/data/models/offer_model.dart:31,52,75-76`).

`OffersRepositoryImpl.accept()` (ligne 144-163) ne touche aujourd'hui que
le document `offers/{id}` — confirmé par la lecture du code : aucune
écriture sur `product` n'a lieu à l'acceptation. Il faudra que cette
méthode écrive **les deux documents** (offer + product), idéalement via
un batch/transaction Firestore côté client (pas de Cloud Function) pour
limiter le risque d'écriture partielle, déclenchable par **n'importe quelle
partie** puisque l'acceptation peut venir du vendeur ou de l'acheteur
(règle actuelle `offers`, lignes 387-421 de `firestore.rules.chantier-candidat`,
autorise déjà les deux sens).

Règle `product` proposée (ajout à `allow update`, inchangé sinon) —
**esquisse, pas de syntaxe garantie à 100%, à valider en test avant tout
déploiement** :
```
// Réservation automatique suite à une offre acceptée (Lot D)
|| (resource.data.status == 'available'
    && request.resource.data.status == 'reserved'
    && request.resource.data.diff(resource.data).affectedKeys()
         .hasOnly(['status', 'reservedUntil', 'reservedFor', 'updatedAt'])
    && request.resource.data.reservedFor is string
    && request.resource.data.reservedUntil is timestamp
    && (request.auth.uid == request.resource.data.reservedFor
        || request.auth.uid == resource.data.sellerId)
    && get(/databases/$(database)/documents/offers/$(productId + '_' + request.resource.data.reservedFor)).data.status == 'accepted'
    && get(/databases/$(database)/documents/offers/$(productId + '_' + request.resource.data.reservedFor)).data.sellerId == resource.data.sellerId
    && get(/databases/$(database)/documents/offers/$(productId + '_' + request.resource.data.reservedFor)).data.reservedUntil == request.resource.data.reservedUntil)
```
Champs limités à `status/reservedUntil/reservedFor/updatedAt` (même
discipline que les autres branches). Le `get()` croisé sur `offers/{id}`
empêche un vendeur/acheteur de poser une réservation fantaise sans offre
`accepted` réelle derrière.

**Manque à combler côté règle `offers`** (trouvé en relisant le fichier
pour cet audit) : la branche "accepter" (lignes 387-395 et 408-413) ne
vérifie pas que `product.status == 'available'` au moment d'accepter —
contrairement à la création (ligne 327) et à la relance (ligne 378). Sans
ce garde-fou, une offre pourrait être acceptée sur un article déjà
vendu/réservé entre-temps (voir §4). À ajouter dans le même mouvement que
la réservation.

### 2. Libération après 24h (paresseuse, sans Cloud Function)

Même principe que l'expiration d'offre déjà en prod
(`OffersRepositoryImpl.expireIfNeeded`, lignes 242-260) : le client
compare `DateTime.now()` à la deadline et tente l'update ; la règle
revérifie `request.time` côté serveur pour empêcher la triche.

Règle `product` proposée (nouvelle branche `allow update`) :
```
// Libération paresseuse de la réservation (Lot D)
|| (resource.data.status == 'reserved'
    && request.time > resource.data.reservedUntil
    && request.resource.data.status == 'available'
    && request.resource.data.diff(resource.data).affectedKeys()
         .hasOnly(['status', 'reservedUntil', 'reservedFor', 'updatedAt']))
```
N'importe quel utilisateur authentifié peut déclencher la libération
(comme l'expiration d'offre) — c'est un simple passage de relais, pas un
droit particulier.

**Points d'appel paresseux proposés** — mêmes trois écrans que pour
`expireIfNeeded` déjà câblés aujourd'hui (confirmé par grep) :
- fiche produit (`product_detail_page.dart`, à l'ouverture),
- `my_listings_page.dart` (vendeur, ligne 46 a déjà `expireIfNeeded` au
  même endroit — ajouter la vérification produit juste à côté),
- `my_offers_page.dart` (acheteur, ligne 31, même pattern).

### 3. Notifications

Les types `offerAccepted`/`offerRejected`/`newOffer` existent déjà dans
`NotificationType` (`notification_entity.dart:29-45`) et sont déjà
branchés côté affichage (icônes/couleurs dans `notification_tile.dart` et
`notifications_page.dart`) — **mais ne sont jamais créés nulle part** :
`NotificationRepositoryImpl` (data/repositories/notification_repository_impl.dart)
n'expose **aucune méthode de création**, seulement lecture/lu/suppression.
Aucun appelant dans tout `lib/features` ne construit de
`NotificationModel` pour l'écrire. C'est un circuit mort aujourd'hui, pas
spécifique aux offres.

Il faudra : (a) ajouter une méthode `create()` au repository, (b)
l'appeler des deux côtés au moment de l'acceptation (notifie le vendeur
ET l'acheteur) et à la libération (notifie les deux), (c) ajouter un
nouveau type `NotificationType.reservationExpired` (absent aujourd'hui).
Règle Firestore : **aucun changement nécessaire** — `allow create: if
isAuthenticated();` sur `/notification` (ligne 191) est déjà assez large
pour qu'une partie crée une notification adressée à l'autre (même
principe que `/wallet`, déjà toléré faute de Cloud Function — même
réserve de sécurité à durcir plus tard).

Confirmé : **aucun push n'est possible sans passer sur le plan Blaze**
(Cloud Functions requis pour déclencher FCM côté serveur) — ce sera donc
strictement in-app, cohérent avec le reste de l'app (badge non-lu du chat,
déjà listé en §7 comme limite acceptée "sans Blaze").

### 4. Interaction avec la réservation manuelle existante

Le vendeur peut déjà marquer manuellement vendu/réservé/annuler
(`my_listings_page.dart`, `_markStatus` ligne 153-172,
`canRevertToAvailable` ligne 341-343) — **mais uniquement si le paiement
est désactivé** (`!paymentEnabled`), ce qui est le cas actuellement. Cette
porte est **inconditionnelle sur le statut de départ** : rien n'empêche
aujourd'hui un vendeur de cliquer "Remettre disponible" sur un article
`reserved` **pendant** la fenêtre des 24h d'une réservation issue d'une
offre acceptée, sans que l'offre `accepted` correspondante ne soit
touchée — elle resterait affichée "Acceptée" indéfiniment dans "Mes
offres" de l'acheteur, déconnectée de la réalité du produit. Symétrique
pour "Marquer vendu" : rien ne referme l'offre.

C'est une vraie question à trancher, pas une simple note : trois options,
aucune codée :
- **(a)** laisser tel quel pour la phase ~20 vendeuses (le vendeur garde
  la main, l'incohérence "Mes offres" reste visuelle seulement) ;
- **(b)** faire que le changement manuel de statut d'un produit dont
  `reservedFor` est non-nul mette aussi à jour l'offre liée (ex. statut
  `cancelled` avec une raison "produit marqué vendu/disponible
  manuellement") — un peu de code client en plus, pas de Cloud Function ;
- **(c)** interdire le bouton manuel tant qu'une réservation active existe
  (`reservedFor != null`), en renvoyant vers le flux normal
  (attendre l'expiration ou traiter la vente via la commande).

Je recommande (b) : évite l'état incohérent sans bloquer le vendeur, peu
de code. Mais c'est ta décision, pas la mienne à prendre seule.

### 5. Risques de sécurité, tests prévus, diff proposé

**Risques identifiés sur les deux règles produit** :
- Sans le `get()` croisé vers `offers/{id}.status == 'accepted'`, n'importe
  qui pourrait poser une "réservation" fantôme sur un article d'autrui —
  d'où l'obligation de cette vérification dans la règle §1.
- Le croisement `offers.reservedUntil == request.resource.data.reservedUntil`
  (égalité stricte) empêche un des deux partis de choisir une durée plus
  longue que celle réellement écrite sur l'offre au moment de
  l'acceptation — sans cette égalité, un acheteur pourrait tenter de poser
  une date de libération arbitrairement lointaine.
- La règle de libération (§2) est volontairement ouverte à "n'importe
  quel utilisateur connecté" comme l'expiration d'offre — c'est déjà le
  modèle accepté pour `offers`, donc cohérent, mais à redire explicitement
  puisque ça touche `product` cette fois (collection plus visible/large).
- Le garde-fou manquant côté `offers` (accepter uniquement si
  `product.status == 'available'`, §1) est un vrai trou à combler avant
  tout déploiement, indépendamment de la réservation elle-même.

**Tests prévus** (mêmes suites que le lot offres, nouveaux scénarios dans
`rules-test/test-offers.mjs` et un nouveau bloc `product` réservation) :
acceptation par le vendeur → produit réservé ; acceptation par
l'acheteur → produit réservé ; tentative de réservation sans offre
`accepted` réelle → refusée ; tentative avec `reservedUntil` différent de
celui de l'offre → refusée ; libération avant l'échéance → refusée ;
libération après l'échéance → acceptée, par n'importe quel utilisateur
connecté ; acceptation d'une offre sur un produit déjà non-disponible →
refusée (nouveau garde-fou) ; non-partie à l'offre ne peut ni réserver ni
libérer en dehors des règles ci-dessus.

**Diff proposé** : deux nouvelles branches dans `allow update` de
`match /product/{productId}` (réservation + libération, esquissées en §1
et §2), une condition supplémentaire dans la branche "accepter" de
`match /offers/{offerId}` (`product.status == 'available'`), aucune
modification des autres collections. Rien n'est appliqué — fichier
`firestore.rules.chantier-candidat` non modifié par cet audit.

**Non codé, non déployé.** En attente de ton accord avant d'écrire la
moindre ligne.

---

## Statut

Valeurs validées par Fatou. Lot A codé, durci, testé (voir commits
dédiés), non déployé. **Question ouverte à trancher avant le Lot B** :
comment appliquer "une seule offre pending par acheteur/article" (§2).
Ne pas commencer les écrans avant accord explicite.
