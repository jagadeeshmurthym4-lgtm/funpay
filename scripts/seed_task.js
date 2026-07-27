/**
 * Custom Task Seed Script
 * Adds a task document to the 'custom_tasks' collection in Firestore.
 *
 * Usage:
 *   cd scripts && node seed_task.js
 *
 * Prerequisites:
 *   - Run `firebase login` to authenticate
 *   - Or set GOOGLE_APPLICATION_CREDENTIALS env var
 *   - npm install (to get firebase-admin dependency)
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
  projectId: 'cashspark-c15bd',
});

const db = admin.firestore();

// ─── Task Data ─────────────────────────────────────────────────

const TASKS = [
  {
    taskId: 'task_' + Date.now() + '_' + Math.random().toString(36).substring(2, 11),
    title: 'Find Bug and Earn',
    description: 'Find a bug in the app and report it with details. If the bug is confirmed, you earn ₹10 instantly!',
    rewardAmount: 10.0,
    taskLink: null,
    category: 'General',
    isActive: true,
    createdBy: 'admin',
  },
];

// ─── Seed Function ─────────────────────────────────────────────

async function seedTasks() {
  console.log('🚀 Seeding "custom_tasks" collection...');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log(`Project: ${process.env.GOOGLE_CLOUD_PROJECT || 'cashspark-c15bd'}`);

  const batch = db.batch();
  const now = admin.firestore.Timestamp.now();

  for (const task of TASKS) {
    const ref = db.collection('custom_tasks').doc(task.taskId);
    const data = {
      ...task,
      createdAt: now,
      updatedAt: now,
    };
    batch.set(ref, data);
    console.log(`  📝 Task: "${task.title}" (₹${task.rewardAmount})`);
  }

  await batch.commit();
  console.log(`\n✅ ${TASKS.length} task(s) written to "custom_tasks"`);
}

async function main() {
  try {
    await seedTasks();
    console.log('\n🎉 Done! You can now see the task in the app.');
  } catch (error) {
    console.error('\n❌ Seeding failed:', error.message);
    process.exit(1);
  }
  process.exit(0);
}

main();
