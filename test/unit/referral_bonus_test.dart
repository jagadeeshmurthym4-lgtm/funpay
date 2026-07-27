import 'package:cashspark/core/errors/exceptions.dart';
import 'package:cashspark/data/datasources/firebase_auth_datasource.dart';
import 'package:cashspark/data/datasources/firebase_firestore_datasource.dart';
import 'package:cashspark/data/datasources/referral_firestore_datasource.dart';
import 'package:cashspark/data/datasources/reward_firestore_datasource.dart';
import 'package:cashspark/data/datasources/wallet_firestore_datasource.dart';
import 'package:cashspark/data/models/referral_model.dart';
import 'package:cashspark/data/models/referral_reward_config_model.dart';
import 'package:cashspark/data/models/reward_model.dart';
import 'package:cashspark/data/models/transaction_model.dart';
import 'package:cashspark/data/models/user_model.dart';
import 'package:cashspark/data/models/wallet_model.dart';
import 'package:cashspark/data/repositories/auth_repository_impl.dart';
import 'package:cashspark/domain/entities/referral_entity.dart';
import 'package:cashspark/domain/entities/reward_entity.dart';
import 'package:cashspark/domain/entities/transaction_entity.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// ─── Mocktail mocks ─────────────────────────────────────────

class MockFirebaseAuthDataSource extends Mock
    implements FirebaseAuthDataSource {}

class MockFirestoreDataSource extends Mock
    implements FirebaseFirestoreDataSource {}

class MockWalletDataSource extends Mock
    implements WalletFirestoreDataSource {}

class MockReferralDataSource extends Mock
    implements ReferralFirestoreDataSource {}

class MockRewardDataSource extends Mock
    implements RewardFirestoreDataSource {}

class MockUser extends Mock implements auth.User {}

// ─── Constants ──────────────────────────────────────────────

const _newUserId = 'new-user-uid';
const _referrerUserId = 'referrer-uid';
const _referralCode = 'ABCD1234';
const _referrerBonus = 10.0;
const _referredBonus = 4.0;

// ─── Test Data Builders ─────────────────────────────────────

UserModel _createUserModel({
  required String uid,
  String referralCode = 'MYOWNCODE',
  bool profileCompleted = false,
}) {
  return UserModel(
    uid: uid,
    firstName: '',
    lastName: '',
    fullName: 'Test User',
    email: 'test@test.com',
    referralCode: referralCode,
    createdAt: DateTime.now(),
    walletBalance: 0.0,
    totalEarnings: 0.0,
    profileCompleted: profileCompleted,
  );
}

WalletModel _createWalletModel({
  required String userId,
  double balance = 0.0,
}) {
  return WalletModel(
    userId: userId,
    walletBalance: balance,
    totalEarnings: balance,
    totalWithdrawn: 0,
    updatedAt: DateTime.now(),
  );
}

ReferralRewardConfigModel _createActiveConfig() {
  return ReferralRewardConfigModel(
    id: 'config',
    referrerBonus: _referrerBonus,
    referredBonus: _referredBonus,
    isActive: true,
    updatedAt: DateTime.now(),
  );
}

// ─── Helper: default stubs ─────────────────────────────────

