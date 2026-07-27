/**
 * Premium Systems Seed Script
 * Seeds the 'referral_levels_config' and 'streak_multiplier_config' collections
 * with default milestone data so users see content immediately.
 *
 * Usage:
 *   cd scripts
 *   npm install
 *   node seed_premium_systems.js
 *
 * Prerequisites:
 *   - Place service-account-key.json in scripts/ directory (or set GOOGLE_APPLICATION_CREDENTIALS)
 *   - Run `npm install` in the scripts/ directory (already done if other seeds work)
 *   - The app must have been deployed at least once so the collections exist in Firestore
 */

const admin = require('firebase-admin');

// ─── Firebase Init ─────────────────────────────────────────────

let serviceAccount;
try {
  serviceAccount = require('./service-account-key.json');
} catch (e) {
  // Will use application default credentials instead
}

admin.initializeApp({
  credential: serviceAccount
    ? admin.credential.cert(serviceAccount)
    : admin.credential.applicationDefault(),
  projectId: process.env.GOOGLE_CLOUD_PROJECT || 'cashspark-c15bd',
});

const db = admin.firestore();
const now = admin.firestore.Timestamp.now();

// ─── Referral Milestone Levels ─────────────────────────────────
// 4 levels matching the requirements spec:
//   Level 1: 5 referrals  → ₹25 reward
//   Level 2: 20 referrals → ₹100 reward
//   Level 3: 50 referrals → ₹250 reward
//   Level 4: 100 referrals → ₹500 reward

const REFERRAL_LEVELS = [
  {
    id: 'level_1',
    levelNumber: 1,
    title: 'Bronze Referrer',
    description: 'Referred 5 friends — you are just getting started!',
    requiredReferrals: 5,
    rewardAmount: 25.0,
    badgeIcon: '🥉',
    isActive: true,
    createdAt: now,
    updatedAt: now,
  },
  {
    id: 'level_2',
    levelNumber: 2,
    title: 'Silver Referrer',
    description: 'Referred 20 friends — your network is growing!',
    requiredReferrals: 20,
    rewardAmount: 100.0,
    badgeIcon: '🥈',
    isActive: true,
    createdAt: now,
    updatedAt: now,
  },
  {
    id: 'level_3',
    levelNumber: 3,
    title: 'Gold Referrer',
    description: 'Referred 50 friends — you are a referral machine!',
    requiredReferrals: 50,
    rewardAmount: 250.0,
    badgeIcon: '🥇',
    isActive: true,
    createdAt: now,
    updatedAt: now,
  },
  {
    id: 'level_4',
    levelNumber: 4,
    title: 'Diamond Referrer',
    description: 'Referred 100 friends — absolutely legendary!',
    requiredReferrals: 100,
    rewardAmount: 500.0,
    badgeIcon: '💎',
    isActive: true,
    createdAt: now,
    updatedAt: now,
  },
];

// ─── Streak Multiplier Config ──────────────────────────────────
// 4 milestones matching the requirements spec:
//   7-day streak  → 1.2× multiplier
//   15-day streak → 1.3× multiplier
//   30-day streak → 1.5× multiplier
//   60-day streak → 2.0× multiplier
// All features enabled: recovery, ad-based recovery

const STREAK_MULTIPLIER_CONFIG = {
  id: 'config',
  isEnabled: true,
  streakRecoveryEnabled: true,
  streakRecoveryUsesAd: true,
  milestones: [
    {
      id: 'ms_7',
      targetStreakDays: 7,
      multiplier: 1.2,
      label: '7-Day Streak',
      isActive: true,
    },
    {
      id: 'ms_15',
      targetStreakDays: 15,
      multiplier: 1.3,
      label: '15-Day Streak',
      isActive: true,
    },
    {
      id: 'ms_30',
      targetStreakDays: 30,
      multiplier: 1.5,
      label: '30-Day Streak',
      isActive: true,
    },
    {
      id: 'ms_60',
      targetStreakDays: 60,
      multiplier: 2.0,
      label: '60-Day Streak',
      isActive: true,
    },
  ],
  updatedAt: now,
};

// ─── Seed Functions ─────────────────────────────────────────────

