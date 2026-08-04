/**
 * Fun Pay — Reset All Wallets & Check-ins
 *
 * 1. Zeros wallet balances for ALL users:
 *      users   → walletBalance = 0   (totalEarnings/totalWithdrawn too with --full)
 *      wallets → walletBalance = 0   (totalEarnings/totalWithdrawn too with --full)
 *    (Only fields that already exist on a doc are touched — no new fields added.)
 *
 * 2. Resets daily / weekly / monthly check-ins by DELETING the progress
 *    collections (the app recreates them on the next check-in, same as a
 *    brand-new user):
 *      daily_checkins   → DELETED
 *      weekly_bonuses   → DELETED
 *      monthly_bonuses  → DELETED
 *      streaks          → DELETED   (skip with --no-streaks)
 *
 * NOT TOUCHED: transactions, rewards, withdrawals history, user accounts,
 * config/settings collections, and every other collection.
 *
 * USAGE:
 *   node reset_wallets_and_checkins.js --dry-run   # count what would change
 *   node reset_wallets_and_checkins.js             # balances only + check-ins (prompts)
 *   node reset_wallets_and_checkins.js --yes       # skip the confirmation prompt
 *   node reset_wallets_and_checkins.js --full      # also zero totalEarnings/totalWithdrawn
 *   node reset_wallets_and_checkins.js --no-streaks
 *
 * Prerequisite: scripts/service-account-key.json must exist.
 */

const readline = require('readline');
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

const DRY_RUN = process.argv.includes('--dry-run');
const FORCE = process.argv.includes('--yes');
const FULL = process.argv.includes('--full');
const RESET_STREAKS = !process.argv.includes('--no-streaks');

// ─── Utility: zero listed fields (only existing ones) ──────
async function zeroFields(collectionName, fields) {
  const snapshot = await db.collection(collectionName).get();
  if (snapshot.empty) {
    console.log(`  ⏭️  "${collectionName}" has no documents — skipped.`);
    return 0;
  }

  const BATCH_SIZE = 500;
  const docs = snapshot.docs;
  let total = 0;
  let batches = 0;

  for (let i = 0; i < docs.length; i += BATCH_SIZE) {
    const batch = db.batch();
    const chunk = docs.slice(i, i + BATCH_SIZE);
    let changed = 0;

    for (const doc of chunk) {
      const data = doc.data();
      const update = {};
      for (const field of fields) {
        if (Object.prototype.hasOwnProperty.call(data, field)) {
          update[field] = 0;
        }
      }
      if (Object.prototype.hasOwnProperty.call(data, 'updatedAt')) {
        update.updatedAt = Timestamp.now();
      }
      if (Object.keys(update).length === 0) continue;

      if (!DRY_RUN) {
        batch.update(doc.ref, update);
      }
      changed++;
    }

    if (changed > 0) {
      if (!DRY_RUN) await batch.commit();
      batches++;
      total += changed;
      console.log(`  ${DRY_RUN ? '📋 (dry-run) would update' : '✓ Updated'} batch ${batches}: ${changed} documents`);
    }
  }

  console.log(`  ✅ "${collectionName}": ${total} documents would be ${DRY_RUN ? 'updated' : 'updated'} → fields [${fields.join(', ')}] = 0`);
  return total;
}

// ─── Utility: delete all documents in a collection ─────────
async function deleteCollection(collectionName) {
  const snapshot = await db.collection(collectionName).get();
  if (snapshot.empty) {
    console.log(`  ⏭️  "${collectionName}" is already empty — skipped.`);
    return 0;
  }

  const BATCH_SIZE = 500;
  const docs = snapshot.docs;
  let total = 0;
  let batches = 0;

  for (let i = 0; i < docs.length; i += BATCH_SIZE) {
    const batch = db.batch();
    const chunk = docs.slice(i, i + BATCH_SIZE);
    for (const doc of chunk) {
      if (!DRY_RUN) batch.delete(doc.ref);
    }
    if (!DRY_RUN) await batch.commit();
    batches++;
    total += chunk.length;
    console.log(`  ${DRY_RUN ? '📋 (dry-run) would delete' : '🗑  Deleted'} batch ${batches}: ${chunk.length} documents`);
  }

  console.log(`  ✅ "${collectionName}": ${total} documents ${DRY_RUN ? 'would be deleted' : 'deleted'}`);
  return total;
}

