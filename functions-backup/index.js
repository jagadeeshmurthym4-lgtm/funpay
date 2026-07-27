const functions = require('firebase-functions');
const admin = require('firebase-admin');
const Razorpay = require('razorpay');

admin.initializeApp();

const db = admin.firestore();

// Initialize Razorpay (keys set via firebase functions:config:set)
const razorpayKeyId = functions.config().razorpay?.key_id;
const razorpayKeySecret = functions.config().razorpay?.key_secret;
const razorpayAccountNumber = functions.config().razorpay?.account_number;

let razorpay;
if (razorpayKeyId && razorpayKeySecret) {
  razorpay = new Razorpay({
    key_id: razorpayKeyId,
    key_secret: razorpayKeySecret,
  });
}

/**
 * Send notification to a specific user via their FCM token
 */
async function sendToUser(userId, title, message, type) {
  try {
    const userDoc = await db.collection('users').doc(userId).get();
    if (!userDoc.exists) return;

    const fcmToken = userDoc.data().fcmToken;
    if (!fcmToken) return;

    // Also store notification in Firestore
    const notificationRef = db.collection('notifications').doc();
    await notificationRef.set({
      notificationId: notificationRef.id,
      userId: userId,
      title: title,
      message: message,
      type: type || 'other',
      isRead: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Send FCM push notification
    const payload = {
      notification: {
        title: title,
        body: message,
      },
      data: {
        type: type || 'other',
        notificationId: notificationRef.id,
      },
      token: fcmToken,
    };

    await admin.messaging().send(payload);
    console.log(`Notification sent to user ${userId}: ${title}`);
  } catch (error) {
    console.error(`Error sending notification to user ${userId}:`, error);
  }
}

/**
 * Send notification to all users via the 'all_users' topic
 */
async function sendToAllUsers(title, message, type) {
  try {
    // Store notification for each user in Firestore
    const usersSnapshot = await db.collection('users').get();
    const batch = db.batch();

    usersSnapshot.forEach((userDoc) => {
      const notificationRef = db.collection('notifications').doc();
      batch.set(notificationRef, {
        notificationId: notificationRef.id,
        userId: userDoc.id,
        title: title,
        message: message,
        type: type || 'announcement',
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    });

    await batch.commit();

    // Send FCM push via topic
    const payload = {
      notification: {
        title: title,
        body: message,
      },
      data: {
        type: type || 'announcement',
      },
      topic: 'all_users',
    };

    await admin.messaging().send(payload);
    console.log(`Notification sent to all users: ${title}`);
  } catch (error) {
    console.error('Error sending to all users:', error);
  }
}

// =====================================================
// RazorpayX Payout Processing
// =====================================================

/**
 * Process a withdrawal payout via RazorpayX
 * Called by the Firestore trigger and the callable function
 */
async function processRazorpayPayout(withdrawalId, withdrawalData) {
  const { userId, amount, method, accountDetails } = withdrawalData;

  if (!razorpay) {
    // Razorpay not configured - mark as failed with instructions
    await db.collection('withdrawals').doc(withdrawalId).update({
      status: 'failed',
      adminRemarks: 'RazorpayX not configured. Admin needs to manually process this payout.',
      processedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    return { success: false, error: 'Razorpay not configured' };
  }

  try {
    // Get user details
    const userDoc = await db.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      throw new Error('User not found');
    }
    const userData = userDoc.data();
    const userName = userData.fullName || 'User';
    const userEmail = userData.email || '';
    const userPhone = userData.phone || '';

    // Check if user already has a Razorpay contact ID stored
    let contactId = userData.razorpayContactId;

    // Create contact if not exists
    if (!contactId) {
      const contact = await razorpay.contacts.create({
        name: userName,
        email: userEmail,
        contact: userPhone.replace(/\D/g, '').slice(0, 10),
        type: 'customer',
        reference_id: userId,
      });
      contactId = contact.id;
      // Store contact ID for future use
      await db.collection('users').doc(userId).update({
        razorpayContactId: contactId,
      });
    }

    // Create fund account based on withdrawal method
    let fundAccountId;

    if (method === 'upi') {
      // UPI fund account
      const fundAccount = await razorpay.fundAccount.create({
        contact_id: contactId,
        account_type: 'vpa',
        vpa: {
          address: accountDetails.trim(),
        },
      });
      fundAccountId = fundAccount.id;
    } else if (method === 'paytm' || method === 'bankTransfer') {
      // For bank transfer, we need account number and IFSC
      // Parse from accountDetails field
      const lines = accountDetails.split('\n').map(l => l.trim());
      const parts = accountDetails.split(/[,|\n]/).map(p => p.trim());

      // Expect format: "Account Number, IFSC, Name" or similar
      const bankAccount = {
        name: parts.length >= 3 ? parts[2] : userName,
        ifsc: parts.length >= 2 ? parts[1] : '',
        account_number: parts.length >= 1 ? parts[0].replace(/\D/g, '') : '',
      };

      if (!bankAccount.ifsc || !bankAccount.account_number) {
        throw new Error('Incomplete bank details. Required: Account Number, IFSC Code');
      }

      const fundAccount = await razorpay.fundAccount.create({
        contact_id: contactId,
        account_type: 'bank_account',
        bank_account: bankAccount,
      });
      fundAccountId = fundAccount.id;
    } else {
      throw new Error(`Unsupported withdrawal method: ${method}`);
    }

    // Create the payout
    const payoutMode = method === 'upi' ? 'UPI' : 'IMPS';
    const amountInPaise = Math.round(amount * 100);

    const payout = await razorpay.payouts.create({
      account_number: razorpayAccountNumber,
      fund_account_id: fundAccountId,
      amount: amountInPaise,
      currency: 'INR',
      mode: payoutMode,
      purpose: 'payout',
      queue_if_low_balance: true,
      reference_id: withdrawalId,
      notes: {
        userId: userId,
        method: method,
      },
    });

    // Update withdrawal as paid
    await db.collection('withdrawals').doc(withdrawalId).update({
      status: 'paid',
      razorpayPayoutId: payout.id,
      razorpayStatus: payout.status,
      adminRemarks: 'Auto-processed via RazorpayX',
      processedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Deduct from wallet
    const walletRef = db.collection('wallets').doc(userId);
    await walletRef.update({
      walletBalance: admin.firestore.FieldValue.increment(-amount),
      totalWithdrawn: admin.firestore.FieldValue.increment(amount),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Create transaction record
    const transactionRef = db.collection('transactions').doc();
    await transactionRef.set({
      transactionId: transactionRef.id,
      userId: userId,
      type: 'debit',
      amount: amount,
      source: 'withdrawal',
      status: 'completed',
      description: `Withdrawal of ₹${amount.toFixed(2)} via ${method} (RazorpayX auto-payout)`,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(`Payout processed successfully: ${withdrawalId}, payout ID: ${payout.id}`);
    return { success: true, payoutId: payout.id };

  } catch (error) {
    console.error(`Razorpay payout failed for ${withdrawalId}:`, error);

    // Update withdrawal with failure
    await db.collection('withdrawals').doc(withdrawalId).update({
      status: 'failed',
      adminRemarks: `Auto-payout failed: ${error.message}`,
      processedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { success: false, error: error.message };
  }
}

// =====================================================
// Callable: Process a withdrawal payout
// =====================================================

/**
 * Admin callable function to manually trigger a payout for a withdrawal
 */
exports.processWithdrawalPayout = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be logged in');
  }

  // Verify admin
  const adminDoc = await db.collection('admins').doc(context.auth.uid).get();
  if (!adminDoc.exists) {
    throw new functions.https.HttpsError('permission-denied', 'Only admins can process payouts');
  }

  const { withdrawalId } = data;
  if (!withdrawalId) {
    throw new functions.https.HttpsError('invalid-argument', 'withdrawalId is required');
  }

  // Get withdrawal
  const withdrawalDoc = await db.collection('withdrawals').doc(withdrawalId).get();
  if (!withdrawalDoc.exists) {
    throw new functions.https.HttpsError('not-found', 'Withdrawal not found');
  }

  const withdrawal = withdrawalDoc.data();
  if (withdrawal.status !== 'pending') {
    throw new functions.https.HttpsError('failed-precondition', 'Withdrawal is not in pending status');
  }

  // Process the payout
  const result = await processRazorpayPayout(withdrawalId, withdrawal);

  // Log admin action
  await db.collection('admin_logs').add({
    adminUid: context.auth.uid,
    action: 'process_payout',
    targetType: 'withdrawal',
    targetId: withdrawalId,
    details: `Processed payout: ${result.success ? 'Success' : 'Failed - ' + result.error}`,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return result;
});

/**
 * Firestore trigger: Auto-process pending withdrawals via RazorpayX
 * Fires when a withdrawal document is created with status 'pending'
 */
exports.onWithdrawalCreated = functions.firestore
  .document('withdrawals/{withdrawalId}')
  .onCreate(async (snap, context) => {
    const withdrawal = snap.data();

    // Only auto-process if status is pending
    if (withdrawal.status !== 'pending') return;

    console.log(`Auto-processing withdrawal ${context.params.withdrawalId}`);

    // Add a small delay to ensure Firestore consistency
    await new Promise(resolve => setTimeout(resolve, 1000));

    await processRazorpayPayout(context.params.withdrawalId, withdrawal);
  });

// =====================================================
// Trigger Functions
// =====================================================

/**
 * Send notification when a withdrawal is approved/rejected/paid
 */
exports.onWithdrawalUpdated = functions.firestore
  .document('withdrawals/{withdrawalId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    // Only send if status changed
    if (before.status === after.status) return;

    const userId = after.userId;
    const amount = after.amount;

    if (after.status === 'paid') {
      await sendToUser(
        userId,
        'Withdrawal Paid ✅',
        `Your withdrawal of ₹${amount.toFixed(2)} has been paid!`,
        'withdrawal'
      );
    } else if (after.status === 'approved') {
      await sendToUser(
        userId,
        'Withdrawal Approved ✅',
        `Your withdrawal of ₹${amount.toFixed(2)} has been approved.`,
        'withdrawal'
      );
    } else if (after.status === 'rejected') {
      const remarks = after.adminRemarks || 'No reason provided';
      await sendToUser(
        userId,
        'Withdrawal Rejected ❌',
        `Your withdrawal of ₹${amount.toFixed(2)} was rejected. Reason: ${remarks}`,
        'withdrawal'
      );
    }
  });

/**
 * Auto-send notification on reward claim
 */
exports.onRewardClaimed = functions.firestore
  .document('rewards/{rewardId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    if (data.status !== 'claimed') return;

    const userId = data.userId;
    const amount = data.rewardAmount;
    const rewardType = data.rewardType || 'reward';

    const titles = {
      adReward: 'Ad Reward Earned 🎉',
      dailyCheckIn: 'Daily Check-In Bonus ✅',
      streakBonus: 'Streak Bonus 🔥',
      taskReward: 'Task Completed! 🏆',
      bonus: 'Bonus Reward 🎁',
    };

    const messages = {
      adReward: `You earned $${amount.toFixed(2)} from watching an ad!`,
      dailyCheckIn: `You earned $${amount.toFixed(2)} from your daily check-in!`,
      streakBonus: `Amazing! You earned a $${amount.toFixed(2)} streak bonus!`,
      taskReward: `Great job! You earned $${amount.toFixed(2)} for completing a task!`,
      bonus: `You received a $${amount.toFixed(2)} bonus!`,
    };

    await sendToUser(
      userId,
      titles[rewardType] || 'Reward Earned 🎉',
      messages[rewardType] || `You earned $${amount.toFixed(2)}!`,
      'reward'
    );
  });

/**
 * Auto-send notification on new referral
 */
exports.onNewReferral = functions.firestore
  .document('referrals/{referralId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    const referrerId = data.referrerUserId;
    const referredId = data.referredUserId;
    const amount = data.rewardAmount || 0;

    await sendToUser(
      referrerId,
      'New Referral! 🎉',
      `Someone joined using your referral code! You earned $${amount.toFixed(2)}.`,
      'referral'
    );

    await sendToUser(
      referredId,
      'Welcome to Fun Pay! 🚀',
      `You received a welcome bonus of $${amount.toFixed(2)}. Start earning more rewards!`,
      'referral'
    );
  });

// =====================================================
// Callable Functions (called from the app)
// =====================================================

/**
 * Send announcement to all users (admin callable)
 */
exports.sendAnnouncement = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'You must be logged in to send announcements'
    );
  }

  // Verify admin
  const adminDoc = await db.collection('admins').doc(context.auth.uid).get();
  if (!adminDoc.exists) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Only admins can send announcements'
    );
  }

  const { title, message } = data;
  if (!title || !message) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Title and message are required'
    );
  }

  await sendToAllUsers(title, message, 'announcement');

  // Log admin action
  await db.collection('admin_logs').add({
    adminUid: context.auth.uid,
    action: 'send_announcement',
    targetType: 'all_users',
    details: `Sent announcement: ${title}`,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { success: true };
});

/**
 * Send notification to a specific user (admin callable)
 */
exports.sendNotificationToUser = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be logged in');
  }

  const adminDoc = await db.collection('admins').doc(context.auth.uid).get();
  if (!adminDoc.exists) {
    throw new functions.https.HttpsError('permission-denied', 'Admins only');
  }

  const { userId, title, message, type } = data;
  if (!userId || !title || !message) {
    throw new functions.https.HttpsError('invalid-argument', 'userId, title, and message required');
  }

  await sendToUser(userId, title, message, type || 'announcement');

  await db.collection('admin_logs').add({
    adminUid: context.auth.uid,
    action: 'send_notification',
    targetType: 'user',
    targetId: userId,
    details: `Sent notification: ${title}`,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { success: true };
});

// =====================================================
// Fraud Detection Functions
// =====================================================

/**
 * Auto-detect self-referral and duplicate device fraud on new referral
 */
exports.detectReferralFraud = functions.firestore
  .document('referrals/{referralId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    const referrerId = data.referrerUserId;
    const referredUserId = data.referredUserId;

    // Check self-referral
    if (referrerId === referredUserId) {
      const reportRef = db.collection('fraud_reports').doc();
      await reportRef.set({
        reportId: reportRef.id,
        userId: referrerId,
        reason: 'Self-referral detected',
        riskLevel: 'high',
        fraudScore: 80,
        status: 'underReview',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        detectedBy: 'system',
      });
      console.log(`Self-referral detected for user ${referrerId}`);

      // Flag the referral
      await snap.ref.update({ flagged: true, flagReason: 'self_referral' });
    }

    // Check for duplicate referral abuse (same referred user)
    const existingRefs = await db.collection('referrals')
      .where('referredUserId', '==', referredUserId)
      .get();

    if (existingRefs.size > 1) {
      const reportRef = db.collection('fraud_reports').doc();
      await reportRef.set({
        reportId: reportRef.id,
        userId: referrerId,
        reason: 'Duplicate referral - referred user already exists in system',
        riskLevel: 'medium',
        fraudScore: 50,
        status: 'underReview',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        detectedBy: 'system',
      });
      console.log(`Duplicate referral detected for referrer ${referrerId}`);
    }
  });

/**
 * Auto-detect rapid reward claiming abuse
 */
exports.detectRewardAbuse = functions.firestore
  .document('rewards/{rewardId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    const userId = data.userId;
    const rewardType = data.rewardType || 'unknown';

    // Check for rapid claims by same user in last 5 minutes
    const fiveMinAgo = new Date(Date.now() - 5 * 60 * 1000);
    const recentRewards = await db.collection('rewards')
      .where('userId', '==', userId)
      .where('createdAt', '>=', fiveMinAgo)
      .get();

    // If more than 10 rewards in 5 minutes, flag it
    if (recentRewards.size > 10) {
      const reportRef = db.collection('fraud_reports').doc();
      await reportRef.set({
        reportId: reportRef.id,
        userId: userId,
        reason: `Rapid reward claiming: ${recentRewards.size} claims in 5 minutes`,
        riskLevel: 'medium',
        fraudScore: 40 + (recentRewards.size - 10) * 5,
        status: 'underReview',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        detectedBy: 'system',
      });
      console.log(`Rapid reward abuse detected for user ${userId}`);
    }
  });

