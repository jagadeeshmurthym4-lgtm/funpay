import 'package:cashspark/core/errors/exceptions.dart';
import 'package:cashspark/core/utils/helpers.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart' show PlatformException;
import 'package:cashspark/data/datasources/firebase_auth_datasource.dart';
import 'package:cashspark/data/datasources/firebase_firestore_datasource.dart';
import 'package:cashspark/data/datasources/referral_firestore_datasource.dart';
import 'package:cashspark/data/datasources/reward_firestore_datasource.dart';
import 'package:cashspark/data/datasources/wallet_firestore_datasource.dart';
import 'package:cashspark/data/models/referral_model.dart';
import 'package:cashspark/data/models/reward_model.dart';
import 'package:cashspark/data/models/transaction_model.dart';
import 'package:cashspark/data/models/user_model.dart';
import 'package:cashspark/data/models/wallet_model.dart';
import 'package:cashspark/domain/entities/referral_entity.dart';
import 'package:cashspark/domain/entities/reward_entity.dart';
import 'package:cashspark/domain/entities/transaction_entity.dart';
import 'package:cashspark/domain/entities/user_entity.dart';
import 'package:cashspark/domain/repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:uuid/uuid.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuthDataSource _authDataSource;
  final FirebaseFirestoreDataSource _firestoreDataSource;
  final WalletFirestoreDataSource _walletDataSource;
  final ReferralFirestoreDataSource _referralDataSource;
  final RewardFirestoreDataSource _rewardDataSource;
  final Uuid _uuid;

  AuthRepositoryImpl({
    required FirebaseAuthDataSource authDataSource,
    required FirebaseFirestoreDataSource firestoreDataSource,
    required WalletFirestoreDataSource walletDataSource,
    required ReferralFirestoreDataSource referralDataSource,
    RewardFirestoreDataSource? rewardDataSource,
    Uuid? uuid,
  })  : _authDataSource = authDataSource,
        _firestoreDataSource = firestoreDataSource,
        _walletDataSource = walletDataSource,
        _referralDataSource = referralDataSource,
        _rewardDataSource = rewardDataSource ?? RewardFirestoreDataSource(),
        _uuid = uuid ?? const Uuid();

  @override
  Stream<UserEntity?> get authStateChanges {
    return _authDataSource.authStateChanges.map((authUser) {
      if (authUser == null) return null;
      return UserEntity(
        uid: authUser.uid,
        email: authUser.email ?? '',
        fullName: authUser.displayName ?? '',
        referralCode: '',
        createdAt: DateTime.now(),
        isEmailVerified: authUser.emailVerified,
      );
    });
  }

  @override
  UserEntity? get currentUser {
    final authUser = _authDataSource.currentUser;
    if (authUser == null) return null;
    return UserEntity(
      uid: authUser.uid,
      email: authUser.email ?? '',
      fullName: authUser.displayName ?? '',
      referralCode: '',
      createdAt: DateTime.now(),
      isEmailVerified: authUser.emailVerified,
    );
  }

  @override
  Future<({UserEntity user, bool isNewUser})> signInWithGoogle() async {
    try {
      final credential = await _authDataSource.signInWithGoogle();
      final uid = credential.user?.uid;
      final userEmail = credential.user?.email;
      final displayName = credential.user?.displayName;
      if (uid == null || userEmail == null) {
        throw AuthException('Google sign-in failed');
      }

      var userModel = await _firestoreDataSource.getUser(uid);

      if (userModel == null) {
        // ─── NEW USER ───────────────────────────────────────
        // Check if user exists by email (migration from old account)
        final existingByEmail = await _firestoreDataSource.getUserByEmail(userEmail);
        if (existingByEmail != null) {
          // Migrate the existing Firestore doc to the new Google UID
          userModel = existingByEmail.copyWithModel(
            uid: uid,
            lastLoginAt: DateTime.now(),
          );
          await _firestoreDataSource.createUser(userModel);
          if (existingByEmail.uid != uid) {
            await _migrateWallet(existingByEmail.uid, uid);
            await _migrateTransactions(existingByEmail.uid, uid);
            await _migrateReferrals(existingByEmail.uid, uid);
            try {
              await _firestoreDataSource.deleteUser(existingByEmail.uid);
            } catch (e) {
              debugPrint('AuthRepo.signInWithGoogle: deleteUser failed for ${existingByEmail.uid}: $e');
            }
          }
          return (user: userModel, isNewUser: true);
        }

        // Generate a referral code for the new user
        String newReferralCode;
        do {
          newReferralCode = Helpers.generateReferralCode();
        } while (await _firestoreDataSource.isReferralCodeTaken(newReferralCode));

        // Create minimal user with profileCompleted = false
        userModel = UserModel(
          uid: uid,
          firstName: '',
          lastName: '',
          fullName: displayName ?? '',
          email: userEmail,
          phone: null,
          referralCode: newReferralCode,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
          walletBalance: 0.0,
          totalEarnings: 0.0,
          profileCompleted: false,
          isEmailVerified: credential.user?.emailVerified ?? false,
        );
        await _firestoreDataSource.createUser(userModel);
        await _ensureWalletCreated(uid);

        return (user: userModel, isNewUser: true);
      } else {
        // ─── EXISTING USER ──────────────────────────────────
        // For existing users, just update last login and return
        if (!userModel.profileCompleted) {
          // Profile not yet completed — treat as new for routing purposes
          return (user: userModel, isNewUser: true);
        }

        userModel = userModel.copyWithModel(
          isEmailVerified: credential.user?.emailVerified ?? false,
          lastLoginAt: DateTime.now(),
        );
        await _firestoreDataSource.updateUser(userModel);

        return (user: userModel, isNewUser: false);
      }
    } on AuthCancelledException {
      // User cancelled the Google account picker — silently propagate
      // so the UI doesn't show an error banner.
      rethrow;
    } on AuthConfigurationException catch (e) {
      // Configuration errors (SHA mismatch, missing OAuth client, etc.)
      debugPrint('[AuthRepo] AuthConfigurationException: ${e.message}');
      throw AuthException(
        'Google sign-in could not be completed due to a configuration issue. '
        'Please update the app or contact support. (Error: AUTH_CONFIG)',
      );
    } on auth.FirebaseAuthException catch (e) {
      debugPrint('[AuthRepo] signInWithGoogle FirebaseAuthException: ${e.code} - ${e.message}');
      if (e.code == 'invalid-credential') {
        throw AuthException(
          'Your Google sign-in session has expired. Please try again.',
          code: e.code,
        );
      }
      if (e.code == 'operation-not-allowed') {
        throw AuthException(
          'Google sign-in is not enabled. Please contact support.',
          code: e.code,
        );
      }
      throw AuthException(_mapGoogleAuthError(e), code: e.code);
    } on PlatformException catch (e) {
      // PlatformExceptions from the Google Sign-In plugin on Android
      debugPrint('[AuthRepo] signInWithGoogle PlatformException:');
      debugPrint('  code: ${e.code}');
      debugPrint('  message: ${e.message}');
      debugPrint('  details: ${e.details}');
      throw AuthException(_mapPlatformSignInError(e), code: e.code);
    } catch (e, stack) {
      debugPrint('[AuthRepo] signInWithGoogle unexpected error: $e');
      debugPrint('  stack: $stack');
      throw AuthException('Google sign-in failed. Please try again. If the issue persists, use email sign-in instead.');
    }
  }

  @override
  Future<UserEntity> completeProfile({
    required String firstName,
    required String lastName,
    required String phone,
    required String dateOfBirth,
    String? referralCode,
  }) async {
    try {
      final authUser = _authDataSource.currentUser;
      if (authUser == null) {
        throw AuthException('Not authenticated');
      }

      final uid = authUser.uid;
      var userModel = await _firestoreDataSource.getUser(uid);
      if (userModel == null) {
        throw AuthException('User not found');
      }

      final fullName = '$firstName $lastName';

      // Process referral code if provided
      if (referralCode != null && referralCode.trim().isNotEmpty) {
        final cleanedCode = referralCode.trim().toUpperCase();
        final referrerUser = await _firestoreDataSource.getUserByReferralCode(cleanedCode);

        if (referrerUser != null) {
          // Validate: cannot refer self
          if (referrerUser.uid == uid) {
            throw ReferralException('You cannot use your own referral code');
          }

          // Validate: user hasn't already been referred
          final alreadyReferred = await _referralDataSource.hasUserBeenReferred(uid);
          if (!alreadyReferred) {
            // Create referral record
            final referral = ReferralModel(
              referralId: _uuid.v4(),
              referrerUserId: referrerUser.uid,
              referredUserId: uid,
              referralCode: cleanedCode,
              rewardAmount: 0.0,
              status: ReferralStatus.completed,
              createdAt: DateTime.now(),
              firstProjectRewarded: false,
              lifetimeProjectCommission: 0.0,
              rewardedProjectIds: [],
              approvedProjectCount: 0,
            );
            await _referralDataSource.createReferral(referral);

            // ─── Immediate Sign-up Bonus ─────────────────────
            // Credit 4 pts to the referred user's wallet immediately
            try {
              await _walletDataSource.updateWalletBalance(
                userId: uid,
                amountChange: 4.0,
                earningsChange: 4.0,
                withdrawnChange: 0,
              );

              // Create transaction record for referred user bonus
              final txn = TransactionModel(
                transactionId: _uuid.v4(),
                userId: uid,
                type: TransactionType.credit,
                amount: 4.0,
                source: TransactionSource.referral,
                status: TransactionStatus.completed,
                description: 'Welcome bonus: 4 pts for using a referral code!',
                createdAt: DateTime.now(),
              );
              await _walletDataSource.createTransaction(txn);

              // Create reward record (shows in earnings breakdown pie chart)
              await _rewardDataSource.createReward(RewardModel(
                rewardId: _uuid.v4(),
                userId: uid,
                rewardType: RewardType.bonus,
                rewardAmount: 4.0,
                status: RewardStatus.claimed,
                createdAt: DateTime.now(),
                claimedAt: DateTime.now(),
              ));
            } catch (e) {
              debugPrint('Failed to credit referred user welcome bonus: $e');
            }

            // ─── Referrer 10 pts Sign-up Bonus ──────────────────
            // Each write is wrapped in its own try/catch so a failure in one
            // (e.g. transaction/reward creation denied by Firestore rules)
            // doesn't prevent the credit or guard flag from being set.

            // Step 1: Credit 10 pts to referrer's wallet (via _referralId rule)
            try {
              await _walletDataSource.creditReferralSignupBonus(
                referrerUserId: referrerUser.uid,
                referralId: referral.referralId,
              );
            } catch (e) {
              debugPrint('Failed to credit referrer wallet: $e');
            }

            // Step 2: Create transaction record for referrer (best-effort)
            try {
              final referrerTxn = TransactionModel(
                transactionId: _uuid.v4(),
                userId: referrerUser.uid,
                type: TransactionType.credit,
                amount: 10.0,
                source: TransactionSource.referral,
                status: TransactionStatus.completed,
                description: 'Sign-up bonus: 10 pts for referring a new user!',
                createdAt: DateTime.now(),
              );
              await _walletDataSource.createTransaction(referrerTxn);
            } catch (e) {
              debugPrint('Failed to create referrer transaction record: $e');
            }

            // Step 3: Create reward record for referrer (best-effort)
            try {
              await _rewardDataSource.createReward(RewardModel(
                rewardId: _uuid.v4(),
                userId: referrerUser.uid,
                rewardType: RewardType.bonus,
                rewardAmount: 10.0,
                status: RewardStatus.claimed,
                createdAt: DateTime.now(),
                claimedAt: DateTime.now(),
              ));
            } catch (e) {
              debugPrint('Failed to create referrer reward record: $e');
            }

            // Step 4: Set guard flag to prevent double-credit
            try {
              await _referralDataSource.updateReferral(
                referral.copyWithModel(signupBonusCredited: true),
              );
            } catch (e) {
              debugPrint('Failed to set signupBonusCredited guard flag: $e');
            }
          }
        }
        // If referral code is invalid, we just silently ignore it
      }

      // Save all profile information
      userModel = userModel.copyWithModel(
        firstName: firstName,
        lastName: lastName,
        fullName: fullName,
        phone: phone.isNotEmpty ? phone : null,
        dateOfBirth: dateOfBirth,
        referralCodeUsed: (referralCode != null && referralCode.trim().isNotEmpty)
            ? referralCode.trim().toUpperCase()
            : null,
        profileCompleted: true,
        profileCompletionPercentage: 100,
        lastLoginAt: DateTime.now(),
      );

      await _firestoreDataSource.updateUser(userModel);

      // Ensure wallet exists
      await _ensureWalletCreated(uid);

      return userModel;
    } catch (e) {
      debugPrint('AuthRepo.completeProfile error: $e');
      if (e is AuthException || e is ReferralException) rethrow;
      throw AuthException('Failed to complete profile: ${e.toString()}');
    }
  }

  /// Migrates referral records from oldUid to newUid during account linking.
  Future<void> _migrateReferrals(String oldUid, String newUid) async {
    try {
      final asReferrer = await _referralDataSource.getReferralsByReferrer(oldUid);
      for (final ref in asReferrer) {
        final migrated = ReferralModel(
          referralId: ref.referralId,
          referrerUserId: newUid,
          referredUserId: ref.referredUserId,
          referralCode: ref.referralCode,
          rewardAmount: ref.rewardAmount,
          status: ref.status,
          createdAt: ref.createdAt,
        );
        await _referralDataSource.createReferral(migrated);
      }

      final asReferred = await _referralDataSource.getReferralsByReferred(oldUid);
      for (final ref in asReferred) {
        final migrated = ReferralModel(
          referralId: ref.referralId,
          referrerUserId: ref.referrerUserId,
          referredUserId: newUid,
          referralCode: ref.referralCode,
          rewardAmount: ref.rewardAmount,
          status: ref.status,
          createdAt: ref.createdAt,
        );
        await _referralDataSource.createReferral(migrated);
      }
    } catch (e) {
      debugPrint('_migrateReferrals error: $e');
    }
  }

  Future<void> _migrateTransactions(String oldUid, String newUid) async {
    try {
      final transactions = await _walletDataSource.getAllTransactions(oldUid);
      if (transactions.isEmpty) return;

      for (final txn in transactions) {
        final migrated = TransactionModel(
          transactionId: txn.transactionId,
          userId: newUid,
          type: txn.type,
          amount: txn.amount,
          source: txn.source,
          status: txn.status,
          description: txn.description,
          createdAt: txn.createdAt,
        );
        await _walletDataSource.createTransaction(migrated);
      }
    } catch (e) {
      debugPrint('_migrateTransactions error: $e');
    }
  }

  Future<void> _migrateWallet(String oldUid, String newUid) async {
    try {
      final wallet = await _walletDataSource.getWallet(oldUid);
      if (wallet != null) {
        final migratedWallet = WalletModel(
          userId: newUid,
          walletBalance: wallet.walletBalance,
          totalEarnings: wallet.totalEarnings,
          totalWithdrawn: wallet.totalWithdrawn,
          updatedAt: DateTime.now(),
        );
        await _walletDataSource.createWallet(migratedWallet);
        try {
          await _walletDataSource.deleteWallet(oldUid);
        } catch (e) {
          debugPrint('_migrateWallet: deleteWallet failed for $oldUid: $e');
        }
      }
    } catch (e) {
      debugPrint('_migrateWallet error: $e');
    }
  }

  Future<void> _ensureWalletCreated(String uid) async {
    try {
      final existing = await _walletDataSource.getWallet(uid);
      if (existing == null) {
        await _walletDataSource.createWallet(
          WalletModel(
            userId: uid,
            walletBalance: 0.0,
            totalEarnings: 0.0,
            totalWithdrawn: 0.0,
            updatedAt: DateTime.now(),
          ),
        );
      }
    } catch (e) {
      debugPrint('_ensureWalletCreated error: $e');
    }
  }

  @override
  Future<void> reloadUser() async {
    try {
      await _authDataSource.reloadUser();
    } on auth.FirebaseAuthException catch (e) {
      throw AuthException(_mapAuthError(e), code: e.code);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _authDataSource.signOut();
    } on auth.FirebaseAuthException catch (e) {
      throw AuthException(_mapAuthError(e), code: e.code);
    }
  }

  @override
  Future<UserEntity> updateProfile({
    String? fullName,
    String? phone,
    String? dateOfBirth,
    String? gender,
    String? address,
    String? city,
    String? state,
    String? country,
    String? username,
    String? aboutMe,
    String? education,
    String? experience,
    List<String>? portfolioLinks,
    String? profilePicture,
    String? coverImage,
    String? upiQrCodeUrl,
    DateTime? qrCodeUploadedAt,
    DateTime? qrCodeUpdatedAt,
    String? qrCodeUploadedBy,
  }) async {
    try {
      final authUser = _authDataSource.currentUser;
      if (authUser == null) {
        throw AuthException('Not authenticated');
      }

      var userModel = await _firestoreDataSource.getUser(authUser.uid);
      if (userModel == null) {
        throw AuthException('User not found');
      }

      final completion = _calculateProfileCompletion({
        'fullName': fullName ?? userModel.fullName,
        'phone': phone ?? userModel.phone,
        'dateOfBirth': dateOfBirth ?? userModel.dateOfBirth,
        'gender': gender ?? userModel.gender,
        'address': address ?? userModel.address,
        'city': city ?? userModel.city,
        'state': state ?? userModel.state,
        'country': country ?? userModel.country,
        'username': username ?? userModel.username,
        'aboutMe': aboutMe ?? userModel.aboutMe,
        'education': education ?? userModel.education,
        'experience': experience ?? userModel.experience,
        'portfolioLinks': (portfolioLinks ?? userModel.portfolioLinks).isNotEmpty,
        'profilePicture': profilePicture ?? userModel.profilePicture,
        'coverImage': coverImage ?? userModel.coverImage,
      });

      userModel = userModel.copyWithModel(
        fullName: fullName,
        phone: phone,
        dateOfBirth: dateOfBirth,
        gender: gender,
        address: address,
        city: city,
        state: state,
        country: country,
        username: username,
        aboutMe: aboutMe,
        education: education,
        experience: experience,
        portfolioLinks: portfolioLinks,
        profilePicture: profilePicture,
        coverImage: coverImage,
        upiQrCodeUrl: upiQrCodeUrl,
        qrCodeUploadedAt: qrCodeUploadedAt,
        qrCodeUpdatedAt: qrCodeUpdatedAt,
        qrCodeUploadedBy: qrCodeUploadedBy,
        profileCompletionPercentage: completion,
      );

      await _firestoreDataSource.updateUser(userModel);
      return userModel;
    } catch (e) {
      debugPrint('AuthRepo.updateProfile error: $e');
      throw AuthException('Failed to update profile: ${e.toString()}');
    }
  }

  int _calculateProfileCompletion(Map<String, dynamic> fields) {
    const totalFields = 15;
    int filled = 0;
    for (final entry in fields.entries) {
      final value = entry.value;
      if (value is String && value.isNotEmpty) {
        filled++;
      } else if (value is bool && value) {
        filled++;
      } else if (value is List && value.isNotEmpty) {
        filled++;
      }
    }
    return ((filled / totalFields) * 100).round();
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    final authUser = _authDataSource.currentUser;
    if (authUser == null) return null;

    var userModel = await _firestoreDataSource.getUser(authUser.uid);

    if (userModel == null) return null;

    return userModel.copyWithModel(
      isEmailVerified: authUser.emailVerified,
    );
  }

  @override
  Future<UserEntity> signInWithEmail({
    required String email,
    required String password,
  }) async {
    // Normalize credentials early so variables are accessible in both try and catch
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedPassword = password.trim();
    
    try {
      debugPrint('[AuthRepo] signInWithEmail - normalized email: "$normalizedEmail"');
      debugPrint('[AuthRepo] signInWithEmail - password length: ${normalizedPassword.length}');

      final credential = await _authDataSource.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: normalizedPassword,
      );
      
      final uid = credential.user?.uid;
      debugPrint('[AuthRepo] signInWithEmail SUCCESS - UID: $uid, email: ${credential.user?.email}');
      
      if (uid == null) {
        throw AuthException('Sign-in failed - no UID returned');
      }

      var userModel = await _firestoreDataSource.getUser(uid);

      if (userModel == null) {
        debugPrint('[AuthRepo] signInWithEmail - User exists in Auth but NOT in Firestore for UID: $uid');
        throw AuthException('Account not fully set up. Please contact support.');
      }

      debugPrint('[AuthRepo] signInWithEmail - Firestore user found: ${userModel.email}');

      // Update last login
      userModel = userModel.copyWithModel(
        isEmailVerified: credential.user?.emailVerified ?? false,
        lastLoginAt: DateTime.now(),
      );
      await _firestoreDataSource.updateUser(userModel);

      return userModel;
    } on auth.FirebaseAuthException catch (e) {
      debugPrint('[AuthRepo] signInWithEmail FirebaseAuthException - code: ${e.code}, message: ${e.message}');
      // Include the raw error code in the exception for better diagnostics
      throw AuthException(
        _mapSignInAuthError(e),
        code: e.code,
      );
    } catch (e) {
      debugPrint('[AuthRepo] signInWithEmail unexpected error: $e');
      if (e is AuthException) rethrow;
      throw AuthException('Sign-in failed. Please try again.');
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email, {Map<String, dynamic>? actionCodeSettings}) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();
      debugPrint('[AuthRepo] Sending password reset to: $normalizedEmail');

      auth.ActionCodeSettings? settings;
      if (actionCodeSettings != null) {
        settings = auth.ActionCodeSettings(
          url: actionCodeSettings['url'] as String? ?? 'https://cashspark-c15bd.firebaseapp.com',
          handleCodeInApp: actionCodeSettings['handleCodeInApp'] as bool? ?? false,
          iOSBundleId: actionCodeSettings['iOSBundleId'] as String?,
          androidPackageName: actionCodeSettings['androidPackageName'] as String?,
          androidInstallApp:
              (actionCodeSettings['androidInstallApp'] as bool?) ?? false,
        );
      }

      await _authDataSource.sendPasswordResetEmail(
        normalizedEmail,
        actionCodeSettings: settings,
      );
    } on auth.FirebaseAuthException catch (e) {
      debugPrint('[AuthRepo] sendPasswordResetEmail error: ${e.code} - ${e.message}');
      throw AuthException(_mapPasswordResetError(e), code: e.code);
    }
  }

  @override
  Future<bool> sendEmailVerification() async {
    try {
      final user = _authDataSource.currentUser;
      if (user == null) {
        debugPrint('[AuthRepo] sendEmailVerification - no user signed in');
        return false;
      }

      if (user.emailVerified) {
        debugPrint('[AuthRepo] sendEmailVerification - email already verified');
        return false;
      }

      // Use ActionCodeSettings so the verification link can handle in-app redirect
      final settings = auth.ActionCodeSettings(
        url: 'https://cashspark-c15bd.firebaseapp.com',
        handleCodeInApp: true,
        iOSBundleId: 'com.spydev.funpay',
        androidPackageName: 'com.spydev.funpay',
        androidInstallApp: true,
      );

      await _authDataSource.sendEmailVerification(
        actionCodeSettings: settings,
      );
      debugPrint('[AuthRepo] sendEmailVerification - email sent successfully');
      return true;
    } on auth.FirebaseAuthException catch (e) {
      debugPrint('[AuthRepo] sendEmailVerification error: ${e.code} - ${e.message}');
      throw AuthException(_mapEmailVerificationError(e), code: e.code);
    }
  }

  @override
  Future<UserEntity> signUpWithEmail({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    String? firstName,
    String? lastName,
    String? dateOfBirth,
    String? referralCode,
  }) async {
    try {
      final credential = await _authDataSource.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = credential.user?.uid;
      final userEmail = credential.user?.email;
      if (uid == null || userEmail == null) {
        throw AuthException('Sign-up failed');
      }

      // Generate a referral code for the new user
      String newReferralCode;
      do {
        newReferralCode = Helpers.generateReferralCode();
      } while (await _firestoreDataSource.isReferralCodeTaken(newReferralCode));

      // Determine first/last name — use explicit params if provided, otherwise split fullName
      final resolvedFirstName = firstName ?? fullName.split(' ').first;
      final resolvedLastName = lastName ??
          (fullName.split(' ').length > 1
              ? fullName.split(' ').sublist(1).join(' ')
              : '');

      // Create user in Firestore (password is NEVER stored here — only in Firebase Auth)
      var userModel = UserModel(
        uid: uid,
        firstName: resolvedFirstName,
        lastName: resolvedLastName,
        fullName: fullName,
        email: userEmail,
        phone: phone.isNotEmpty ? phone : null,
        dateOfBirth: dateOfBirth,
        referralCode: newReferralCode,
        profileCompleted: true,
        walletBalance: 0.0,
        totalEarnings: 0.0,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        isEmailVerified: false,
      );

      await _firestoreDataSource.createUser(userModel);
      await _ensureWalletCreated(uid);

      // Process referral code if provided
      String? usedReferralCode;
      if (referralCode != null && referralCode.trim().isNotEmpty) {
        final cleanedCode = referralCode.trim().toUpperCase();
        final referrerUser = await _firestoreDataSource.getUserByReferralCode(cleanedCode);

        if (referrerUser != null && referrerUser.uid != uid) {
          final alreadyReferred = await _referralDataSource.hasUserBeenReferred(uid);
          if (!alreadyReferred) {
            usedReferralCode = cleanedCode;

            // Create referral record
            final referral = ReferralModel(
              referralId: _uuid.v4(),
              referrerUserId: referrerUser.uid,
              referredUserId: uid,
              referralCode: cleanedCode,
              rewardAmount: 0.0,
              status: ReferralStatus.completed,
              createdAt: DateTime.now(),
              firstProjectRewarded: false,
              lifetimeProjectCommission: 0.0,
              rewardedProjectIds: [],
              approvedProjectCount: 0,
            );
            await _referralDataSource.createReferral(referral);

            // ─── Immediate Sign-up Bonus ─────────────────────
            // Credit 4 pts to the referred user's wallet immediately
            try {
              await _walletDataSource.updateWalletBalance(
                userId: uid,
                amountChange: 4.0,
                earningsChange: 4.0,
                withdrawnChange: 0,
              );

              // Create transaction record for referred user bonus
              final txn = TransactionModel(
                transactionId: _uuid.v4(),
                userId: uid,
                type: TransactionType.credit,
                amount: 4.0,
                source: TransactionSource.referral,
                status: TransactionStatus.completed,
                description: 'Welcome bonus: 4 pts for using a referral code!',
                createdAt: DateTime.now(),
              );
              await _walletDataSource.createTransaction(txn);

              // Create reward record (shows in earnings breakdown pie chart)
              await _rewardDataSource.createReward(RewardModel(
                rewardId: _uuid.v4(),
                userId: uid,
                rewardType: RewardType.bonus,
                rewardAmount: 4.0,
                status: RewardStatus.claimed,
                createdAt: DateTime.now(),
                claimedAt: DateTime.now(),
              ));
            } catch (e) {
              debugPrint('Failed to credit referred user welcome bonus: $e');
            }

            // ─── Referrer 10 pts Sign-up Bonus ──────────────────
            // Each write is wrapped in its own try/catch so a failure in one
            // (e.g. transaction/reward creation denied by Firestore rules)
            // doesn't prevent the credit or guard flag from being set.

            // Step 1: Credit 10 pts to referrer's wallet (via _referralId rule)
            try {
              await _walletDataSource.creditReferralSignupBonus(
                referrerUserId: referrerUser.uid,
                referralId: referral.referralId,
              );
            } catch (e) {
              debugPrint('Failed to credit referrer wallet: $e');
            }

            // Step 2: Create transaction record for referrer (best-effort)
            try {
              final referrerTxn = TransactionModel(
                transactionId: _uuid.v4(),
                userId: referrerUser.uid,
                type: TransactionType.credit,
                amount: 10.0,
                source: TransactionSource.referral,
                status: TransactionStatus.completed,
                description: 'Sign-up bonus: 10 pts for referring a new user!',
                createdAt: DateTime.now(),
              );
              await _walletDataSource.createTransaction(referrerTxn);
            } catch (e) {
              debugPrint('Failed to create referrer transaction record: $e');
            }

            // Step 3: Create reward record for referrer (best-effort)
            try {
              await _rewardDataSource.createReward(RewardModel(
                rewardId: _uuid.v4(),
                userId: referrerUser.uid,
                rewardType: RewardType.bonus,
                rewardAmount: 10.0,
                status: RewardStatus.claimed,
                createdAt: DateTime.now(),
                claimedAt: DateTime.now(),
              ));
            } catch (e) {
              debugPrint('Failed to create referrer reward record: $e');
            }

            // Step 4: Set guard flag to prevent double-credit
            try {
              await _referralDataSource.updateReferral(
                referral.copyWithModel(signupBonusCredited: true),
              );
            } catch (e) {
              debugPrint('Failed to set signupBonusCredited guard flag: $e');
            }
          }
        }
      }

      // Update the user document with referralCodeUsed if a code was used
      if (usedReferralCode != null) {
        userModel = userModel.copyWithModel(
          referralCodeUsed: usedReferralCode,
        );
        await _firestoreDataSource.updateUser(userModel);
      }

      return userModel;
    } on auth.FirebaseAuthException catch (e) {
      debugPrint('AuthRepo.signUpWithEmail FirebaseAuthException: ${e.code} - ${e.message}');
      throw AuthException(_mapAuthError(e), code: e.code);
    } catch (e) {
      debugPrint('AuthRepo.signUpWithEmail error: $e');
      if (e is AuthException) rethrow;
      throw AuthException('Sign-up failed: ${e.toString()}');
    }
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _authDataSource.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
    } on auth.FirebaseAuthException catch (e) {
      debugPrint('AuthRepo.changePassword FirebaseAuthException: ${e.code} - ${e.message}');
      throw AuthException(_mapAuthError(e), code: e.code);
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      final uid = _authDataSource.currentUser?.uid;
      if (uid != null) {
        await _firestoreDataSource.deleteUser(uid);
      }
      await _authDataSource.deleteUser();
    } on auth.FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw AuthException(
          'Please sign out and sign in again before deleting your account. This is a security measure.',
          code: e.code,
        );
      }
      throw AuthException(_mapAuthError(e), code: e.code);
    }
  }

  /// Maps FirebaseAuth errors for email/password sign-in.
  ///
  /// IMPORTANT: In firebase_auth ^6.x (Firebase Auth SDK v22+), the error codes
  /// `wrong-password` and `user-not-found` have been merged into `invalid-credential`.
  /// So `invalid-credential` can mean EITHER wrong password OR the account doesn't
  /// have email/password auth (e.g. signed up with Google). The message must cover
  /// both scenarios.
  String _mapSignInAuthError(auth.FirebaseAuthException e) {
    debugPrint('[AuthRepo] _mapSignInAuthError - mapping code "${e.code}" to user-friendly message');
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email. If you registered with Google, please use the "Sign in with Google" button below.';
      case 'wrong-password':
        return 'Incorrect password. Please try again. If you forgot your password, use the "Forgot Password?" link.';
      case 'invalid-email':
        return 'Please enter a valid email or Gmail address';
      case 'invalid-credential':
        // In Firebase Auth SDK v22+, this replaces BOTH wrong-password AND user-not-found
        return 'Incorrect email or password. Please check your credentials and try again. '
            'If you signed up with Google, use "Sign in with Google" below. '
            'If you forgot your password, use "Forgot Password?".';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled';
      case 'account-exists-with-different-credential':
        return 'An account already exists with a different sign-in method. Try "Sign in with Google".';
      case 'network-request-failed':
        return 'Network error. Please check your connection';
      case 'invalid-verification-code':
        return 'Invalid verification code';
      case 'session-expired':
        return 'Session expired. Please try again';
      case 'email-already-in-use':
        return 'An account already exists with this email';
      default:
        return 'Sign-in failed (${e.code}). Please try again. If the issue persists, use "Sign in with Google".';
    }
  }

  /// Maps FirebaseAuth errors specific to password reset flow.
  ///
  /// Handles error codes that can be returned by
  /// `FirebaseAuth.sendPasswordResetEmail()`.
  /// Maps FirebaseAuth errors specific to email verification.
  String _mapEmailVerificationError(auth.FirebaseAuthException e) {
    debugPrint('[AuthRepo] _mapEmailVerificationError - code: "${e.code}"');
    switch (e.code) {
      case 'no-current-user':
        return 'You need to sign in first before verifying your email.';
      case 'too-many-requests':
        return 'Too many verification email requests. Please wait a few minutes and try again.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection and try again.';
      case 'missing-continue-uri':
        return 'Configuration error: missing verification link. Please contact support.';
      case 'invalid-continue-uri':
        return 'Configuration error: invalid verification link. Please contact support.';
      default:
        debugPrint('[AuthRepo] _mapEmailVerificationError - unmapped code: "${e.code}"');
        return 'Unable to send verification email right now. Please try again later.';
    }
  }

  String _mapPasswordResetError(auth.FirebaseAuthException e) {
    debugPrint('[AuthRepo] _mapPasswordResetError - mapping code "${e.code}" to user-friendly message');
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email address. Please check that you entered the correct email, or sign up for a new account.';
      case 'invalid-email':
        return 'Please enter a valid email address (e.g., name@example.com).';
      case 'missing-email':
        return 'Please enter your email address first.';
      case 'missing-continue-uri':
        return 'Configuration error: missing reset link destination. Please contact support.';
      case 'invalid-continue-uri':
        return 'Configuration error: invalid reset link. Please contact support.';
      case 'too-many-requests':
        return 'Too many password reset attempts. Please wait a few minutes and try again.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support for help.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection and try again.';
      case 'operation-not-allowed':
        return 'Password reset is not available at this time. Please contact support.';
      default:
        debugPrint('[AuthRepo] _mapPasswordResetError - unmapped code: "${e.code}", message: "${e.message}"');
        return 'Unable to send password reset email right now (${e.code}). Please try again later or contact support.';
    }
  }

  /// Maps FirebaseAuth errors specifically for Google sign-in flows.
  ///
  /// Different from email sign-in errors because Google sign-in uses
  /// `signInWithCredential` instead of `signInWithEmailAndPassword`.
  String _mapGoogleAuthError(auth.FirebaseAuthException e) {
    debugPrint('[AuthRepo] _mapGoogleAuthError - mapping code "${e.code}"');
    switch (e.code) {
      case 'invalid-credential':
        return 'Your Google sign-in session has expired or is invalid. Please try again.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'operation-not-allowed':
        return 'Google sign-in is not enabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many sign-in attempts. Please wait a moment and try again.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with this email using a different sign-in method. Please sign in with your email and password.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection and try again.';
      case 'credential-already-in-use':
        return 'This Google account is already linked to another user.';
      case 'requires-recent-login':
        return 'Please sign out and sign in again before making this change.';
      case 'web-context-already-presented':
        return 'Sign-in is already in progress. Please wait.';
      default:
        debugPrint('[AuthRepo] _mapGoogleAuthError - unmapped code: "${e.code}", message: "${e.message}"');
        return 'Google sign-in encountered an issue (${e.code}). Please try again or use email sign-in.';
    }
  }

  /// Maps PlatformException errors from the Google Sign-In Android plugin.
  ///
  /// These are thrown by `google_sign_in_android`'s native code when the
  /// underlying Google Sign-In API returns an error. Common causes:
  /// - SHA-1/SHA-256 fingerprint mismatch
  /// - OAuth client ID mismatch
  /// - Missing Google Play Services
  String _mapPlatformSignInError(PlatformException e) {
    debugPrint('[AuthRepo] _mapPlatformSignInError - code: "${e.code}", message: "${e.message}", details: "${e.details}"');
    switch (e.code) {
      case 'sign_in_failed':
        // This is the most common error. It can mean:
        // 1. SHA fingerprint not registered in Firebase Console
        // 2. Package name mismatch
        // 3. Invalid client ID
        if (e.message != null && e.message!.contains('certificate')) {
          debugPrint('[AuthRepo] ⚠️ DETECTED CERTIFICATE/SHA FINGERPRINT ISSUE');
          debugPrint('[AuthRepo] The app\'s signing certificate is not registered in Firebase Console.');
          debugPrint('[AuthRepo] Verify that the SHA-1 and SHA-256 fingerprints of BOTH the upload key');
          debugPrint('[AuthRepo] AND the Play App Signing key are added to the Firebase Android app.');
        }
        return 'Unable to sign in with Google. This may be due to an app configuration issue. Please try again or use email sign-in.';
      case 'network_error':
        return 'Network error. Please check your internet connection and try again.';
      case 'internal_error':
        debugPrint('[AuthRepo] ⚠️ internal_error from Google Sign-In - often means SHA mismatch or Play Services issue');
        return 'Google sign-in encountered an internal error. Please try again or use email sign-in.';
      case 'sign_in_cancelled':
        // Shouldn't reach here since cancellation is handled separately
        return 'Sign-in was cancelled.';
      case 'sign_in_required':
        return 'Please select a Google account to sign in.';
      default:
        debugPrint('[AuthRepo] _mapPlatformSignInError - unmapped code: "${e.code}"');
        return 'Google sign-in failed. Please try again or use email sign-in.';
    }
  }

  String _mapAuthError(auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled';
      case 'account-exists-with-different-credential':
        return 'An account already exists with a different sign-in method';
      case 'network-request-failed':
        return 'Network error. Please check your connection';
      case 'requires-recent-login':
        return 'Please sign out and sign in again before deleting your account';
      default:
        return 'An unexpected error occurred. Please try again';
    }
  }
}
