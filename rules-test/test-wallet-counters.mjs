// Tests du durcissement du 2026-11-04 (revue Ali) : wallet (plus aucune
// ecriture client) + compteurs produit (viewCount/favoriteCount/rating/
// reviewCount desormais bornes a la seule ecriture legitime que l'appli
// produit). Deux sections : cas VALIDES (ce que l'appli fait reellement,
// doit continuer de marcher) et cas REFUSES (ce qui doit desormais etre
// bloque).
//
// Teste UNIQUEMENT ../firestore.rules.chantier-candidat (jamais le fichier
// de production firestore.rules). Necessite l'emulateur Firestore local sur
// 127.0.0.1:8124 (firebase emulators:start --only firestore).
import { readFileSync } from 'node:fs';
import {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} from '@firebase/rules-unit-testing';

const PROJECT_ID = 'bamako-thrif-wallet-counters';
const RULES_PATH = '../firestore.rules.chantier-candidat';

let passed = 0;
let failed = 0;

async function check(name, fn) {
  try {
    await fn();
    passed++;
    console.log(`  OK   ${name}`);
  } catch (e) {
    failed++;
    console.log(`  FAIL ${name}`);
    console.log(`       ${e.message.split('\n')[0]}`);
  }
}

const testEnv = await initializeTestEnvironment({
  projectId: PROJECT_ID,
  firestore: { rules: readFileSync(RULES_PATH, 'utf8'), host: '127.0.0.1', port: 8124 },
});
await testEnv.clearFirestore();

const SELLER = 'seller1';
const BUYER = 'buyer1';
const STRANGER = 'stranger1';
const ADMIN = 'admin1';

function sellerCtx() { return testEnv.authenticatedContext(SELLER).firestore(); }
function buyerCtx() { return testEnv.authenticatedContext(BUYER).firestore(); }
function strangerCtx() { return testEnv.authenticatedContext(STRANGER).firestore(); }
function adminCtx() { return testEnv.authenticatedContext(ADMIN).firestore(); }

async function seed(docs) {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    for (const [path, data] of Object.entries(docs)) {
      await db.doc(path).set(data);
    }
  });
}

await seed({ 'admin_users/admin1': { role: 'admin' } });

console.log('\n========================================================');
console.log('WALLET -- plus aucune ecriture client (admin uniquement)');
console.log('========================================================');

await seed({ 'wallet/seller1': { balance: 1000, totalEarned: 1000 } });

console.log('\n--- refuse ---');
await check('le proprietaire NE PEUT PLUS ecrire son propre wallet', async () => {
  await assertFails(sellerCtx().doc('wallet/seller1').update({ balance: 2000 }));
});
await check('un inconnu NE PEUT PAS crediter le wallet d\'un autre', async () => {
  await assertFails(strangerCtx().doc('wallet/seller1').set({ balance: 999999999 }, { merge: true }));
});
await check('un inconnu NE PEUT PAS creer une transaction dans le wallet d\'un autre', async () => {
  await assertFails(strangerCtx().collection('wallet/seller1/transactions').add({ amount: 999999, type: 'credit' }));
});
await check('le proprietaire NE PEUT PAS creer sa propre transaction', async () => {
  await assertFails(sellerCtx().collection('wallet/seller1/transactions').add({ amount: 500, type: 'credit' }));
});
await check('un inconnu NE PEUT PAS lire le wallet d\'un autre', async () => {
  await assertFails(strangerCtx().doc('wallet/seller1').get());
});

console.log('\n--- valide (droits conserves) ---');
await check('le proprietaire peut TOUJOURS lire son propre wallet', async () => {
  await assertSucceeds(sellerCtx().doc('wallet/seller1').get());
});
await check('un admin (back-office) peut TOUJOURS lire n\'importe quel wallet', async () => {
  await assertSucceeds(adminCtx().doc('wallet/seller1').get());
});
await check('un admin peut ecrire/crediter un wallet', async () => {
  await assertSucceeds(adminCtx().doc('wallet/seller1').update({ balance: 2000 }));
});
await check('un admin peut creer une transaction', async () => {
  await assertSucceeds(adminCtx().collection('wallet/seller1/transactions').add({ amount: 500, type: 'credit' }));
});

console.log('\n========================================================');
console.log('PRODUCT -- compteurs (viewCount/favoriteCount/rating/reviewCount)');
console.log('========================================================');

