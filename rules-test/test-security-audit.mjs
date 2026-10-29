// Tests de l'audit de securite du 2026-10-26 (voir rapport donne a Ali).
// Deux sections :
//  1. Reproduction des scenarios CRITIQUE / ELEVE / MOYEN -- log EXPLOITABLE
//     ou BLOQUE selon le resultat reel (pas d'assertion figee : ce fichier
//     sert a comparer l'etat AVANT et APRES la correction).
//  2. Non-regression : parcours normaux qui doivent reussir, avant ET apres
//     la correction (creer/modifier une annonce, offre, message, suppression
//     de compte, relay manager sur /relay/disputes, admin_users auto-edition
//     des champs de profil autorises, cycle de commande complet).
//
// Teste UNIQUEMENT ../firestore.rules.chantier-candidat (jamais le fichier de
// production firestore.rules). Necessite l'emulateur Firestore local sur
// 127.0.0.1:8123 (firebase emulators:start --only firestore).
import { readFileSync } from 'node:fs';
import {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} from '@firebase/rules-unit-testing';

const PROJECT_ID = 'bamako-thrif-security-audit';
const RULES_PATH = '../firestore.rules.chantier-candidat';

let passed = 0;
let failed = 0;
let exploitable = 0;
let blocked = 0;

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

// Pour la section 1 : ne force pas un sens attendu, constate juste si
// l'attaque reussit (EXPLOITABLE) ou echoue (BLOQUE).
async function probe(name, fn) {
  try {
    await fn();
    exploitable++;
    console.log(`  EXPLOITABLE  ${name}`);
  } catch (e) {
    blocked++;
    console.log(`  BLOQUE       ${name}`);
  }
}

const testEnv = await initializeTestEnvironment({
  projectId: PROJECT_ID,
  firestore: { rules: readFileSync(RULES_PATH, 'utf8'), host: '127.0.0.1', port: 8123 },
});
// Ce script est relance plusieurs fois (avant/apres correction) sous le
// meme projectId : sans ce nettoyage, les documents crees par l'execution
// precedente restent dans l'emulateur et faussent les tests suivants
// (set() est alors evalue comme "update", pas "create").
await testEnv.clearFirestore();

const SELLER = 'seller1';
const BUYER = 'buyer1';
const VICTIM = 'victim1';
const STRANGER = 'stranger1';
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
function buyerCtx() { return testEnv.authenticatedContext(BUYER).firestore(); }
function victimCtx() { return testEnv.authenticatedContext(VICTIM).firestore(); }
function strangerCtx() { return testEnv.authenticatedContext(STRANGER).firestore(); }
function adminCtx() { return testEnv.authenticatedContext(ADMIN).firestore(); }
function relayCtx() { return testEnv.authenticatedContext(RELAY).firestore(); }
function freshBuyerSecurity(label) {
  const uid = `buyer-sec-${label}`;
  return { uid, db: testEnv.authenticatedContext(uid).firestore() };
}

await seed({
  'admin_users/admin1': { role: 'admin' },
  'admin_users/relay1': { role: 'relay_manager', displayName: 'Relais Bamako', phone: '70000000', city: 'Bamako' },
});

console.log('\n========================================================');
console.log('SECTION 1 -- Reproduction des scenarios (avant correction)');
console.log('========================================================');

console.log('\n--- CRITIQUE : escalade admin_users ---');
await probe('un relay_manager se promeut lui-meme admin', async () => {
  await assertSucceeds(relayCtx().doc('admin_users/relay1').update({ role: 'admin' }));
});

console.log('\n--- CRITIQUE : order sans validation de champs ---');
await seed({ 'product/p-victim': { sellerId: VICTIM, title: 'Sac a main', status: 'available', price: 15000 } });
await probe('creation d\'une commande avec sellerId/totalAmount fantaisistes (sans lien avec le vrai produit)', async () => {
  await assertSucceeds(
    strangerCtx().doc('order/o-fake1').set({
      buyerId: STRANGER, sellerId: 'uid-invente', productId: 'produit-invente',
      totalAmount: 999999999, status: 'pending', createdAt: new Date(),
    })
  );
});

