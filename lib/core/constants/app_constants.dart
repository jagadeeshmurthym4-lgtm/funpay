

import 'package:flutter/foundation.dart';

class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'Fun Pay';
  static const String appVersion = '1.0.0';

  // Collection Names
  static const String usersCollection = 'users';
  static const String walletsCollection = 'wallets';
  static const String transactionsCollection = 'transactions';
  static const String withdrawalsCollection = 'withdrawals';
  static const String referralsCollection = 'referrals';
  static const String referralRewardsCollection = 'referral_rewards';
  static const String adminsCollection = 'admins';
  static const String rewardsCollection = 'rewards';
  static const String rewardsConfigCollection = 'rewards_config';
  static const String tasksCollection = 'tasks';
  static const String dailyCheckInsCollection = 'daily_checkins';
  static const String streaksCollection = 'streaks';
  static const String adminLogsCollection = 'admin_logs';
  static const String appSettingsCollection = 'app_settings';
  static const String agreementsCollection = 'agreements';
  static const String notificationsCollection = 'notifications';
  static const String fraudReportsCollection = 'fraud_reports';
  static const String deviceRegistryCollection = 'device_registry';
  static const String loginAttemptsCollection = 'login_attempts';
  static const String bannersCollection = 'banners';
  static const String adConfigCollection = 'ad_config';
  static const String verificationRequestsCollection = 'verification_requests';
  static const String offersCollection = 'offers';
  static const String projectsCollection = 'projects';
  static const String affiliateProjectsCollection = 'affiliate_projects';
  static const String projectParticipationsCollection = 'project_participations';
  static const String spinDataCollection = 'spin_data';
  static const String customTasksCollection = 'custom_tasks';
  static const String taskSubmissionsCollection = 'task_submissions';
  static const String scratchCardsCollection = 'scratch_cards';
  static const String couponsCollection = 'coupons';
  static const String weeklyBonusesCollection = 'weekly_bonuses';
  static const String monthlyBonusesCollection = 'monthly_bonuses';

  // ─── New: Referral Levels & Streak Multiplier ────────────
  static const String referralLevelsConfigCollection = 'referral_levels_config';
  static const String claimedMilestonesCollection = 'claimed_milestones';
  static const String streakMultiplierConfigCollection = 'streak_multiplier_config';

  // ─── CPX Research Offer Wall ────────────────────────────────
  /// Server-written survey reward records (by the cpxPostback function).
  static const String cpxTransactionsCollection = 'cpx_transactions';

  /// Config doc id inside the `app_settings` collection (readable by
  /// authenticated users, writable by admins). Only NON-secret values live
  /// here (appId, appSecureHash for the entry link, enabled). The postback
  /// verification secret lives in Firebase Functions config only.
  static const String cpxSettingsDocId = 'cpx';

  /// CPX Research publisher App ID (from publisher.cpx-research.com dashboard).
  /// Overridable via the `admin_config/cpx` doc's `appId` field.
  static const String cpxAppId = '35037';

  /// CPX Research offer wall base URL (iframe/API integration docs).
  static const String cpxOfferWallBaseUrl = 'https://offers.cpx-research.com/index.php';

  // Document Fields
  static const String fieldUid = 'uid';
  static const String fieldFullName = 'fullName';
  static const String fieldEmail = 'email';
  static const String fieldPhone = 'phone';
  static const String fieldReferralCode = 'referralCode';
  static const String fieldCreatedAt = 'createdAt';
  static const String fieldWalletBalance = 'walletBalance';
  static const String fieldTotalEarnings = 'totalEarnings';
  static const String fieldTotalWithdrawn = 'totalWithdrawn';
  static const String fieldUpdatedAt = 'updatedAt';
  static const String fieldUserId = 'userId';
  static const String fieldTransactionId = 'transactionId';
  static const String fieldType = 'type';
  static const String fieldAmount = 'amount';
  static const String fieldSource = 'source';
  static const String fieldStatus = 'status';
  static const String fieldDescription = 'description';

  static const String ticketsCollection = 'support_tickets';
  static const String chatMessagesCollection = 'support_chat_messages';
  static const String faqsCollection = 'faqs';

  // Validation
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;
  static const int minNameLength = 2;
  static const int maxNameLength = 50;
  static const int phoneLength = 10;
  static const int referralCodeLength = 8;

  // Cache Keys
  static const String authStateKey = 'auth_state';
  static const String userDataKey = 'user_data';
  static const String themeModeKey = 'theme_mode';

  // Timeouts
  static const Duration splashDuration = Duration(seconds: 2);
  static const Duration snackBarDuration = Duration(seconds: 3);

  // ─── Backend URLs ──────────────────────────────────────────
  /// The cpx-server base URL for development.
  /// For Android emulator, use 'http://10.0.2.2:3001'.
  /// For iOS simulator, 'http://localhost:3001' works.
  static const String _devBackendUrl = 'http://localhost:3001';

  /// The cpx-server base URL for production.
  static const String _productionBackendUrl = 'https://cashspark-cpx-server.onrender.com';

  /// Auto-selects the backend URL based on build mode.
  static String get backendUrl =>
      kReleaseMode ? _productionBackendUrl : _devBackendUrl;

  /// API key for the CPX server FCM endpoints.
  /// Set this to match the FCM_API_KEY environment variable on the CPX server.
  /// Leave empty for local development (server skips auth in dev mode).
  static const String fcmApiKey = 'cpx-server-secret-funpay-2024';

  /// CPX Research postback URL (configure in their publisher dashboard →
  /// Postback Settings). The endpoint runs on the Render backend
  /// (cpx-server) — see cpx-server/README.md. A Cloud Functions variant
  /// (functions/cpx.js) exists for projects on the Blaze plan.
  static const String cpxPostbackUrl =
      'https://cashspark-cpx-server.onrender.com/cpx/postback';
}
