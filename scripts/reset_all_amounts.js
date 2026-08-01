/**
 * Fun Pay — Complete Reset Script
 * 
 * Resets all monetary amounts and clears specified collections.
 * 
 * WHAT THIS SCRIPT DOES:
 *   1. wallets      → Sets walletBalance=0, totalEarnings=0, totalWithdrawn=0
 *   2. users        → Sets walletBalance=0, totalEarnings=0, totalWithdrawn=0
 *   3. projects     → DELETES all documents
 *   4. affiliate_projects     → DELETES all documents
 *   5. project_participations → DELETES all documents
 *   6. withdrawals  → DELETES all documents
 *   7. transactions → DELETES all documents
 * 
 * WHAT IS NOT TOUCHED:
 *   - Users (personal info, referrals, auth data)
 *   - Referrals, referral_rewards
 *   - Rewards, spin_data, scratch_cards
 *   - Notifications
 *   - All other collections
 * 
 * USAGE:
 *   1. Place your Firebase service key at scripts/service-account-key.json
 *   2. cd scripts && npm install
 *   3. node reset_all_amounts.js
 */

const admin = require('firebase-admin');

// ─── Load Service Account ──────────────────────────────────
let serviceAccount;
try {
  serviceAccount = require('./service-account-key.json');
} catch (e) {
  console.error('❌ Could not load service-account-key.json');
  console.error('   Place your Firebase service account key at:');
  console.error('   scripts/service-account-key.json');
  console.error('   Download from: Firebase Console > Settings > Service Accounts > Generate New Private Key');
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();
const Timestamp = admin.firestore.Timestamp;

// ─── Utility: Delete all documents from a collection ───────
async function deleteCollection(collectionName) {
  console.log(`\n📦 Deleting all documents from "${collectionName}"...`);
  const snapshot = await db.collection(collectionName).get();

  if (snapshot.empty) {
    console.log(`  ✅ "${collectionName}" is already empty.`);
    return 0;
  }

  const BATCH_SIZE = 500;
  let totalDeleted = 0;
  let batches = 0;
  const docs = snapshot.docs;

  for (let i = 0; i < docs.length; i += BATCH_SIZE) {
    const batch = db.batch();
    const chunk = docs.slice(i, i + BATCH_SIZE);
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

// ─── Utility: Reset specific fields to 0 in all docs ───────
async function resetFieldsToZero(collectionName, fields) {
  console.log(`\n💰 Resetting fields [${fields.join(', ')}] to 0 in "${collectionName}"...`);
  const snapshot = await db.collection(collectionName).get();

  if (snapshot.empty) {
    console.log(`  ✅ "${collectionName}" has no documents.`);
    return 0;
  }

  const BATCH_SIZE = 500;
  let totalReset = 0;
  let batches = 0;
  const docs = snapshot.docs;

  for (let i = 0; i < docs.length; i += BATCH_SIZE) {
    const batch = db.batch();
    const chunk = docs.slice(i, i + BATCH_SIZE);

    for (const doc of chunk) {
      const updateData = {};
      for (const field of fields) {
        updateData[field] = 0;
      }
      updateData.updatedAt = Timestamp.now();
      batch.update(doc.ref, updateData);
    }

    await batch.commit();
    batches++;
    totalReset += chunk.length;
    console.log(`  Reset batch ${batches}: ${chunk.length} documents`);
  }

  console.log(`  ✅ Reset ${totalReset} documents in "${collectionName}"`);
  return totalReset;
}

// ─── Main ──────────────────────────────────────────────────
async function main() {
  console.log('============================================');
  console.log('  Fun Pay — Complete Amount & Data Reset');
  console.log('============================================\n');

  const results = {
    walletsReset: 0,
    usersReset: 0,
    projectsDeleted: 0,
    affiliateProjectsDeleted: 0,
    participationsDeleted: 0,
    withdrawalsDeleted: 0,
    transactionsDeleted: 0,
  };

  try {
    // ── Step 1: Reset wallets to zero ────────────────────
    console.log('\n═══ STEP 1: Reset Wallet Balances ═══');
    results.walletsReset = await resetFieldsToZero('wallets', [
      'walletBalance',
      'totalEarnings',
      'totalWithdrawn',
    ]);

    // ── Step 2: Reset user balances to zero ──────────────
    console.log('\n═══ STEP 2: Reset User Balances ═══');
    results.usersReset = await resetFieldsToZero('users', [
      'walletBalance',
      'totalEarnings',
      'totalWithdrawn',
    ]);

    // ── Step 3: Delete project participations ────────────
    console.log('\n═══ STEP 3: Delete Project Participations ═══');
    results.participationsDeleted = await deleteCollection('project_participations');

    // ── Step 4: Delete affiliate projects ────────────────
    console.log('\n═══ STEP 4: Delete Affiliate Projects ═══');
    results.affiliateProjectsDeleted = await deleteCollection('affiliate_projects');

    // ── Step 5: Delete regular projects ──────────────────
    console.log('\n═══ STEP 5: Delete Projects ═══');
    results.projectsDeleted = await deleteCollection('projects');

    // ── Step 6: Delete withdrawal history ────────────────
    console.log('\n═══ STEP 6: Delete Withdrawal History ═══');
    results.withdrawalsDeleted = await deleteCollection('withdrawals');

    // ── Step 7: Delete transaction history ───────────────
    console.log('\n═══ STEP 7: Delete Transaction History ═══');
    results.transactionsDeleted = await deleteCollection('transactions');

    // ── Summary ──────────────────────────────────────────
    console.log('\n══════════════════════════════════════════');
    console.log('  ✅ RESET COMPLETE');
    console.log('══════════════════════════════════════════');
    console.log('');
    console.log('  Amounts Reset to ₹0:');
    console.log(`    • Wallets:       ${results.walletsReset}`);
    console.log(`    • Users:         ${results.usersReset}`);
    console.log('');
    console.log('  Collections Deleted:');
    console.log(`    • Projects:              ${results.projectsDeleted}`);
    console.log(`    • Affiliate Projects:    ${results.affiliateProjectsDeleted}`);
    console.log(`    • Participations:        ${results.participationsDeleted}`);
    console.log(`    • Withdrawals:           ${results.withdrawalsDeleted}`);
    console.log(`    • Transactions:          ${results.transactionsDeleted}`);
    console.log('');
    console.log('  No other collections were modified.');
    console.log('  All user accounts, auth, referrals, rewards, and settings are preserved.');
    console.log('══════════════════════════════════════════\n');

  } catch (error) {
    console.error('\n❌ Failed:', error.message);
    console.error(error.stack);
    process.exit(1);
  }

  process.exit(0);
}

main();