console.log('\n--- CRITIQUE : order, reecriture libre apres creation ---');
await seed({ 'order/o-real1': { buyerId: BUYER, sellerId: SELLER, productId: 'p-victim', totalAmount: 15000, status: 'pending' } });
await probe('l\'acheteur reecrit totalAmount et status de sa propre commande sans contrainte', async () => {
  await assertSucceeds(
    buyerCtx().doc('order/o-real1').update({ totalAmount: 999999999, status: 'completed' })
  );
});

console.log('\n--- CRITIQUE : wallet, ecriture par un tiers sans lien ---');
await seed({ 'config/payment': { enabled: false } });
await probe('un inconnu credite le wallet de la victime sans aucune commande (paiement desactive)', async () => {
  await assertSucceeds(
    strangerCtx().doc('wallet/victim1').set({ balance: 999999999, totalEarned: 999999999 }, { merge: true })
  );
});

console.log('\n--- ELEVE : vandalisme totalSales/lastActivityAt ---');
await seed({ 'users/victim1': { displayName: 'Victime', totalSales: 0 } });
await probe('un inconnu sans aucune commande gonfle totalSales de la victime', async () => {
  await assertSucceeds(
    strangerCtx().doc('users/victim1').update({ totalSales: 9999, lastActivityAt: new Date() })
  );
});

console.log('\n--- MOYEN : chat, suppression et reecriture par un participant ---');
await seed({ 'chat/c-del': { participantIds: [BUYER, SELLER], lastMessage: 'salut', productId: 'p1' } });
await probe('un participant supprime entierement la conversation (affecte l\'autre participant)', async () => {
  await assertSucceeds(buyerCtx().doc('chat/c-del').delete());
});
await seed({ 'chat/c-rw': { participantIds: [BUYER, SELLER], lastMessage: 'salut', productId: 'p1' } });
await probe('un participant reecrit participantIds du chat (vole/exclut l\'autre)', async () => {
  await assertSucceeds(buyerCtx().doc('chat/c-rw').update({ participantIds: [BUYER, 'uid-invente'] }));
});

console.log('\n--- MOYEN : notification, spam vers un autre utilisateur ---');
await probe('un inconnu cree une fausse notification adressee a la victime', async () => {
  await assertSucceeds(
    strangerCtx().doc('notification/n-spam').set({
      userId: VICTIM, type: 'system', title: 'Phishing', body: '...', isRead: false,
    })
  );
});

console.log('\n--- MOYEN : offers, originalPrice sans lien avec le vrai prix ---');
await seed({ 'product/p-offer-victim': { sellerId: SELLER, title: 'Veste', status: 'available', price: 20000 } });
await probe('l\'acheteur invente une base de negociation (originalPrice) deconnectee du vrai prix produit', async () => {
  await assertSucceeds(
    buyerCtx().doc(`offers/p-offer-victim_${BUYER}`).set({
      productId: 'p-offer-victim', productTitle: 'Veste', sellerId: SELLER, buyerId: BUYER,
      originalPrice: 1000, currentPrice: 700, round: 1, turn: 'seller', status: 'pending',
      respondBy: new Date(Date.now() + 48 * 3600 * 1000), createdAt: new Date(),
    })
  );
});