async function seedReferralLevels() {
  console.log('\n🏅 Seeding "referral_levels_config" collection...');
  const batch = db.batch();

  for (const level of REFERRAL_LEVELS) {
    const ref = db
      .collection('referral_levels_config')
      .doc(level.id);
    batch.set(ref, {
      id: level.id,
      levelNumber: level.levelNumber,
      title: level.title,
      description: level.description,
      requiredReferrals: level.requiredReferrals,
      rewardAmount: level.rewardAmount,
      badgeIcon: level.badgeIcon,
      isActive: level.isActive,
      createdAt: level.createdAt,
      updatedAt: level.updatedAt,
    });
    console.log(
      `  📍 ${level.badgeIcon} Level ${level.levelNumber}: "${level.title}" – ${level.requiredReferrals} referrals → ₹${level.rewardAmount}`
    );
  }

  await batch.commit();
  console.log(`  ✅ ${REFERRAL_LEVELS.length} referral levels written`);
}

async function seedStreakMultiplier() {
  console.log('\n📈 Seeding "streak_multiplier_config" collection...');

  const ref = db
    .collection('streak_multiplier_config')
    .doc('config');

  await ref.set({
    id: 'config',
    isEnabled: STREAK_MULTIPLIER_CONFIG.isEnabled,
    streakRecoveryEnabled: STREAK_MULTIPLIER_CONFIG.streakRecoveryEnabled,
    streakRecoveryUsesAd: STREAK_MULTIPLIER_CONFIG.streakRecoveryUsesAd,
    milestones: STREAK_MULTIPLIER_CONFIG.milestones.map((m) => ({
      id: m.id,
      targetStreakDays: m.targetStreakDays,
      multiplier: m.multiplier,
      label: m.label,
      isActive: m.isActive,
    })),
    updatedAt: now,
  });

  console.log('  🎯 Milestones seeded:');
  for (const m of STREAK_MULTIPLIER_CONFIG.milestones) {
    console.log(`     ${m.targetStreakDays}-day streak → ${m.multiplier}× reward multiplier`);
  }
  console.log('  ✅ Streak multiplier config written');
}

async function verifySeeds() {
  console.log('\n🔍 Verifying seeds...');
  let verified = 0;

  // Verify referral levels
  const levelsSnapshot = await db
    .collection('referral_levels_config')
    .orderBy('levelNumber')
    .get();
  console.log(`  📍 referral_levels_config: ${levelsSnapshot.size} documents`);
  if (levelsSnapshot.size > 0) verified++;

  // Verify streak multiplier config
  const configDoc = await db
    .collection('streak_multiplier_config')
    .doc('config')
    .get();
  const configExists = configDoc.exists;
  console.log(
    `  📍 streak_multiplier_config: ${configExists ? '✅ exists' : '❌ missing'}`
  );
  if (configExists) verified++;

  return verified === 2;
}

// ─── Main ──────────────────────────────────────────────────────

async function main() {
  console.log('🚀 Fun Pay — Premium Systems Seed Script');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log(`Project: ${process.env.GOOGLE_CLOUD_PROJECT || 'cashspark-c15bd'}`);
  console.log('');

  try {
    await seedReferralLevels();
    console.log('');
    await seedStreakMultiplier();
    console.log('');

    const allGood = await verifySeeds();
    if (allGood) {
      console.log('\n✅✅✅ All systems seeded successfully!');
      console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      console.log('  🏅  4 Referral Milestone Levels');
      console.log('  📈  4 Streak Multiplier Milestones');
      console.log('      • 7-day  → 1.2×');
      console.log('      • 15-day → 1.3×');
      console.log('      • 30-day → 1.5×');
      console.log('      • 60-day → 2.0×');
      console.log('  🔄  Streak recovery enabled');
      console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      console.log('\n➡️  Open the app and check:');
      console.log('   • Referral Dashboard → Milestone Levels card');
      console.log('   • Referral Levels screen at /referral-levels');
      console.log('   • Admin Panel → Referral Lvls & Streak Mult tabs');
    } else {
      console.log('\n⚠️  Some seeds failed verification. Check Firestore console.');
    }
  } catch (error) {
    console.error('\n❌ Seeding failed:', error.message);
    console.error(error.stack);
    process.exit(1);
  }

  process.exit(0);
}

main();
