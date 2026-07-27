/**
 * Delete All Projects + Reset Wallets Script
 * 
 * Deletes all documents from:
 *   - projects
 *   - affiliate_projects
 *   - project_participations
 * 
 * Resets walletBalance and totalEarnings to 0 for ALL users in the wallets collection.
 * Does NOT touch any other collections.
 *
 * Usage:
 *   cd scripts/
 *   npm install (if not already done)
 *   node delete_all_projects.js
 */

const admin = require('firebase-admin');

const serviceAccount = require('./service-account-key.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function deleteCollection(collectionName) {
  console.log(`\n📦 Deleting all documents from "${collectionName}"...`);
  const snapshot = await db.collection(collectionName).get();

  if (snapshot.empty) {
    console.log(`  ✅ "${collectionName}" is already empty.`);
    return 0;
  }

  const batchSize = 500;
  let totalDeleted = 0;
  let batches = 0;

  const docs = snapshot.docs;
  for (let i = 0; i < docs.length; i += batchSize) {
    const batch = db.batch();
    const chunk = docs.slice(i, i + batchSize);

    for (const doc of chunk) {
      batch.delete(doc.ref);
    }

    await batch.commit();
    batches++;
    totalDeleted += chunk.length;
    console.log(`  Deleted batch ${batches}: ${chunk.length} documents`);
  }

  console.log(`  ✅ Deleted ${totalDeleted} documents from "${collectionName}"`);
  return totalDeleted;
}

async function resetWallets() {
  console.log(`\n💰 Resetting all wallets to ₹0...`);
  const snapshot = await db.collection('wallets').get();

  if (snapshot.empty) {
    console.log(`  ✅ No wallets found.`);
    return 0;
  }

  const batchSize = 500;
  let totalReset = 0;
  let batches = 0;

  const docs = snapshot.docs;
  for (let i = 0; i < docs.length; i += batchSize) {
    const batch = db.batch();
    const chunk = docs.slice(i, i + batchSize);

    for (const doc of chunk) {
      batch.update(doc.ref, {
        walletBalance: 0,
        updatedAt: admin.firestore.Timestamp.now(),
      });
    }

    await batch.commit();
    batches++;
    totalReset += chunk.length;
    console.log(`  Reset batch ${batches}: ${chunk.length} wallets`);
  }

  console.log(`  ✅ Reset ${totalReset} wallets to ₹0`);
  return totalReset;
}

async function main() {
  console.log('🗑️  Fun Pay — Reset Projects & Wallets Script');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('');

  try {
    // 1. Delete project participations (they reference projects)
    const participationsDeleted = await deleteCollection('project_participations');

    // 2. Delete affiliate projects
    const affiliateProjectsDeleted = await deleteCollection('affiliate_projects');

    // 3. Delete regular projects
    const projectsDeleted = await deleteCollection('projects');

    // 4. Reset all wallets to ₹0
    const walletsReset = await resetWallets();

    console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('✅ Complete!');
    console.log(`   📍 ${participationsDeleted} participations deleted`);
    console.log(`   📍 ${affiliateProjectsDeleted} affiliate projects deleted`);
    console.log(`   📍 ${projectsDeleted} projects deleted`);
    console.log(`   📍 ${walletsReset} wallets reset to ₹0`);
    console.log('');
    console.log('Projects screens will now show empty states.');
    console.log('All user wallets have been set to ₹0.');
    console.log('No other collections were modified.');
  } catch (error) {
    console.error('\n❌ Failed:', error.message);
    process.exit(1);
  }

  process.exit(0);
}

main();
