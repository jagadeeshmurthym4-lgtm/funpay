/**
 * Firestore Seed Script
 * Seeds the 'offers' and 'projects' collections with initial data
 * matching the original hardcoded values from the HomeScreen.
 *
 * Usage:
 *   1. cd scripts/
 *   2. npm install
 *   3. Set GOOGLE_APPLICATION_CREDENTIALS or use firebase login
 *   4. node seed_data.js
 *
 * Note: This script uses the Firebase Admin SDK and requires
 * a service account key. Download one from:
 *   Firebase Console > Project Settings > Service Accounts > Generate Key
 *
 * Alternatively, run with:
 *   GOOGLE_APPLICATION_CREDENTIALS=path/to/key.json node seed_data.js
 */

const admin = require('firebase-admin');

// ─── Firebase Init ─────────────────────────────────────────────

// Try loading credentials from env or fall back to application default
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
});

const db = admin.firestore();

// ─── Seed Data ─────────────────────────────────────────────────

const AFFILIATE_PROJECTS = [
  {
    projectId: 'aff-project-1',
    title: 'App Install - Music',
    subtitle: 'Install the music streaming app and earn ₹50',
    description: 'Install the music streaming app and create an account to earn instant rewards.',
    rewardAmount: 50,
    category: 'Install',
    projectType: 'installApp',
    affiliateTrackingLink: 'https://play.google.com/store/apps/details?id=com.example.music',
    instructions: ['Click "Complete Now" to open the app page', 'Install the app from the store', 'Open the app and create an account', 'Take a screenshot as proof'],
    termsAndConditions: 'Must be a new user. Only one claim per device.',
    completionTime: 15,
    difficulty: 'easy',
    lifecycleStatus: 'active',
    featured: true,
    isNew: true,
    createdBy: 'admin',
  },
  {
    projectId: 'aff-project-2',
    title: 'YouTube Review',
    subtitle: 'Watch and review a video for ₹80',
    description: 'Watch a video and leave a genuine review to earn rewards.',
    rewardAmount: 80,
    category: 'Social',
    projectType: 'affiliateOffer',
    affiliateTrackingLink: 'https://youtube.com/watch?v=partner-review',
    instructions: ['Click "Complete Now" to open the video', 'Watch the full video', 'Leave an honest review/comment', 'Take a screenshot of your comment'],
    termsAndConditions: 'Review must be genuine. Copy-paste reviews will be rejected.',
    completionTime: 10,
    difficulty: 'easy',
    lifecycleStatus: 'active',
    featured: false,
    isNew: true,
    createdBy: 'admin',
  },
  {
    projectId: 'aff-project-3',
    title: 'Shop & Earn',
    subtitle: 'Browse products and earn ₹120',
    description: 'Browse featured products on our partner platform and earn rewards for purchases.',
    rewardAmount: 120,
    category: 'Shopping',
    projectType: 'affiliateOffer',
    affiliateTrackingLink: 'https://shop.example.com/featured?ref=cashspark',
    instructions: ['Click "Complete Now" to visit the shop', 'Browse the featured products', 'Add an item to cart (no purchase needed)', 'Take a screenshot of your cart'],
    termsAndConditions: 'No purchase necessary. Just adding to cart counts.',
    completionTime: 20,
    difficulty: 'easy',
    lifecycleStatus: 'active',
    featured: true,
    isNew: false,
    createdBy: 'admin',
  },
  {
    projectId: 'aff-project-4',
    title: 'Sign Up Bonus',
    subtitle: 'Sign up on partner platform for ₹30',
    description: 'Sign up on our partner platform using your referral link.',
    rewardAmount: 30,
    category: 'Install',
    projectType: 'registration',
    affiliateTrackingLink: 'https://partner.example.com/signup?ref=cashspark',
    instructions: ['Click "Complete Now" to open the signup page', 'Fill in your details', 'Verify your email/phone', 'Take a screenshot of the confirmation'],
    termsAndConditions: 'Must be a new user on the partner platform.',
    completionTime: 5,
    difficulty: 'easy',
    lifecycleStatus: 'active',
    featured: false,
    isNew: true,
    createdBy: 'admin',
  },
  {
    projectId: 'aff-project-5',
    title: 'Watch Ad Video',
    subtitle: 'Watch a short ad for ₹10',
    description: 'Watch a 30-second advertisement video to earn quick rewards.',
    rewardAmount: 10,
    category: 'Watch',
    projectType: 'watchVideo',
    affiliateTrackingLink: 'https://ads.example.com/watch/partner',
    instructions: ['Click "Complete Now" to start the video', 'Watch the full 30-second ad', 'That is it! Reward is automatically credited'],
    termsAndConditions: 'Must watch the full ad. Skipping will not count.',
    completionTime: 1,
    difficulty: 'easy',
    lifecycleStatus: 'active',
    featured: false,
    isNew: false,
    createdBy: 'admin',
  },
  {
    projectId: 'aff-project-6',
    title: 'Daily Check-in',
    subtitle: 'Check in daily to maintain your streak',
    description: 'Check in daily to maintain your streak and earn bonus rewards.',
    rewardAmount: 5,
    category: 'Daily',
    projectType: 'customTask',
    affiliateTrackingLink: 'https://cashspark.app/checkin',
    instructions: ['Open the app daily', 'Tap the check-in button', 'Keep your streak alive for bigger bonuses'],
    termsAndConditions: 'Streak resets if you miss a day.',
    completionTime: 1,
    difficulty: 'easy',
    lifecycleStatus: 'active',
    featured: false,
    isNew: false,
    createdBy: 'admin',
  },
  {
    projectId: 'aff-project-7',
    title: 'Game Trial',
    subtitle: 'Try a new game and reach level 5',
    description: 'Try a new game and reach level 5 to earn rewards.',
    rewardAmount: 60,
    category: 'Install',
    projectType: 'installApp',
    affiliateTrackingLink: 'https://play.google.com/store/apps/details?id=com.example.game',
    instructions: ['Click "Complete Now" to download the game', 'Install and open the game', 'Play through the tutorial and reach level 5', 'Take a screenshot showing your level'],
    termsAndConditions: 'Must be a new player. Existing accounts not eligible.',
    completionTime: 30,
    difficulty: 'medium',
    lifecycleStatus: 'active',
    featured: false,
    isNew: false,
    createdBy: 'admin',
  },
  {
    projectId: 'aff-project-8',
    title: 'Survey Feedback',
    subtitle: 'Complete a quick survey for ₹40',
    description: 'Complete a 5-minute survey about your preferences and earn instant rewards.',
    rewardAmount: 40,
    category: 'Survey',
    projectType: 'survey',
    affiliateTrackingLink: 'https://survey.example.com/feedback?ref=cashspark',
    instructions: ['Click "Complete Now" to start the survey', 'Answer all questions honestly', 'Submit the survey', 'Screenshot the completion screen'],
    termsAndConditions: 'Answers must be genuine. Automated responses will be rejected.',
    completionTime: 5,
    difficulty: 'easy',
    lifecycleStatus: 'active',
    featured: false,
    isNew: false,
    createdBy: 'admin',
  },
  {
    projectId: 'aff-project-9',
    title: 'Install Utility App',
    subtitle: 'Install a utility app and earn ₹75',
    description: 'Install a utility app and complete onboarding to earn rewards.',
    rewardAmount: 75,
    category: 'Install',
    projectType: 'installApp',
    affiliateTrackingLink: 'https://play.google.com/store/apps/details?id=com.example.utility',
    instructions: ['Click "Complete Now" to open the app page', 'Install the utility app', 'Complete the onboarding process', 'Take a screenshot of the home screen'],
    termsAndConditions: 'Must complete onboarding. Just installing is not enough.',
    completionTime: 15,
    difficulty: 'easy',
    lifecycleStatus: 'active',
    featured: false,
    isNew: true,
    createdBy: 'admin',
  },
  {
    projectId: 'aff-project-10',
    title: 'Video Upload',
    subtitle: 'Create and upload a short video for ₹200',
    description: 'Create and upload a short video using the partner app.',
    rewardAmount: 200,
    category: 'Social',
    projectType: 'affiliateOffer',
    affiliateTrackingLink: 'https://video.example.com/create?ref=cashspark',
    instructions: ['Click "Complete Now" to open the partner app', 'Create a short video (15-60 seconds)', 'Upload and publish it', 'Take a screenshot of your uploaded video'],
    termsAndConditions: 'Video must be original. Copyrighted content will be rejected.',
    completionTime: 30,
    difficulty: 'medium',
    lifecycleStatus: 'active',
    featured: true,
    isNew: false,
    createdBy: 'admin',
  },
  {
    projectId: 'aff-project-11',
    title: 'Walk & Earn',
    subtitle: 'Track your steps and earn ₹25',
    description: 'Track your daily steps and earn rewards for reaching 10K steps.',
    rewardAmount: 25,
    category: 'Fitness',
    projectType: 'customTask',
    affiliateTrackingLink: 'https://cashspark.app/walk',
    instructions: ['Enable step tracking in the app', 'Walk at least 10,000 steps in a day', 'Come back tomorrow to claim your reward'],
    termsAndConditions: 'Only tracked steps within the app count.',
    completionTime: 1,
    difficulty: 'medium',
    lifecycleStatus: 'active',
    featured: false,
    isNew: false,
    createdBy: 'admin',
  },
  {
    projectId: 'aff-project-12',
    title: 'Referral Challenge',
    subtitle: 'Refer 5 friends and earn ₹500',
    description: 'Refer 5 friends who complete their first task and earn a big bonus.',
    rewardAmount: 500,
    category: 'Referral',
    projectType: 'affiliateOffer',
    affiliateTrackingLink: 'https://cashspark.app/refer?ref=share',
    instructions: ['Share your referral link with friends', 'Ask them to sign up and complete a task', 'Track your progress in the referral dashboard', 'Reward is credited after 5 friends complete'],
    termsAndConditions: 'Friends must be new users and complete at least one task.',
    completionTime: 60,
    difficulty: 'hard',
    lifecycleStatus: 'active',
    featured: true,
    isNew: false,
    createdBy: 'admin',
  },
];

