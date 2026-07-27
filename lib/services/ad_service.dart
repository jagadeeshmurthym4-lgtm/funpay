/// Abstract interface for ad services (AdMob, test mocks, etc.).
///
/// All screens should depend on this interface rather than the concrete
/// [AdMobServiceImpl] so tests can inject a [MockAdService].
abstract class AdService {
  // ─── SDK Lifecycle ──────────────────────────────────────────

  /// Initialize the ad SDK and start preloading ads.
  Future<void> initialize();

  /// Dispose all ads and reset state.
  void dispose();

  // ─── App Open Ads ──────────────────────────────────────────

  /// Enable or disable App Open ads (must be disabled on auth screens).
  void setAppOpenEnabled(bool enabled);

  /// Try to show the preloaded App Open ad.
  /// Returns true if the ad was shown, false if none was ready or disabled.
  Future<bool> showAppOpenAd();

  /// Whether an App Open ad is currently being shown.
  bool get isAppOpenShowing;

  // ─── Rewarded Ads ──────────────────────────────────────────

  /// Load a rewarded ad.
  Future<void> loadRewardedAd();

  /// Show a rewarded ad. Returns the reward amount if user earns it, null otherwise.
  Future<double?> showRewardedAd();

  /// Whether a rewarded ad is ready to show.
  bool get isRewardedReady;

  /// Last error message from rewarded ad operations.
  String? get lastError;

  /// Legacy alias — whether a rewarded ad is ready.
  bool get isAdReady;

  // ─── Interstitial Ads ──────────────────────────────────────

  /// Show an interstitial ad. Returns true if the ad was shown.
  Future<bool> showInterstitialAd();

  // ─── Banner Ads ────────────────────────────────────────────

  /// Create and load a banner ad.
  void createBannerAd();

  /// Toggle banner visibility.
  void setBannerVisible(bool visible);

  /// The loaded banner ad (if any). Used with [AdWidget] for rendering.
  dynamic get bannerAd;
}