async function freshProduct(id, overrides = {}) {
  await seed({ [`product/${id}`]: {
    sellerId: SELLER, title: 'Robe', status: 'available', price: 10000,
    viewCount: 5, favoriteCount: 2, rating: 4.0, reviewCount: 3,
    ...overrides,
  }});
}

console.log('\n--- valide : ce que l\'appli produit reellement ---');

await freshProduct('p-view');
await check('un visiteur incremente viewCount de +1 (ouverture de fiche)', async () => {
  await assertSucceeds(strangerCtx().doc('product/p-view').update({ viewCount: 6 }));
});

await freshProduct('p-view-owner');
await check('le proprietaire incremente aussi viewCount de +1 (consultation de sa propre fiche)', async () => {
  await assertSucceeds(sellerCtx().doc('product/p-view-owner').update({ viewCount: 6 }));
});

await freshProduct('p-fav-add');
await check('un acheteur ajoute un favori : favoriteCount +1', async () => {
  await assertSucceeds(buyerCtx().doc('product/p-fav-add').update({ favoriteCount: 3 }));
});

await freshProduct('p-fav-remove');
await check('un acheteur retire un favori : favoriteCount -1', async () => {
  await assertSucceeds(buyerCtx().doc('product/p-fav-remove').update({ favoriteCount: 1 }));
});

await freshProduct('p-review-new');
await check('premier avis d\'un acheteur : reviewCount +1, rating recalcule dans [0,5]', async () => {
  await assertSucceeds(buyerCtx().doc('product/p-review-new').update({ rating: 4.25, reviewCount: 4 }));
});

await freshProduct('p-review-edit');
await check('avis modifie (meme acheteur) : reviewCount inchange, rating recalcule', async () => {
  await assertSucceeds(buyerCtx().doc('product/p-review-edit').update({ rating: 3.5, reviewCount: 3 }));
});

console.log('\n--- refuse : vandalisme / valeurs impossibles ---');

await freshProduct('p-view-bad');
await check('viewCount ne peut PAS sauter de plus de 1', async () => {
  await assertFails(strangerCtx().doc('product/p-view-bad').update({ viewCount: 999999 }));
});

await freshProduct('p-fav-bad1');
await check('favoriteCount ne peut PAS etre pousse a une valeur arbitraire', async () => {
  await assertFails(strangerCtx().doc('product/p-fav-bad1').update({ favoriteCount: 999999 }));
});

await freshProduct('p-fav-bad2', { favoriteCount: 0 });
await check('favoriteCount ne peut PAS devenir negatif', async () => {
  await assertFails(strangerCtx().doc('product/p-fav-bad2').update({ favoriteCount: -1 }));
});

await freshProduct('p-rating-bad1');
await check('rating ne peut PAS depasser 5', async () => {
  await assertFails(strangerCtx().doc('product/p-rating-bad1').update({ rating: 7, reviewCount: 4 }));
});

await freshProduct('p-rating-bad2');
await check('rating ne peut PAS etre negatif', async () => {
  await assertFails(strangerCtx().doc('product/p-rating-bad2').update({ rating: -1, reviewCount: 4 }));
});

await freshProduct('p-rating-bad3');
await check('rating ne peut PAS etre une chaine de caracteres', async () => {
  await assertFails(strangerCtx().doc('product/p-rating-bad3').update({ rating: 'cinq etoiles', reviewCount: 4 }));
});

await freshProduct('p-review-bad');
await check('reviewCount ne peut PAS diminuer', async () => {
  await assertFails(strangerCtx().doc('product/p-review-bad').update({ reviewCount: 2 }));
});

await freshProduct('p-review-bad2');
await check('reviewCount ne peut PAS sauter de plus de 1', async () => {
  await assertFails(strangerCtx().doc('product/p-review-bad2').update({ reviewCount: 5 }));
});

await freshProduct('p-mixed-bad');
await check('un champ hors liste en meme temps qu\'un compteur : refuse (non-regression hasOnly)', async () => {
  await assertFails(strangerCtx().doc('product/p-mixed-bad').update({ viewCount: 6, price: 1 }));
});

console.log('\n--- non-regression : les autres droits du vendeur restent intacts ---');

await freshProduct('p-sold', { status: 'available' });
await check('le vendeur peut toujours marquer son article vendu (paiement desactive)', async () => {
  await assertSucceeds(sellerCtx().doc('product/p-sold').update({ status: 'sold' }));
});

console.log(`\n=== Resultat : ${passed} OK, ${failed} FAIL ===\n`);
process.exit(failed > 0 ? 1 : 0);