const OFFERS = [
  {
    offerId: 'offer-1',
    title: 'Download & Earn',
    subtitle: 'Install partner apps and earn instant rewards up to ₹150',
    iconName: 'download',
    reward: '₹150',
    colorValue: 0xFF4ADE80,
    isActive: true,
    sortOrder: 1,
  },
  {
    offerId: 'offer-2',
    title: 'Complete Tasks',
    subtitle: 'Finish daily tasks & surveys to earn bonus cash rewards',
    iconName: 'assignment',
    reward: '₹200',
    colorValue: 0xFF3B82F6,
    isActive: true,
    sortOrder: 2,
  },
  {
    offerId: 'offer-3',
    title: 'Watch & Win',
    subtitle: 'Watch short videos and ads to earn real money instantly',
    iconName: 'play_circle',
    reward: '₹100',
    colorValue: 0xFF8B5CF6,
    isActive: true,
    sortOrder: 3,
  },
  {
    offerId: 'offer-4',
    title: 'Refer Friends',
    subtitle: 'Invite friends and earn 10% of their earnings forever',
    iconName: 'person_add',
    reward: '₹500',
    colorValue: 0xFFF59E0B,
    isActive: true,
    sortOrder: 4,
  },
  {
    offerId: 'offer-5',
    title: 'Spin & Win',
    subtitle: 'Try your luck with the daily spin wheel for bonus prizes',
    iconName: 'sports_esports',
    reward: '₹250',
    colorValue: 0xFFEC4899,
    isActive: true,
    sortOrder: 5,
  },
  {
    offerId: 'offer-6',
    title: 'Quiz Challenge',
    subtitle: 'Answer trivia questions correctly and win cash rewards',
    iconName: 'quiz',
    reward: '₹300',
    colorValue: 0xFF14B8A6,
    isActive: true,
    sortOrder: 6,
  },
];