console.log('\n--- Durcissements du 2026-10-26 (revue Ali) : users.totalSales, admin_users, chat.create ---');
await seed({ 'users/victim-totalsales': { displayName: 'Victime2', totalSales: 3 } });
await probe('users.totalSales : sauter a une valeur arbitraire (pas +1) malgre une preuve de commande valide', async () => {
  await seed({
    'product/p-ts-abuse': { sellerId: 'victim-totalsales', title: 'Jupe', status: 'available', price: 2000 },
    'order/o-ts-abuse': { buyerId: STRANGER, sellerId: 'victim-totalsales', productId: 'p-ts-abuse', totalAmount: 2000, status: 'completed' },
  });
  await assertSucceeds(
    strangerCtx().doc('users/victim-totalsales').update({ totalSales: 999, lastActivityAt: new Date(), lastCompletedOrderId: 'o-ts-abuse' })
  );
});
await probe('users.totalSales : omettre lastCompletedOrderId (ancienne forme exploitable)', async () => {
  await assertSucceeds(
    strangerCtx().doc('users/victim-totalsales').update({ totalSales: 4, lastActivityAt: new Date() })
  );
});
await probe('admin_users : relay_manager s\'auto-attribue relayCenterId (hors liste blanche)', async () => {
  await assertSucceeds(relayCtx().doc('admin_users/relay1').update({ relayCenterId: 'rc-invente' }));
});
await probe('admin_users : relay_manager s\'auto-attribue isActive (hors liste blanche)', async () => {
  await assertSucceeds(relayCtx().doc('admin_users/relay1').update({ isActive: true }));
});
await probe('chat.create : conversation a 1 seul participant (soi-meme)', async () => {
  await assertSucceeds(buyerCtx().doc('chat/c-solo').set({ participantIds: [BUYER], lastMessage: null }));
});
await probe('chat.create : conversation a 3 participants', async () => {
  await assertSucceeds(buyerCtx().doc('chat/c-trio').set({ participantIds: [BUYER, SELLER, STRANGER], lastMessage: null }));
});

console.log('\n--- Durcissements du 2026-10-26 (demande Ali, 2e revue) : offre non acceptee, rejeu totalSales ---');
await seed({ 'product/p-lowball': { sellerId: SELLER, title: 'Breloque', status: 'available', price: 3 } });
await probe('offre a 1 FCFA jamais acceptee par le vendeur -> commande au prix de l\'offre quand meme', async () => {
  const b = freshBuyerSecurity('lowball');
  await b.db.doc(`offers/p-lowball_${b.uid}`).set({
    productId: 'p-lowball', productTitle: 'Breloque', sellerId: SELLER, buyerId: b.uid,
    originalPrice: 3, currentPrice: 1, round: 1, turn: 'seller', status: 'pending',
    respondBy: new Date(Date.now() + 48 * 3600 * 1000), createdAt: new Date(),
  });
  await assertSucceeds(
    b.db.doc('order/o-lowball').set({
      buyerId: b.uid, sellerId: SELLER, productId: 'p-lowball', productTitle: 'Breloque',
      totalAmount: 1, status: 'pending', paymentMethod: 'wave', createdAt: new Date(),
    })
  );
});
await probe('creation directe d\'une offre avec status "accepted" (contourne la negociation)', async () => {
  const b = freshBuyerSecurity('direct-accept');
  await assertSucceeds(
    b.db.doc(`offers/p-lowball_${b.uid}`).set({
      productId: 'p-lowball', productTitle: 'Breloque', sellerId: SELLER, buyerId: b.uid,
      originalPrice: 3, currentPrice: 1, round: 1, turn: 'seller', status: 'accepted',
      respondBy: new Date(Date.now() + 48 * 3600 * 1000), createdAt: new Date(),
    })
  );
});

await seed({
  'users/seller-replay': { displayName: 'VendeurReplay', totalSales: 0 },
  'product/p-replay': { sellerId: 'seller-replay', title: 'Montre', status: 'available', price: 5000 },
  'order/o-replay': { buyerId: BUYER, sellerId: 'seller-replay', productId: 'p-replay', totalAmount: 5000, status: 'completed' },
});
await check('premiere utilisation de la preuve o-replay : OK', async () => {
  await assertSucceeds(
    buyerCtx().doc('users/seller-replay').update({ totalSales: 1, lastActivityAt: new Date(), lastCompletedOrderId: 'o-replay' })
  );
});
await probe('rejeu de la MEME preuve o-replay une seconde fois (totalSales encore +1)', async () => {
  await assertSucceeds(
    buyerCtx().doc('users/seller-replay').update({ totalSales: 2, lastActivityAt: new Date(), lastCompletedOrderId: 'o-replay' })
  );
});

console.log('\n--- MOYEN : product, usurpation de sellerId ---');
await seed({ 'product/p-spoof': { sellerId: SELLER, title: 'Chaussures', status: 'available', price: 8000 } });
await probe('le vendeur transfere sa propre annonce a un autre uid (sellerId)', async () => {
  await assertSucceeds(sellerCtx().doc('product/p-spoof').update({ sellerId: STRANGER }));
});

