/**
 * Admin Setup Script
 * Looks up a Firebase Auth user by email and creates an admin document in Firestore.
 *
 * Usage:
 *   cd scripts && node add_admin.js
 *
 * Prerequisites:
 *   - Run `firebase login` to authenticate
 *   - Or set GOOGLE_APPLICATION_CREDENTIALS env var
 */

const admin = require('firebase-admin');
const readline = require('readline');

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout,
});

function ask(question) {
  return new Promise((resolve) => {
    rl.question(question, (answer) => {
      resolve(answer.trim());
    });
  });
}

async function main() {
  // Try loading service account key, fall back to application default
  let serviceAccount;
  try {
    serviceAccount = require('./service-account-key.json');
  } catch (e) {
    // Will use application default credentials
  }

  admin.initializeApp({
    credential: serviceAccount
      ? admin.credential.cert(serviceAccount)
      : admin.credential.applicationDefault(),
  });

  const auth = admin.auth();
  const db = admin.firestore();

  const email = 'jagadeeshmurthym4@gmail.com';

  console.log(`🔍 Looking up user: ${email}`);
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

  try {
    const userRecord = await auth.getUserByEmail(email);
    const uid = userRecord.uid;
    console.log(`✅ Found user:`);
    console.log(`   UID:      ${uid}`);
    console.log(`   Email:    ${userRecord.email}`);
    console.log(`   Provider: ${userRecord.providerData.map(p => p.providerId).join(', ')}`);

    console.log(`\n📝 Creating admin document at /admins/${uid}...`);

    const adminData = {
      uid: uid,
      email: email,
      fullName: userRecord.displayName || 'Admin User',
      role: 'admin',
      isActive: true,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    await db.collection('admins').doc(uid).set(adminData);

    console.log(`✅ Admin document created successfully!`);
    console.log(`   Collection: admins`);
    console.log(`   Document:   ${uid}`);
    console.log(`\n🎉 You can now create tasks with Google Sign-In using ${email}`);
  } catch (error) {
    if (error.code === 'auth/user-not-found') {
      console.error(`❌ User not found: ${email}`);
      console.error(`   Make sure you've signed in at least once with this Google account.`);
      console.error(`   If the user exists, check Firebase Console → Authentication → Users.`);
    } else {
      console.error(`❌ Error:`, error.message);
    }
    process.exit(1);
  }

  rl.close();
  process.exit(0);
}

main();
