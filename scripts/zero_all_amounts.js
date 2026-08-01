/**
 * Fun Pay — Zero All Monetary Amounts (Keep All Records)
 *
 * Sets every monetary / earnings field to 0 across all money-related
 * collections WITHOUT deleting any documents. Users, projects, referrals,
 * transactions, etc. all remain — only the amounts become ₹0.
 *
 * WHAT THIS SCRIPT DOES (per collection):
 *   users                  → walletBalance, totalEarnings, totalWithdrawn = 0
 *   wallets                → walletBalance, totalEarnings, totalWithdrawn = 0
 *   transactions           → amount = 0
 *   withdrawals            → amount, walletBalanceAtRequest = 0
 *   referrals              → rewardAmount, lifetimeProjectCommission = 0
 *   projects               → rewardAmount = 0
 *   affiliate_projects     → rewardAmount, totalRewardsPaid = 0
 *   project_participations → rewardAmount = 0
 *   scratch_cards          → rewardAmount = 0
 *   rewards                → rewardAmount = 0
 *   daily_checkins         → rewardAmount = 0
 *   custom_tasks           → rewardAmount = 0
 *   task_submissions       → rewardAmount = 0
 *   spin_data              → totalRewardsEarned = 0, spinHistory[].amount = 0
 *   claimed_milestones     → rewardAmount = 0
 *
 * WHAT IS NOT TOUCHED:
 *   - No documents are deleted.
 *   - Config/settings collections (rewards_config, referral_rewards,
 *     referral_levels_config, streak_multiplier_config, ad_config,
 *     app_settings, coupons, offers, banners, faqs, notifications, etc.)
 *   - Any field NOT listed above is left unchanged.
 *
 * USAGE:
 *   1. Place your Firebase service key at scripts/service-account-key.json
 *   2. cd scripts && npm install
 *   3. node zero_all_amounts.js
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
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();
const Timestamp = admin.firestore.Timestamp;

// Collection name → monetary fields to zero (only existing fields are set).
const COLLECTION_FIELDS = {
  users: ['walletBalance', 'totalEarnings', 'totalWithdrawn'],
  wallets: ['walletBalance', 'totalEarnings', 'totalWithdrawn'],
  transactions: ['amount'],
  withdrawals: ['amount', 'walletBalanceAtRequest'],
  referrals: ['rewardAmount', 'lifetimeProjectCommission'],
  projects: ['rewardAmount'],
  affiliate_projects: ['rewardAmount', 'totalRewardsPaid'],
  project_participations: ['rewardAmount'],
  scratch_cards: ['rewardAmount'],
  rewards: ['rewardAmount'],
  daily_checkins: ['rewardAmount'],
  custom_tasks: ['rewardAmount'],
  task_submissions: ['rewardAmount'],
  claimed_milestones: ['rewardAmount'],
  spin_data: ['totalRewardsEarned'],
};

// ─── Utility: Zero listed fields in every doc of a collection ─
async function zeroFields(collectionName, fields) {
  const snapshot = await db.collection(collectionName).get();

  if (snapshot.empty) {
    console.log(`  ⏭️  "${collectionName}" has no documents — skipped.`);
    return 0;
  }

  const BATCH_SIZE = 500;
  const docs = snapshot.docs;
  let totalUpdated = 0;
  let batches = 0;

  for (let i = 0; i < docs.length; i += BATCH_SIZE) {
    const batch = db.batch();
    const chunk = docs.slice(i, i + BATCH_SIZE);
    let changedInChunk = 0;

    for (const doc of chunk) {
      const data = doc.data();
      const update = {};

      for (const field of fields) {
        // Only zero fields that already exist on the document — never add new ones.
        if (Object.prototype.hasOwnProperty.call(data, field)) {
          update[field] = 0;
        }
      }

      // spin_data special case: zero amounts inside the spin history array.
      if (collectionName === 'spin_data' && Array.isArray(data.spinHistory)) {
        update.spinHistory = data.spinHistory.map((entry) => {
          if (typeof entry === 'object' && entry !== null) {
            return { ...entry, amount: 0 };
          }
          return entry;
        });
      }

      if (Object.keys(update).length === 0) continue;

      // Only touch updatedAt if the document already has it — never add new fields.
      if (Object.prototype.hasOwnProperty.call(data, 'updatedAt')) {
        update.updatedAt = Timestamp.now();
      }
      batch.update(doc.ref, update);
      changedInChunk++;
    }

    if (changedInChunk > 0) {
      await batch.commit();
      totalUpdated += changedInChunk;
      batches++;
      console.log(`  ✓ Batch ${batches}: ${changedInChunk} documents updated`);
    }
  }

  console.log(`  ✅ "${collectionName}": ${totalUpdated} documents zeroed.`);
  return totalUpdated;
}

// ─── Main ──────────────────────────────────────────────────
async function main() {
  console.log('============================================');
  console.log('  Fun Pay — Zero All Amounts (Keep Records)');
  console.log('============================================\n');

  const results = {};

  try {
    for (const [collection, fields] of Object.entries(COLLECTION_FIELDS)) {
      console.log(`\n💰 Zeroing [${fields.join(', ')}] in "${collection}"...`);
      results[collection] = await zeroFields(collection, fields);
    }

    console.log('\n══════════════════════════════════════════');
    console.log('  ✅ ZERO-ALL-AMOUNTS COMPLETE');
    console.log('══════════════════════════════════════════');
    console.log('');
    console.log('  Documents updated (amounts → ₹0):');
    for (const [collection, count] of Object.entries(results)) {
      console.log(`    • ${collection}: ${count}`);
    }
    console.log('');
    console.log('  ✅ No documents were deleted.');
    console.log('  ✅ All user accounts, projects, referrals, and records preserved.');
    console.log('  ✅ Config/settings collections untouched.');
    console.log('══════════════════════════════════════════\n');
  } catch (error) {
    console.error('\n❌ Failed:', error.message);
    console.error(error.stack);
    process.exit(1);
  }

  process.exit(0);
}

main();