console.log('\n========================================================');
console.log('SECTION 2 -- Non-regression (parcours normaux, doivent TOUJOURS reussir)');
console.log('========================================================');

console.log('\n--- Creer et modifier une annonce ---');
await check('vendeur cree une annonce valide', async () => {
  await assertSucceeds(
    sellerCtx().doc('product/p-new-listing').set({
      sellerId: SELLER, title: 'Robe wax', description: 'Jamais portee', price: 12000,
      imageUrls: [], category: 'femme', status: 'available', createdAt: new Date(),
    })
  );
});
await check('vendeur modifie le prix de sa propre annonce (sellerId reste inchange)', async () => {
  await assertSucceeds(sellerCtx().doc('product/p-new-listing').update({ price: 11000 }));
});

console.log('\n--- Faire une offre et l\'accepter (voir aussi test-offers.mjs) ---');
await seed({ 'product/p-offer-ok': { sellerId: SELLER, title: 'Montre', status: 'available', price: 20000 } });
await check('acheteur fait une offre valide (originalPrice = vrai prix produit)', async () => {
  await assertSucceeds(
    buyerCtx().doc(`offers/p-offer-ok_${BUYER}`).set({
      productId: 'p-offer-ok', productTitle: 'Montre', sellerId: SELLER, buyerId: BUYER,
      originalPrice: 20000, currentPrice: 15000, round: 1, turn: 'seller', status: 'pending',
      respondBy: new Date(Date.now() + 48 * 3600 * 1000), createdAt: new Date(),
    })
  );
});
await check('vendeur accepte l\'offre', async () => {
  await assertSucceeds(sellerCtx().doc(`offers/p-offer-ok_${BUYER}`).update({ status: 'accepted' }));
});

console.log('\n--- Envoyer un message de chat ---');
await seed({ 'chat/c-msg': { participantIds: [BUYER, SELLER], lastMessage: null, productId: 'p1', unreadCount: { [BUYER]: 0, [SELLER]: 0 } } });
await check('acheteur envoie un message texte (sous-collection message)', async () => {
  await assertSucceeds(
    buyerCtx().collection('chat/c-msg/message').add({
      chatId: 'c-msg', senderId: BUYER, content: 'Bonjour, toujours dispo ?',
      type: 'text', isRead: false, createdAt: new Date(),
    })
  );
});
await check('l\'envoi met a jour lastMessage/lastMessageAt du chat (champ autorise)', async () => {
  await assertSucceeds(buyerCtx().doc('chat/c-msg').update({ lastMessage: 'Bonjour, toujours dispo ?', lastMessageAt: new Date() }));
});
await check('le vendeur marque ses messages comme lus (unreadCount, champ autorise)', async () => {
  await assertSucceeds(sellerCtx().doc('chat/c-msg').update({ 'unreadCount.seller1': 0 }));
});
await check('le vendeur (participant) peut toujours lire le chat', async () => {
  await assertSucceeds(sellerCtx().doc('chat/c-msg').get());
});

console.log('\n--- Suppression de compte (anonymisation) ---');
await seed({
  'users/to-delete': { displayName: 'Ali K.', totalSales: 3, isVendeurPro: false },
  'product/p-to-deactivate': { sellerId: 'to-delete', title: 'Veille annonce', status: 'available', price: 5000 },
});
function deletedUserCtx() { return testEnv.authenticatedContext('to-delete').firestore(); }
await check('le proprietaire anonymise son propre profil (sans toucher isVendeurPro)', async () => {
  await assertSucceeds(deletedUserCtx().doc('users/to-delete').update({ displayName: 'Utilisateur supprime', bio: null }));
});
await check('le proprietaire efface ses donnees privees (email/telephone/fcmToken)', async () => {
  await assertSucceeds(
    deletedUserCtx().doc('users/to-delete/private/data').set({ email: null, phone: null, fcmToken: null }, { merge: true })
  );
});
await check('le proprietaire passe ses annonces disponibles en inactive', async () => {
  await assertSucceeds(deletedUserCtx().doc('product/p-to-deactivate').update({ status: 'inactive' }));
});

