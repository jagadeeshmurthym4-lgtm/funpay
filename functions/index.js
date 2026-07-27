const functions = require('firebase-functions');
const admin = require('firebase-admin');
const nodemailer = require('nodemailer');

admin.initializeApp();

const db = admin.firestore();

// ─────────────────────────────────────────────────────────
// Email Transporter (lazy initialised)
// Uses Firebase Functions config: `firebase functions:config:set app.admin_email="..." smtp.host="..." smtp.port="587" smtp.user="..." smtp.pass="..."`
// ─────────────────────────────────────────────────────────
let _transporter = null;

async function getTransporter() {
  if (_transporter) return _transporter;

  const config = functions.config();

  // Try Firebase Config first, then Firestore doc, then fallback defaults
  let smtpConfig = {
    host: config.smtp?.host || 'smtp.gmail.com',
    port: parseInt(config.smtp?.port || '587', 10),
    secure: config.smtp?.secure === 'true',
    auth: {
      user: config.smtp?.user,
      pass: config.smtp?.pass,
    },
  };

  // If no SMTP credentials in config, try reading from Firestore config doc
  if (!smtpConfig.auth.user || !smtpConfig.auth.pass) {
    try {
      const configDoc = await db.collection('admin_config').doc('email').get();
      if (configDoc.exists) {
        const data = configDoc.data();
        smtpConfig.host = data.smtpHost || smtpConfig.host;
        smtpConfig.port = parseInt(data.smtpPort || smtpConfig.port, 10);
        smtpConfig.secure = data.smtpSecure === true;
        smtpConfig.auth.user = data.smtpUser || smtpConfig.auth.user;
        smtpConfig.auth.pass = data.smtpPass || smtpConfig.auth.pass;
      }
    } catch (e) {
      console.warn('Failed to read email config from Firestore:', e.message);
    }
  }

  if (!smtpConfig.auth.user || !smtpConfig.auth.pass) {
    throw new Error('SMTP credentials not configured. Run: firebase functions:config:set smtp.user="..." smtp.pass="..."');
  }

  _transporter = nodemailer.createTransport(smtpConfig);
  return _transporter;
}

function getAdminEmail() {
  const config = functions.config();
  return config.app?.admin_email || 'admin@cashspark.app';
}

/**
 * Formats the ticket info into a plain-text email body.
 */
function formatTicketEmail(ticket) {
  return `
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  NEW SUPPORT TICKET
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Ticket ID:    ${ticket.ticketId}
  User ID:      ${ticket.userId}
  Category:     ${ticket.category || 'Not specified'}
  Subject:      ${ticket.subject || 'No subject'}
  Submitted:    ${ticket.createdAt ? new Date(ticket.createdAt.toMillis()).toLocaleString() : 'Just now'}

────────────────────────────────────────

MESSAGE:
───
${ticket.message || 'No message'}
───

${ticket.deviceInfo ? `Device Info: ${ticket.deviceInfo}\n` : ''}${ticket.screenshotUrl ? `Screenshot: ${ticket.screenshotUrl}\n` : ''}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
`;
}

// =====================================================
// Referral Reward Processing
// =====================================================

/**
 * Auto-process referral rewards when a project participation is approved
 * and the reward is credited to the referred user.
 *
 * Rules:
 *   1. If referred user's FIRST approved project → ₹7 to referrer (one-time).
 *   2. Subsequent approved projects → 5% commission on the project reward.
 *   3. Only from approved project earnings (excludes check-in, spin, etc.).
 *   4. No referral reward for Pending, Under Review, Rejected, Cancelled, Failed.
 *   5. Duplicate prevention via participation ID tracking + atomic guard flag.
 *
 * Atomicity: All writes (wallet + referral doc + participation guard flag)
 * happen inside a Firestore transaction to prevent double-crediting on retry.
 */
