import 'package:cashspark/services/ad_service.dart';

/// A no-op [AdService] that can be injected in tests to avoid
/// depending on the real Google Mobile Ads SDK.
///
/// All methods are safe no-ops — they return `false`, `null`, or `void`
/// and never schedule timers or make network calls.
class MockAdService implements AdService {
  @override
  Future<void> initialize() async {}

  @override
  void dispose() {}

  @override
  void setAppOpenEnabled(bool enabled) {}

  @override
  Future<bool> showAppOpenAd() async => false;

  @override
  bool get isAppOpenShowing => false;

  @override
  Future<void> loadRewardedAd() async {}

  @override
  Future<double?> showRewardedAd() async => null;

  @override
  bool get isRewardedReady => false;

  @override
  String? get lastError => null;

  @override
  bool get isAdReady => false;

  @override
  Future<void> loadRewardedInterstitialAd() async {}

  @override
  Future<double?> showRewardedInterstitialAd() async => null;

  @override
  bool get isRewardedInterstitialReady => false;

  @override
  Future<bool> loadNativeAd({int slot = 0}) async => false;

  @override
  dynamic getNativeAd(int slot) => null;

  @override
  void disposeNativeAd(int slot) {}

  @override
  Future<bool> showInterstitialAd() async => false;

  @override
  void createBannerAd() {}

  @override
  void setBannerVisible(bool visible) {}

  @override
  dynamic get bannerAd => null;
}
