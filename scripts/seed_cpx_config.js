/**
 * CPX Research Config Seed Script
 * Creates or updates the `app_settings/cpx` document used by the app's
 * CpxProvider (offer wall URL + enable flag).
 *
 * Usage:
 *   cd scripts && node seed_cpx_config.js
 *
 * Prerequisites:
 *   - Run `firebase login` to authenticate
 *   - Or set GOOGLE_APPLICATION_CREDENTIALS env var
 *   - Or place a service-account-key.json in this folder
 *
 * Fields:
 *   appId          — CPX Research App ID from publisher.cpx-research.com (dashboard)
 *   appSecureHash  — optional; enables the secure_hash=md5(ext_user_id-secret)
 *                    parameter on the offer wall entry link (see CPX docs).
 *                    This value IS readable by the app, so only use it for the
 *                    entry link — NEVER as the postback verification secret.
 *   enabled        — set false to hide/disable the CPX wall in the app
 *
 * The postback verification secret must be set in Firebase Functions config
 * (server-side only, never in Firestore):
 *   firebase functions:config:set cpx.secret="<your-postback-secret>"
 */

const admin = require('firebase-admin');

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

  const db = admin.firestore();

  const config = {
    appId: '35037',
    appSecureHash: '', // optional — see header comment
    enabled: true,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  const ref = db.collection('app_settings').doc('cpx');
  await ref.set(config, { merge: true });

  console.log('✅ CPX config saved to app_settings/cpx:');
  console.log('   appId:    35037');
  console.log('   enabled:  true');
  console.log('');
  console.log('📌 Next steps:');
  console.log('   1. Set the postback secret (server-side only, NEVER in Firestore):');
  console.log('      firebase functions:config:set cpx.secret="<your-secret>"');
  console.log('   2. Deploy functions + rules:');
  console.log('      firebase deploy --only functions,firestore:rules');
  console.log('   3. In the CPX publisher dashboard → Postback Settings, set:');
  console.log('      https://us-central1-cashspark-c15bd.cloudfunctions.net/cpxPostback');
  console.log('');
  console.log('⚠️  The postback endpoint rejects unsigned postbacks by default.');
  console.log('   Configure the hash in the CPX dashboard once the secret is set.');

  process.exit(0);
}

main().catch((error) => {
  console.error('❌ Error:', error.message);
  process.exit(1);
});