/**
 * Auto-flag users with repeated failed login attempts
 */
exports.detectSuspiciousLogins = functions.firestore
  .document('login_attempts/{attemptId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    if (data.success) return; // Only flag failed attempts

    const userId = data.userId;

    // Count recent failed attempts for this user
    const fifteenMinAgo = new Date(Date.now() - 15 * 60 * 1000);
    const recentAttempts = await db.collection('login_attempts')
      .where('userId', '==', userId)
      .where('createdAt', '>=', fifteenMinAgo)
      .get();

    const failedAttempts = recentAttempts.docs.filter(d => !d.data().success);

    if (failedAttempts.length >= 5) {
      // Flag the user for suspicious activity
      // Check if already flagged
      const existingReports = await db.collection('fraud_reports')
        .where('userId', '==', userId)
        .where('reason', '>=', 'Suspicious login')
        .where('reason', '<=', 'Suspicious login\uf8ff')
        .where('status', '==', 'underReview')
        .get();

      if (existingReports.empty) {
        const reportRef = db.collection('fraud_reports').doc();
        await reportRef.set({
          reportId: reportRef.id,
          userId: userId,
          reason: 'Suspicious login activity - multiple failed attempts',
          riskLevel: 'medium',
          fraudScore: 35,
          status: 'underReview',
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          detectedBy: 'system',
        });
        console.log(`Suspicious login activity detected for user ${userId}`);
      }

      // Create notification for security alert
      const notifRef = db.collection('notifications').doc();
      await notifRef.set({
        notificationId: notifRef.id,
        userId: userId,
        title: 'Security Alert ⚠️',
        message: 'We detected multiple failed login attempts on your account. If this wasn\'t you, please secure your account immediately.',
        type: 'security',
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  });

/**
 * On new user signup, check for duplicate device registration
 */
exports.detectDuplicateDevice = functions.firestore
  .document('device_registry/{deviceId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    const userId = data.userId;
    const deviceId = context.params.deviceId;

    // Check if this device was previously registered
    const prevRegistrations = await db.collection('device_registry')
      .where(admin.firestore.FieldPath.documentId(), '==', deviceId)
      .get();

    if (prevRegistrations.size > 0) {
      prevRegistrations.forEach(async (doc) => {
        const existingUserId = doc.data().userId;
        if (existingUserId !== userId) {
          // Multiple accounts on same device - potential fraud
          const reportRef = db.collection('fraud_reports').doc();
          await reportRef.set({
            reportId: reportRef.id,
            userId: userId,
            reason: `Multiple accounts on same device. Existing user: ${existingUserId}`,
            riskLevel: 'medium',
            fraudScore: 45,
            status: 'underReview',
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            detectedBy: 'system',
          });
          console.log(`Duplicate device detected: ${deviceId} used by ${existingUserId} and ${userId}`);
        }
      });
    }
  });

/**
 * Admin callable: get fraud dashboard summary
 */
exports.getFraudSummary = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be logged in');
  }

  const adminDoc = await db.collection('admins').doc(context.auth.uid).get();
  if (!adminDoc.exists) {
    throw new functions.https.HttpsError('permission-denied', 'Admins only');
  }

  const reportsSnapshot = await db.collection('fraud_reports').get();
  const total = reportsSnapshot.size;
  const highRisk = reportsSnapshot.docs.filter(d => d.data().riskLevel === 'high').length;
  const mediumRisk = reportsSnapshot.docs.filter(d => d.data().riskLevel === 'medium').length;
  const pendingReview = reportsSnapshot.docs.filter(d => d.data().status === 'underReview').length;
  const confirmed = reportsSnapshot.docs.filter(d => d.data().status === 'confirmed').length;

  // Flagged users count (unique)
  const flaggedUserIds = new Set();
  reportsSnapshot.docs.forEach(doc => {
    if (doc.data().status === 'underReview' || doc.data().status === 'confirmed') {
      flaggedUserIds.add(doc.data().userId);
    }
  });

  return {
    totalReports: total,
    highRiskReports: highRisk,
    mediumRiskReports: mediumRisk,
    lowRiskReports: total - highRisk - mediumRisk,
    pendingReview: pendingReview,
    confirmed: confirmed,
    flaggedUsers: flaggedUserIds.size,
  };
});