console.log('\n--- Relay manager sur /relay/disputes ---');
await seed({
  'order/o-nc-relay': { buyerId: BUYER, sellerId: SELLER, productId: 'p1' },
  'non_conformities/o-nc-relay_buyer1': {
    orderId: 'o-nc-relay', buyerId: BUYER, sellerId: SELLER, productId: 'p1',
    reason: 'Article endommage', status: 'buyer_continue',
  },
});
await check('le relay manager peut lire une non-conformite dont il n\'est pas partie', async () => {
  await assertSucceeds(relayCtx().doc('non_conformities/o-nc-relay_buyer1').get());
});
await check('le relay manager peut faire avancer le statut (evaluation du cout)', async () => {
  await assertSucceeds(relayCtx().doc('non_conformities/o-nc-relay_buyer1').update({ status: 'cost_evaluated', repairCost: 2000 }));
});

console.log('\n--- admin_users : auto-edition du profil (champs autorises, pas le role) ---');
await check('le relay manager modifie son propre profil (displayName/phone/city)', async () => {
  await assertSucceeds(
    relayCtx().doc('admin_users/relay1').update({ displayName: 'Relais Bamako Centre', phone: '70111111', city: 'Bamako' })
  );
});

console.log('\n--- notification : creation legitime par admin/relay pour un autre utilisateur ---');
await check('l\'admin notifie un vendeur (article verifie)', async () => {
  await assertSucceeds(
    adminCtx().doc('notification/n-verif').set({ userId: SELLER, type: 'productVerified', title: 'Article verifie', body: '...', isRead: false })
  );
});
await check('le relay manager notifie un vendeur (remise en etat requise)', async () => {
  await assertSucceeds(
    relayCtx().doc('notification/n-repair').set({ userId: SELLER, type: 'repairValidation', title: 'Remise en etat requise', body: '...', isRead: false })
  );
});

console.log('\n--- Cycle de commande complet (create -> collecte -> completed) ---');
await seed({
  'product/p-order-cycle': { sellerId: SELLER, title: 'Sac', status: 'available', price: 7000 },
  'users/seller1': { displayName: 'Vendeur', totalSales: 0 },
});
await check('acheteur cree une commande (totalAmount = vrai prix produit)', async () => {
  await assertSucceeds(
    buyerCtx().doc('order/o-cycle').set({
      buyerId: BUYER, sellerId: SELLER, productId: 'p-order-cycle', productTitle: 'Sac',
      totalAmount: 7000, status: 'pending', paymentMethod: 'orangeMoney', createdAt: new Date(),
    })
  );
});
await check('vendeur marque la commande collectee', async () => {
  await assertSucceeds(sellerCtx().doc('order/o-cycle').update({ status: 'collecte', collectedAt: new Date() }));
});
await check('acheteur confirme reception (commande terminee)', async () => {
  await assertSucceeds(buyerCtx().doc('order/o-cycle').update({ status: 'completed', receivedAt: new Date() }));
});
await check('le compteur totalSales du vendeur est mis a jour avec la preuve de commande (lastCompletedOrderId)', async () => {
  await assertSucceeds(
    buyerCtx().doc('users/seller1').update({ totalSales: 1, lastActivityAt: new Date(), lastCompletedOrderId: 'o-cycle' })
  );
});
await check('le compteur totalPurchases de l\'acheteur (auto-ecriture) reste toujours autorise', async () => {
  await seed({ 'users/buyer1': { displayName: 'Acheteur', totalPurchases: 0 } });
  await assertSucceeds(buyerCtx().doc('users/buyer1').update({ totalPurchases: 1, lastActivityAt: new Date() }));
});

