# Tests de règles Firestore — lot "offres"

Teste `../firestore.rules.chantier-candidat` (jamais le fichier de production
`firestore.rules`) via l'émulateur Firestore local.

## Prérequis

- Node.js (déjà présent pour ce projet).
- **JDK 21 ou plus récent.** `firebase-tools` (>= 14) refuse de démarrer
  l'émulateur Firestore avec une version de Java plus ancienne
  ("firebase-tools no longer supports Java version before 21"). Sur cette
  machine au moment de l'écriture de ce lot, seul Java 14 est installé —
  les tests ci-dessous sont écrits mais **n'ont pas pu être exécutés**.
  Vérifier avec `java -version` avant de lancer quoi que ce soit.

## Installation

```
cd rules-test
npm install
```

## Lancer les tests

Dans un terminal :
```
firebase emulators:start --only firestore --config firebase.json --project bamako-thrif-offers-test
```

Dans un second terminal, une fois l'émulateur démarré :
```
npm run test:offers
```

## Important

Ces tests ne touchent QUE l'émulateur local (projet factice
`bamako-thrif-offers-test`) — aucun risque pour les données réelles. Ils ne
déploient rien. Le déploiement de `firestore.rules.chantier-candidat` reste
une décision séparée, à prendre seulement après que ces tests soient
effectivement passés.
