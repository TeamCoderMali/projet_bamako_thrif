import { readFileSync } from 'node:fs';
import {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} from '@firebase/rules-unit-testing';

const PROJECT_ID = 'bamako-thrif-chantier-test';
const RULES_PATH = 'C:\\projet_bamako_thrif\\firestore.rules.chantier-candidat';

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
  firestore: { rules: readFileSync(RULES_PATH, 'utf8'), host: '127.0.0.1', port: 8123 },
});

const SELLER = 'seller1';
const OTHER_SELLER = 'seller2';
const BUYER = 'buyer1';
const ADMIN = 'admin1';
const RELAY = 'relay1';

async function seed(docs) {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    for (const [path, data] of Object.entries(docs)) {
      await db.doc(path).set(data);
    }
  });
}

function sellerCtx() { return testEnv.authenticatedContext(SELLER).firestore(); }
function otherSellerCtx() { return testEnv.authenticatedContext(OTHER_SELLER).firestore(); }
function buyerCtx() { return testEnv.authenticatedContext(BUYER).firestore(); }
function adminCtx() { return testEnv.authenticatedContext(ADMIN).firestore(); }
function relayCtx() { return testEnv.authenticatedContext(RELAY).firestore(); }
function visitorCtx() { return testEnv.unauthenticatedContext().firestore(); }

await seed({
  'admin_users/admin1': { role: 'admin' },
  'admin_users/relay1': { role: 'relay_manager' },
});

console.log('\n=== config/payment : lecture ===');

await check('visiteur (non connecte) NE PEUT PAS lire config/payment', async () => {
  await seed({ 'config/payment': { enabled: true } });
  await assertFails(visitorCtx().doc('config/payment').get());
});

await check('acheteur connecte peut lire config/payment', async () => {
  await assertSucceeds(buyerCtx().doc('config/payment').get());
});

await check('vendeur connecte peut lire config/payment', async () => {
  await assertSucceeds(sellerCtx().doc('config/payment').get());
});

console.log('\n=== config/payment : ecriture ===');

await check('admin peut ecrire config/payment (desactiver)', async () => {
  await assertSucceeds(adminCtx().doc('config/payment').set({ enabled: false }));
});

await check('vendeur NE PEUT PAS ecrire config/payment', async () => {
  await assertFails(sellerCtx().doc('config/payment').set({ enabled: false }));
});

await check('relais NE PEUT PAS ecrire config/payment', async () => {
  await assertFails(relayCtx().doc('config/payment').set({ enabled: false }));
});

console.log('\n=== reports : creation ===');

await check('acheteur cree un signalement avec son propre reporterId (ID deterministe)', async () => {
  await assertSucceeds(
    buyerCtx().doc('reports/buyer1_product_p1').set({
      reporterId: BUYER, targetType: 'product', targetId: 'p1',
      reasonCode: 'Autre', status: 'nouveau',
    })
  );
});

await check('vendeur NE PEUT PAS creer un signalement avec le reporterId d\'un autre', async () => {
  await assertFails(
    sellerCtx().doc('reports/buyer1_chat_c1').set({
      reporterId: BUYER, targetType: 'chat', targetId: 'c1',
      reasonCode: 'Autre', status: 'nouveau',
    })
  );
});

await check('visiteur (non connecte) NE PEUT PAS creer de signalement', async () => {
  await assertFails(
    visitorCtx().doc('reports/anon_product_p1').set({
      reporterId: 'anon', targetType: 'product', targetId: 'p1',
      reasonCode: 'Autre', status: 'nouveau',
    })
  );
});

await check('ID ne correspondant pas a reporterId_targetType_targetId : refuse', async () => {
  await assertFails(
    buyerCtx().doc('reports/id-invalide').set({
      reporterId: BUYER, targetType: 'product', targetId: 'p99',
      reasonCode: 'Autre', status: 'nouveau',
    })
  );
});

await check('signalement en double sur le meme objet : refuse (deja existant)', async () => {
  await seed({
    'reports/buyer1_product_p-dup': { reporterId: BUYER, targetType: 'product', targetId: 'p-dup', reasonCode: 'Autre', status: 'nouveau' },
  });
  await assertFails(
    buyerCtx().doc('reports/buyer1_product_p-dup').set({
      reporterId: BUYER, targetType: 'product', targetId: 'p-dup',
      reasonCode: 'Contenu inapproprié', status: 'nouveau',
    })
  );
});

console.log('\n=== reports : lecture / traitement ===');