const PROJECTS = [
  {
    projectId: 'project-1',
    name: 'App Install - Music',
    rewardAmount: 50,
    category: 'Install',
    description: 'Install the music streaming app and create an account',
    colorValue: 0xFF4ADE80,
    iconName: 'music_note',
    status: 'New',
    isActive: true,
    sortOrder: 1,
  },
  {
    projectId: 'project-2',
    name: 'YouTube Review',
    rewardAmount: 80,
    category: 'Social',
    description: 'Watch a video and leave a genuine review',
    colorValue: 0xFF3B82F6,
    iconName: 'thumb_up',
    status: 'Trending',
    isActive: true,
    sortOrder: 2,
  },
  {
    projectId: 'project-3',
    name: 'Shop & Earn',
    rewardAmount: 120,
    category: 'Shopping',
    description: 'Browse featured products and earn rewards for purchases',
    colorValue: 0xFF8B5CF6,
    iconName: 'shopping_bag',
    status: 'Popular',
    isActive: true,
    sortOrder: 3,
  },
  {
    projectId: 'project-4',
    name: 'Sign Up Bonus',
    rewardAmount: 30,
    category: 'Install',
    description: 'Sign up on partner platform using referral',
    colorValue: 0xFFF59E0B,
    iconName: 'person_add',
    status: 'New',
    isActive: true,
    sortOrder: 4,
  },
  {
    projectId: 'project-5',
    name: 'Watch Ad Video',
    rewardAmount: 10,
    category: 'Watch',
    description: 'Watch a 30-second advertisement video',
    colorValue: 0xFFEC4899,
    iconName: 'play_circle',
    status: 'Available',
    isActive: true,
    sortOrder: 5,
  },
  {
    projectId: 'project-6',
    name: 'Daily Check-in',
    rewardAmount: 5,
    category: 'Daily',
    description: 'Check in daily to maintain your streak and earn bonuses',
    colorValue: 0xFF14B8A6,
    iconName: 'checklist',
    status: 'Available',
    isActive: true,
    sortOrder: 6,
  },
  {
    projectId: 'project-7',
    name: 'Game Trial',
    rewardAmount: 60,
    category: 'Install',
    description: 'Try a new game and reach level 5',
    colorValue: 0xFFFF6B6B,
    iconName: 'sports_esports',
    status: 'Trending',
    isActive: true,
    sortOrder: 7,
  },
  {
    projectId: 'project-8',
    name: 'Survey Feedback',
    rewardAmount: 40,
    category: 'Survey',
    description: 'Complete a 5-minute survey about your preferences',
    colorValue: 0xFF845EF7,
    iconName: 'quiz',
    status: 'Available',
    isActive: true,
    sortOrder: 8,
  },
  {
    projectId: 'project-9',
    name: 'Install Utility App',
    rewardAmount: 75,
    category: 'Install',
    description: 'Install a utility app and complete onboarding',
    colorValue: 0xFF20C997,
    iconName: 'extension',
    status: 'New',
    isActive: true,
    sortOrder: 9,
  },
  {
    projectId: 'project-10',
    name: 'Video Upload',
    rewardAmount: 200,
    category: 'Social',
    description: 'Create and upload a short video using the partner app',
    colorValue: 0xFFFF922B,
    iconName: 'videocam',
    status: 'Trending',
    isActive: true,
    sortOrder: 10,
  },
  {
    projectId: 'project-11',
    name: 'Walk & Earn',
    rewardAmount: 25,
    category: 'Fitness',
    description: 'Track your daily steps and earn rewards for 10K steps',
    colorValue: 0xFF4ADE80,
    iconName: 'directions_walk',
    status: 'Available',
    isActive: true,
    sortOrder: 11,
  },
  {
    projectId: 'project-12',
    name: 'Referral Challenge',
    rewardAmount: 500,
    category: 'Referral',
    description: 'Refer 5 friends who complete their first task',
    colorValue: 0xFFF59E0B,
    iconName: 'stars',
    status: 'Popular',
    isActive: true,
    sortOrder: 12,
  },
];