void _defaultStubs({
  required MockFirebaseAuthDataSource auth,
  required MockFirestoreDataSource firestore,
  required MockWalletDataSource wallet,
  required MockReferralDataSource referral,
  required MockRewardDataSource reward,
  required auth.User? currentAuthUser,
  required UserModel? existingUser,
}) {
  // Auth
  when(() => auth.currentUser).thenReturn(currentAuthUser);

  // Firestore
  when(() => firestore.getUser(any())).thenAnswer((_) async => existingUser);
  when(() => firestore.getUserByEmail(any())).thenAnswer((_) async => null);
  when(() => firestore.getUserByPhone(any())).thenAnswer((_) async => null);
  when(() => firestore.getUserByReferralCode(any())).thenAnswer((_) async => null);
  when(() => firestore.isReferralCodeTaken(any())).thenAnswer((_) async => false);
  when(() => firestore.createUser(any())).thenAnswer((_) async {});
  when(() => firestore.updateUser(any())).thenAnswer((_) async {});
  when(() => firestore.deleteUser(any())).thenAnswer((_) async {});

  // Wallet
  when(() => wallet.getWallet(any())).thenAnswer((_) async => null);
  when(() => wallet.createWallet(any())).thenAnswer((_) async {});
  when(() => wallet.deleteWallet(any())).thenAnswer((_) async {});
  when(() => wallet.getAllTransactions(any())).thenAnswer((_) async => []);
  when(() => wallet.createTransaction(any())).thenAnswer((_) async {});
  when(() => wallet.getTransactions(any())).thenAnswer((_) async => []);

  when(() => wallet.updateWalletBalance(
    userId: any(named: 'userId'),
    amountChange: any(named: 'amountChange'),
    earningsChange: any(named: 'earningsChange'),
    withdrawnChange: any(named: 'withdrawnChange'),
  )).thenAnswer((invocation) async {
    final userId = invocation.namedArguments[#userId] as String;
    final amountChange = invocation.namedArguments[#amountChange] as double;
    final earningsChange = invocation.namedArguments[#earningsChange] as double;
    return WalletModel(
      userId: userId,
      walletBalance: amountChange > 0 ? amountChange : 0,
      totalEarnings: earningsChange > 0 ? earningsChange : 0,
      totalWithdrawn: 0,
      updatedAt: DateTime.now(),
    );
  });

  // Wallet - creditReferralSignupBonus
  when(() => wallet.creditReferralSignupBonus(
    referrerUserId: any(named: 'referrerUserId'),
    referralId: any(named: 'referralId'),
  )).thenAnswer((_) async {});

  // Referral
  when(() => referral.getReferralsByReferrer(any())).thenAnswer((_) async => []);
  when(() => referral.getReferralsByReferred(any())).thenAnswer((_) async => []);
  when(() => referral.createReferral(any())).thenAnswer((_) async {});
  when(() => referral.updateReferral(any())).thenAnswer((_) async {});
  when(() => referral.hasUserBeenReferred(any())).thenAnswer((_) async => false);
  when(() => referral.getRewardConfig()).thenAnswer((_) async => _createActiveConfig());

  // Reward
  when(() => reward.createReward(any())).thenAnswer((_) async {});
}

// ─── Setup helpers ──────────────────────────────────────────

AuthRepositoryImpl _buildRepo({
  required MockFirebaseAuthDataSource auth,
  required MockFirestoreDataSource firestore,
  required MockWalletDataSource wallet,
  required MockReferralDataSource referral,
  required MockRewardDataSource reward,
}) {
  return AuthRepositoryImpl(
    authDataSource: auth,
    firestoreDataSource: firestore,
    walletDataSource: wallet,
    referralDataSource: referral,
    rewardDataSource: reward,
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(UserModel(
      uid: '',
      firstName: '',
      lastName: '',
      fullName: '',
      email: '',
      referralCode: '',
      createdAt: DateTime.now(),
    ));
    registerFallbackValue(WalletModel(
      userId: '',
      updatedAt: DateTime.now(),
    ));
    registerFallbackValue(TransactionModel(
      transactionId: '',
      userId: '',
      type: TransactionType.credit,
      amount: 0,
      createdAt: DateTime.now(),
    ));
    registerFallbackValue(ReferralModel(
      referralId: '',
      referrerUserId: '',
      referredUserId: '',
      referralCode: '',
      createdAt: DateTime.now(),
      signupBonusCredited: false,
    ));
    registerFallbackValue(RewardModel(
      rewardId: '',
      userId: '',
      rewardType: RewardType.bonus,
      createdAt: DateTime.now(),
    ));
  });

  group('completeProfile - referral bonus logic', () {
    late MockFirebaseAuthDataSource mockAuthDataSource;
    late MockFirestoreDataSource mockFirestoreDataSource;
    late MockWalletDataSource mockWalletDataSource;
    late MockReferralDataSource mockReferralDataSource;
    late MockRewardDataSource mockRewardDataSource;
    late AuthRepositoryImpl authRepo;

    setUp(() {
      mockAuthDataSource = MockFirebaseAuthDataSource();
      mockFirestoreDataSource = MockFirestoreDataSource();
      mockWalletDataSource = MockWalletDataSource();
      mockReferralDataSource = MockReferralDataSource();

      final mockAuthUser = MockUser();
      when(() => mockAuthUser.uid).thenReturn(_newUserId);

      mockRewardDataSource = MockRewardDataSource();

      _defaultStubs(
        auth: mockAuthDataSource,
        firestore: mockFirestoreDataSource,
        wallet: mockWalletDataSource,
        referral: mockReferralDataSource,
        reward: mockRewardDataSource,
        currentAuthUser: mockAuthUser,
        existingUser: _createUserModel(uid: _newUserId),
      );

      authRepo = _buildRepo(
        auth: mockAuthDataSource,
        firestore: mockFirestoreDataSource,
        wallet: mockWalletDataSource,
        referral: mockReferralDataSource,
        reward: mockRewardDataSource,
      );
    });

    test('creates referral record for a valid referral code', () async {
      // Arrange: referrer exists with the given referral code
      final referrerUser = _createUserModel(
        uid: _referrerUserId,
        referralCode: _referralCode,
        profileCompleted: true,
      );
      when(() => mockFirestoreDataSource.getUserByReferralCode(_referralCode))
          .thenAnswer((_) async => referrerUser);

      // The new user has a wallet that already exists
      when(() => mockWalletDataSource.getWallet(_newUserId))
          .thenAnswer((_) async => _createWalletModel(userId: _newUserId));

      // Act
      final result = await authRepo.completeProfile(
        firstName: 'John',
        lastName: 'Doe',
        phone: '9876543210',
        dateOfBirth: '01/01/2000',
        referralCode: _referralCode,
      );

      // Assert: referral record created with rewardAmount = 0 (project-based now)
      verify(() => mockReferralDataSource.createReferral(
        any(that: predicate<ReferralModel>((r) =>
            r.referrerUserId == _referrerUserId &&
            r.referredUserId == _newUserId &&
            r.referralCode == _referralCode &&
            r.rewardAmount == 0.0 &&
            r.firstProjectRewarded == false &&
            r.lifetimeProjectCommission == 0.0 &&
            r.rewardedProjectIds.isEmpty &&
            r.approvedProjectCount == 0 &&
            r.status == ReferralStatus.completed)),
      )).called(1);

      // Assert: referred user gets ₹4 immediate sign-up bonus (they own their wallet)
      verify(() => mockWalletDataSource.updateWalletBalance(
        userId: _newUserId,
        amountChange: 4.0,
        earningsChange: 4.0,
        withdrawnChange: 0,
      )).called(1);

      // Assert: transaction record created for the referred user's bonus
      verify(() => mockWalletDataSource.createTransaction(
        any(that: predicate<TransactionModel>((t) =>
            t.userId == _newUserId &&
            t.type == TransactionType.credit &&
            t.amount == 4.0 &&
            t.source == TransactionSource.referral &&
            t.status == TransactionStatus.completed)),
      )).called(1);

      // Assert: referrer gets ₹10 sign-up bonus via creditReferralSignupBonus
      verify(() => mockWalletDataSource.creditReferralSignupBonus(
        referrerUserId: _referrerUserId,
        referralId: any(named: 'referralId'),
      )).called(1);

      // Assert: transaction record created for the referrer's bonus
      verify(() => mockWalletDataSource.createTransaction(
        any(that: predicate<TransactionModel>((t) =>
            t.userId == _referrerUserId &&
            t.type == TransactionType.credit &&
            t.amount == 10.0 &&
            t.source == TransactionSource.referral &&
            t.status == TransactionStatus.completed)),
      )).called(1);

      // Assert: reward record created for the referrer
      verify(() => mockRewardDataSource.createReward(
        any(that: predicate<RewardModel>((r) =>
            r.userId == _referrerUserId &&
            r.rewardType == RewardType.bonus &&
            r.rewardAmount == 10.0 &&
            r.status == RewardStatus.claimed)),
      )).called(1);

      // Assert: signupBonusCredited guard flag set on referral doc
      verify(() => mockReferralDataSource.updateReferral(
        any(that: predicate<ReferralModel>((r) =>
            r.signupBonusCredited == true)),
      )).called(1);

      // Assert: duplicate prevention check was performed
      verify(() => mockReferralDataSource.hasUserBeenReferred(_newUserId)).called(1);

      // Assert: user document updated with profile info
      verify(() => mockFirestoreDataSource.updateUser(
        any(that: predicate<UserModel>((u) =>
            u.uid == _newUserId &&
            u.firstName == 'John' &&
            u.lastName == 'Doe' &&
            u.fullName == 'John Doe' &&
            u.phone == '9876543210' &&
            u.dateOfBirth == '01/01/2000' &&
            u.referralCodeUsed == _referralCode &&
            u.profileCompleted == true &&
            u.profileCompletionPercentage == 100)),
      )).called(1);

      // Assert: returned user has correct fields
      expect(result.profileCompleted, true);
      expect(result.fullName, 'John Doe');
      expect(result.firstName, 'John');
      expect(result.lastName, 'Doe');
    });

    test('silently ignores an invalid referral code and continues registration', () async {
      // Arrange: no user found with the given referral code
      when(() => mockFirestoreDataSource.getUserByReferralCode('INVALID'))
          .thenAnswer((_) async => null);

      // Act
      final result = await authRepo.completeProfile(
        firstName: 'Jane',
        lastName: 'Smith',
        phone: '',
        dateOfBirth: '15/06/1995',
        referralCode: 'INVALID',
      );

      // Assert: no referral record was created
      verifyNever(() => mockReferralDataSource.createReferral(any()));

      // Assert: no wallet balance updates
      verifyNever(() => mockWalletDataSource.updateWalletBalance(
        userId: any(named: 'userId'),
        amountChange: any(named: 'amountChange'),
        earningsChange: any(named: 'earningsChange'),
        withdrawnChange: any(named: 'withdrawnChange'),
      ));

      // Assert: user document was still updated with profile info
      verify(() => mockFirestoreDataSource.updateUser(
        any(that: predicate<UserModel>((u) =>
            u.uid == _newUserId &&
            u.firstName == 'Jane' &&
            u.lastName == 'Smith' &&
            u.fullName == 'Jane Smith' &&
            u.phone == null &&
            u.dateOfBirth == '15/06/1995' &&
            u.referralCodeUsed == 'INVALID' &&
            u.profileCompleted == true)),
      )).called(1);

      expect(result.profileCompleted, true);
    });

    test('no referral code entered continues registration normally', () async {
      // Act
      final result = await authRepo.completeProfile(
        firstName: 'Alice',
        lastName: 'Brown',
        phone: '1234567890',
        dateOfBirth: '20/12/1998',
        referralCode: null,
      );

      // Assert: no referral-related calls
      verifyNever(() => mockFirestoreDataSource.getUserByReferralCode(any()));
      verifyNever(() => mockReferralDataSource.createReferral(any()));
      verifyNever(() => mockWalletDataSource.updateWalletBalance(
        userId: any(named: 'userId'),
        amountChange: any(named: 'amountChange'),
        earningsChange: any(named: 'earningsChange'),
        withdrawnChange: any(named: 'withdrawnChange'),
      ));

      // Assert: user document updated with no referral code used
      verify(() => mockFirestoreDataSource.updateUser(
        any(that: predicate<UserModel>((u) =>
            u.uid == _newUserId &&
            u.firstName == 'Alice' &&
            u.lastName == 'Brown' &&
            u.referralCodeUsed == null &&
            u.profileCompleted == true)),
      )).called(1);

      expect(result.profileCompleted, true);
    });

    test('throws ReferralException when user enters their own referral code', () async {
      // Arrange: getUserByReferralCode returns the user themselves
      final ownUser = _createUserModel(
        uid: _newUserId,
        referralCode: _referralCode,
      );
      when(() => mockFirestoreDataSource.getUserByReferralCode(_referralCode))
          .thenAnswer((_) async => ownUser);

      // Act & Assert
      expect(
        () => authRepo.completeProfile(
          firstName: 'Self',
          lastName: 'Referrer',
          phone: '9999999999',
          dateOfBirth: '10/10/2000',
          referralCode: _referralCode,
        ),
        throwsA(isA<ReferralException>().having(
          (e) => e.message,
          'message',
          'You cannot use your own referral code',
        )),
      );

      // Assert: no referral record created
      verifyNever(() => mockReferralDataSource.createReferral(any()));

      // Assert: no wallet updates
      verifyNever(() => mockWalletDataSource.updateWalletBalance(
        userId: any(named: 'userId'),
        amountChange: any(named: 'amountChange'),
        earningsChange: any(named: 'earningsChange'),
        withdrawnChange: any(named: 'withdrawnChange'),
      ));

      // Assert: user document NOT saved (exception aborted the flow)
      verifyNever(() => mockFirestoreDataSource.updateUser(any()));
    });

    test('skips referral bonus when user has already been referred (duplicate prevention)', () async {
      // Arrange: referrer exists
      final referrerUser = _createUserModel(
        uid: _referrerUserId,
        referralCode: _referralCode,
        profileCompleted: true,
      );
      when(() => mockFirestoreDataSource.getUserByReferralCode(_referralCode))
          .thenAnswer((_) async => referrerUser);

      when(() => mockWalletDataSource.getWallet(_newUserId))
          .thenAnswer((_) async => _createWalletModel(userId: _newUserId));

      // The new user has already been referred by someone else
      when(() => mockReferralDataSource.hasUserBeenReferred(_newUserId))
          .thenAnswer((_) async => true);

      // Act
      final result = await authRepo.completeProfile(
        firstName: 'Bob',
        lastName: 'Dup',
        phone: '7777777777',
        dateOfBirth: '05/05/2001',
        referralCode: _referralCode,
      );

      // Assert: no referral record created (duplicate prevention)
      verifyNever(() => mockReferralDataSource.createReferral(any()));

      // Assert: no wallet updates made
      verifyNever(() => mockWalletDataSource.updateWalletBalance(
        userId: any(named: 'userId'),
        amountChange: any(named: 'amountChange'),
        earningsChange: any(named: 'earningsChange'),
        withdrawnChange: any(named: 'withdrawnChange'),
      ));

      // Assert: user document still updated with profile info
      verify(() => mockFirestoreDataSource.updateUser(
        any(that: predicate<UserModel>((u) =>
            u.uid == _newUserId &&
            u.referralCodeUsed == _referralCode &&
            u.profileCompleted == true)),
      )).called(1);

      expect(result.profileCompleted, true);
    });
  });

  group('completeProfile - edge cases', () {
    test('throws AuthException when no authenticated user', () async {
      final mockAuth = MockFirebaseAuthDataSource();
      final mockFirestore = MockFirestoreDataSource();
      final mockWallet = MockWalletDataSource();
      final mockReferral = MockReferralDataSource();
      final mockReward = MockRewardDataSource();

      when(() => mockAuth.currentUser).thenReturn(null);
      when(() => mockFirestore.getUser(any())).thenAnswer((_) async => _createUserModel(uid: 'ignored'));

      final repo = _buildRepo(
        auth: mockAuth,
        firestore: mockFirestore,
        wallet: mockWallet,
        referral: mockReferral,
        reward: mockReward,
      );

      expect(
        () => repo.completeProfile(
          firstName: 'No',
          lastName: 'Auth',
          phone: '',
          dateOfBirth: '01/01/2000',
        ),
        throwsA(isA<AuthException>().having(
          (e) => e.message,
          'message',
          'Not authenticated',
        )),
      );
    });

    test('throws AuthException when user not found in Firestore', () async {
      final mockAuth = MockFirebaseAuthDataSource();
      final mockFirestore = MockFirestoreDataSource();
      final mockWallet = MockWalletDataSource();
      final mockReferral = MockReferralDataSource();
      final mockReward = MockRewardDataSource();

      final mockAuthUser = MockUser();
      when(() => mockAuthUser.uid).thenReturn('ghost-uid');
      when(() => mockAuth.currentUser).thenReturn(mockAuthUser);
      when(() => mockFirestore.getUser(any())).thenAnswer((_) async => null);

      final repo = _buildRepo(
        auth: mockAuth,
        firestore: mockFirestore,
        wallet: mockWallet,
        referral: mockReferral,
        reward: mockReward,
      );

      expect(
        () => repo.completeProfile(
          firstName: 'Ghost',
          lastName: 'User',
          phone: '',
          dateOfBirth: '01/01/2000',
        ),
        throwsA(isA<AuthException>().having(
          (e) => e.message,
          'message',
          'User not found',
        )),
      );
    });

    test('saves profile with empty phone (optional field)', () async {
      final mockAuth = MockFirebaseAuthDataSource();
      final mockFirestore = MockFirestoreDataSource();
      final mockWallet = MockWalletDataSource();
      final mockReferral = MockReferralDataSource();
      final mockReward = MockRewardDataSource();

      final mockAuthUser = MockUser();
      when(() => mockAuthUser.uid).thenReturn('phone-optional');
      when(() => mockAuth.currentUser).thenReturn(mockAuthUser);
      when(() => mockFirestore.getUser(any()))
          .thenAnswer((_) async => _createUserModel(uid: 'phone-optional'));
      when(() => mockFirestore.updateUser(any())).thenAnswer((_) async {});
      // Ensure wallet creation doesn't fail
      when(() => mockWallet.getWallet(any())).thenAnswer((_) async => _createWalletModel(userId: 'phone-optional'));

      final repo = _buildRepo(
        auth: mockAuth,
        firestore: mockFirestore,
        wallet: mockWallet,
        referral: mockReferral,
        reward: mockReward,
      );

      final result = await repo.completeProfile(
        firstName: 'No',
        lastName: 'Phone',
        phone: '',
        dateOfBirth: '01/01/2000',
      );

      verify(() => mockFirestore.updateUser(
        any(that: predicate<UserModel>((u) =>
            u.phone == null && u.profileCompleted == true)),
      )).called(1);

      expect(result.phone, isNull);
    });
  });
}
