import 'dart:async';

import 'package:cashspark/services/ad_service.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Production implementation of [AdService] backed by Google Mobile Ads.
///
/// Handles:
/// - **App Open Ads** — shown on app launch (never during auth screens or while other ads are visible)
/// - **Rewarded Ads** — auto-preload, exponential backoff retry, no duplicate rewards
/// - **Banner Ads** — responsive, auto-retry, no blank spaces
/// - **Interstitial Ads** — preload, show at natural transitions, auto-reload
///
/// Every callback from the Google Mobile Ads SDK is logged at debug level.
class AdMobServiceImpl implements AdService {
  // ─── Injectable instance ────────────────────────────────────
  static AdService? _instance;

  /// Returns the current [AdService] instance (creates a default one if none set).
  /// Tests can override this by calling [setInstance] with a [MockAdService].
  static AdService get instance {
    _instance ??= AdMobServiceImpl._internal();
    return _instance!;
  }

  /// Override the global [AdService] instance (e.g. with a mock in tests).
  static void setInstance(AdService service) {
    _instance = service;
  }

  /// Reset to default (production) implementation.
  static void resetInstance() {
    _instance = null;
  }

  // ─── Production Ad Unit IDs ────────────────────────────────
  static const String _productionRewardedId =
      'ca-app-pub-5256378460782254/8425897883';
  static const String _productionRewardedInterstitialId =
      'ca-app-pub-5256378460782254/5480149239';
  static const String _productionInterstitialId =
      'ca-app-pub-5256378460782254/8015043773';
  static const String _productionBannerId =
      'ca-app-pub-5256378460782254/6763717456';
  static const String _productionAppOpenId =
      'ca-app-pub-5256378460782254/7693655743';
  static const String _productionNativeAdId =
      'ca-app-pub-5256378460782254/3331784031';

  String get _rewardedAdUnitId => _productionRewardedId;
  String get _rewardedInterstitialAdUnitId => _productionRewardedInterstitialId;
  String get _interstitialAdUnitId => _productionInterstitialId;
  String get _bannerAdUnitId => _productionBannerId;
  String get _appOpenAdUnitId => _productionAppOpenId;
  String get _nativeAdUnitId => _productionNativeAdId;

  // ─── Ad instances ──────────────────────────────────────────
  RewardedAd? _rewardedAd;
  RewardedInterstitialAd? _rewardedInterstitialAd;
  InterstitialAd? _interstitialAd;
  BannerAd? _bannerAd;
  AppOpenAd? _appOpenAd;
  final Map<int, NativeAd> _nativeAds = {};

  // ─── Loading flags ─────────────────────────────────────────
  bool _isRewardedLoading = false;
  bool _isRewardedInterstitialLoading = false;
  bool _isInterstitialLoading = false;
  bool _isAppOpenLoading = false;
  final Map<int, bool> _isNativeLoading = {};

  // ─── Retry state ───────────────────────────────────────────
  int _rewardedRetryCount = 0;
  int _rewardedInterstitialRetryCount = 0;
  int _interstitialRetryCount = 0;
  int _appOpenRetryCount = 0;
  final Map<int, int> _nativeRetryCounts = {};
  static const int _maxRetries = 5;
  static const Duration _baseRetryDelay = Duration(seconds: 2);

  // ─── Error tracking ────────────────────────────────────────
  String? _lastRewardedError;

  // ─── Banner visibility ────────────────────────────────────
  bool _bannerVisible = true;

  // ─── App Open ad state ─────────────────────────────────────
  bool _isAppOpenShowing = false;
  bool _appOpenDisabled = false;

  AdMobServiceImpl._internal();

  // ─── Getters ───────────────────────────────────────────────
  @override
  bool get isRewardedReady => _rewardedAd != null;
  @override
  bool get isRewardedInterstitialReady => _rewardedInterstitialAd != null;
  @override
  String? get lastError => _lastRewardedError;
  @override
  bool get isAdReady => isRewardedReady;
  @override
  bool get isAppOpenShowing => _isAppOpenShowing;
  @override
  dynamic get bannerAd => _bannerAd;

  // ═══════════════════════════════════════════════════════════
  // SDK INITIALIZATION
  // ═══════════════════════════════════════════════════════════

  @override
  Future<void> initialize() async {
    _log('AdMob', 'Initializing SDK (PRODUCTION mode)');

    await MobileAds.instance.initialize();
    _log('AdMob', 'SDK initialized successfully');

    loadRewardedAd();
    loadRewardedInterstitialAd();
    loadInterstitialAd();
    if (!kIsWeb) {
      loadNativeAd(slot: 0); // Home screen slot — preload for instant display
    }

    _log('AdMob', 'Initial auto-load complete');
  }

