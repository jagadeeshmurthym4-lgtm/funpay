import 'dart:async';
import 'package:cashspark/app.dart';
import 'package:cashspark/data/datasources/firebase_auth_datasource.dart';
import 'package:cashspark/data/datasources/firebase_firestore_datasource.dart';
import 'package:cashspark/data/datasources/offer_firestore_datasource.dart';
import 'package:cashspark/data/datasources/project_firestore_datasource.dart';
import 'package:cashspark/data/datasources/affiliate_project_firestore_datasource.dart';
import 'package:cashspark/data/datasources/referral_firestore_datasource.dart';
import 'package:cashspark/data/repositories/affiliate_project_repository_impl.dart';
import 'package:cashspark/data/datasources/reward_firestore_datasource.dart';
import 'package:cashspark/data/datasources/wallet_firestore_datasource.dart';
import 'package:cashspark/data/datasources/withdrawal_firestore_datasource.dart';
import 'package:cashspark/data/datasources/admin_firestore_datasource.dart';
import 'package:cashspark/data/datasources/fraud_firestore_datasource.dart';
import 'package:cashspark/data/datasources/notification_firestore_datasource.dart';
import 'package:cashspark/data/datasources/consent_firestore_datasource.dart';
import 'package:cashspark/data/datasources/ticket_firestore_datasource.dart';
import 'package:cashspark/data/datasources/scratch_card_firestore_datasource.dart';
import 'package:cashspark/data/datasources/coupon_firestore_datasource.dart';
import 'package:cashspark/data/datasources/referral_level_firestore_datasource.dart';
import 'package:cashspark/data/datasources/streak_multiplier_firestore_datasource.dart';
import 'package:cashspark/domain/repositories/reward_repository.dart';
import 'package:cashspark/domain/repositories/wallet_repository.dart';
import 'package:cashspark/data/repositories/auth_repository_impl.dart';
import 'package:cashspark/data/repositories/offer_repository_impl.dart';
import 'package:cashspark/data/repositories/project_repository_impl.dart';
import 'package:cashspark/data/repositories/referral_repository_impl.dart';
import 'package:cashspark/data/repositories/reward_repository_impl.dart';
import 'package:cashspark/data/repositories/wallet_repository_impl.dart';
import 'package:cashspark/data/repositories/withdrawal_repository_impl.dart';
import 'package:cashspark/data/repositories/admin_repository_impl.dart';
import 'package:cashspark/data/repositories/fraud_repository_impl.dart';
import 'package:cashspark/data/repositories/notification_repository_impl.dart';
import 'package:cashspark/data/repositories/consent_repository_impl.dart';
import 'package:cashspark/data/repositories/scratch_card_repository_impl.dart';
import 'package:cashspark/data/repositories/coupon_repository_impl.dart';
import 'package:cashspark/data/repositories/referral_level_repository_impl.dart';
import 'package:cashspark/data/repositories/streak_multiplier_repository_impl.dart';
import 'package:cashspark/data/repositories/support_ticket_repository_impl.dart';
import 'package:cashspark/presentation/providers/auth_provider.dart';
import 'package:cashspark/presentation/providers/consent_provider.dart';
import 'package:cashspark/presentation/providers/offer_provider.dart';
import 'package:cashspark/presentation/providers/affiliate_project_provider.dart';
import 'package:cashspark/presentation/providers/project_provider.dart';
import 'package:cashspark/presentation/providers/referral_provider.dart';
import 'package:cashspark/presentation/providers/referral_level_provider.dart';
import 'package:cashspark/presentation/providers/streak_multiplier_provider.dart';
import 'package:cashspark/presentation/providers/reward_provider.dart';
import 'package:cashspark/presentation/providers/language_provider.dart';
import 'package:cashspark/presentation/providers/theme_provider.dart';
import 'package:cashspark/presentation/providers/wallet_provider.dart';
import 'package:cashspark/presentation/providers/withdrawal_provider.dart';
import 'package:cashspark/presentation/providers/admin_provider.dart';
import 'package:cashspark/presentation/providers/fraud_provider.dart';
import 'package:cashspark/presentation/providers/scratch_card_provider.dart';
import 'package:cashspark/presentation/providers/coupon_provider.dart';
import 'package:cashspark/presentation/providers/help_provider.dart';
import 'package:cashspark/presentation/providers/search_provider.dart';
import 'package:cashspark/presentation/providers/cpx_provider.dart';
import 'package:cashspark/presentation/providers/notification_provider.dart';
import 'package:cashspark/services/admob_service.dart';
import 'package:cashspark/services/cloudinary_service.dart';
import 'package:cashspark/services/connectivity_service.dart';
import 'package:cashspark/services/crash_monitoring_service.dart';
import 'package:cashspark/services/fcm_service.dart';
import 'package:cashspark/services/firestore_cache_busting_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';