// ID au format reel {reporterId}_{targetType}_{targetId} (pas un ID
// arbitraire "r1") : necessaire depuis le 2026-10-09, la regle de
// lecture du signaleur se base sur ce format (id.split('_')[0]).
await seed({
  'reports/buyer1_product_p1': { reporterId: BUYER, targetType: 'product', targetId: 'p1', reasonCode: 'Autre', status: 'nouveau' },
});

await check('admin peut lire un signalement', async () => {
  await assertSucceeds(adminCtx().doc('reports/buyer1_product_p1').get());
});

await check('admin peut marquer un signalement traite', async () => {
  await assertSucceeds(adminCtx().doc('reports/buyer1_product_p1').update({ status: 'traite' }));
});

// Corrige le 2026-10-09 : le signaleur doit pouvoir relire SON PROPRE
// signalement (report_dialog.dart fait un .get() avant meme d'afficher
// le formulaire, pour detecter un doublon -- avec l'ancienne regle
// isAdmin()-seul, CE .get() echouait a chaque fois, meme sur un premier
// signalement jamais fait, cassant la fonctionnalite entiere).
await check('le signaleur peut relire son propre signalement existant', async () => {
  await assertSucceeds(buyerCtx().doc('reports/buyer1_product_p1').get());
});

await check('le signaleur peut verifier sa propre place avant tout signalement (exists=false, pas permission-denied)', async () => {
  const snap = await assertSucceeds(buyerCtx().doc('reports/buyer1_product_jamais-signale').get());
  if (snap.exists) throw new Error('le document ne devrait pas exister');
});

await check('un tiers NE PEUT PAS lire le signalement de quelqu\'un d\'autre (existant)', async () => {
  await assertFails(sellerCtx().doc('reports/buyer1_product_p1').get());
});

await check('un tiers NE PEUT PAS sonder la place de signalement d\'un autre (inexistante)', async () => {
  await assertFails(sellerCtx().doc('reports/buyer1_product_jamais-signale-2').get());
});

await check('relais NE PEUT PAS lire le signalement de quelqu\'un d\'autre (admin uniquement selon la consigne)', async () => {
  await assertFails(relayCtx().doc('reports/buyer1_product_p1').get());
});

await check('le signaleur ne peut toujours pas traiter (update) son propre signalement', async () => {
  await assertFails(buyerCtx().doc('reports/buyer1_product_p1').update({ status: 'traite' }));
});

console.log('\n=== non_conformities : ID deterministe (audit du 2026-10-08) ===');

await seed({
  'order/o-nc1': { buyerId: BUYER, sellerId: SELLER, productId: 'p1' },
});

await check('acheteur cree une non-conformite avec le bon ID {orderId}_{buyerId}', async () => {
  await assertSucceeds(
    buyerCtx().doc('non_conformities/o-nc1_buyer1').set({
      orderId: 'o-nc1', buyerId: BUYER, sellerId: SELLER, productId: 'p1',
      reason: 'Article endommagé', status: 'buyer_continue',
    })
  );
});

await check('ID ne correspondant pas a orderId_buyerId : refuse', async () => {
  await assertFails(
    buyerCtx().doc('non_conformities/id-invalide').set({
      orderId: 'o-nc1', buyerId: BUYER, sellerId: SELLER, productId: 'p1',
      reason: 'Article endommagé', status: 'buyer_continue',
    })
  );
});

await check('non-conformite en double sur la meme commande : refusee (deja existante)', async () => {
  await seed({
    'non_conformities/o-nc-dup_buyer1': { orderId: 'o-nc-dup', buyerId: BUYER, sellerId: SELLER, productId: 'p1', status: 'buyer_continue' },
  });
  await assertFails(
    buyerCtx().doc('non_conformities/o-nc-dup_buyer1').set({
      orderId: 'o-nc-dup', buyerId: BUYER, sellerId: SELLER, productId: 'p1',
      reason: 'Autre', status: 'buyer_continue',
    })
  );
});

await check('un tiers NE PEUT PAS creer une non-conformite en usurpant un autre buyerId', async () => {
  await assertFails(
    otherSellerCtx().doc('non_conformities/o-nc1_buyer1').set({
      orderId: 'o-nc1', buyerId: BUYER, sellerId: SELLER, productId: 'p1',
      reason: 'Autre', status: 'buyer_continue',
    })
  );
});

