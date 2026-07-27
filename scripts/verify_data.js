const admin = require('firebase-admin');

const serviceAccount = require('./service-account-key.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function verify() {
  console.log('=== Verifying affiliate_projects collection ===\n');
  
  const snapshot = await db.collection('affiliate_projects').get();
  
  if (snapshot.empty) {
    console.log('❌ affiliate_projects collection is EMPTY!');
    console.log('No documents found.');
  } else {
    console.log(`✅ Found ${snapshot.docs.length} documents in affiliate_projects\n`);
    
    for (const doc of snapshot.docs) {
      const data = doc.data();
      console.log(`[${doc.id}] ${data.title || 'NO TITLE'}`);
      console.log(`   lifecycleStatus: "${data.lifecycleStatus}"`);
      console.log(`   featured: ${data.featured}`);
      console.log(`   rewardAmount: ${data.rewardAmount}`);
      console.log(`   category: ${data.category}`);
      console.log('');
    }
    
    // Check how many have lifecycleStatus = 'active'
    const activeSnapshot = await db.collection('affiliate_projects')
      .where('lifecycleStatus', '==', 'active')
      .get();
    
    console.log(`\n=== Filtered: lifecycleStatus == 'active' ===`);
    if (activeSnapshot.empty) {
      console.log('❌ No documents match lifecycleStatus == "active"');
      // Show all lifecycleStatus values present
      const statuses = new Set();
      snapshot.docs.forEach(d => statuses.add(d.data().lifecycleStatus));
      console.log(`   Available lifecycleStatus values: ${[...statuses].join(', ')}`);
    } else {
      console.log(`✅ ${activeSnapshot.docs.length} documents match the filter`);
      activeSnapshot.docs.forEach(d => {
        console.log(`   - ${d.data().title}: status="${d.data().lifecycleStatus}"`);
      });
    }
  }

  console.log('\n=== Verifying projects collection ===');
  const projectsSnap = await db.collection('projects').get();
  if (projectsSnap.empty) {
    console.log('❌ projects collection is EMPTY!');
  } else {
    console.log(`✅ Found ${projectsSnap.docs.length} documents`);
    projectsSnap.docs.forEach(d => {
      const data = d.data();
      console.log(`   [${d.id}] ${data.name || data.title || 'NO NAME'} - isActive: ${data.isActive}`);
    });
  }

  process.exit(0);
}

verify().catch(err => {
  console.error('❌ Error:', err);
  process.exit(1);
});
