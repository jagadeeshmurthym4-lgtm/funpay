/**
 * Cleanup Duplicate User Accounts
 *
 * Finds user documents that share the same email and cleans them up, keeping
 * the MOST RECENTLY ACTIVE account. Duplicate accounts are created when a user
 * deletes their account, reinstalls the app, and re-signs-in with the same
 * Google account — Firebase issues a new UID, the old (stale) user document
 * survives, and the app's migration cannot delete it, so the admin dashboard
 * counts the same person twice.
 *
 * Merge policy (FULL MERGE):
 *   - Per-user collections are REPARENTED to the kept UID: transactions,
 *     withdrawals, rewards, referral_rewards, daily_checkins, tasks,
 *     notifications, device_registry, scratch_cards, project_participations,
 *     support_tickets, cpx_transactions, verification_requests.
 *   - Referrals are reparented on both referrerUserId and referredUserId
 *     (self-referrals are skipped).
 *   - support_chat_messages are reparented on ticketUserId.
 *   - Id-keyed collections (wallets, streaks, weekly_bonuses, monthly_bonuses,
 *     spin_data, agreements): if the kept account already owns the doc the
 *     duplicate's copy is DELETED (avoids double-crediting wallet balances);
 *     otherwise the duplicate's doc is MOVED to the kept UID.
 *   - Missing profile fields on the kept user doc are backfilled from the
 *     duplicates (phone, picture, address, etc.). Wallet balance fields are
 *     NEVER summed — the wallet collection is authoritative.
 *   - The duplicate user document(s) are then deleted.
 *
 * Not covered (unverified schema): custom_tasks, task_submissions,
 * claimed_milestones, login_attempts, fraud_reports. If those collections
 * store a userId field they should be added to REPARENT_BY_USER_ID.
 *
 * Safety:
 *   - DRY-RUN by default — pass --apply to actually modify data.
 *   - Groups containing an admin UID are skipped (never deletes an admin's user doc).
 *   - Everything runs in batches; nothing is written without --apply.
 *   - --delete-auth also removes the duplicate Firebase Auth accounts
 *     (opt-in; skips accounts that are already gone, which is the common case).
 *
 * Usage:
 *   cd scripts/
 *   node cleanup_duplicate_users.js                          # dry-run report
 *   node cleanup_duplicate_users.js --apply                  # perform cleanup
 *   node cleanup_duplicate_users.js --email user@gmail.com   # only that email
 *   node cleanup_duplicate_users.js --apply --delete-auth    # + remove auth accounts
 */

const admin = require('firebase-admin');

