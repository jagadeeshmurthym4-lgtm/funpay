import 'package:cashspark/core/theme/app_theme.dart';
import 'package:cashspark/services/admob_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Renders an AdMob native ad (template style) in a rounded card.
///
/// Native ads are **mobile-only** — this widget renders nothing on web
/// (the web build uses AdSense instead).
///
/// Each placement must use a distinct [slot] because a single `NativeAd`
/// instance can only be shown by one `AdWidget` at a time (and `MainShell`
/// keeps every tab alive via `IndexedStack`).
class NativeAdView extends StatefulWidget {
  const NativeAdView({super.key, required this.slot});

  /// Unique slot id for this placement. Must differ across screens that are
  /// alive at the same time.
  final int slot;

  @override
  State<NativeAdView> createState() => _NativeAdViewState();
}

class _NativeAdViewState extends State<NativeAdView> {
  bool _loaded = false;
  bool _requested = false;

  @override
  void initState() {
    super.initState();
    _request();
  }

  Future<void> _request() async {
    if (kIsWeb || _requested) return;
    _requested = true;
    final service = AdMobServiceImpl.instance;
    await service.loadNativeAd(slot: widget.slot);
    if (!mounted) return;

    // If the ad isn't ready yet (slot was already loading when we asked, or
    // the first attempt failed and a background retry is scheduled), wait
    // briefly for it to appear — same pattern as showRewardedInterstitialAd.
    // Only the real service polls; mock-based tests stay timer-free.
    if (service is AdMobServiceImpl && service.getNativeAd(widget.slot) == null) {
      final deadline = DateTime.now().add(const Duration(seconds: 15));
      while (mounted &&
          service.getNativeAd(widget.slot) == null &&
          DateTime.now().isBefore(deadline)) {
        await Future.delayed(const Duration(milliseconds: 250));
      }
    }
    if (!mounted) return;
    setState(() {
      _loaded = service.getNativeAd(widget.slot) != null;
    });
  }

  @override
  void dispose() {
    // Free the slot's ad when this placement is torn down (e.g. a pushed
    // screen, or switching Projects tabs which swaps list feeds). The service
    // re-loads on the next mount, and disposes everything on app shutdown.
    AdMobServiceImpl.instance.disposeNativeAd(widget.slot);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || !_loaded) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final NativeAd? ad = AdMobServiceImpl.instance.getNativeAd(widget.slot) as NativeAd?;
    if (ad == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isDark ? AppTheme.borderColor : const Color(0xFFCBD5E1))
              .withValues(alpha: 0.4),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: AdWidget(ad: ad),
    );
  }
}
