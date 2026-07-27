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

class MockUserCredential extends Mock implements auth.UserCredential {}

class MockUser extends Mock implements auth.User {}

class MockRewardFirestoreDataSource extends Mock
    implements RewardFirestoreDataSource {}

// ─── Helper: default stubs for datasource methods ──────────

/// Sets up default stubs for all datasource methods so mocktail returns
/// proper values instead of null.  Individual tests override specific
/// stubs with `when(...).thenAnswer(...)` as needed.
void _defaultStubs(
  MockFirebaseAuthDataSource auth,
  MockFirestoreDataSource firestore,
  MockWalletDataSource wallet,
  MockReferralDataSource referral,
  MockRewardFirestoreDataSource reward,
) {
  // ── FirebaseAuthDataSource ──
  when(() => auth.signOut()).thenAnswer((_) async {});
  when(() => auth.reloadUser()).thenAnswer((_) async {});
  when(() => auth.deleteUser()).thenAnswer((_) async {});

  // ── FirebaseFirestoreDataSource ──
  when(() => firestore.getUser(any())).thenAnswer((_) async => null);
  when(() => firestore.getUserByEmail(any())).thenAnswer((_) async => null);
  when(() => firestore.getUserByPhone(any())).thenAnswer((_) async => null);
  when(() => firestore.getUserByReferralCode(any())).thenAnswer((_) async => null);
  when(() => firestore.isReferralCodeTaken(any())).thenAnswer((_) async => false);
  when(() => firestore.createUser(any())).thenAnswer((_) async {});
  when(() => firestore.deleteUser(any())).thenAnswer((_) async {});
  when(() => firestore.updateUser(any())).thenAnswer((_) async {});

  // ── WalletFirestoreDataSource ──
  when(() => wallet.getWallet(any())).thenAnswer((_) async => null);
  when(() => wallet.createWallet(any())).thenAnswer((_) async {});
  when(() => wallet.deleteWallet(any())).thenAnswer((_) async {});
  when(() => wallet.getAllTransactions(any())).thenAnswer((_) async => []);
  when(() => wallet.createTransaction(any())).thenAnswer((_) async {});
  when(() => wallet.getTransactions(any())).thenAnswer((_) async => []);

  // ── ReferralFirestoreDataSource ──
  when(() => referral.getReferralsByReferrer(any())).thenAnswer((_) async => []);
  when(() => referral.getReferralsByReferred(any())).thenAnswer((_) async => []);
  when(() => referral.createReferral(any())).thenAnswer((_) async {});
  when(() => referral.hasUserBeenReferred(any())).thenAnswer((_) async => false);
  when(() => referral.getRewardConfig()).thenAnswer((_) async => null);

  // ── RewardFirestoreDataSource ──
  when(() => reward.createReward(any())).thenAnswer((_) async {});
}

// ─── Test Data Builders ─────────────────────────────────────

UserModel createUserModel({
  required String uid,
  String email = 'test@test.com',
  String? phone,
  double balance = 100.0,
}) {
  return UserModel(
    uid: uid,
    fullName: 'Test User',
    email: email,
    phone: phone,
    referralCode: 'TEST1234',
    createdAt: DateTime.now(),
    walletBalance: balance,
    totalEarnings: balance,
    isEmailVerified: false,
  );
}

WalletModel createWalletModel({
  required String userId,
  double balance = 100.0,
}) {
  return WalletModel(
    userId: userId,
    walletBalance: balance,
    totalEarnings: balance,
    totalWithdrawn: 0,
    updatedAt: DateTime.now(),
  );
}

TransactionModel createTransactionModel({
  required String userId,
  required String transactionId,
  double amount = 50.0,
}) {
  return TransactionModel(
    transactionId: transactionId,
    userId: userId,
    type: TransactionType.credit,
    amount: amount,
    source: TransactionSource.referral,
    status: TransactionStatus.completed,
    description: 'Test transaction',
    createdAt: DateTime.now(),
  );
}

ReferralModel createReferralModel({
  required String referralId,
  required String referrerUserId,
  required String referredUserId,
  double rewardAmount = 10.0,
}) {
  return ReferralModel(
    referralId: referralId,
    referrerUserId: referrerUserId,
    referredUserId: referredUserId,
    referralCode: 'REFCODE',
    rewardAmount: rewardAmount,
    status: ReferralStatus.completed,
    createdAt: DateTime.now(),
  );
}

