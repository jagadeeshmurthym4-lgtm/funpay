/**
 * Cleanup: Delete all old QR code images from Firebase Storage.
 *
 * Since QR code uploads have been migrated to Cloudinary, the
 * `qr_codes/` prefix in Firebase Storage is no longer used.
 * This script deletes all remaining files in that prefix.
 *
 * Usage:
 *   1. Place your Firebase service account key as scripts/service-account-key.json
 *   2. cd scripts && npm install
 *   3. node cleanup_storage_qr_codes.js
 *
 * The bucket name comes from firebase_options.dart:
 *   cashspark-c15bd.firebasestorage.app
 */

const admin = require('firebase-admin');

// ─── Configuration ──────────────────────────────────────────
const BUCKET = 'cashspark-c15bd.firebasestorage.app';
const PREFIX = 'qr_codes/';  // The folder to clean up

// ─── Initialize Admin SDK ────────────────────────────────────
let serviceAccount;
try {
  serviceAccount = require('./service-account-key.json');
} catch (e) {
  console.error('❌ Could not load service-account-key.json');
  console.error('   Place your Firebase service account key in scripts/service-account-key.json');
  console.error('   You can download it from Firebase Console > Project Settings > Service Accounts');
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  storageBucket: BUCKET,
});

const bucket = admin.storage().bucket();

async function cleanupQrCodes() {
  console.log(`🧹 Cleaning up Firebase Storage: gs://${BUCKET}/${PREFIX}*`);
  console.log('');

  // Step 1: List all files under qr_codes/
  const [files] = await bucket.getFiles({ prefix: PREFIX });

  if (files.length === 0) {
    console.log('✅ No files found under the qr_codes/ prefix. Nothing to clean up.');
    process.exit(0);
  }

  console.log(`📦 Found ${files.length} file(s) to delete:`);
  for (const file of files) {
    const sizeMB = (file.metadata.size / (1024 * 1024)).toFixed(2);
    console.log(`   - ${file.name} (${sizeMB} MB)`);
  }
  console.log('');

  // Step 2: Delete all files
  console.log('🗑️  Deleting files...');
  let deleted = 0;
  let errors = 0;

  for (const file of files) {
    try {
      await file.delete();
      console.log(`   ✅ Deleted: ${file.name}`);
      deleted++;
    } catch (err) {
      console.error(`   ❌ Failed to delete ${file.name}: ${err.message}`);
      errors++;
    }
  }

  // Step 3: Summary
  console.log('');
  console.log('═══════════════════════════════════════');
  console.log(`   ✅ ${deleted} file(s) deleted successfully`);
  if (errors > 0) {
    console.log(`   ⚠️  ${errors} file(s) failed (may need manual cleanup)`);
  }
  console.log('═══════════════════════════════════════');
  console.log('');
  console.log('💡 Tip: You can also verify in Firebase Console:');
  console.log('   Storage > Files > qr_codes/');
  console.log('');

  process.exit(errors > 0 ? 1 : 0);
}

cleanupQrCodes().catch(err => {
  console.error('❌ Error:', err);
  process.exit(1);
});