// ─── Seed Function ─────────────────────────────────────────────

async function seedCollection(collectionName, documents) {
  console.log(`\n📦 Seeding "${collectionName}" collection...`);
  const batch = db.batch();
  const now = admin.firestore.Timestamp.now();

  for (const doc of documents) {
    // Use userId as doc ID for spin_data, otherwise offerId or projectId
    const docId = collectionName === 'spin_data' ? doc.userId : (doc.offerId || doc.projectId);
    const ref = db.collection(collectionName).doc(docId);

    // Attach timestamps (but not for spin_data which has its own lastSpinDate)
    // Affiliate projects use createdDate/expiryDate/updatedDate field naming
    const data = collectionName === 'spin_data'
      ? {
          ...doc,
          lastSpinDate: now,
          createdAt: now,
          updatedAt: now,
        }
      : collectionName === 'affiliate_projects'
        ? {
            ...doc,
            createdDate: now,
            expiryDate: admin.firestore.Timestamp.fromDate(
              new Date(Date.now() + 30 * 24 * 60 * 60 * 1000)
            ),
            updatedDate: now,
          }
        : {
            ...doc,
            createdAt: now,
            updatedAt: now,
          };

    batch.set(ref, data);
  }

  await batch.commit();
  console.log(`  ✅ ${documents.length} documents written to "${collectionName}"`);
}

async function main() {
  console.log('🚀 Fun Pay — Firestore Seed Script');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log(`Project: ${process.env.GOOGLE_CLOUD_PROJECT || 'cashspark-c15bd'}`);

  try {
    await seedCollection('offers', OFFERS);
    await seedCollection('projects', PROJECTS);
    await seedCollection('affiliate_projects', AFFILIATE_PROJECTS);
    console.log('\n✅ Seeding complete!');
    console.log('  📍 6 offers created');
    console.log('  📍 12 projects created');
    console.log('  📍 12 affiliate projects created');
  } catch (error) {
    console.error('\n❌ Seeding failed:', error.message);
    process.exit(1);
  }

  process.exit(0);
}

main();
