import 'package:cashspark/domain/entities/referral_entity.dart';
import 'package:cashspark/domain/entities/referral_reward_config_entity.dart';
import 'package:cashspark/presentation/providers/referral_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/mock_repositories.dart';

void main() {
  late MockReferralRepository mockRepository;
  late ReferralProvider provider;

  setUp(() {
    mockRepository = MockReferralRepository();
    provider = ReferralProvider(referralRepository: mockRepository);
  });

  tearDown(() {
    provider.dispose();
  });

  group('initial state', () {
    test('referrals empty, config null, count 0, earnings 0, not loading',
        () async {
      expect(provider.referrals, isEmpty);
      expect(provider.rewardConfig, isNull);
      expect(provider.referralCount, 0);
      expect(provider.totalEarnings, 0.0);
      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, isNull);
    });
  });

  group('loadReferrals', () {
    final referrals = [
      ReferralEntity(
        referralId: 'r1',
        referrerUserId: 'user-1',
        referredUserId: 'referred-1',
        referralCode: 'CODE1',
        rewardAmount: 10.0,
        status: ReferralStatus.completed,
        createdAt: DateTime(2025, 1, 1),
      ),
      ReferralEntity(
        referralId: 'r2',
        referrerUserId: 'user-1',
        referredUserId: 'referred-2',
        referralCode: 'CODE2',
        rewardAmount: 20.0,
        status: ReferralStatus.completed,
        createdAt: DateTime(2025, 1, 2),
      ),
    ];

    testWidgets('loads referrals, count, and earnings', (tester) async {
      mockRepository.setReferrals(referrals);

      await provider.loadReferrals('user-1');

      expect(provider.referrals, hasLength(2));
      expect(provider.referralCount, 2);
      expect(provider.totalEarnings, 30.0);
      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, isNull);
    });

    testWidgets('sets loading state while loading', (tester) async {
      mockRepository.setReferrals(referrals);

      final future = provider.loadReferrals('user-1');
      expect(provider.isLoading, isTrue);
      await future;
      expect(provider.isLoading, isFalse);
    });

    testWidgets('handles generic error', (tester) async {
      mockRepository.setShouldThrow(true);

      await provider.loadReferrals('user-1');

      expect(provider.referrals, isEmpty);
      expect(provider.errorMessage, 'Failed to load referrals');
      expect(provider.isLoading, isFalse);
    });

    testWidgets('handles FirestoreException', (tester) async {
      mockRepository.setShouldThrowFirestore(true);

      await provider.loadReferrals('user-1');

      expect(provider.errorMessage, 'Permission denied');
      expect(provider.isLoading, isFalse);
    });
  });

  group('loadRewardConfig', () {
    const config = ReferralRewardConfigEntity(
      id: 'config-1',
      referrerBonus: 15.0,
      referredBonus: 5.0,
      isActive: true,
    );

    testWidgets('loads reward config successfully', (tester) async {
      mockRepository.setRewardConfig(config);

      await provider.loadRewardConfig();

      expect(provider.rewardConfig, equals(config));
    });

    testWidgets('silently fails on error (uses default config)', (tester) async {
      mockRepository.setShouldThrowOnRewardConfig(true);

      // Should not throw, just silently fail
      await provider.loadRewardConfig();

      expect(provider.rewardConfig, isNull);
      expect(provider.errorMessage, isNull);
    });
  });

  group('listenToReferrals', () {
    final referrals = [
      ReferralEntity(
        referralId: 'r1',
        referrerUserId: 'user-1',
        referredUserId: 'referred-1',
        referralCode: 'CODE1',
        rewardAmount: 10.0,
        status: ReferralStatus.completed,
        createdAt: DateTime(2025, 1, 1),
      ),
      ReferralEntity(
        referralId: 'r2',
        referrerUserId: 'user-1',
        referredUserId: 'referred-2',
        referralCode: 'CODE2',
        rewardAmount: 20.0,
        status: ReferralStatus.completed,
        createdAt: DateTime(2025, 1, 2),
      ),
    ];

    testWidgets('streams referrals and computes count and earnings',
        (tester) async {
      provider.listenToReferrals('user-1');

      mockRepository.emitReferrals(referrals);
      await tester.pump();

      expect(provider.referrals, hasLength(2));
      expect(provider.referralCount, 2);
      expect(provider.totalEarnings, 30.0);
      expect(provider.errorMessage, isNull);
    });

    testWidgets('streams empty list', (tester) async {
      provider.listenToReferrals('user-1');

      mockRepository.emitReferrals([]);
      await tester.pump();

      expect(provider.referrals, isEmpty);
      expect(provider.referralCount, 0);
      expect(provider.totalEarnings, 0.0);
    });

    testWidgets('handles stream error', (tester) async {
      provider.listenToReferrals('user-1');

      mockRepository.emitReferralsError(Exception('Stream error'));
      await tester.pump();

      expect(provider.errorMessage, 'Exception: Stream error');
    });

    testWidgets('replaces previous subscription when called again',
        (tester) async {
      final batch1 = [
        ReferralEntity(
          referralId: 'r1',
          referrerUserId: 'user-1',
          referredUserId: 'referred-1',
          referralCode: 'CODE1',
          rewardAmount: 10.0,
          status: ReferralStatus.completed,
          createdAt: DateTime(2025, 1, 1),
        ),
      ];
      final batch2 = [
        ReferralEntity(
          referralId: 'r2',
          referrerUserId: 'user-1',
          referredUserId: 'referred-2',
          referralCode: 'CODE2',
          rewardAmount: 20.0,
          status: ReferralStatus.completed,
          createdAt: DateTime(2025, 1, 2),
        ),
      ];

      provider.listenToReferrals('user-1');
      mockRepository.emitReferrals(batch1);
      await tester.pump();
      expect(provider.referralCount, 1);

      provider.listenToReferrals('user-1');
      mockRepository.emitReferrals(batch2);
      await tester.pump();
      expect(provider.referralCount, 1);
      expect(provider.referrals.first.referralId, 'r2');
    });
  });

  group('generateReferralLink', () {
    test('generates correct referral link', () async {
      final link = provider.generateReferralLink('ABC123');

      expect(link, 'https://cashspark.app/signup?ref=ABC123');
    });
  });

  group('clearError', () {
    testWidgets('clears error message', (tester) async {
      mockRepository.setShouldThrow(true);
      await provider.loadReferrals('user-1');
      expect(provider.errorMessage, isNotNull);

      provider.clearError();

      expect(provider.errorMessage, isNull);
    });
  });

  group('cancelSubscription', () {
    testWidgets('stops receiving stream updates after cancellation',
        (tester) async {
      final referrals = [
        ReferralEntity(
          referralId: 'r1',
          referrerUserId: 'user-1',
          referredUserId: 'referred-1',
          referralCode: 'CODE1',
          rewardAmount: 10.0,
          status: ReferralStatus.completed,
          createdAt: DateTime(2025, 1, 1),
        ),
      ];

      provider.listenToReferrals('user-1');
      provider.cancelSubscription();

      // Emit after cancellation — should NOT update
      mockRepository.emitReferrals(referrals);
      await tester.pump();

      expect(provider.referrals, isEmpty);
    });
  });

  group('dispose', () {
    testWidgets('stops receiving stream updates after cancelSubscription',
        (tester) async {
      final referrals = [
        ReferralEntity(
          referralId: 'r1',
          referrerUserId: 'user-1',
          referredUserId: 'referred-1',
          referralCode: 'CODE1',
          rewardAmount: 10.0,
          status: ReferralStatus.completed,
          createdAt: DateTime(2025, 1, 1),
        ),
      ];

      provider.listenToReferrals('user-1');
      provider.cancelSubscription();

      // Emit after cancellation — should NOT update
      mockRepository.emitReferrals(referrals);
      await tester.pump();

      expect(provider.referrals, isEmpty);
    });
  });
}
