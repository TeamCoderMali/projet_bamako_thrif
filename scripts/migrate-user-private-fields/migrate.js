// ─── DANAYA — Migration ponctuelle users/ → users/{uid}/private/data ───────
// Script à exécuter MANUELLEMENT, UNE SEULE FOIS. Ce n'est PAS une Cloud
// Function : rien ici n'est déployé, rien ne s'exécute automatiquement.
//
// Les comptes créés avant le refactor public/privé du 2026-09-30 ont encore
// email / phoneNumber / isEmailVerified / fcmToken / fcmUpdatedAt dans le
// document public users/{uid}. Ce script les déplace vers
// users/{uid}/private/data (lisible uniquement par le propriétaire + admin)
// puis les retire du document public. Les comptes déjà migrés (ou créés
// après le refactor) n'ont plus ces champs en public : le script les ignore
// (idempotent, ré-exécutable sans risque).
//
// Prérequis : des identifiants avec accès admin Firestore sur le projet
// bamako-thrif, par ex. :
//   GOOGLE_APPLICATION_CREDENTIALS=chemin/vers/cle-service-account.json
// ou une session `gcloud auth application-default login` déjà active.
//
// Usage :
//   npm install                 (une fois, installe firebase-admin ici)
//   node migrate.js             → mode simulation, n'écrit rien
//   node migrate.js --apply     → applique réellement les changements

const admin = require("firebase-admin");

admin.initializeApp({ projectId: "bamako-thrif" });
const db = admin.firestore();

// Alignés sur les champs privés réellement utilisés dans le code
// (auth_repository_impl.dart + notification_repository_impl.dart).
const PRIVATE_FIELDS = [
  "email",
  "phoneNumber",
  "isEmailVerified",
  "fcmToken",
  "fcmUpdatedAt",
];

const APPLY = process.argv.includes("--apply");

async function main() {
  const snap = await db.collection("users").get();
  console.log(`${snap.size} document(s) users/ trouvé(s).\n`);

  let migrated = 0;
  let skipped = 0;

  for (const doc of snap.docs) {
    const data = doc.data();
    const privateData = {};
    const fieldsFound = [];

    for (const field of PRIVATE_FIELDS) {
      if (Object.prototype.hasOwnProperty.call(data, field)) {
        privateData[field] = data[field];
        fieldsFound.push(field);
      }
    }

    if (fieldsFound.length === 0) {
      skipped++;
      continue;
    }

    migrated++;
    console.log(`- ${doc.id} : ${fieldsFound.join(", ")}`);

    if (APPLY) {
      const privateRef = doc.ref.collection("private").doc("data");
      const deleteMap = {};
      for (const field of fieldsFound) {
        deleteMap[field] = admin.firestore.FieldValue.delete();
      }

      const batch = db.batch();
      batch.set(privateRef, privateData, { merge: true });
      batch.update(doc.ref, deleteMap);
      await batch.commit();
    }
  }

  console.log("");
  console.log(
    `Résumé : ${migrated} compte(s) ${APPLY ? "migré(s)" : "à migrer"}, ` +
      `${skipped} déjà propre(s) (rien à faire).`
  );
  if (!APPLY) {
    console.log(
      "Mode simulation — aucune écriture effectuée. Relancer avec --apply pour appliquer réellement."
    );
  }
}

main()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error("Échec de la migration :", err);
    process.exit(1);
  });
