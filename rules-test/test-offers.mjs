// Tests des regles Firestore candidates pour la collection "offers"
// (lot A du systeme d'offres, voir PLAN_OFFRES.md a la racine du repo).
// Necessite un emulateur Firestore local (firebase emulators:start --only
// firestore --config firebase.json), lui-meme necessitant un JDK 21+
// (firebase-tools >= 14 ne supporte plus Java < 21). Voir README.md.
import { readFileSync } from 'node:fs';
import {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} from '@firebase/rules-unit-testing';

const PROJECT_ID = 'bamako-thrif-offers-test';
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
  firestore: {
    rules: readFileSync(RULES_PATH, 'utf8'),
    host: '127.0.0.1',
    port: 8123,
  },
});

const SELLER = 'seller1';
const BUYER = 'buyer1';
const OTHER_BUYER = 'buyer2';
const STRANGER = 'stranger1';
const ADMIN = 'admin1';

async function seed(docs) {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    for (const [path, data] of Object.entries(docs)) {
      await db.doc(path).set(data);
    }
  });
}

function sellerCtx() { return testEnv.authenticatedContext(SELLER).firestore(); }
function buyerCtx() { return testEnv.authenticatedContext(BUYER).firestore(); }
function otherBuyerCtx() { return testEnv.authenticatedContext(OTHER_BUYER).firestore(); }
function strangerCtx() { return testEnv.authenticatedContext(STRANGER).firestore(); }
function adminCtx() { return testEnv.authenticatedContext(ADMIN).firestore(); }

await seed({
  'admin_users/admin1': { role: 'admin' },
  'product/p1': { sellerId: SELLER, title: 'Robe', status: 'available', price: 10000 },
  'product/p-sold': { sellerId: SELLER, title: 'Vendu', status: 'sold', price: 10000 },
});

function baseOffer(overrides = {}) {
  return {
    productId: 'p1',
    productTitle: 'Robe',
    sellerId: SELLER,
    buyerId: BUYER,
    originalPrice: 10000,
    currentPrice: 6000,
    round: 1,
    turn: 'seller',
    status: 'pending',
    respondBy: new Date(Date.now() + 48 * 3600 * 1000),
    createdAt: new Date(),
    ...overrides,
  };
}

console.log('\n=== Creation : repli config/offers absent (ratio 0.5 par defaut) ===');

await check('acheteur cree une offre valide (>=50%, < prix) : OK', async () => {
  await assertSucceeds(buyerCtx().collection('offers').add(baseOffer()));
});

await check('offre a exactement 50% du prix : OK (limite incluse)', async () => {
  await assertSucceeds(
    buyerCtx().collection('offers').add(baseOffer({ currentPrice: 5000 }))
  );
});

await check('offre en dessous de 50% du prix : refusee', async () => {
  await assertFails(
    buyerCtx().collection('offers').add(baseOffer({ currentPrice: 4999 }))
  );
});

await check('offre egale au prix de depart (pas strictement inferieure) : refusee', async () => {
  await assertFails(
    buyerCtx().collection('offers').add(baseOffer({ currentPrice: 10000 }))
  );
});

await check('offre au-dessus du prix de depart : refusee', async () => {
  await assertFails(
    buyerCtx().collection('offers').add(baseOffer({ currentPrice: 12000 }))
  );
});

await check('sellerId ne correspond pas au vrai vendeur du produit : refusee', async () => {
  await assertFails(
    buyerCtx().collection('offers').add(baseOffer({ sellerId: STRANGER }))
  );
});

await check('produit non disponible (vendu) : refusee', async () => {
  await assertFails(
    buyerCtx().collection('offers').add(
      baseOffer({ productId: 'p-sold', sellerId: SELLER })
    )
  );
});

await check('round different de 1 a la creation : refusee', async () => {
  await assertFails(
    buyerCtx().collection('offers').add(baseOffer({ round: 2 }))
  );
});

await check('turn different de "seller" a la creation : refusee', async () => {
  await assertFails(
    buyerCtx().collection('offers').add(baseOffer({ turn: 'buyer' }))
  );
});

await check('buyerId usurpe (pas request.auth.uid) : refusee', async () => {
  await assertFails(
    buyerCtx().collection('offers').add(baseOffer({ buyerId: OTHER_BUYER }))
  );
});

await check('offre sur son propre article (buyerId == sellerId) : refusee', async () => {
  await seed({ 'product/p-own': { sellerId: SELLER, title: 'Mien', status: 'available', price: 10000 } });
  await assertFails(
    sellerCtx().collection('offers').add(
      baseOffer({ productId: 'p-own', buyerId: SELLER, sellerId: SELLER })
    )
  );
});

