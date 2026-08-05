import 'package:cashspark/data/models/scratch_card_model.dart';
import 'package:cashspark/domain/repositories/scratch_card_repository.dart';
import 'package:cashspark/presentation/providers/scratch_card_provider.dart';
import 'package:cashspark/services/admob_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/mock_ad_service.dart';

class MockScratchCardRepository extends Mock implements ScratchCardRepository {}

/// Records which rewarded-ad method was invoked so tests can verify the
/// scratch-card flow uses the rewarded INTERSTITIAL unit, not the plain
/// rewarded unit (which remains in use by Watch & Earn).
class _RecordingAdService extends MockAdService {
  bool interstitialCalled = false;
  bool standardRewardedCalled = false;

  @override
  Future<double?> showRewardedInterstitialAd() async {
    interstitialCalled = true;
    return 1.0; // ad fully completed
  }

  @override
  Future<double?> showRewardedAd() async {
    standardRewardedCalled = true;
    return null;
  }
}

void main() {
  late MockScratchCardRepository repo;

  setUpAll(() {
    registerFallbackValue(ScratchCardModel(
      scratchCardId: '',
      userId: '',
      submissionId: '',
      rewardAmount: 0.0,
      isUsed: false,
      createdAt: DateTime.now(),
    ));
  });

  setUp(() {
    repo = MockScratchCardRepository();
    when(() => repo.createScratchCard(any())).thenAnswer((_) async {});
  });

  tearDown(AdMobServiceImpl.resetInstance);

  group('ScratchCardProvider.earnScratchCardFromAd', () {
    test('uses the rewarded interstitial ad and creates a card on completion', () async {
      final ad = _RecordingAdService();
      AdMobServiceImpl.setInstance(ad);

      final provider = ScratchCardProvider(scratchCardRepository: repo);
      final success = await provider.earnScratchCardFromAd('user-1');

      expect(ad.interstitialCalled, isTrue,
          reason: 'scratch cards should use the rewarded interstitial ad unit');
      expect(ad.standardRewardedCalled, isFalse);
      expect(success, isTrue);
      verify(() => repo.createScratchCard(any())).called(1);
    });

    test('does not create a card when the ad is skipped or fails', () async {
      // MockAdService returns null → treated as skipped/failed.
      AdMobServiceImpl.setInstance(MockAdService());

      final provider = ScratchCardProvider(scratchCardRepository: repo);
      final success = await provider.earnScratchCardFromAd('user-1');

      expect(success, isFalse);
      verifyNever(() => repo.createScratchCard(any()));
    });
  });
}