/// Global error handler for all uncaught Flutter/Dart exceptions.
///
/// Catches errors that would otherwise crash the app:
/// - InheritedProvider setState() after dispose
/// - Provider null check operator crashes
/// - Firebase SDK internal errors
/// - Any other unhandled async error
///
/// The handler itself is crash-proof — it never throws.
void _globalErrorHandler(FlutterErrorDetails details) {
  try {
    debugPrint('══════ GLOBAL ERROR HANDLER ══════');
    debugPrint('Exception: ${details.exception}');
    debugPrint('Stack trace:\n${details.stack}');
    debugPrint('══════════════════════════════════════');
    // Attempt to forward to Crashlytics if available
    if (!kIsWeb) {
      try {
        FirebaseCrashlytics.instance.recordFlutterFatalError(details);
      } catch (_) {}
    }
  } catch (_) {
    // Never crash in the error handler itself
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set a global FlutterError handler that never crashes.
  // crash_monitoring_service.dart will REPLACE this with its Crashlytics
  // handler once initialized, but if it fails, this fallback remains active.
  FlutterError.onError = _globalErrorHandler;

  // Wrap everything in a zone that catches ALL unhandled async errors,
  // including Provider lifecycle errors, Firebase SDK internal errors, etc.
  runZonedGuarded(() async {
    try {
      // ── Firebase Initialization ──────────────────────────
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      final firestore = FirebaseFirestore.instance;
      firestore.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
      debugPrint('[Main] Firestore settings configured');
      debugPrint('[Main] Firebase project: ${firestore.app.options.projectId}');

      // ── Services Initialization ──────────────────────────
      try {
        await CrashMonitoringService().initialize();
      } catch (e) {
        debugPrint('[Main] CrashMonitoring init failed (non-fatal): $e');
      }

      try {
        await ConnectivityService().initialize();
      } catch (e) {
        debugPrint('[Main] ConnectivityService init failed (non-fatal): $e');
      }

      try {
        await AdMobServiceImpl.instance.initialize();
      } catch (e) {
        debugPrint('[Main] AdMob init failed (non-fatal): $e');
      }

      try {
        CloudinaryService.initialize(
          cloudName: 'q9recjxy',
          uploadPreset: 'funny_uploads',
        );
      } catch (e) {
        debugPrint('[Main] Cloudinary init failed (non-fatal): $e');
      }

      try {
        await FirestoreCacheBustingService().refreshOnAppStart();
      } catch (e) {
        debugPrint('[Main] CacheBusting init failed (non-fatal): $e');
      }

      // ── Data Sources ─────────────────────────────────────
      final firebaseAuthDataSource = FirebaseAuthDataSource();
      final firebaseFirestoreDataSource = FirebaseFirestoreDataSource();
      final walletFirestoreDataSource = WalletFirestoreDataSource();
      final referralFirestoreDataSource = ReferralFirestoreDataSource();
      final rewardFirestoreDataSource = RewardFirestoreDataSource();
      final withdrawalFirestoreDataSource = WithdrawalFirestoreDataSource();
      final adminFirestoreDataSource = AdminFirestoreDataSource();
      final fraudFirestoreDataSource = FraudFirestoreDataSource();
      final ticketFirestoreDataSource = TicketFirestoreDataSource();
      final notificationFirestoreDataSource = NotificationFirestoreDataSource();
      final consentFirestoreDataSource = ConsentFirestoreDataSource();
      final offerFirestoreDataSource = OfferFirestoreDataSource();
      final projectFirestoreDataSource = ProjectFirestoreDataSource();
      final affiliateProjectFirestoreDataSource = AffiliateProjectFirestoreDataSource();
      final referralLevelFirestoreDataSource = ReferralLevelFirestoreDataSource();
      final streakMultiplierFirestoreDataSource = StreakMultiplierFirestoreDataSource();
      final scratchCardFirestoreDataSource = ScratchCardFirestoreDataSource();
      final couponFirestoreDataSource = CouponFirestoreDataSource();

      // ── Repositories ─────────────────────────────────────
      final authRepository = AuthRepositoryImpl(
        authDataSource: firebaseAuthDataSource,
        firestoreDataSource: firebaseFirestoreDataSource,
        walletDataSource: walletFirestoreDataSource,
        referralDataSource: referralFirestoreDataSource,
      );
      final walletRepository = WalletRepositoryImpl(dataSource: walletFirestoreDataSource);
      final referralRepository = ReferralRepositoryImpl(dataSource: referralFirestoreDataSource);
      final rewardRepository = RewardRepositoryImpl(
        dataSource: rewardFirestoreDataSource,
        walletDataSource: walletFirestoreDataSource,
        notificationDataSource: notificationFirestoreDataSource,
        streakMultiplierDataSource: streakMultiplierFirestoreDataSource,
      );
      final withdrawalRepository = WithdrawalRepositoryImpl(
        dataSource: withdrawalFirestoreDataSource,
        walletDataSource: walletFirestoreDataSource,
        notificationDataSource: notificationFirestoreDataSource,
      );
      final adminRepository = AdminRepositoryImpl(
        dataSource: adminFirestoreDataSource,
        walletDataSource: walletFirestoreDataSource,
        notificationDataSource: notificationFirestoreDataSource,
      );
      final fraudRepository = FraudRepositoryImpl(dataSource: fraudFirestoreDataSource);
      final notificationRepository = NotificationRepositoryImpl(dataSource: notificationFirestoreDataSource);
      final consentRepository = ConsentRepositoryImpl(dataSource: consentFirestoreDataSource);
      final ticketRepository = SupportTicketRepositoryImpl(dataSource: ticketFirestoreDataSource);
      final offerRepository = OfferRepositoryImpl(dataSource: offerFirestoreDataSource);
      final projectRepository = ProjectRepositoryImpl(dataSource: projectFirestoreDataSource);
      final scratchCardRepository = ScratchCardRepositoryImpl(
        dataSource: scratchCardFirestoreDataSource,
        walletDataSource: walletFirestoreDataSource,
      );
      final referralLevelRepository = ReferralLevelRepositoryImpl(
        dataSource: referralLevelFirestoreDataSource,
        walletDataSource: walletFirestoreDataSource,
      );
      final streakMultiplierRepository = StreakMultiplierRepositoryImpl(
        dataSource: streakMultiplierFirestoreDataSource,
      );
      final couponRepository = CouponRepositoryImpl(dataSource: couponFirestoreDataSource);
      final affiliateProjectRepository = AffiliateProjectRepositoryImpl(
        dataSource: affiliateProjectFirestoreDataSource,
        walletDataSource: walletFirestoreDataSource,
        notificationDataSource: notificationFirestoreDataSource,
        adminDataSource: adminFirestoreDataSource,
      );
      final fcmService = FcmService();

      // ── Run App ──────────────────────────────────────────
      runApp(
        MultiProvider(
          providers: [
            Provider<RewardRepository>.value(value: rewardRepository),
            Provider<WalletRepository>.value(value: walletRepository),
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider(create: (_) => LanguageProvider()),
            ChangeNotifierProvider(
              create: (_) => AuthProvider(authRepository: authRepository),
            ),
            ChangeNotifierProvider(
              create: (_) => WalletProvider(
                walletRepository: walletRepository,
                rewardRepository: rewardRepository,
                referralRepository: referralRepository,
              ),
            ),
            ChangeNotifierProvider(
              create: (_) => ReferralProvider(referralRepository: referralRepository),
            ),
            ChangeNotifierProvider(
              create: (_) => RewardProvider(rewardRepository: rewardRepository),
            ),
            ChangeNotifierProvider(
              create: (_) => WithdrawalProvider(withdrawalRepository: withdrawalRepository),
            ),
            ChangeNotifierProvider(
              create: (_) => AdminProvider(adminRepository: adminRepository),
            ),
            ChangeNotifierProvider(
              create: (_) => NotificationProvider(
                notificationRepository: notificationRepository,
                fcmService: fcmService,
              ),
            ),
            ChangeNotifierProvider(
              create: (_) => ConsentProvider(consentRepository: consentRepository),
            ),
            ChangeNotifierProvider(
              create: (_) => FraudProvider(fraudRepository: fraudRepository),
            ),
            ChangeNotifierProvider(
              create: (_) => OfferProvider(offerRepository: offerRepository),
            ),
            ChangeNotifierProvider(
              create: (_) => ProjectProvider(projectRepository: projectRepository),
            ),
            ChangeNotifierProvider(
              create: (_) => AffiliateProjectProvider(repository: affiliateProjectRepository),
            ),
            ChangeNotifierProvider(
              create: (_) => HelpProvider(ticketRepository: ticketRepository),
            ),
            ChangeNotifierProvider(
              create: (_) => SearchProvider(
                offerRepository: offerRepository,
                projectRepository: projectRepository,
              ),
            ),
            ChangeNotifierProvider(
              create: (_) => ScratchCardProvider(scratchCardRepository: scratchCardRepository),
            ),
            ChangeNotifierProvider(
              create: (_) => CouponProvider(couponRepository: couponRepository),
            ),
            ChangeNotifierProvider(
              create: (_) => ReferralLevelProvider(repository: referralLevelRepository),
            ),
            ChangeNotifierProvider(
              create: (_) => StreakMultiplierProvider(repository: streakMultiplierRepository),
            ),
            ChangeNotifierProvider(
              create: (_) => CpxProvider(),
            ),
          ],
          child: const FunPayApp(),
        ),
      );
    } catch (e, stack) {
      // If anything in the initialization throws, log it and try to show the app anyway
      debugPrint('[Main] Fatal init error: $e\n$stack');
      if (!kIsWeb) {
        try {
          FirebaseCrashlytics.instance.recordError(e, stack, fatal: false);
        } catch (_) {}
      }
      // Re-throw so runZonedGuarded catches it
      rethrow;
    }
  }, (error, stack) {
    // Zone error handler - catches EVERYTHING that wasn't caught above
    try {
      debugPrint('══════ ZONE ERROR HANDLER ══════');
      debugPrint('Unhandled zone error: $error');
      debugPrint('Stack: $stack');
      debugPrint('══════════════════════════════════════');
      if (!kIsWeb) {
        try {
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: false);
        } catch (_) {}
      }
    } catch (_) {
      // Never crash in the error handler
    }
  });
}