// ─── Confirmation prompt ───────────────────────────────────
function confirm(planLines) {
  return new Promise((resolve) => {
    const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
    console.log('\n⚠️  THIS WILL MODIFY PRODUCTION DATA. What will happen:');
    for (const line of planLines) console.log(`   • ${line}`);
    rl.question('\nType "RESET" to confirm: ', (answer) => {
      rl.close();
      resolve(answer.trim() === 'RESET');
    });
  });
}

// ─── Main ──────────────────────────────────────────────────
async function main() {
  const mode = FULL ? 'FULL monetary reset' : 'balances only';
  console.log('============================================');
  console.log('  Fun Pay — Reset Wallets & Check-ins');
  console.log(`  Mode: ${mode}${DRY_RUN ? '  [DRY RUN — no changes]' : ''}`);
  console.log(`  Streaks: ${RESET_STREAKS ? 'will be reset' : 'left alone'}`);
  console.log('============================================\n');

  const planLines = [
    `users   → ${FULL ? 'walletBalance, totalEarnings, totalWithdrawn' : 'walletBalance'} = 0`,
    `wallets → ${FULL ? 'walletBalance, totalEarnings, totalWithdrawn' : 'walletBalance'} = 0`,
    'daily_checkins   → all documents deleted',
    'weekly_bonuses   → all documents deleted',
    'monthly_bonuses  → all documents deleted',
    RESET_STREAKS ? 'streaks          → all documents deleted' : 'streaks          → NOT touched',
    '',
    'NOT touched: transactions, rewards, withdrawals, users, config/settings.',
  ];

  if (!DRY_RUN && !FORCE) {
    const ok = await confirm(planLines);
    if (!ok) {
      console.log('\n❌ Aborted — no changes were made.');
      process.exit(0);
    }
  }

  const balanceFields = FULL
    ? ['walletBalance', 'totalEarnings', 'totalWithdrawn']
    : ['walletBalance'];

  const results = {};
  try {
    console.log('\n═══ STEP 1: Zero wallet balances ═══');
    results.users = await zeroFields('users', balanceFields);
    results.wallets = await zeroFields('wallets', balanceFields);

    console.log('\n═══ STEP 2: Reset daily check-ins ═══');
    results.daily_checkins = await deleteCollection('daily_checkins');

    console.log('\n═══ STEP 3: Reset weekly bonuses ═══');
    results.weekly_bonuses = await deleteCollection('weekly_bonuses');

    console.log('\n═══ STEP 4: Reset monthly bonuses ═══');
    results.monthly_bonuses = await deleteCollection('monthly_bonuses');

    if (RESET_STREAKS) {
      console.log('\n═══ STEP 5: Reset streaks ═══');
      results.streaks = await deleteCollection('streaks');
    }

    console.log('\n══════════════════════════════════════════');
    console.log(`  ${DRY_RUN ? '📋 DRY RUN COMPLETE — nothing was changed.' : '✅ RESET COMPLETE'}`);
    console.log('══════════════════════════════════════════');
    console.log(`  users balances zeroed:        ${results.users}`);
    console.log(`  wallets balances zeroed:      ${results.wallets}`);
    console.log(`  daily_checkins deleted:       ${results.daily_checkins}`);
    console.log(`  weekly_bonuses deleted:       ${results.weekly_bonuses}`);
    console.log(`  monthly_bonuses deleted:      ${results.monthly_bonuses}`);
    console.log(`  streaks deleted:              ${results.streaks || 0}`);
    console.log('');
    console.log('  Transactions/rewards/withdrawals history preserved.');
    console.log('══════════════════════════════════════════\n');
  } catch (error) {
    console.error('\n❌ Failed:', error.message);
    console.error(error.stack);
    process.exit(1);
  }

  process.exit(0);
}

main();