const serviceAccount = require('./service-account-key.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

// ─── CLI options ───────────────────────────────────────────────
const APPLY = process.argv.includes('--apply');
const DELETE_AUTH = process.argv.includes('--delete-auth');
const HELP = process.argv.includes('--help');
const emailFilter =
  process.argv
    .find((a) => a.startsWith('--email='))
    ?.split('=')[1]
    ?.trim() || null;

// ─── Config ─────────────────────────────────────────────────────
const BATCH_SIZE = 400;

/** Collections keyed by their own doc id; the `userId` field references the user. */
const REPARENT_BY_USER_ID = [
  'transactions',
  'withdrawals',
  'rewards',
  'referral_rewards',
  'daily_checkins',
  'tasks',
  'notifications',
  'device_registry',
  'scratch_cards',
  'project_participations',
  'support_tickets',
  'cpx_transactions',
  'verification_requests',
];

/** Collections whose document ID IS the userId (one doc per user). */
const ID_KEYED_COLLECTIONS = [
  'wallets',
  'streaks',
  'weekly_bonuses',
  'monthly_bonuses',
  'spin_data',
  'agreements',
];

/** Profile fields backfilled onto the kept user doc when they are missing. */
const PROFILE_FIELDS = [
  'firstName',
  'lastName',
  'fullName',
  'phone',
  'dateOfBirth',
  'gender',
  'address',
  'city',
  'state',
  'country',
  'username',
  'aboutMe',
  'education',
  'experience',
  'portfolioLinks',
  'resumeUrl',
  'certificateUrl',
  'profilePicture',
  'coverImage',
  'referralCodeUsed',
];

if (HELP) {
  console.log(`
  cleanup_duplicate_users.js — merge/clean duplicate user accounts (same email)

  Options:
    --apply          Perform the merge + deletion (default is dry-run).
    --email=ADDR     Only process accounts matching this email.
    --delete-auth    Also delete the duplicate Firebase Auth accounts (requires --apply).
    --help           Show this help.
  `);
  process.exit(0);
}

// ─── Helpers ────────────────────────────────────────────────────

function normalizeEmail(email) {
  if (!email) return '';
  return String(email).trim().toLowerCase();
}

function tsMillis(value) {
  if (!value) return null;
  if (typeof value === 'string') {
    const t = Date.parse(value);
    return Number.isNaN(t) ? null : t;
  }
  if (typeof value.toDate === 'function') return value.toDate().getTime();
  return null;
}

function activityMillis(data) {
  return tsMillis(data.lastLoginAt) ?? tsMillis(data.createdAt) ?? 0;
}

function fmtTs(value) {
  const ms = tsMillis(value);
  return ms ? new Date(ms).toISOString() : 'n/a';
}

function isEmpty(value) {
  return value == null || (Array.isArray(value) && value.length === 0);
}

async function batchRun(items, fn) {
  for (let i = 0; i < items.length; i += BATCH_SIZE) {
    const chunk = items.slice(i, i + BATCH_SIZE);
    const batch = db.batch();
    for (const item of chunk) fn(batch, item);
    await batch.commit();
  }
}

function bump(report, key) {
  report[key] = (report[key] || 0) + 1;
}

// ─── Merge operations ───────────────────────────────────────────

/**
 * Reassigns documents whose `field` equals oldUid to keeperUid.
 */
async function reparentCollection(collectionName, field, oldUid, keeperUid, report) {
  const snapshot = await db
    .collection(collectionName)
    .where(field, '==', oldUid)
    .get();
  if (snapshot.empty) return;
  if (APPLY) {
    await batchRun(snapshot.docs, (batch, doc) => batch.update(doc.ref, { [field]: keeperUid }));
  }
  bump(report, `${collectionName}.updated`);
}

/**
 * Reparents support chat messages (keyed by messageId, references user via ticketUserId).
 */
async function reparentChatMessages(oldUid, keeperUid, report) {
  const snapshot = await db
    .collection('support_chat_messages')
    .where('ticketUserId', '==', oldUid)
    .get();
  if (snapshot.empty) return;
  if (APPLY) {
    await batchRun(snapshot.docs, (batch, doc) =>
      batch.update(doc.ref, { ticketUserId: keeperUid }),
    );
  }
  bump(report, 'support_chat_messages.updated');
}

/**
 * Reparents referrals on both referrerUserId and referredUserId.
 * Skips any referral that would become a self-referral.
 */
async function mergeReferrals(oldUid, keeperUid, report) {
  const ids = new Set();
  const [asReferrer, asReferred] = await Promise.all([
    db.collection('referrals').where('referrerUserId', '==', oldUid).get(),
    db.collection('referrals').where('referredUserId', '==', oldUid).get(),
  ]);
  asReferrer.docs.forEach((d) => ids.add(d.id));
  asReferred.docs.forEach((d) => ids.add(d.id));
  if (ids.size === 0) return;

  // Reads first (need current data to guard against self-referrals)…
  const updates = [];
  for (const id of ids) {
    const ref = db.collection('referrals').doc(id);
    const doc = await ref.get();
    if (!doc.exists) continue;
    const data = doc.data();

    const patch = {};
    if (data.referrerUserId === oldUid) patch.referrerUserId = keeperUid;
    if (data.referredUserId === oldUid) patch.referredUserId = keeperUid;
    if (Object.keys(patch).length === 0) continue;

    const newReferrer = patch.referrerUserId ?? data.referrerUserId;
    const newReferred = patch.referredUserId ?? data.referredUserId;
    if (newReferrer === newReferred) {
      console.log(`     ⚠️  Skipping referral ${id} (would become a self-referral)`);
      continue;
    }
    updates.push({ ref, patch });
  }

  if (updates.length === 0) return;
  if (APPLY) {
    await batchRun(updates, (batch, { ref, patch }) => batch.update(ref, patch));
  }
  report['referrals.updated'] = (report['referrals.updated'] || 0) + updates.length;
}

/**
 * Handles collections keyed by userId:
 *   - keeper already owns one  → delete the duplicate's (no double-credit).
 *   - keeper has none          → move the duplicate's doc to the keeper UID.
 */
async function mergeIdKeyedCollection(collectionName, oldUid, keeperUid, report) {
  const oldDoc = await db.collection(collectionName).doc(oldUid).get();
  if (!oldDoc.exists) return;

  const keeperDoc = await db.collection(collectionName).doc(keeperUid).get();
  if (keeperDoc.exists) {
    if (APPLY) await oldDoc.ref.delete();
    bump(report, `${collectionName}.deleted`);
  } else {
    if (APPLY) {
      const batch = db.batch();
      batch.set(db.collection(collectionName).doc(keeperUid), oldDoc.data());
      batch.delete(oldDoc.ref);
      await batch.commit();
    }
    bump(report, `${collectionName}.moved`);
  }
}

/**
 * Backfills missing profile fields on the kept user doc from a duplicate.
 * Wallet/financial fields are intentionally NOT merged (wallets is authoritative).
 */
function mergeProfileFields(keeperData, dupData) {
  const patch = {};
  for (const field of PROFILE_FIELDS) {
    if (isEmpty(keeperData[field]) && !isEmpty(dupData[field])) {
      patch[field] = dupData[field];
    }
  }
  // State flags: only upgrade to "true" — never downgrade the kept account.
  if (!keeperData.isVerified && dupData.isVerified) patch.isVerified = true;
  return patch;
}

// ─── Main ───────────────────────────────────────────────────────

async function findDuplicateGroups() {
  const users = await db.collection('users').get();
  const byEmail = new Map();
  for (const doc of users.docs) {
    const email = normalizeEmail(doc.data().email);
    if (!email) continue;
    if (!byEmail.has(email)) byEmail.set(email, []);
    byEmail.get(email).push(doc);
  }

  const groups = [...byEmail.values()].filter((g) => g.length > 1);
  if (!emailFilter) return groups;

  const wanted = normalizeEmail(emailFilter);
  return groups.filter((g) => normalizeEmail(g[0].data().email) === wanted);
}

async function main() {
  console.log('🔍 Fun Pay — Duplicate User Cleanup');
  console.log(`   Mode: ${APPLY ? 'APPLY — writes WILL be performed' : 'DRY-RUN — no changes will be made'}`);
  if (emailFilter) console.log(`   Filter: only ${emailFilter}`);
  if (DELETE_AUTH) console.log(`   Auth: duplicate Firebase Auth accounts will ${APPLY ? 'be deleted' : 'be listed (needs --apply)'}`);
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

  // Never touch groups that contain an admin account.
  const admins = await db.collection('admins').get();
  const adminUids = new Set();
  admins.docs.forEach((d) => {
    adminUids.add(d.id);
    if (d.data().uid) adminUids.add(d.data().uid);
  });

  const groups = await findDuplicateGroups();
  if (groups.length === 0) {
    console.log('✅ No duplicate user accounts found (by email).');
    return;
  }

  console.log(`Found ${groups.length} email group(s) with duplicate accounts:\n`);

  let skippedAdminGroups = 0;
  let duplicateDocs = 0;
  const overallReport = {};

  for (const group of groups) {
    // Most recently active account wins (lastLoginAt, then createdAt).
    group.sort((a, b) => activityMillis(b.data()) - activityMillis(a.data()));
    const keeper = group[0];
    const dups = group.slice(1);
    const email = normalizeEmail(keeper.data().email);
    const keeperData = keeper.data();

    if (group.some((d) => adminUids.has(d.id))) {
      skippedAdminGroups++;
      console.log(`⛔ ${email} — skipped (group contains an admin UID)`);
      console.log('');
      continue;
    }

    console.log(`📧 ${email}  (${group.length} docs)`);
    for (const d of group) {
      const data = d.data();
      const tag = d.id === keeper.id ? '✅ KEEP' : '🗑️  dup';
      console.log(
        `   ${tag}  ${d.id}\n` +
          `        created: ${fmtTs(data.createdAt)}   lastLogin: ${fmtTs(data.lastLoginAt)}`,
      );
    }

    const report = {};
    // Merged profile patches accumulate across dups and are applied once below.
    // Each dup is compared against the original keeper data, so for groups of
    // 3+ docs the LAST dup wins on fields the keeper was missing — harmless
    // since every doc in the group is the same person.
    let profilePatch = {};
    for (const dup of dups) {
      const dupUid = dup.id;

      for (const col of REPARENT_BY_USER_ID) {
        await reparentCollection(col, 'userId', dupUid, keeper.id, report);
      }
      await mergeReferrals(dupUid, keeper.id, report);
      await reparentChatMessages(dupUid, keeper.id, report);
      for (const col of ID_KEYED_COLLECTIONS) {
        await mergeIdKeyedCollection(col, dupUid, keeper.id, report);
      }

      // Backfill missing profile info into the kept user doc.
      Object.assign(profilePatch, mergeProfileFields(keeperData, dup.data()));

      if (APPLY) {
        await db.collection('users').doc(dupUid).delete();
      }
      if (DELETE_AUTH) {
        if (APPLY) {
          try {
            await admin.auth().deleteUser(dupUid);
            bump(report, 'auth_accounts.deleted');
          } catch (err) {
            if (err.code !== 'auth/user-not-found') {
              console.log(`     ⚠️  Could not delete auth account ${dupUid}: ${err.message}`);
            }
          }
        } else {
          bump(report, 'auth_accounts.to_delete');
        }
      }
      duplicateDocs++;
    }

    // Apply the merged profile patch once per group.
    if (Object.keys(profilePatch).length > 0) {
      if (APPLY) await db.collection('users').doc(keeper.id).update(profilePatch);
      bump(report, 'user_doc.profile_backfilled');
    }

    for (const [key, count] of Object.entries(report)) {
      overallReport[key] = (overallReport[key] || 0) + count;
    }
    const summary =
      Object.keys(report).length === 0
        ? 'nothing to merge'
        : Object.entries(report)
            .map(([k, v]) => `${k}: ${v}`)
            .join(', ');
    console.log(`   ${APPLY ? '🔄 Merged' : '📋 Would merge'}: ${summary}`);
    console.log('');
  }

  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  if (APPLY) {
    console.log(`✅ Cleanup complete! ${duplicateDocs} duplicate user doc(s) processed.`);
  } else {
    console.log(`ℹ️  DRY-RUN complete — nothing was modified.`);
    console.log(`   ${duplicateDocs} duplicate user doc(s) found across ${groups.length} group(s).`);
    console.log(`   Re-run with --apply to perform the merge and deletion.`);
  }
  if (skippedAdminGroups > 0) {
    console.log(`   ⛔ ${skippedAdminGroups} group(s) skipped because they contain an admin UID.`);
  }
  if (Object.keys(overallReport).length > 0) {
    console.log('\n   Per-collection totals:');
    for (const [k, v] of Object.entries(overallReport)) {
      console.log(`     - ${k}: ${v}`);
    }
  }
  console.log('');
}

main()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error('\n❌ Failed:', err.message);
    console.error(err.stack);
    process.exit(1);
  });
