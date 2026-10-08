# Lot 9 — Textes modifiés (fichier NON commité)

Liste complète des textes changés, avec variantes quand le texte dépend de
l'interrupteur de paiement (`config/payment`, lu via `PaymentConfigService`,
repli = désactivé).

---

## 1. Intro / onboarding — `lib/features/onboarding/presentation/pages/intro_page.dart`

### Slide 2 — dépend de `pressingEnabled` (constante, PAS de l'interrupteur paiement)

**Avant** (une seule version, affichée inconditionnellement) :
- Titre : `Vêtements vérifiés & lavés`
- Description : `Chaque article est inspecté et lavé par notre équipe avant la remise.`

**Après — variante `pressingEnabled = false` (état actuel)** :
- Titre : `Articles de seconde main, choisis avec soin`
- Description : `Chaque vendeur décrit précisément l'état de son article avant publication.`

**Après — variante `pressingEnabled = true`** : texte "Avant" ci-dessus, inchangé, conservé dans le code.

### Slide 3 — dépend de l'interrupteur paiement

**Avant** (une seule version, affichée inconditionnellement) :
- Titre : `Paiement 100% sécurisé`
- Description : `Orange Money, Moov Money et portefeuille virtuel disponibles.`

**Après — variante paiement DÉSACTIVÉ (état actuel par défaut)** :
- Titre : `Mise en relation directe`
- Description : `Discutez avec le vendeur dans l'app et mettez-vous d'accord sur la remise de l'article.`

**Après — variante paiement SÉCURISÉ/ACTIVÉ** : texte "Avant" ci-dessus, inchangé, conservé dans le code.

---

## 2. À propos — `lib/features/settings/presentation/pages/about_page.dart`

Champ "Paiement" dans la liste d'infos.

**Avant** (une seule version, affichée inconditionnellement) :
`Orange Money & Moov Money`

**Après — variante paiement DÉSACTIVÉ (état actuel par défaut)** :
`Directement entre acheteur et vendeur (phase test)`

**Après — variante paiement SÉCURISÉ/ACTIVÉ** :
`Orange Money & Moov Money` (texte "Avant", inchangé)

---

## 3. Confidentialité — `lib/features/settings/presentation/pages/privacy_page.dart`

Section "Paiements".

**Avant** (une seule version, affichée inconditionnellement) :
`Les paiements sont traités via Orange Money et Moov Money. Les fonds sont bloqués jusqu'à validation de la transaction par notre équipe.`

**Après — variante paiement DÉSACTIVÉ (état actuel par défaut)** :
`Pendant la phase de test, Danaya n'intervient pas dans le paiement : il se fait directement entre l'acheteur et le vendeur, en dehors de l'app.`

**Après — variante paiement SÉCURISÉ/ACTIVÉ** :
`Les paiements sont traités via Orange Money et Moov Money. Les fonds sont bloqués jusqu'à validation de la transaction par notre équipe.` (texte "Avant", inchangé)

---

## 4. Confirmation de paiement — `lib/features/payment/presentation/pages/payment_success_page.dart`

**Pas de variante** : cette page est structurellement inatteignable quand le
paiement est désactivé (`payment_page.dart` redirige avant de s'afficher,
donc aucune commande n'est créée pour y mener). Un seul texte, utilisé
uniquement quand le paiement est actif.

**Avant** (texte principal) :
`Votre commande a bien été enregistrée.\nL'argent est sécurisé en escrow.`

**Après** :
`Votre commande a bien été enregistrée.`

**Avant** (étape ✅) :
`Paiement reçu et sécurisé`

**Après** :
`Commande enregistrée`

---

## 5. Suivi de commande — `lib/features/order/presentation/pages/order_tracking_page.dart`

**Pas de variante** : ce changement n'est pas lié au paiement, juste au
retrait de la mention "équipe" (l'app n'a plus d'équipe terrain). S'applique
dans tous les cas.

**Avant** (SnackBar après signalement) :
`Signalement envoyé à l'équipe`

**Après** :
`Signalement envoyé`

---

## Non modifié — voir `FLUX_ANCIEN_MODELE_A_REACTIVER.md`

Deux flux entiers (pas juste du texte) laissés intacts, à traiter séparément :
1. Annulation de vente / remboursement (`order_tracking_page.dart`)
2. Validation remise en état (`notifications_page.dart`, `_RepairValidationSheet`)