console.log('\n--- _confirmReceipt() cote app : paiement desactive, le wallet est saute (pas tente), les compteurs passent toujours ---');
await seed({
  'config/payment': { enabled: false },
  'product/p-order-cycle2': { sellerId: SELLER, title: 'Chapeau', status: 'available', price: 3000 },
});
await check('creation de la commande (paiement desactive)', async () => {
  await assertSucceeds(
    buyerCtx().doc('order/o-cycle2').set({
      buyerId: BUYER, sellerId: SELLER, productId: 'p-order-cycle2', productTitle: 'Chapeau',
      totalAmount: 3000, status: 'pending', paymentMethod: 'wave', createdAt: new Date(),
    })
  );
});
await check('acheteur confirme reception (commande terminee)', async () => {
  await assertSucceeds(buyerCtx().doc('order/o-cycle2').update({ status: 'completed', receivedAt: new Date() }));
});
// Paiement desactive : l'app ne tente meme plus l'ecriture wallet (voir
// PaymentConfigService.isPaymentEnabled() dans order_tracking_page.dart),
// donc rien a verifier ici cote wallet -- seuls les compteurs, toujours
// executes, sont testes.
await check('totalSales du vendeur est quand meme mis a jour (wallet non tente)', async () => {
  await assertSucceeds(
    buyerCtx().doc('users/seller1').update({ totalSales: 2, lastActivityAt: new Date(), lastCompletedOrderId: 'o-cycle2' })
  );
});
await check('totalPurchases de l\'acheteur est quand meme mis a jour (wallet non tente)', async () => {
  await assertSucceeds(buyerCtx().doc('users/buyer1').update({ totalPurchases: 2, lastActivityAt: new Date() }));
});

console.log('\n--- Durcissements du 2026-10-26 : parcours legitimes toujours OK ---');
await check('users.totalSales : exactement +1 avec preuve de commande reste autorise', async () => {
  await seed({
    'users/seller-exact': { displayName: 'VendeurExact', totalSales: 5 },
    'product/p-exact': { sellerId: 'seller-exact', title: 'Ceinture', status: 'available', price: 1500 },
    'order/o-exact': { buyerId: BUYER, sellerId: 'seller-exact', productId: 'p-exact', totalAmount: 1500, status: 'completed' },
  });
  await assertSucceeds(
    buyerCtx().doc('users/seller-exact').update({ totalSales: 6, lastActivityAt: new Date(), lastCompletedOrderId: 'o-exact' })
  );
});
await check('admin_users : relay_manager modifie son profil (liste blanche)', async () => {
  await assertSucceeds(
    relayCtx().doc('admin_users/relay1').update({ displayName: 'Relais Bamako Rive Droite', email: 'relais2@danaya.ml', phone: '70222222', city: 'Bamako' })
  );
});
await check('chat.create : conversation normale a 2 participants (acheteur + vendeur)', async () => {
  await assertSucceeds(buyerCtx().doc('chat/c-normal').set({ participantIds: [BUYER, SELLER], lastMessage: null, lastMessageAt: new Date() }));
});
await seed({
  'product/p-offer-order': { sellerId: SELLER, title: 'Sac a dos', status: 'available', price: 12000 },
  'offers/p-offer-order_buyer1': { productId: 'p-offer-order', sellerId: SELLER, buyerId: BUYER, originalPrice: 12000, currentPrice: 8000, status: 'accepted', round: 1, turn: 'seller' },
});
await check('order.create : totalAmount au prix d\'une offre acceptee (different du prix catalogue) reste autorise', async () => {
  await assertSucceeds(
    buyerCtx().doc('order/o-from-offer').set({
      buyerId: BUYER, sellerId: SELLER, productId: 'p-offer-order', productTitle: 'Sac a dos',
      totalAmount: 8000, status: 'pending', paymentMethod: 'wave', createdAt: new Date(),
    })
  );
});

console.log('\n--- Annulation de commande (litige refuse) ---');
await seed({ 'product/p-cancel': { sellerId: SELLER, title: 'Chemise', status: 'sold', price: 4000 } });
await seed({ 'order/o-cancel': { buyerId: BUYER, sellerId: SELLER, productId: 'p-cancel', totalAmount: 4000, status: 'pending' } });
await check('acheteur annule la commande suite a un litige refuse', async () => {
  await assertSucceeds(buyerCtx().doc('order/o-cancel').update({ status: 'cancelled', updatedAt: new Date() }));
});