void main() {
  late MockFirebaseAuthDataSource mockAuthDataSource;
  late MockFirestoreDataSource mockFirestoreDataSource;
  late MockWalletDataSource mockWalletDataSource;
  late MockReferralDataSource mockReferralDataSource;
  late MockRewardFirestoreDataSource mockRewardDataSource;
  late AuthRepositoryImpl authRepo;

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
    ));
    registerFallbackValue(RewardModel(
      rewardId: '', userId: '', rewardType: RewardType.bonus,
      rewardAmount: 0, status: RewardStatus.claimed, createdAt: DateTime.now(),
    ));
  });

  setUp(() {
    mockAuthDataSource = MockFirebaseAuthDataSource();
    mockFirestoreDataSource = MockFirestoreDataSource();
    mockWalletDataSource = MockWalletDataSource();
    mockReferralDataSource = MockReferralDataSource();
    mockRewardDataSource = MockRewardFirestoreDataSource();
    _defaultStubs(mockAuthDataSource, mockFirestoreDataSource,
        mockWalletDataSource, mockReferralDataSource, mockRewardDataSource);
    authRepo = AuthRepositoryImpl(
      authDataSource: mockAuthDataSource,
      firestoreDataSource: mockFirestoreDataSource,
      walletDataSource: mockWalletDataSource,
      referralDataSource: mockReferralDataSource,
      rewardDataSource: mockRewardDataSource,
    );
  });

  group('Phone → Google account linking migration', () {
    const oldUid = 'phone-old-uid';
    const newUid = 'google-new-uid';
    const userEmail = 'existing@test.com';

    setUp(() {
      // Google credential
      final mockUser = MockUser();
      when(() => mockUser.uid).thenReturn(newUid);
      when(() => mockUser.email).thenReturn(userEmail);
      when(() => mockUser.displayName).thenReturn('Google User');
      when(() => mockUser.phoneNumber).thenReturn(null);
      when(() => mockUser.emailVerified).thenReturn(false);

      final mockCredential = MockUserCredential();
      when(() => mockCredential.user).thenReturn(mockUser);

      when(() => mockAuthDataSource.signInWithGoogle())
          .thenAnswer((_) async => mockCredential);

      // Existing phone user in Firestore by email
      when(() => mockFirestoreDataSource.getUserByEmail(userEmail))
          .thenAnswer((_) async => createUserModel(
                uid: oldUid, email: userEmail, phone: '+919876543210', balance: 250.0));

      // Existing wallet for old UID
      when(() => mockWalletDataSource.getWallet(oldUid))
          .thenAnswer((_) async => createWalletModel(userId: oldUid, balance: 250.0));

      // Existing transactions
      when(() => mockWalletDataSource.getAllTransactions(oldUid))
          .thenAnswer((_) async => [
            createTransactionModel(userId: oldUid, transactionId: 'txn-1', amount: 100.0),
            createTransactionModel(userId: oldUid, transactionId: 'txn-2', amount: 50.0),
          ]);

      // Referrals where old user was referrer (2)
      when(() => mockReferralDataSource.getReferralsByReferrer(oldUid))
          .thenAnswer((_) async => [
            createReferralModel(
              referralId: 'ref-1', referrerUserId: oldUid, referredUserId: 'other-1'),
            createReferralModel(
              referralId: 'ref-2', referrerUserId: oldUid, referredUserId: 'other-2'),
          ]);

      // Referrals where old user was referred (1)
      when(() => mockReferralDataSource.getReferralsByReferred(oldUid))
          .thenAnswer((_) async => [
            createReferralModel(
              referralId: 'ref-3', referrerUserId: 'inviter-1', referredUserId: oldUid),
          ]);
    });

    test('migrates user doc, wallet, transactions, and referrals', () async {
      await authRepo.signInWithGoogle();

      // User doc created with new UID
      verify(() => mockFirestoreDataSource.createUser(
        any(that: predicate<UserModel>((u) => u.uid == newUid)),
      )).called(1);

      // Wallet migrated to new UID, old deleted
      verify(() => mockWalletDataSource.createWallet(
        any(that: predicate<WalletModel>((w) => w.userId == newUid && w.walletBalance == 250.0)),
      )).called(1);
      verify(() => mockWalletDataSource.deleteWallet(oldUid)).called(1);

      // Both transactions migrated with new userId
      verify(() => mockWalletDataSource.createTransaction(
        any(that: predicate<TransactionModel>((t) => t.userId == newUid)),
      )).called(2);

      // Referrals updated (2 as referrer)
      verify(() => mockReferralDataSource.createReferral(
        any(that: predicate<ReferralModel>((r) =>
            r.referrerUserId == newUid && r.referredUserId == 'other-1')),
      )).called(1);
      verify(() => mockReferralDataSource.createReferral(
        any(that: predicate<ReferralModel>((r) =>
            r.referrerUserId == newUid && r.referredUserId == 'other-2')),
      )).called(1);

      // 1 as referred
      verify(() => mockReferralDataSource.createReferral(
        any(that: predicate<ReferralModel>((r) =>
            r.referredUserId == newUid && r.referrerUserId == 'inviter-1')),
      )).called(1);

      // Old user doc deleted
      verify(() => mockFirestoreDataSource.deleteUser(oldUid)).called(1);
    });
  });

  group('Migration no-ops for fresh sign-ins', () {
    setUp(() {
      // Google credential
      final googleUser = MockUser();
      when(() => googleUser.uid).thenReturn('google-new-uid');
      when(() => googleUser.email).thenReturn('new@test.com');
      when(() => googleUser.displayName).thenReturn('New User');
      when(() => googleUser.phoneNumber).thenReturn(null);
      when(() => googleUser.emailVerified).thenReturn(false);

      final googleCred = MockUserCredential();
      when(() => googleCred.user).thenReturn(googleUser);
      when(() => mockAuthDataSource.signInWithGoogle())
          .thenAnswer((_) async => googleCred);

    });

    test('fresh Google sign-in creates new user doc and wallet', () async {
      await authRepo.signInWithGoogle();

      verify(() => mockFirestoreDataSource.createUser(any())).called(1);
      verify(() => mockWalletDataSource.createWallet(
        any(that: predicate<WalletModel>((w) => w.walletBalance == 0.0)),
      )).called(1);
      verifyNever(() => mockFirestoreDataSource.deleteUser(any()));
    });

  });
}
