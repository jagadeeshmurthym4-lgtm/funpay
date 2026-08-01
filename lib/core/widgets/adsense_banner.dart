import 'package:cashspark/services/adsense_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Renders an AdSense display ad inside a fixed-height slot.
///
/// - On **web**: injects the real `<ins class="adsbygoogle">` unit via a
///   platform view and triggers the `adsbygoogle.push({})` request.
/// - On **mobile / tests**: renders nothing (`SizedBox.shrink`) so the app
///   looks identical on Android/iOS and existing widget tests keep passing.
class AdSenseBanner extends StatefulWidget {
  const AdSenseBanner({
    super.key,
    this.clientId = 'ca-pub-5256378460782254',
    this.adSlot,
    this.height = 90,
  });

  /// AdSense publisher client ID (`ca-pub-...`).
  final String clientId;

  /// AdSense ad slot ID (`data-ad-slot`). If null/empty, nothing renders.
  final String? adSlot;

  /// Reserved height for the ad container (recommended ≥ 90 for auto format).
  final double height;

  @override
  State<AdSenseBanner> createState() => _AdSenseBannerState();
}

class _AdSenseBannerState extends State<AdSenseBanner> {
  String? _viewType;

  @override
  void initState() {
    super.initState();
    final slot = widget.adSlot;
    if (kIsWeb && slot != null && slot.isNotEmpty) {
      _viewType = registerAdBanner(widget.clientId, slot);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewType = _viewType;
    if (!kIsWeb || viewType == null) {
      // Non-web or registration failed — show nothing.
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: widget.height),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
      ),
      child: HtmlElementView(viewType: viewType),
    );
  }
}