  void _resetRetryCounters() {
    _rewardedRetryCount = 0;
    _rewardedInterstitialRetryCount = 0;
    _interstitialRetryCount = 0;
    _appOpenRetryCount = 0;
    _nativeRetryCounts.clear();
  }

  // ═══════════════════════════════════════════════════════════
  // 1. REWARDED ADS
  // ═══════════════════════════════════════════════════════════

  @override
  Future<void> loadRewardedAd() async {
    if (_isRewardedLoading) {
      _log('Rewarded', 'Already loading – skipping');
      return;
    }
    _isRewardedLoading = true;
    _lastRewardedError = null;

    await _rewardedAd?.dispose();
    _rewardedAd = null;

    final unitId = _rewardedAdUnitId;
    _log('Rewarded', 'Loading ad: $unitId');

    await RewardedAd.load(
      adUnitId: unitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedLoading = false;
          _rewardedRetryCount = 0;
          _lastRewardedError = null;
          _log('Rewarded', '✅ Loaded successfully');

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) {
              _log('Rewarded', '▶️ Ad showed full screen');
            },
            onAdDismissedFullScreenContent: (ad) {
              _log('Rewarded', '⏹️ Ad dismissed');
              ad.dispose();
              _rewardedAd = null;
              loadRewardedAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              _log('Rewarded', '❌ Failed to show: code=${error.code} msg=${error.message}');
              ad.dispose();
              _rewardedAd = null;
              _lastRewardedError = 'Failed to show: ${error.message}';
              _scheduleRewardedRetry();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _isRewardedLoading = false;
          _rewardedAd = null;
          _lastRewardedError = 'Load failed: code=${error.code} msg=${error.message}';
          _log('Rewarded', '⚠️ Load FAILED — code=${error.code} ${error.message}');
          _scheduleRewardedRetry();
        },
      ),
    );
  }

  void _scheduleRewardedRetry() {
    _rewardedRetryCount++;
    if (_rewardedRetryCount > _maxRetries) {
      _log('Rewarded', '⚠️ Max retries ($_maxRetries) reached. Giving up until next explicit load.');
      return;
    }
    final delay = Duration(
      seconds: _baseRetryDelay.inSeconds * (1 << (_rewardedRetryCount - 1)),
    );
    _log('Rewarded', 'Retry $_rewardedRetryCount/$_maxRetries in ${delay.inSeconds}s');
    Future.delayed(delay, () => loadRewardedAd());
  }

  @override
  Future<double?> showRewardedAd() async {
    final ad = _rewardedAd;
    if (ad == null) {
      _log('Rewarded', 'Show requested but no ad ready — auto-loading');
      loadRewardedAd();
      return null;
    }

    final completer = Completer<double?>();
    bool rewarded = false;
    double earnedAmount = 0.0;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _log('Rewarded', '▶️ Full screen content showed');
      },
      onAdDismissedFullScreenContent: (ad) {
        _log('Rewarded', '⏹️ Full screen dismissed. User was rewarded: $rewarded');
        if (!completer.isCompleted) {
          completer.complete(rewarded ? earnedAmount : null);
        }
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _log('Rewarded', '❌ Failed to show: ${error.message}');
        if (!completer.isCompleted) {
          completer.complete(null);
        }
        ad.dispose();
        _rewardedAd = null;
        _lastRewardedError = error.message;
        loadRewardedAd();
      },
    );

    ad.show(onUserEarnedReward: (ad, reward) {
      rewarded = true;
      earnedAmount = reward.amount.toDouble();
      _log('Rewarded', '💰 User earned reward! Type=${reward.type} Amount=${reward.amount}');
    });

    return completer.future;
  }

  // ═══════════════════════════════════════════════════════════
  // 1b. REWARDED INTERSTITIAL ADS
  // ═══════════════════════════════════════════════════════════

  @override
  Future<void> loadRewardedInterstitialAd() async {
    if (_isRewardedInterstitialLoading) {
      _log('RewardedInterstitial', 'Already loading – skipping');
      return;
    }
    _isRewardedInterstitialLoading = true;

    await _rewardedInterstitialAd?.dispose();
    _rewardedInterstitialAd = null;

    final unitId = _rewardedInterstitialAdUnitId;
    _log('RewardedInterstitial', 'Loading ad: $unitId');

    await RewardedInterstitialAd.load(
      adUnitId: unitId,
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedInterstitialAd = ad;
          _isRewardedInterstitialLoading = false;
          _rewardedInterstitialRetryCount = 0;
          _log('RewardedInterstitial', '✅ Loaded successfully');

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) {
              _log('RewardedInterstitial', '▶️ Ad showed full screen');
            },
            onAdDismissedFullScreenContent: (ad) {
              _log('RewardedInterstitial', '⏹️ Ad dismissed');
              ad.dispose();
              _rewardedInterstitialAd = null;
              loadRewardedInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              _log('RewardedInterstitial', '❌ Failed to show: code=${error.code} msg=${error.message}');
              ad.dispose();
              _rewardedInterstitialAd = null;
              _scheduleRewardedInterstitialRetry();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _isRewardedInterstitialLoading = false;
          _rewardedInterstitialAd = null;
          _log('RewardedInterstitial', '⚠️ Load FAILED — code=${error.code} ${error.message}');
          _scheduleRewardedInterstitialRetry();
        },
      ),
    );
  }

  void _scheduleRewardedInterstitialRetry() {
    _rewardedInterstitialRetryCount++;
    if (_rewardedInterstitialRetryCount > _maxRetries) {
      _log('RewardedInterstitial', '⚠️ Max retries ($_maxRetries) reached. Giving up until next explicit load.');
      return;
    }
    final delay = Duration(
      seconds: _baseRetryDelay.inSeconds * (1 << (_rewardedInterstitialRetryCount - 1)),
    );
    _log('RewardedInterstitial', 'Retry $_rewardedInterstitialRetryCount/$_maxRetries in ${delay.inSeconds}s');
    Future.delayed(delay, () => loadRewardedInterstitialAd());
  }

  @override
  Future<double?> showRewardedInterstitialAd() async {
    var ad = _rewardedInterstitialAd;
    if (ad == null) {
      _log('RewardedInterstitial', 'Show requested but no ad ready — loading first');
      loadRewardedInterstitialAd();
      // Wait briefly for the load so the first tap succeeds even when the ad
      // was torn down by another screen (e.g. leaving Watch & Earn disposes
      // all ads). Falls back to null after a timeout so the UI never hangs.
      final deadline = DateTime.now().add(const Duration(seconds: 15));
      while (_rewardedInterstitialAd == null && DateTime.now().isBefore(deadline)) {
        await Future.delayed(const Duration(milliseconds: 250));
      }
      ad = _rewardedInterstitialAd;
      if (ad == null) {
        _log('RewardedInterstitial', 'Ad still not ready after waiting');
        return null;
      }
    }

    final completer = Completer<double?>();
    bool rewarded = false;
    double earnedAmount = 0.0;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _log('RewardedInterstitial', '▶️ Full screen content showed');
      },
      onAdDismissedFullScreenContent: (ad) {
        _log('RewardedInterstitial', '⏹️ Full screen dismissed. User was rewarded: $rewarded');
        if (!completer.isCompleted) {
          completer.complete(rewarded ? earnedAmount : null);
        }
        ad.dispose();
        _rewardedInterstitialAd = null;
        loadRewardedInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _log('RewardedInterstitial', '❌ Failed to show: ${error.message}');
        if (!completer.isCompleted) {
          completer.complete(null);
        }
        ad.dispose();
        _rewardedInterstitialAd = null;
        loadRewardedInterstitialAd();
      },
    );

    ad.show(onUserEarnedReward: (ad, reward) {
      rewarded = true;
      earnedAmount = reward.amount.toDouble();
      _log('RewardedInterstitial', '💰 User earned reward! Type=${reward.type} Amount=${reward.amount}');
    });

    return completer.future;
  }

  // ═══════════════════════════════════════════════════════════
  // 2. INTERSTITIAL ADS
  // ═══════════════════════════════════════════════════════════

  @override
  Future<bool> showInterstitialAd() async {
    final ad = _interstitialAd;
    if (ad == null) {
      _log('Interstitial', 'Show requested but no ad ready');
      loadInterstitialAd();
      return false;
    }
    ad.show();
    return true;
  }

  Future<void> loadInterstitialAd() async {
    if (_isInterstitialLoading) {
      _log('Interstitial', 'Already loading – skipping');
      return;
    }
    _isInterstitialLoading = true;

    await _interstitialAd?.dispose();
    _interstitialAd = null;

    final unitId = _interstitialAdUnitId;
    _log('Interstitial', 'Loading ad: $unitId');

    await InterstitialAd.load(
      adUnitId: unitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialLoading = false;
          _interstitialRetryCount = 0;
          _log('Interstitial', '✅ Loaded successfully');

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) {
              _log('Interstitial', '▶️ Ad showed full screen');
            },
            onAdDismissedFullScreenContent: (ad) {
              _log('Interstitial', '⏹️ Ad dismissed');
              ad.dispose();
              _interstitialAd = null;
              loadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              _log('Interstitial', '❌ Failed to show: ${error.message}');
              ad.dispose();
              _interstitialAd = null;
              _scheduleInterstitialRetry();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _isInterstitialLoading = false;
          _interstitialAd = null;
          _log('Interstitial', '⚠️ Load FAILED — code=${error.code} ${error.message}');
          _scheduleInterstitialRetry();
        },
      ),
    );
  }

  void _scheduleInterstitialRetry() {
    _interstitialRetryCount++;
    if (_interstitialRetryCount > _maxRetries) {
      _log('Interstitial', '⚠️ Max retries ($_maxRetries) reached.');
      return;
    }
    final delay = Duration(
      seconds: _baseRetryDelay.inSeconds * (1 << (_interstitialRetryCount - 1)),
    );
    _log('Interstitial', 'Retry $_interstitialRetryCount/$_maxRetries in ${delay.inSeconds}s');
    Future.delayed(delay, () => loadInterstitialAd());
  }

  // ═══════════════════════════════════════════════════════════
  // 3. BANNER ADS
  // ═══════════════════════════════════════════════════════════

  @override
  void createBannerAd() {
    if (!_bannerVisible) return;

    final ad = BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _log('Banner', '✅ Loaded successfully');
        },
        onAdFailedToLoad: (ad, error) {
          _log('Banner', '⚠️ Load FAILED — code=${error.code} ${error.message}');
          ad.dispose();
          _bannerAd = null;
          Future.delayed(const Duration(seconds: 30), () {
            if (_bannerVisible) createBannerAd();
          });
        },
        onAdOpened: (ad) => _log('Banner', '⏩ Opened'),
        onAdClosed: (ad) => _log('Banner', '⏹️ Closed'),
        onAdImpression: (ad) => _log('Banner', '👁️ Impression'),
      ),
    );

    ad.load();
    _bannerAd = ad;
    _log('Banner', 'Loading ad: $_bannerAdUnitId');
  }

  @override
  void setBannerVisible(bool visible) {
    _bannerVisible = visible;
    if (visible && _bannerAd == null) {
      createBannerAd();
    } else if (!visible && _bannerAd != null) {
      _bannerAd?.dispose();
      _bannerAd = null;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // 3b. NATIVE ADS
  // ═══════════════════════════════════════════════════════════

  @override
  Future<bool> loadNativeAd({int slot = 0}) async {
    if (_isNativeLoading[slot] ?? false) {
      _log('Native', 'Slot $slot already loading – skipping');
      return false;
    }
    if (_nativeAds.containsKey(slot)) {
      _log('Native', 'Slot $slot already loaded – skipping');
      return true;
    }
    _isNativeLoading[slot] = true;

    final unitId = _nativeAdUnitId;
    _log('Native', 'Slot $slot — loading ad: $unitId');

    final ad = NativeAd(
      adUnitId: unitId,
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium,
        cornerRadius: 16.0,
      ),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          _nativeAds[slot] = ad as NativeAd;
          _isNativeLoading[slot] = false;
          _nativeRetryCounts[slot] = 0;
          _log('Native', 'Slot $slot ✅ Loaded successfully');
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _isNativeLoading[slot] = false;
          _log('Native', 'Slot $slot ⚠️ Load FAILED — code=${error.code} ${error.message}');
          _scheduleNativeRetry(slot);
        },
      ),
    );

    await ad.load();
    return _nativeAds.containsKey(slot);
  }

  void _scheduleNativeRetry(int slot) {
    final retryCount = (_nativeRetryCounts[slot] ?? 0) + 1;
    _nativeRetryCounts[slot] = retryCount;
    if (retryCount > _maxRetries) {
      _log('Native', 'Slot $slot ⚠️ Max retries ($_maxRetries) reached. Giving up until next explicit load.');
      _nativeRetryCounts.remove(slot);
      return;
    }
    final delay = Duration(
      seconds: _baseRetryDelay.inSeconds * (1 << (retryCount - 1)),
    );
    _log('Native', 'Slot $slot Retry $retryCount/$_maxRetries in ${delay.inSeconds}s');
    Future.delayed(delay, () => loadNativeAd(slot: slot));
  }

  @override
  dynamic getNativeAd(int slot) => _nativeAds[slot];

  @override
  void disposeNativeAd(int slot) {
    final ad = _nativeAds.remove(slot);
    ad?.dispose();
    _isNativeLoading.remove(slot);
    _nativeRetryCounts.remove(slot);
    _log('Native', 'Slot $slot disposed');
  }

  // ═══════════════════════════════════════════════════════════
  // 4. APP OPEN ADS
  // ═══════════════════════════════════════════════════════════

  @override
  void setAppOpenEnabled(bool enabled) {
    _appOpenDisabled = !enabled;
    _log('AppOpen', enabled ? 'Enabled' : 'Disabled');
    if (enabled && _appOpenAd == null && !_isAppOpenLoading) {
      loadAppOpenAd();
    }
  }

  Future<void> loadAppOpenAd() async {
    if (_isAppOpenLoading || _appOpenDisabled) return;
    _isAppOpenLoading = true;

    await _appOpenAd?.dispose();
    _appOpenAd = null;

    final unitId = _appOpenAdUnitId;
    _log('AppOpen', 'Loading ad: $unitId');

    await AppOpenAd.load(
      adUnitId: unitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          _isAppOpenLoading = false;
          _appOpenRetryCount = 0;
          _log('AppOpen', '✅ Loaded successfully');

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) {
              _isAppOpenShowing = true;
              _log('AppOpen', '▶️ Ad showed full screen');
            },
            onAdDismissedFullScreenContent: (ad) {
              _isAppOpenShowing = false;
              _log('AppOpen', '⏹️ Ad dismissed');
              ad.dispose();
              _appOpenAd = null;
              if (!_appOpenDisabled) loadAppOpenAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              _isAppOpenShowing = false;
              _log('AppOpen', '❌ Failed to show: ${error.message}');
              ad.dispose();
              _appOpenAd = null;
              if (!_appOpenDisabled) _scheduleAppOpenRetry();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _isAppOpenLoading = false;
          _appOpenAd = null;
          _log('AppOpen', '⚠️ Load FAILED — code=${error.code} ${error.message}');
          if (!_appOpenDisabled) _scheduleAppOpenRetry();
        },
      ),
    );
  }

  void _scheduleAppOpenRetry() {
    _appOpenRetryCount++;
    if (_appOpenRetryCount > _maxRetries) {
      _log('AppOpen', '⚠️ Max retries ($_maxRetries) reached.');
      return;
    }
    final delay = Duration(
      seconds: _baseRetryDelay.inSeconds * (1 << (_appOpenRetryCount - 1)),
    );
    _log('AppOpen', 'Retry $_appOpenRetryCount/$_maxRetries in ${delay.inSeconds}s');
    Future.delayed(delay, () => loadAppOpenAd());
  }

  @override
  Future<bool> showAppOpenAd() async {
    if (_appOpenDisabled) {
      _log('AppOpen', 'Show requested but disabled — skipping');
      return false;
    }
    if (_isAppOpenShowing) {
      _log('AppOpen', 'Already showing — skipping');
      return false;
    }
    final ad = _appOpenAd;
    if (ad == null) {
      _log('AppOpen', 'Show requested but no ad ready — continuing without ad');
      loadAppOpenAd();
      return false;
    }
    ad.show();
    _log('AppOpen', '▶️ Ad shown');
    return true;
  }

  // ═══════════════════════════════════════════════════════════
  // UTILITY
  // ═══════════════════════════════════════════════════════════

  void _log(String tag, String message) {
    debugPrint('[AdMob][$tag] $message');
  }

  @override
  void dispose() {
    _log('AdMob', 'Disposing all ads...');
    _rewardedAd?.dispose();
    _rewardedAd = null;
    _rewardedInterstitialAd?.dispose();
    _rewardedInterstitialAd = null;
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _bannerAd?.dispose();
    _bannerAd = null;
    _appOpenAd?.dispose();
    _appOpenAd = null;
    for (final ad in _nativeAds.values) {
      ad.dispose();
    }
    _nativeAds.clear();

    _isRewardedLoading = false;
    _isRewardedInterstitialLoading = false;
    _isInterstitialLoading = false;
    _isAppOpenLoading = false;
    _isAppOpenShowing = false;
    _isNativeLoading.clear();
    _bannerVisible = true;
    _resetRetryCounters();
    _lastRewardedError = null;
  }
}