console.log('\n=== Creation : config/offers present avec ratio personnalise ===');

await seed({ 'config/offers': { minOfferRatio: 0.7, maxRounds: 2 } });

await check('ratio personnalise (0.7) : offre a 60% refusee', async () => {
  await assertFails(
    buyerCtx().collection('offers').add(baseOffer({ currentPrice: 6000 }))
  );
});

await check('ratio personnalise (0.7) : offre a 70% acceptee', async () => {
  await assertSucceeds(
    buyerCtx().collection('offers').add(baseOffer({ currentPrice: 7000 }))
  );
});

// Reinitialise config/offers avant les tests suivants : ils supposent tous
// le repli par defaut (ratio 0.5, max 3 rounds), pas le ratio/plafond
// personnalise teste ci-dessus.
await testEnv.withSecurityRulesDisabled(async (ctx) => {
  await ctx.firestore().doc('config/offers').delete();
});

console.log('\n=== Lecture ===');

await seed({
  'offers/o1': baseOffer(),
});

await check('acheteur proprietaire peut lire son offre', async () => {
  await assertSucceeds(buyerCtx().doc('offers/o1').get());
});

await check('vendeur concerne peut lire l\'offre', async () => {
  await assertSucceeds(sellerCtx().doc('offers/o1').get());
});

await check('admin peut lire n\'importe quelle offre', async () => {
  await assertSucceeds(adminCtx().doc('offers/o1').get());
});

await check('un tiers ne peut pas lire l\'offre', async () => {
  await assertFails(strangerCtx().doc('offers/o1').get());
});

console.log('\n=== Mise a jour : tour du vendeur ===');

await seed({ 'offers/o-seller-turn': baseOffer() });

await check('vendeur accepte quand c\'est son tour', async () => {
  await assertSucceeds(
    sellerCtx().doc('offers/o-seller-turn').update({ status: 'accepted' })
  );
});

await seed({ 'offers/o-seller-turn2': baseOffer() });

await check('vendeur refuse quand c\'est son tour', async () => {
  await assertSucceeds(
    sellerCtx().doc('offers/o-seller-turn2').update({ status: 'rejected' })
  );
});

await seed({ 'offers/o-seller-counter': baseOffer() });

await check('vendeur contre-propose (round+1, tour passe a l\'acheteur)', async () => {
  await assertSucceeds(
    sellerCtx().doc('offers/o-seller-counter').update({
      currentPrice: 8000, round: 2, turn: 'buyer', status: 'pending',
    })
  );
});

await check('contre-offre du vendeur en dessous du ratio minimal : refusee', async () => {
  await seed({ 'offers/o-counter-too-low': baseOffer() });
  await assertFails(
    sellerCtx().doc('offers/o-counter-too-low').update({
      currentPrice: 4999, round: 2, turn: 'buyer', status: 'pending',
    })
  );
});

await check('contre-offre du vendeur au-dessus du prix de depart : refusee', async () => {
  await seed({ 'offers/o-counter-too-high': baseOffer() });
  await assertFails(
    sellerCtx().doc('offers/o-counter-too-high').update({
      currentPrice: 10001, round: 2, turn: 'buyer', status: 'pending',
    })
  );
});

await check('acheteur ne peut pas agir quand ce n\'est pas son tour', async () => {
  await seed({ 'offers/o-not-buyer-turn': baseOffer() }); // turn: seller
  await assertFails(
    buyerCtx().doc('offers/o-not-buyer-turn').update({ status: 'accepted' })
  );
});

console.log('\n=== Mise a jour : tour de l\'acheteur (apres contre-offre) ===');

await seed({
  'offers/o-buyer-turn': baseOffer({ turn: 'buyer', round: 2, currentPrice: 8000 }),
});

await check('acheteur accepte quand c\'est son tour', async () => {
  await assertSucceeds(
    buyerCtx().doc('offers/o-buyer-turn').update({ status: 'accepted' })
  );
});

await seed({
  'offers/o-buyer-counter': baseOffer({ turn: 'buyer', round: 2, currentPrice: 8000 }),
});

await check('acheteur contre-propose a son tour (round+1, tour revient au vendeur)', async () => {
  await assertSucceeds(
    buyerCtx().doc('offers/o-buyer-counter').update({
      currentPrice: 7000, round: 3, turn: 'seller', status: 'pending',
    })
  );
});