console.log('\n--- Notification "article vendu" aux favoris (ajout du 2026-10-29) ---');
await seed({
  'product/p-fav-sold': { sellerId: SELLER, title: 'Veste jean', status: 'available', price: 9000 },
  [`users/${BUYER}/favorites/p-fav-sold`]: { productId: 'p-fav-sold', addedAt: new Date() },
});
await check('le vendeur peut lire si un utilisateur precis a CE produit en favori (get direct)', async () => {
  await assertSucceeds(sellerCtx().doc(`users/${BUYER}/favorites/p-fav-sold`).get());
});
await probe('un tiers (pas le vendeur) peut aussi lire ce favori (get direct)', async () => {
  await assertSucceeds(strangerCtx().doc(`users/${BUYER}/favorites/p-fav-sold`).get());
});

// Vraie requete collectionGroup (pas un .doc().get()) -- c'est exactement
// ce que fait _markStatus() dans my_listings_page.dart. Une regle imbriquee
// sous /users/{userId}/favorites ne s'applique PAS a ce type de requete ;
// il faut le bloc /{path=**}/favorites/{productId} separe (bug signale par
// Ali le 2026-10-29, corrige).
await check('collectionGroup REEL : le vendeur retrouve le favori sur SON produit', async () => {
  const snap = await assertSucceeds(
    sellerCtx().collectionGroup('favorites').where('productId', '==', 'p-fav-sold').get()
  );
  if (snap.size !== 1) throw new Error(`attendu 1 resultat, recu ${snap.size}`);
});
await probe('collectionGroup REEL : un tiers (pas le vendeur) lance la meme requete sur ce produit', async () => {
  await assertSucceeds(
    strangerCtx().collectionGroup('favorites').where('productId', '==', 'p-fav-sold').get()
  );
});
await seed({
  'product/p-other-seller': { sellerId: STRANGER, title: 'Autre article', status: 'available', price: 5000 },
  [`users/${BUYER}/favorites/p-other-seller`]: { productId: 'p-other-seller', addedAt: new Date() },
});
await probe('collectionGroup REEL : le vendeur de p-fav-sold lance la requete sur le produit d\'un AUTRE vendeur', async () => {
  await assertSucceeds(
    sellerCtx().collectionGroup('favorites').where('productId', '==', 'p-other-seller').get()
  );
});
await check('le vendeur cree la notification "productSold" pour l\'utilisateur qui a favori', async () => {
  await assertSucceeds(
    sellerCtx().doc(`notification/sold_p-fav-sold_${BUYER}`).set({
      userId: BUYER, type: 'productSold', title: 'Article vendu',
      body: "L'article Veste jean que tu avais en favori vient d'être vendu.",
      data: { productId: 'p-fav-sold' }, isRead: false, createdAt: new Date(),
    })
  );
});
await probe('le vendeur cree la notification pour un utilisateur qui n\'a PAS favori cet article', async () => {
  await assertSucceeds(
    sellerCtx().doc(`notification/sold_p-fav-sold_${STRANGER}`).set({
      userId: STRANGER, type: 'productSold', title: 'Article vendu',
      body: 'spam', data: { productId: 'p-fav-sold' }, isRead: false, createdAt: new Date(),
    })
  );
});
await probe('un tiers (pas le vendeur) cree la notification "productSold" pour le favori d\'un autre', async () => {
  await assertSucceeds(
    strangerCtx().doc(`notification/sold_p-fav-sold_${BUYER}_fake`).set({
      userId: BUYER, type: 'productSold', title: 'Article vendu',
      body: 'usurpe', data: { productId: 'p-fav-sold' }, isRead: false, createdAt: new Date(),
    })
  );
});
await probe('le vendeur cree une notification d\'un AUTRE type via cette exception (contournement)', async () => {
  await assertSucceeds(
    sellerCtx().doc(`notification/n-other-type`).set({
      userId: BUYER, type: 'promotion', title: 'Pub',
      body: 'spam promo', data: { productId: 'p-fav-sold' }, isRead: false, createdAt: new Date(),
    })
  );
});

console.log(`\n=== Resultat section 2 (non-regression) : ${passed} OK, ${failed} FAIL ===`);
console.log(`=== Resultat section 1 (vulnerabilites)  : ${exploitable} EXPLOITABLE, ${blocked} BLOQUE ===\n`);

await testEnv.cleanup();
process.exit(failed > 0 ? 1 : 0);
