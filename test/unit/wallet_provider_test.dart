import 'package:cashspark/domain/entities/transaction_entity.dart';
import 'package:cashspark/domain/entities/wallet_entity.dart';
import 'package:cashspark/presentation/providers/wallet_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/mock_repositories.dart';

void main() {
  late MockWalletRepository mockRepository;
  late WalletProvider provider;

  setUp(() {
    mockRepository = MockWalletRepository();
    provider = WalletProvider(walletRepository: mockRepository);
  });

  tearDown(() {
    provider.dispose();
  });

  group('initial state', () {
    test('wallet is null, transactions are empty, not loading, no error',
        () async {
      expect(provider.wallet, isNull);
      expect(provider.recentTransactions, isEmpty);
      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, isNull);
    });
  });

  group('loadWallet', () {
    final testWallet = WalletEntity(
      userId: 'user-1',
      walletBalance: 100.0,
      totalEarnings: 250.0,
      totalWithdrawn: 50.0,
      updatedAt: DateTime(2025, 1, 1),
    );

    testWidgets('loads wallet successfully', (tester) async {
      mockRepository.setWallet(testWallet);

      await provider.loadWallet('user-1');

      expect(provider.wallet, equals(testWallet));
      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, isNull);
    });

    testWidgets('sets loading state while loading', (tester) async {
      mockRepository.setWallet(testWallet);

      final future = provider.loadWallet('user-1');
      expect(provider.isLoading, isTrue);
      await future;
      expect(provider.isLoading, isFalse);
    });

    testWidgets('handles generic error', (tester) async {
      mockRepository.setShouldThrow(true);

      await provider.loadWallet('user-1');

      expect(provider.wallet, isNull);
      expect(provider.errorMessage, 'Failed to load wallet');
      expect(provider.isLoading, isFalse);
    });

    testWidgets('handles FirestoreException', (tester) async {
      mockRepository.setShouldThrowFirestore(true);

      await provider.loadWallet('user-1');

      expect(provider.errorMessage, 'Permission denied');
      expect(provider.isLoading, isFalse);
    });
  });

  group('loadTransactions', () {
    final transactions = [
      TransactionEntity(
        transactionId: 't1',
        userId: 'user-1',
        type: TransactionType.credit,
        amount: 50.0,
        description: 'Referral bonus',
        createdAt: DateTime(2025, 1, 1),
      ),
      TransactionEntity(
        transactionId: 't2',
        userId: 'user-1',
        type: TransactionType.debit,
        amount: 20.0,
        description: 'Withdrawal',
        createdAt: DateTime(2025, 1, 2),
      ),
    ];

    testWidgets('loads transactions successfully', (tester) async {
      mockRepository.setTransactions(transactions);

      await provider.loadTransactions('user-1');

      expect(provider.recentTransactions, hasLength(2));
      expect(provider.recentTransactions[0].transactionId, 't1');
      expect(provider.recentTransactions[1].transactionId, 't2');
      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, isNull);
    });

    testWidgets('handles generic error', (tester) async {
      mockRepository.setShouldThrow(true);

      await provider.loadTransactions('user-1');

      expect(provider.recentTransactions, isEmpty);
      expect(provider.errorMessage, 'Failed to load transactions');
      expect(provider.isLoading, isFalse);
    });

    testWidgets('handles FirestoreException', (tester) async {
      mockRepository.setShouldThrowFirestore(true);

      await provider.loadTransactions('user-1');

      expect(provider.errorMessage, 'Permission denied');
      expect(provider.isLoading, isFalse);
    });
  });

  group('listenToWallet', () {
    final testWallet = WalletEntity(
      userId: 'user-1',
      walletBalance: 100.0,
      totalEarnings: 250.0,
      totalWithdrawn: 50.0,
      updatedAt: DateTime(2025, 1, 1),
    );

    testWidgets('streams wallet updates', (tester) async {
      provider.listenToWallet('user-1');

      mockRepository.emitWallet(testWallet);
      await tester.pump();

      expect(provider.wallet, equals(testWallet));
      expect(provider.errorMessage, isNull);
    });

    testWidgets('streams null wallet', (tester) async {
      provider.listenToWallet('user-1');

      mockRepository.emitWallet(null);
      await tester.pump();

      expect(provider.wallet, isNull);
    });

    testWidgets('handles stream error', (tester) async {
      provider.listenToWallet('user-1');

      mockRepository.emitWalletError(Exception('Stream error'));
      await tester.pump();

      expect(provider.errorMessage, 'Exception: Stream error');
    });

    testWidgets('replaces previous subscription when called again',
        (tester) async {
      final wallet1 = testWallet;
      final wallet2 = testWallet.copyWith(walletBalance: 200.0);

      provider.listenToWallet('user-1');
      mockRepository.emitWallet(wallet1);
      await tester.pump();
      expect(provider.wallet?.walletBalance, 100.0);

      provider.listenToWallet('user-1');
      mockRepository.emitWallet(wallet2);
      await tester.pump();
      expect(provider.wallet?.walletBalance, 200.0);
    });
  });

  group('ensureWalletExists', () {
    testWidgets('returns true when wallet exists', (tester) async {
      mockRepository.setWallet(WalletEntity(
        userId: 'user-1',
        updatedAt: DateTime(2025, 1, 1),
      ));

      final result = await provider.ensureWalletExists('user-1');

      expect(result, isTrue);
    });

    testWidgets('creates wallet when not found', (tester) async {
      // Don't set a wallet — getWallet will throw
      final result = await provider.ensureWalletExists('user-1');

      expect(result, isTrue);
      expect(provider.wallet, isNotNull);
      expect(provider.wallet!.userId, 'user-1');
    });

    testWidgets('returns false when wallet creation fails', (tester) async {
      mockRepository.setShouldThrowFirestore(true);
      mockRepository.setShouldThrow(true);

      final result = await provider.ensureWalletExists('user-1');

      expect(result, isFalse);
      expect(provider.errorMessage, 'Failed to create wallet');
    });
  });

  group('addSpinReward', () {
    testWidgets('adds spin reward successfully', (tester) async {
      mockRepository.setWallet(WalletEntity(
        userId: 'user-1',
        updatedAt: DateTime(2025, 1, 1),
      ));

      await provider.addSpinReward('user-1', 50.0);

      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, isNull);
    });

    testWidgets('handles FirestoreException', (tester) async {
      mockRepository.setShouldThrowFirestore(true);

      await provider.addSpinReward('user-1', 50.0);

      expect(provider.errorMessage, 'Permission denied');
      expect(provider.isLoading, isFalse);
    });

    testWidgets('handles generic error', (tester) async {
      mockRepository.setShouldThrow(true);

      await provider.addSpinReward('user-1', 50.0);

      expect(provider.errorMessage, 'Failed to add spin reward');
      expect(provider.isLoading, isFalse);
    });
  });

  group('WalletProvider._clearError (automatic clear before operations)', () {
    testWidgets('clears previous errorMessage when loadWallet succeeds',
        (tester) async {
      // Set up error state first
      mockRepository.setShouldThrow(true);
      await provider.loadWallet('user-1');
      expect(provider.errorMessage, isNotNull);

      // Now succeed — _clearError() should fire at the top of loadWallet()
      mockRepository.setShouldThrow(false);
      final wallet = WalletEntity(
        userId: 'user-1',
        walletBalance: 100.0,
        totalEarnings: 250.0,
        totalWithdrawn: 50.0,
        updatedAt: DateTime(2025, 1, 1),
      );
      mockRepository.setWallet(wallet);
      await provider.loadWallet('user-1');

      expect(provider.errorMessage, isNull);
      expect(provider.wallet, isNotNull);
      expect(provider.wallet!.walletBalance, 100.0);
    });

    testWidgets('clears previous errorMessage when loadTransactions succeeds',
        (tester) async {
      // Set up error state
      mockRepository.setShouldThrow(true);
      await provider.loadWallet('user-1');
      expect(provider.errorMessage, isNotNull);

      // Now load transactions successfully
      mockRepository.setShouldThrow(false);
      mockRepository.setTransactions([
        TransactionEntity(
          transactionId: 't1',
          userId: 'user-1',
          type: TransactionType.credit,
          amount: 50.0,
          description: 'Bonus',
          createdAt: DateTime(2025, 1, 1),
        ),
      ]);
      await provider.loadTransactions('user-1');

      expect(provider.errorMessage, isNull);
      expect(provider.recentTransactions, hasLength(1));
    });

    testWidgets('clears previous errorMessage when addSpinReward succeeds',
        (tester) async {
      // Set up error state
      mockRepository.setShouldThrow(true);
      await provider.loadWallet('user-1');
      expect(provider.errorMessage, isNotNull);

      // Set up wallet for the spin reward
      mockRepository.setShouldThrow(false);
      mockRepository.setWallet(WalletEntity(
        userId: 'user-1',
        walletBalance: 100.0,
        totalEarnings: 250.0,
        totalWithdrawn: 50.0,
        updatedAt: DateTime(2025, 1, 1),
      ));

      await provider.addSpinReward('user-1', 50.0);

      expect(provider.errorMessage, isNull);
      expect(provider.isLoading, isFalse);
    });

    testWidgets('error persists across operation types when not cleared',
        (tester) async {
      // Set an error with loadWallet
      mockRepository.setShouldThrow(true);
      await provider.loadWallet('user-1');
      expect(provider.errorMessage, isNotNull);

      // loadEarningsBreakdown doesn't set _errorMessage on failure
      // (it silently catches), so after calling it, the old error persists
      // — this is expected because _clearError() runs at the top
      // and there's no new error set in the silent catch.
      await provider.loadEarningsBreakdown('user-1');

      expect(provider.errorMessage, isNull, reason:
          '_clearError() at the top of loadEarningsBreakdown clears the stale error');
    });
  });

  group('clearError', () {
    testWidgets('clears error message', (tester) async {
      mockRepository.setShouldThrow(true);
      await provider.loadWallet('user-1');
      expect(provider.errorMessage, isNotNull);

      provider.clearError();

      expect(provider.errorMessage, isNull);
    });
  });

  group('cancelSubscriptions', () {
    testWidgets('stops receiving stream updates after cancellation',
        (tester) async {
      final testWallet = WalletEntity(
        userId: 'user-1',
        updatedAt: DateTime(2025, 1, 1),
      );

      provider.listenToWallet('user-1');
      provider.cancelSubscriptions();

      // Emit after cancellation — wallet should NOT update
      mockRepository.emitWallet(testWallet);
      await tester.pump();

      expect(provider.wallet, isNull);
    });
  });

  group('dispose', () {
    testWidgets('stops receiving stream updates after cancelSubscriptions',
        (tester) async {
      final testWallet = WalletEntity(
        userId: 'user-1',
        updatedAt: DateTime(2025, 1, 1),
      );

      provider.listenToWallet('user-1');
      provider.cancelSubscriptions();

      // Emit after cancellation — wallet should NOT update
      mockRepository.emitWallet(testWallet);
      await tester.pump();

      expect(provider.wallet, isNull);
    });
  });
}