await check('vendeur ne peut pas agir quand ce n\'est pas son tour', async () => {
  await seed({
    'offers/o-not-seller-turn': baseOffer({ turn: 'buyer', round: 2, currentPrice: 8000 }),
  });
  await assertFails(
    sellerCtx().doc('offers/o-not-seller-turn').update({ status: 'accepted' })
  );
});

console.log('\n=== Mise a jour : plafond de rounds (config par defaut, max 3) ===');

await seed({
  // round 3 = round max par defaut : plus de contre-offre permise, seulement accepter/refuser
  'offers/o-max-round': baseOffer({ round: 3, turn: 'seller' }),
});

await check('contre-offre refusee une fois le plafond de rounds atteint', async () => {
  await assertFails(
    sellerCtx().doc('offers/o-max-round').update({
      currentPrice: 7000, round: 4, turn: 'buyer', status: 'pending',
    })
  );
});

await check('accepter reste possible meme au plafond de rounds', async () => {
  await assertSucceeds(
    sellerCtx().doc('offers/o-max-round').update({ status: 'accepted' })
  );
});

console.log('\n=== Mise a jour : annulation par l\'acheteur ===');

await seed({ 'offers/o-cancel-ok': baseOffer() }); // turn: seller

await check('acheteur annule tant que le vendeur n\'a pas repondu', async () => {
  await assertSucceeds(
    buyerCtx().doc('offers/o-cancel-ok').update({ status: 'cancelled' })
  );
});

await seed({
  'offers/o-cancel-wrong-turn': baseOffer({ turn: 'buyer', round: 2, currentPrice: 8000 }),
});

await check('acheteur ne peut pas annuler quand c\'est a lui de repondre (son tour)', async () => {
  await assertFails(
    buyerCtx().doc('offers/o-cancel-wrong-turn').update({ status: 'cancelled' })
  );
});

console.log('\n=== Mise a jour : expiration paresseuse ===');

// respondBy dans le passe : condition necessaire pour qu'une expiration soit
// desormais acceptee (durcissement demande).
function expiredOffer(overrides = {}) {
  return baseOffer({ respondBy: new Date(Date.now() - 60 * 1000), ...overrides });
}

await seed({ 'offers/o-expire-by-buyer': expiredOffer() });

await check('l\'acheteur peut faire expirer une offre (statut uniquement, respondBy depasse)', async () => {
  await assertSucceeds(
    buyerCtx().doc('offers/o-expire-by-buyer').update({ status: 'expired' })
  );
});

await seed({ 'offers/o-expire-by-seller': expiredOffer() });

await check('le vendeur peut aussi faire expirer une offre (respondBy depasse)', async () => {
  await assertSucceeds(
    sellerCtx().doc('offers/o-expire-by-seller').update({ status: 'expired' })
  );
});

await check('un tiers ne peut pas faire expirer une offre dont il n\'est pas partie', async () => {
  await seed({ 'offers/o-expire-stranger': expiredOffer() });
  await assertFails(
    strangerCtx().doc('offers/o-expire-stranger').update({ status: 'expired' })
  );
});

await check('expiration refusee avant que respondBy soit depasse', async () => {
  await seed({ 'offers/o-expire-too-early': baseOffer() }); // respondBy dans le futur
  await assertFails(
    buyerCtx().doc('offers/o-expire-too-early').update({ status: 'expired' })
  );
});

await check('impossible d\'expirer une offre deja acceptee (pas "pending")', async () => {
  await seed({
    'offers/o-expire-accepted': expiredOffer({ status: 'accepted' }),
  });
  await assertFails(
    buyerCtx().doc('offers/o-expire-accepted').update({ status: 'expired' })
  );
});

console.log('\n=== Mise a jour : champs immuables ===');

await seed({ 'offers/o-immutable': baseOffer() });

await check('le vendeur ne peut pas modifier originalPrice en acceptant', async () => {
  await assertFails(
    sellerCtx().doc('offers/o-immutable').update({ status: 'accepted', originalPrice: 1 })
  );
});

await check('le vendeur ne peut pas modifier buyerId', async () => {
  await assertFails(
    sellerCtx().doc('offers/o-immutable').update({ status: 'accepted', buyerId: OTHER_BUYER })
  );
});

await check('le vendeur ne peut pas changer currentPrice en acceptant', async () => {
  await seed({ 'offers/o-accept-price-change': baseOffer() });
  await assertFails(
    sellerCtx().doc('offers/o-accept-price-change').update({ status: 'accepted', currentPrice: 1 })
  );
});

console.log(`\n=== Resultat : ${passed} OK, ${failed} FAIL ===\n`);
await testEnv.cleanup();
process.exit(failed > 0 ? 1 : 0);