// Corrige le 2026-10-09 : "allow read, update" combinait les deux
// operations sous une seule condition qui reference request.resource
// (valide seulement pour une ecriture) -- une lecture pure plantait
// TOUJOURS ("Property resource is undefined"), meme sur un document
// existant. Cassait notamment la fiche vendeur "Validation remise en
// etat" (notifications_page.dart:183-187, StreamBuilder bloque en
// chargement infini). Jamais teste avant (seulement des update()).
await check('vendeur peut lire une non-conformite existante le concernant (fiche "Validation remise en etat")', async () => {
  await assertSucceeds(sellerCtx().doc('non_conformities/o-nc1_buyer1').get());
});

await check('acheteur peut relire sa propre non-conformite existante', async () => {
  await assertSucceeds(buyerCtx().doc('non_conformities/o-nc1_buyer1').get());
});

await check('un tiers NE PEUT PAS lire une non-conformite dont il n\'est pas partie', async () => {
  await assertFails(otherSellerCtx().doc('non_conformities/o-nc1_buyer1').get());
});

await check('le vendeur peut mettre a jour le statut (transition existante preservee)', async () => {
  await assertSucceeds(
    sellerCtx().doc('non_conformities/o-nc1_buyer1').update({ status: 'seller_accepted' })
  );
});

await check('un non-admin NE PEUT PAS changer les champs identifiants via update', async () => {
  await assertFails(
    sellerCtx().doc('non_conformities/o-nc1_buyer1').update({ buyerId: OTHER_SELLER })
  );
});

// Corrige le 2026-10-09 : order_tracking_page.dart:137-140 fait un
// .doc(ncId).get() avant TOUTE premiere declaration de probleme sur une
// commande, pour detecter un doublon. Avec l'ancienne regle (resource.data
// sans garde), ce .get() plantait des le premier essai sur chaque
// commande, pas seulement sur les doublons.
await check('acheteur peut verifier sa propre place avant toute declaration (exists=false, pas permission-denied)', async () => {
  await seed({ 'order/o-nc-jamais': { buyerId: BUYER, sellerId: SELLER, productId: 'p1' } });
  const snap = await assertSucceeds(buyerCtx().doc('non_conformities/o-nc-jamais_buyer1').get());
  if (snap.exists) throw new Error('le document ne devrait pas exister');
});

await check('un tiers NE PEUT PAS sonder la place de non-conformite d\'un autre acheteur (inexistante)', async () => {
  await assertFails(otherSellerCtx().doc('non_conformities/o-nc-jamais_buyer1').get());
});

console.log('\n=== refund_requests : ID deterministe (audit du 2026-10-08) ===');

await check('acheteur cree une demande de remboursement avec le bon ID {orderId}_{buyerId}', async () => {
  await assertSucceeds(
    buyerCtx().doc('refund_requests/o-nc1_buyer1').set({
      orderId: 'o-nc1', buyerId: BUYER, amount: 5000, status: 'pending',
    })
  );
});

await check('ID ne correspondant pas a orderId_buyerId : refuse', async () => {
  await assertFails(
    buyerCtx().doc('refund_requests/id-invalide').set({
      orderId: 'o-nc1', buyerId: BUYER, amount: 5000, status: 'pending',
    })
  );
});

await check('demande de remboursement en double sur la meme commande : refusee', async () => {
  await seed({
    'refund_requests/o-refund-dup_buyer1': { orderId: 'o-refund-dup', buyerId: BUYER, amount: 1000, status: 'pending' },
  });
  await assertFails(
    buyerCtx().doc('refund_requests/o-refund-dup_buyer1').set({
      orderId: 'o-refund-dup', buyerId: BUYER, amount: 2000, status: 'pending',
    })
  );
});

await check('un tiers NE PEUT PAS creer une demande de remboursement en usurpant un buyerId', async () => {
  await assertFails(
    otherSellerCtx().doc('refund_requests/o-nc1_buyer1').set({
      orderId: 'o-nc1', buyerId: BUYER, amount: 5000, status: 'pending',
    })
  );
});

console.log('\n=== product : vendu/reserve par le vendeur selon paiement ===');

await seed({
  'config/payment': { enabled: false },
  'product/p-dispo-off': { sellerId: SELLER, title: 'A', status: 'available' },
});

await check('paiement DESACTIVE : vendeur peut marquer son article vendu', async () => {
  await assertSucceeds(sellerCtx().doc('product/p-dispo-off').update({ status: 'sold' }));
});

await seed({
  'product/p-dispo-off2': { sellerId: SELLER, title: 'B', status: 'available' },
});

await check('paiement DESACTIVE : vendeur peut marquer son article reserve', async () => {
  await assertSucceeds(sellerCtx().doc('product/p-dispo-off2').update({ status: 'reserved' }));
});