exports.onParticipationRewardCredited = functions.firestore
  .document('project_participations/{participationId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    // ── Guard 1: Only when rewardCredited transitions false → true ──
    if (before.rewardCredited === true || after.rewardCredited !== true) {
      return null;
    }

    // ── Guard 2: Skip if this participation was already processed ──
    // This prevents double-credit if the function retries after a crash.
    if (after.referralProcessed === true) {
      console.log(`ReferralReward: participation ${context.params.participationId} already processed, skipping.`);
      return null;
    }

    // Only process valid participations with a reward
    const rewardAmount = after.rewardAmount;
    if (!rewardAmount || rewardAmount <= 0) return null;

    const userId = after.userId;
    const projectId = after.projectId;
    const participationId = context.params.participationId;
    const participationRef = change.after.ref;

    console.log(`ReferralReward: Processing reward for participation ${participationId}, user ${userId}, amount ₹${rewardAmount}, project ${projectId}`);

    try {
      // 1. Check if this user was referred by someone
      const referralsSnapshot = await db.collection('referrals')
        .where('referredUserId', '==', userId)
        .limit(1)
        .get();

      if (referralsSnapshot.empty) {
        // No referral relationship — nothing to reward
        // Stamp the guard flag so future triggers on this doc also skip
        await participationRef.update({ referralProcessed: true });
        console.log(`ReferralReward: User ${userId} was not referred — no referral reward needed.`);
        return null;
      }

      const referralDoc = referralsSnapshot.docs[0];
      const referralData = referralDoc.data();
      const referralId = referralDoc.id;
      const referrerId = referralData.referrerUserId;

      // 2. Prevent duplicate rewards for the same project
      const rewardedProjectIds = referralData.rewardedProjectIds || [];
      if (rewardedProjectIds.includes(participationId)) {
        await participationRef.update({ referralProcessed: true });
        console.log(`ReferralReward: Participation ${participationId} already rewarded for referral ${referralId} — skipping.`);
        return null;
      }

      // 3. Determine reward amount
      let referralRewardAmount = 0;
      const isFirstProject = !referralData.firstProjectRewarded;

      if (isFirstProject) {
        // FIRST approved project → ₹7 one-time bonus
        referralRewardAmount = 7.0;
        console.log(`ReferralReward: FIRST approved project! Crediting ₹${referralRewardAmount} to referrer ${referrerId}.`);
      } else {
        // Subsequent approved project → 5% commission
        referralRewardAmount = rewardAmount * 0.05;
        referralRewardAmount = Math.round(referralRewardAmount * 100) / 100;
        console.log(`ReferralReward: Subsequent project. 5% of ₹${rewardAmount} = ₹${referralRewardAmount} to referrer ${referrerId}.`);
      }

      if (referralRewardAmount <= 0) {
        await participationRef.update({ referralProcessed: true });
        return null;
      }

      // ── 4. Atomically credit wallet + update referral + stamp guard flag ──
      const transactionRef = db.collection('transactions').doc();
      const notificationRef = db.collection('notifications').doc();
      const walletRef = db.collection('wallets').doc(referrerId);

      const description = isFirstProject
        ? `Referral reward: ₹7 first project bonus for referred user's approved project`
        : `Referral commission: 5% of ₹${rewardAmount.toFixed(2)} from referred user's approved project`;

      const notifTitle = isFirstProject
        ? '🎉 First Project Bonus Earned!'
        : '💰 Referral Commission Earned!';
      const notifMessage = isFirstProject
        ? `Your referred user completed their first project! You earned ₹${referralRewardAmount.toFixed(2)} as a first project bonus.`
        : `Your referred user completed a project! You earned ₹${referralRewardAmount.toFixed(2)} (5% commission).`;

      const currentRewardAmount = referralData.rewardAmount || 0;
      const currentCommission = referralData.lifetimeProjectCommission || 0;
      const currentProjectCount = referralData.approvedProjectCount || 0;

      const referralUpdates = {
        rewardAmount: currentRewardAmount + referralRewardAmount,
        approvedProjectCount: currentProjectCount + 1,
        rewardedProjectIds: admin.firestore.FieldValue.arrayUnion([participationId]),
        lifetimeProjectCommission: isFirstProject
          ? currentCommission
          : currentCommission + referralRewardAmount,
      };

      if (isFirstProject) {
        referralUpdates.firstProjectRewarded = true;
        referralUpdates.firstProjectId = projectId;
        referralUpdates.firstProjectRewardDate = admin.firestore.FieldValue.serverTimestamp();
      }

      await db.runTransaction(async (transaction) => {
        // 4a. Update/credit wallet
        const walletSnap = await transaction.get(walletRef);
        if (!walletSnap.exists) {
          transaction.set(walletRef, {
            userId: referrerId,
            walletBalance: referralRewardAmount,
            totalEarnings: referralRewardAmount,
            totalWithdrawn: 0,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        } else {
          transaction.update(walletRef, {
            walletBalance: admin.firestore.FieldValue.increment(referralRewardAmount),
            totalEarnings: admin.firestore.FieldValue.increment(referralRewardAmount),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        }

        // 4b. Stamp the participation guard flag (prevents double-credit on retry)
        transaction.update(participationRef, { referralProcessed: true });

        // 4c. Update referral document
        transaction.update(referralDoc.ref, referralUpdates);
      });

      // 5. Create transaction record and notification (outside transaction for simplicity)
      await transactionRef.set({
        transactionId: transactionRef.id,
        userId: referrerId,
        type: 'credit',
        amount: referralRewardAmount,
        source: 'referral',
        status: 'completed',
        description: description,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      await notificationRef.set({
        notificationId: notificationRef.id,
        userId: referrerId,
        title: notifTitle,
        message: notifMessage,
        type: 'referral',
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(`ReferralReward: Successfully processed referral reward for ${referralId}: ₹${referralRewardAmount}`);
      return { success: true };
    } catch (error) {
      console.error(`ReferralReward: Error processing referral reward:`, error);
      // Note: If the transaction partially committed and failed after, the guard flag
      // may not be set. On retry, the function will see rewardCredited=true and
      // referralProcessed is still false, so it will attempt again. The transaction
      // is idempotent because the wallet + guard flag + referral update are atomic.
      return null;
    }
  });

// =====================================================
// Referral Sign-up Bonus (Immediate ₹10 to Referrer)
// =====================================================

/**
 * When a referral document is created (new user signed up with a referral code),
 * credit ₹10 to the referrer's wallet as an immediate sign-up bonus.
 *
 * The referred user's ₹4 bonus is handled client-side (they own their wallet).
 * The referrer's ₹10 bonus requires Admin SDK access, so it runs here.
 */
exports.onReferralCreated = functions.firestore
  .document('referrals/{referralId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    const referrerId = data.referrerUserId;
    const referredUserId = data.referredUserId;
    const referralCode = data.referralCode;
    const referralId = context.params.referralId;

    console.log(`ReferralCreated: Processing ₹10 sign-up bonus for referrer ${referrerId}, referred user ${referredUserId}, code ${referralCode}`);

    try {
      const referrerWalletRef = db.collection('wallets').doc(referrerId);
      const transactionRef = db.collection('transactions').doc();
      const notificationRef = db.collection('notifications').doc();
      const referralRef = snap.ref;

      // Atomically check guard, credit wallet, stamp referral doc
      await db.runTransaction(async (transaction) => {
        // ── Guard: Skip if signup bonus already processed ──
        const referralSnap = await transaction.get(referralRef);
        if (referralSnap.data()?.signupBonusCredited === true) {
          console.log(`ReferralCreated: Referral ${referralId} sign-up bonus already processed, skipping.`);
          return;
        }

        // Credit referrer's wallet
        const walletSnap = await transaction.get(referrerWalletRef);
        if (!walletSnap.exists) {
          transaction.set(referrerWalletRef, {
            userId: referrerId,
            walletBalance: 10.0,
            totalEarnings: 10.0,
            totalWithdrawn: 0,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        } else {
          transaction.update(referrerWalletRef, {
            walletBalance: admin.firestore.FieldValue.increment(10.0),
            totalEarnings: admin.firestore.FieldValue.increment(10.0),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        }

        // Stamp guard flag on referral doc (atomic with wallet credit)
        transaction.update(referralRef, { signupBonusCredited: true });
      });

      // Create transaction record and notification (outside transaction)
      await transactionRef.set({
        transactionId: transactionRef.id,
        userId: referrerId,
        type: 'credit',
        amount: 10.0,
        source: 'referral',
        status: 'completed',
        description: 'Referral sign-up bonus: ₹10 for referring a new user!',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      await notificationRef.set({
        notificationId: notificationRef.id,
        userId: referrerId,
        title: '🎉 Referral Bonus Earned!',
        message: `You earned ₹10 for referring a new user! They used your code "${referralCode}". Keep sharing!`,
        type: 'referral',
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(`ReferralCreated: Successfully credited ₹10 to referrer ${referrerId}`);
      return { success: true };
    } catch (error) {
      console.error(`ReferralCreated: Error crediting referrer ${referrerId}:`, error);
      return null;
    }
  });

// =====================================================
// Support Ticket Email Notification
// =====================================================

/**
 * When a new support ticket is created, send an email notification
 * to the configured admin email address via SMTP.
 *
 * SMTP credentials are read from:
 *   1. Firebase Config (`firebase functions:config:set smtp.user="..." smtp.pass="..."`)
 *   2. Firestore doc `admin_config/email`
 *
 * Admin email is read from:
 *   1. Firebase Config (`firebase functions:config:set app.admin_email="..."`)
 *   2. Default: `admin@cashspark.app`
 */
exports.onTicketCreated = functions.firestore
  .document('support_tickets/{ticketId}')
  .onCreate(async (snap, context) => {
    const ticket = snap.data();
    const ticketId = context.params.ticketId;

    console.log(`TicketCreated: New ticket ${ticketId} from user ${ticket.userId}`);

    try {
      const adminEmail = getAdminEmail();
      const transporter = await getTransporter();
      const emailBody = formatTicketEmail(ticket);

      // Look up the user's email so the admin can reply directly
      let userEmail = null;
      try {
        const userDoc = await db.collection('users').doc(ticket.userId).get();
        if (userDoc.exists) {
          userEmail = userDoc.data().email;
        }
      } catch (e) {
        console.warn(`TicketCreated: Could not fetch user email for ${ticket.userId}: ${e.message}`);
      }

      const mailOptions = {
        from: `"CashSpark Support" <${functions.config().smtp?.user || 'noreply@cashspark.app'}>`,
        to: adminEmail,
        replyTo: userEmail || adminEmail,
        subject: `[Support] ${ticket.subject || 'New Ticket'} - ${ticket.ticketId}`,
        text: emailBody,
      };

      const info = await transporter.sendMail(mailOptions);
      console.log(`TicketCreated: Email sent for ticket ${ticketId}: ${info.messageId}`);

      // Stamp the ticket doc so we know the email was sent
      await snap.ref.update({
        adminNotifiedAt: admin.firestore.FieldValue.serverTimestamp(),
        adminNotified: true,
      });

      return { success: true };
    } catch (error) {
      console.error(`TicketCreated: Failed to send email for ticket ${ticketId}:`, error);

      // Mark the failure on the ticket so it can be retried later
      try {
        await snap.ref.update({
          adminNotifiedError: error.message,
          adminNotifiedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      } catch (updateError) {
        console.error(`TicketCreated: Failed to update ticket ${ticketId}:`, updateError);
      }

      return null;
    }
  });

/**
 * HTTPS Callable Function: Send an FCM push notification to the all_users topic.
 *
 * Called from the Flutter app after in-app notifications have been created.
 * This function does NOT create in-app notifications — only sends the FCM push.
 *
 * Required params: { title, message, type }
 * Requires: Authenticated admin user
 */
exports.sendBroadcastPush = functions.https.onCall(async (data, context) => {
  // Require authentication
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'You must be logged in to send push notifications'
    );
  }

  // Verify admin status
  const adminDoc = await db.collection('admins').doc(context.auth.uid).get();
  if (!adminDoc.exists) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Only admins can send broadcast push notifications'
    );
  }

  const { title, message, type } = data;

  if (!title || !message) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Both title and message are required'
    );
  }

  try {
    const payload = {
      notification: {
        title: title,
        body: message,
      },
      data: {
        type: type || 'announcement',
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
      topic: 'all_users',
    };

    await admin.messaging().send(payload);
    console.log(`FCM push sent to all_users topic: "${title}"`);

    return { success: true };
  } catch (error) {
    console.error('Error sending FCM push:', error);
    throw new functions.https.HttpsError(
      'internal',
      `Failed to send push notification: ${error.message}`
    );
  }
});

/**
 * HTTPS Callable Function: Send an FCM push notification to a specific user's topic.
 *
 * The Flutter app subscribes each user to `user_{userId}` upon sign-in.
 * This function sends a push notification to that topic for targeted delivery.
 *
 * Required params: { userId, title, message, type }
 * Requires: Authenticated user (only sends to the caller's own topic for security)
 */
exports.sendTargetedPush = functions.https.onCall(async (data, context) => {
  // Require authentication
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'You must be logged in to send push notifications'
    );
  }

  const { userId, title, message, type } = data;

  // Security: only allow sending to the caller's own topic
  if (userId !== context.auth.uid) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'You can only send push notifications to yourself'
    );
  }

  if (!title || !message) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Both title and message are required'
    );
  }

  try {
    const payload = {
      notification: {
        title: title,
        body: message,
      },
      data: {
        type: type || 'reward',
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
      topic: `user_${userId}`,
    };

    await admin.messaging().send(payload);
    console.log(`FCM push sent to user_${userId} topic: "${title}"`);

    return { success: true };
  } catch (error) {
    console.error('Error sending targeted FCM push:', error);
    throw new functions.https.HttpsError(
      'internal',
      `Failed to send push notification: ${error.message}`
    );
  }
});
