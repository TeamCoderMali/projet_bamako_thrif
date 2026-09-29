# DANAYA — État des lieux et passation

29 sept. 2026 — Document préparé pour reprise par Claude Code (accès direct au dépôt).

## ⚠️ Limitation à connaître avant de commencer

Ce document a été construit à partir d'une conversation de chat (copier-coller manuel de fichiers, pas d'accès direct au dépôt). Il reflète fidèlement ce qui a été discuté, généré et confirmé compiler, mais :
- Le dépôt back-office a été vérifié par clonage GitHub : dernier commit poussé = 382fac4 "Sanctions automatiques NC, expiration solde 3 mois, credit vendeur" — antérieur à tout le pivot Collecte/Livraison ci-dessous. Du travail est probablement en local, non commité.
- Le dépôt mobile (Flutter) n'a jamais eu d'URL communiquée — aucune vérification Git possible. Tout ce qui suit sur le mobile est basé sur des fichiers envoyés en chat et des captures de flutter analyze.
- Première action recommandée pour Claude Code : lancer git status et git log --oneline -15 sur les deux dépôts pour voir l'état réel avant de faire confiance à ce document.

> **Mise à jour 2026-09-29 (Claude Code, vérification directe des deux dépôts)** : ce document s'est révélé globalement fiable, avec 3 écarts confirmés entre ce qui était annoncé "confirmé compilant" et le code réel — voir mémoire de session / commits `ed733f5` (mobile) et `ab048c8` (back-office) pour le détail. Corrigés depuis : règles Firestore manquantes publiées en local, ligne livraison + solde en attente ajoutées, `isVerified` totalement retiré du back-office. Restent non résolus : avis textuels de Skypper et concept "Vendeur Pro" introuvables dans les deux dépôts.

## 1. Architecture générale

Mobile (bamako_thrift, Flutter) : Clean Architecture (domain/data/presentation), BLoC/Cubit, GetIt (DI), go_router, Firebase (Auth, Firestore, Storage, Messaging). Palette DANAYA : vert olive #6B7F4D, terracotta #C3653D, beige clair #F7F4EE. Police Poppins.

Modules connus : auth, catalog, chat, home, notification, onboarding, order, payment, product, profile, publish, settings, admin.

Back-office (Angular, projet_bamako_thrif_back_office) : standalone components, signals, Firebase (mêmes Firestore/Storage/Auth que le mobile — projet Firebase bamako-thrif). Déployé sur Cloudflare Workers (admin-dashboard.danaya-admin.workers.dev). Rôles : admin et relay_manager (guards authGuard/roleGuard).

