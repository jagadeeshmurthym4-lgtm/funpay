/**
 * Fun Pay — Logout All Users Except Owner
 *
 * Revokes the refresh tokens of EVERY Firebase Auth user EXCEPT the
 * protected owner account. Revoking refresh tokens signs the user out
 * of all devices the next time their tokens refresh.
 *
 * The owner's account (jagadeeshmurthym4@gmail.com) is NOT touched.
 *
 * USAGE:
 *   1. Place your Firebase service key at scripts/service-account-key.json
 *   2. cd scripts && npm install
 *   3. node logout_all_users.js
 */

const admin = require('firebase-admin');

// ─── Protected account (NOT logged out) ────────────────────
const PROTECTED_EMAIL = 'jagadeeshmurthym4@gmail.com'.toLowerCase();

// ─── Load Service Account ──────────────────────────────────
let serviceAccount;
try {
  serviceAccount = require('./service-account-key.json');
} catch (e) {
  console.error('❌ Could not load service-account-key.json');
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const auth = admin.auth();

// ─── Main ──────────────────────────────────────────────────
async function main() {
  console.log('============================================');
  console.log('  Fun Pay — Logout All Users (Except Owner)');
  console.log('============================================\n');

  let loggedOut = 0;
  let skippedOwner = 0;
  let errors = 0;

  try {
    // ── Safety pre-flight: confirm the owner exists BEFORE revoking ──
    // If the protected email were missing (typo), we must NOT proceed,
    // otherwise the owner would be logged out along with everyone else.
    let ownerUid = null;
    let firstToken;
    do {
      const pre = await auth.listUsers(1000, firstToken);
      for (const user of pre.users) {
        if ((user.email || '').toLowerCase() === PROTECTED_EMAIL) {
          ownerUid = user.uid;
          break;
        }
      }
      firstToken = pre.pageToken;
    } while (!ownerUid && firstToken);

    if (!ownerUid) {
      console.error(`❌ SAFETY ABORT: protected email "${PROTECTED_EMAIL}" was not found.`);
      console.error('   Nothing was revoked. Double-check the email and re-run.');
      process.exit(1);
    }
    console.log(`✅ Safety check passed — owner "${PROTECTED_EMAIL}" (${ownerUid}) found. Proceeding.\n`);

    // List all users (paginated).
    let nextPageToken;
    do {
      const list = await auth.listUsers(1000, nextPageToken);
      for (const user of list.users) {
        const email = (user.email || '').toLowerCase();

        // Skip by exact UID — immune to email whitespace/unicode edge cases.
        if (user.uid === ownerUid) {
          console.log(`⏭️  SKIPPED (owner): ${email} (${user.uid})`);
          skippedOwner++;
          continue;
        }

        try {
          // Revoking refresh tokens signs the user out on next token refresh.
          await auth.revokeRefreshTokens(user.uid);
          loggedOut++;
          console.log(`🔒 Logged out: ${email || '(no email)'} (${user.uid})`);
        } catch (e) {
          errors++;
          console.error(`❌ Failed to revoke ${user.uid}: ${e.message}`);
        }
      }
      nextPageToken = list.pageToken;
    } while (nextPageToken);

    console.log('\n══════════════════════════════════════════');
    console.log('  ✅ LOGOUT COMPLETE');
    console.log('══════════════════════════════════════════');
    console.log('');
    console.log(`  Logged out:    ${loggedOut}`);
    console.log(`  Protected:     ${skippedOwner} (owner account kept)`);
    console.log(`  Errors:        ${errors}`);
    console.log('');
    console.log('  Users will be signed out of all devices on');
    console.log('  their next token refresh (up to ~1 hour).');
    console.log('══════════════════════════════════════════\n');
  } catch (error) {
    console.error('\n❌ Failed:', error.message);
    process.exit(1);
  }

  process.exit(0);
}

main();