await seed({
  'config/payment': { enabled: true },
  'product/p-dispo-on': { sellerId: SELLER, title: 'C', status: 'available' },
});

await check('paiement ACTIVE : vendeur NE PEUT PAS marquer son article vendu lui-meme', async () => {
  await assertFails(sellerCtx().doc('product/p-dispo-on').update({ status: 'sold' }));
});

await check('paiement ACTIVE : vendeur NE PEUT PAS marquer son article reserve lui-meme', async () => {
  await assertFails(sellerCtx().doc('product/p-dispo-on').update({ status: 'reserved' }));
});

await check('dans tous les cas, le vendeur garde ses autres droits (modifier le prix)', async () => {
  await assertSucceeds(sellerCtx().doc('product/p-dispo-on').update({ price: 5000 }));
});

console.log('\n=== product : annuler vendu/reserve (vente annulee) selon paiement ===');

await seed({
  'config/payment': { enabled: false },
  'product/p-sold-off': { sellerId: SELLER, title: 'F', status: 'sold' },
});

await check('paiement DESACTIVE : vendeur peut remettre un article vendu disponible', async () => {
  await assertSucceeds(sellerCtx().doc('product/p-sold-off').update({ status: 'available' }));
});

await seed({
  'product/p-reserved-off': { sellerId: SELLER, title: 'G', status: 'reserved' },
});

await check('paiement DESACTIVE : vendeur peut remettre un article reserve disponible', async () => {
  await assertSucceeds(sellerCtx().doc('product/p-reserved-off').update({ status: 'available' }));
});

await seed({
  'config/payment': { enabled: true },
  'product/p-sold-on': { sellerId: SELLER, title: 'H', status: 'sold' },
});

await check('paiement ACTIVE : vendeur NE PEUT PAS remettre un article vendu disponible lui-meme (vente reelle geree par le flux de commande)', async () => {
  await assertFails(sellerCtx().doc('product/p-sold-on').update({ status: 'available' }));
});

console.log('\n=== product : achat normal (paiement active, non-regression) ===');

await seed({
  'product/p-for-sale': { sellerId: SELLER, title: 'D', status: 'available' },
  'order/o1': { buyerId: BUYER, productId: 'p-for-sale' },
});

await check('paiement ACTIVE : achat normal, l\'acheteur marque l\'article vendu (payment_page)', async () => {
  await assertSucceeds(
    buyerCtx().doc('product/p-for-sale').update({ status: 'sold', orderId: 'o1' })
  );
});

await check('paiement ACTIVE : acheteur annule sa commande, article remis disponible (order_tracking, non-regression)', async () => {
  await assertSucceeds(buyerCtx().doc('product/p-for-sale').update({ status: 'available' }));
});

await check('un autre vendeur ne peut toujours pas toucher a un article qui n\'est pas le sien', async () => {
  await seed({ 'product/p-isolated': { sellerId: SELLER, title: 'E', status: 'available' } });
  await assertFails(otherSellerCtx().doc('product/p-isolated').update({ title: 'Vole' }));
});

console.log('\n=== repli : document config/payment ABSENT ou champ invalide ===');
await testEnv.withSecurityRulesDisabled(async (ctx) => {
  await ctx.firestore().doc('config/payment').delete();
});
await seed({ 'product/p-no-config': { sellerId: SELLER, title: 'Z', status: 'available' } });
await check('document absent : vendeur PEUT marquer vendu (repli = paiement desactive)', async () => {
  await assertSucceeds(sellerCtx().doc('product/p-no-config').update({ status: 'sold' }));
});

await seed({
  'config/payment': { updatedAt: 'x' }, // champ "enabled" absent du document
  'product/p-bad-config': { sellerId: SELLER, title: 'Y', status: 'available' },
});
await check('document present mais champ enabled absent : vendeur PEUT marquer vendu (repli = paiement desactive)', async () => {
  await assertSucceeds(sellerCtx().doc('product/p-bad-config').update({ status: 'sold' }));
});

await seed({
  'config/payment': { enabled: true },
  'product/p-explicit-on': { sellerId: SELLER, title: 'X', status: 'available' },
});
await check('document present avec enabled=true : vendeur NE PEUT PAS marquer vendu lui-meme', async () => {
  await assertFails(sellerCtx().doc('product/p-explicit-on').update({ status: 'sold' }));
});

console.log(`\n=== Resultat : ${passed} OK, ${failed} FAIL ===\n`);
await testEnv.cleanup();
process.exit(failed > 0 ? 1 : 0);