Collaborateur : Skypper (skypper109) — co-développeur sur DANAYA, a écrit des parties du code jamais vues dans cette conversation (ex. le système d'avis textuels, voir §9).

## 2. CHANGEMENT MAJEUR EN COURS — pivot circuit de livraison

Ancien modèle (pressing/relais physique) abandonné : Dépôt (48h) → Inspection qualité → Retrait (7j) → frais de garde → badge "Vérifié".

Nouveau modèle (demandé par Fatou, cliente) :
1. Vendeur publie
2. Acheteur paie (séquestre)
3. Livreur externe (pas d'accès dashboard) collecte chez le vendeur
4. Livraison à l'acheteur
5. Acheteur confirme réception (fenêtre 24h pour signaler un souci)
6. Fonds libérés au vendeur

Règles métier validées par Fatou :
- Vendeur et acheteur confirment eux-mêmes (pas le livreur, qui n'a pas d'accès app) : vendeur coche "Collecté", acheteur coche "Reçu".
- Si l'acheteur confirme "Reçu" sans que le vendeur ait coché "Collecté" → passe quand même à "terminé", jamais bloqué.
- Relance vendeur si pas collecté sous 24h → PAS IMPLÉMENTÉ (nécessite Cloud Functions programmées, absentes — projet probablement sur plan Firebase gratuit "Spark", pas "Blaze").
- Libération des fonds : décision prise par défaut = immédiate au clic "Reçu" (pas de mécanisme d'attente 24h automatique possible sans Cloud Functions). Pas de confirmation explicite de Fatou sur ce point précis — à revalider avec elle si besoin de la variante B (libération manuelle admin après 24h).
- Statuts commande (collection Firestore order) : pending (vendu) → collecte → completed (reçu) → (ou cancelled).

### État du code — CONFIRMÉ compilant (flutter analyze passé)

- `lib/features/order/presentation/pages/order_tracking_page.dart` — réécrit entièrement : timeline Vendu/Collecté/Reçu, bouton vendeur "Marquer collecté", bouton acheteur "Confirmer réception" (avec crédit portefeuille immédiat côté client), bouton "Signaler un problème" (fenêtre 24h post-réception), formulaire de signalement avec choix intégré "Garder avec dédommagement" / "Annuler et être remboursé" (avoir 3 mois ou demande de remboursement manuelle). **Vérifié réel le 2026-09-29.**
- `lib/features/product/domain/entities/product_entity.dart` + `product_model.dart` — champ isVerified retiré (badge "Vérifié DANAYA" abandonné avec le pivot). **Vérifié réel.**
- `lib/features/home/presentation/pages/home_page.dart` + `lib/features/product/presentation/pages/product_detail_page.dart` — affichage du badge retiré.
- `lib/features/payment/presentation/pages/payment_page.dart` — ligne informative "Livraison (à payer au livreur) : ~1000-2000 FCFA selon la zone" ajoutée (montant placeholder, pas de vraie grille tarifaire). Double-crédit vendeur au paiement corrigé (le crédit ne se fait plus qu'à la réception confirmée). **⚠️ Absente au 2026-09-29, ajoutée ce jour-là (commit ed733f5).**

### État du code — GÉNÉRÉ mais PAS reconfirmé par un flutter analyze séparé

- `lib/features/profile/presentation/pages/wallet_page.dart` — ajout d'un montant "X FCFA en attente" (commandes vendeur non terminées). **⚠️ Absente au 2026-09-29, ajoutée ce jour-là (commit ed733f5), flutter analyze OK.**

## 3. Back-office — nettoyage du circuit pressing

### Confirmé appliqué ET buildé (npx ng build réussi, back-office)

- Supprimés : `src/features/articles/relay/relay-articles.component.ts`, `src/features/disputes/relay/non-conformities.component.ts` (créait la NC à l'inspection relais — obsolète, c'est l'acheteur qui signale désormais).
- `src/app/app.routes.ts` — routes relay/articles et relay/non-conformities retirées ; route relay/disputes ajoutée.
- `src/features/dashboard/relay-dashboard/relay-dashboard.component.ts` — réécrit : stats litiges ("À évaluer", "Chez le vendeur", "Résolus ce mois") au lieu de stats pressing.
- `src/features/disputes/relay/relay-disputes.component.ts` — nouveau fichier, seul vrai rôle restant du relais : comparaison photo annonce (déjà en ligne) vs photo du signalement acheteur, évaluation du coût de remise en état, notification au vendeur (24h pour accepter).
- `src/features/disputes/disputes.component.ts` (admin) — simplifié, la section d'évaluation déplacée vers le relais pour éviter la double logique.

Tous ces fichiers étaient encore non commités au 2026-09-29 — **commités le 2026-09-29 (commit ab048c8)**, build re-vérifié OK avant commit.

### Généré, confirmé build/commité le 2026-09-29 (commit ab048c8)

- `src/core/services/data.service.ts` — isVerified retiré de l'interface Product + méthode updateProductVerified() supprimée. **⚠️ N'était PAS fait au 2026-09-29 (champ + méthode encore présents, code mort) — corrigé et vérifié par rebuild ce jour-là.**
- `src/features/articles/detail/article-detail.component.ts` — badge "Vérifié DANAYA" et bouton associé retirés. Vérifié réel.
- `src/features/reports/relay/relay-history.component.ts` — champ updatedAt renommé en receivedAt (cohérence avec le nouveau statut "Reçu"). Vérifié réel.

### Fichiers mentionnés mais jamais vus en entier

- `src/features/reports/relay/relay-history.component.scss` — **existe bien** (vérifié 2026-09-29, contrairement au doute initial).
- `src/features/settings/relay/relay-profile.component.ts` — existe, jamais lié au pivot, non modifié.

## 4. Sécurité Firestore/Storage

**✅ Publié en local le 2026-09-29 (commit ed733f5 du dépôt mobile), PAS ENCORE DÉPLOYÉ sur Firebase** — règles ajoutées à `firestore.rules` :
- Extension de `match /product/{productId}` : `allow update` permet désormais aussi le changement de `status`/`updatedAt` vers `sold`/`available` par un non-vendeur (nécessaire pour que l'acheteur repasse un produit en `available` lors d'une annulation de vente).
- `match /wallet/{uid}` + sous-collection `transactions` ajoutés.
- `match /non_conformities/{ncId}` ajouté.
- `match /refund_requests/{id}` ajouté.

⚠️ Faille connue et acceptée temporairement : `allow write: if isAuthenticated()` sur wallet permet à n'importe quel utilisateur connecté de modifier n'importe quel solde. C'est nécessaire tant que le crédit vendeur se fait côté client (app mobile) faute de Cloud Functions. À corriger en priorité avant un vrai lancement : déplacer la logique de crédit vers une Cloud Function déclenchée sur la mise à jour du statut de commande.

Règle Storage `non_conformities/{userId}/{fileName}` déjà en place et compatible (l'acheteur uploade sous son propre uid) — aucune modification nécessaire ici.

**Reste à faire : déployer ces règles sur Firebase (`firebase deploy --only firestore:rules`) — pas fait, à confirmer avec l'utilisateur avant de le faire.**

## 5. Fonctionnalités confirmées fonctionnelles (hors pivot)

- Notation produit (étoiles, transaction Firestore anti-double-vote) — mobile + reflété admin.
- Portefeuille : solde recalculé en direct depuis les transactions, crédits expirant à 3 mois (grisés/barrés visuellement une fois expirés).
- Sanctions automatiques : 3 non-conformités = suspension 7j, 5 = ban (isBanned/suspendedUntil sur users/{uid}), vérifié au login (auth_repository_impl.dart, fonction _enforceSanctions) — bloque aussi les comptes déjà connectés au redémarrage de l'app.
- Google Sign-In : fonctionnel et confirmé.
- Facebook Sign-In : bouton présent, backend non implémenté — bloqué sur la vérification SMS de Meta for Developers (numéro malien +223), non résolu après plusieurs tentatives. Nécessite un compte Meta Developer validé.
- Logo : détouré (fond transparent), intégré sur Splash/Welcome/Login/Register/Home (icône + wordmark). Icône d'app (launcher) changée pour un monogramme "D" — nécessite android: "launcher_icon" + config adaptive icon dans pubspec.yaml (piège rencontré : sans ça, Android garde l'ancienne icône en cache même après régénération). **Note : un stash git local ("WIP on feature/frontend-auth: logo DANAYA sur page about") contient du travail non appliqué sur les icônes — à examiner/appliquer ou abandonner.**
- États du vêtement : 4 valeurs conformes au cahier des charges (satisfaisant, bon, tresSatisfaisant, neufAvecEtiquette), avec rétrocompatibilité pour les anciens produits (_parseCondition avec mapping des anciennes valeurs).
- Notifications instantanées (Firestore, pas programmées) : fonctionnelles pour le flux "validation remise en état" (type repairValidation), avec fiche de détail + bouton "Accepter" côté vendeur.

## 6. Jamais commencé / jamais vérifié

- Paiement réel (Orange Money / Moov Money) — `_callPaymentGateway()` dans payment_page.dart est une simulation pure (Future.delayed + succès automatique). Nécessite un serveur intermédiaire (Cloud Function + CinetPay/Paydunya), les clés secrètes ne doivent jamais être côté client.
- Notifications programmées (rappels 48h/J+5/J+7, relance collecte 24h) — nécessite Cloud Functions, changement de plan Firebase ("Blaze", payant à l'usage). **Voir aussi §10, nouvelle demande similaire.**
- Chat — jamais testé ni relu dans cette conversation, existe dans le code (lib/features/chat/) mais fonctionnement réel inconnu.
- Recherche/filtres catalogue — jamais vérifié.
- Avis textuels réservés aux Vendeurs Pro — demande récente de Fatou : les avis écrits (bidirectionnels acheteur/vendeur, mentionnés comme "inchangés" dans le pivot) doivent être limités aux "Vendeurs Pro", les vendeurs classiques gardant uniquement la note par étoiles. Bloqué : le fichier où sont écrits/affichés ces avis textuels n'a jamais été communiqué dans cette conversation (probablement écrit par Skypper). **Confirmé introuvable dans les deux dépôts au 2026-09-29** — à redemander à Skypper. Le concept "Vendeur Pro" lui-même n'existe pas encore dans le code (section 4.9 du cahier des charges, prévue V2) — il faudra a minima un champ isPro sur UserEntity/users/{uid} pour conditionner l'affichage.
- Vendeur Pro / Marketplace directe (cahier des charges 4.9) — V2, jamais commencé.
- Boost d'annonce, modération IA, suggestion de prix IA — V2, jamais commencé.

## 7. Cahier des charges — écarts connus non résolus

- Frais de garde (100-200 FCFA/jour après J+7) — logique liée à l'ancien circuit pressing, obsolète avec le pivot livraison, à confirmer avec Fatou si un équivalent est encore souhaité (retard de collecte/livraison ?).
- Montant de livraison sur l'écran paiement = placeholder texte, pas de vraie grille tarifaire par zone.

## 8. Comptes et accès

- Dashboard admin : admin@danaya.ml — mot de passe à changer avant tout envoi à Fatou (était password123, faible, accès complet finances/utilisateurs — statut du changement non confirmé dans cette conversation).
- Firebase project : bamako-thrif.
- Repo back-office : github.com/TeamCoderMali/projet_bamako_thrif_back_office.
- Repo mobile : `C:\projet_bamako_thrif` (local), remote à vérifier avec `git remote -v`.

## 9. Prochaines étapes suggérées (mise à jour 2026-09-29)

1. ~~git status + git log sur les deux dépôts réels~~ — fait.
2. ~~Vérifier/corriger wallet_page.dart~~ — fait, pas de bug de syntaxe, feature "en attente" ajoutée.
3. ~~Publier les règles Firestore du §4~~ — fait en local (commit ed733f5), **pas encore déployé sur Firebase**.
4. ~~Committer les fichiers back-office "générés mais pas confirmés"~~ — fait (commit ab048c8), **pas encore poussé sur GitHub**.
5. Retrouver le fichier des avis textuels (demander à Skypper ou chercher review/avis dans le repo) pour la restriction Vendeur Pro — toujours à faire, aucune piste locale.
6. Revalider avec Fatou : libération des fonds immédiate vs délai 24h (décision prise par défaut, jamais confirmée explicitement) — toujours en attente.
7. Décider si on pousse (GitHub) et déploie (Firebase rules + Cloudflare back-office) les commits locaux du 2026-09-29.

## 10. Backlog — en attente de validation client (NE PAS DÉVELOPPER)

### Notifications de relance utilisateurs inactifs (demande du 2026-09-29)

Nouvelle demande de la cliente, **en attente de confirmation définitive sous 2-3 jours (~2026-10-02)**. Ne pas commencer le développement avant validation.

Système de notifications de relance pour les utilisateurs inactifs (n'ont plus vendu ni acheté depuis un moment), avec un message adapté à leur profil :
- Si l'utilisateur a l'habitude de vendre → message orienté vente ("remets en vente tes articles", façon Vinted).
- Si l'utilisateur a l'habitude d'acheter → message orienté achat.

**Contrainte technique** : nécessite des Cloud Functions programmées (vérification périodique de l'inactivité), donc un passage au forfait Firebase "Blaze" (payant à l'usage) — le projet est probablement encore sur le plan gratuit "Spark" (voir §2 et §6, même contrainte que les autres notifications programmées jamais implémentées).

**Pourquoi attendre** : passage à Blaze = engagement financier récurrent, décision qui doit venir de la cliente, pas à anticiper techniquement avant son feu vert.
