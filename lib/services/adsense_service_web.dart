// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

int _viewCounter = 0;

/// Registers a platform view factory that renders an AdSense display ad.
///
/// Returns a unique `viewType` that [AdSenseBanner] passes to
/// `HtmlElementView`, or null if registration fails.
String? registerAdBanner(String clientId, String adSlot) {
  try {
    _viewCounter++;
    final viewType = 'adsense-banner-$_viewCounter';

    ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
      // Container div that fills the widget slot.
      final container = html.DivElement()
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.overflow = 'hidden';

      // The AdSense ad unit: <ins class="adsbygoogle" ...>...</ins>
      final ins = html.Element.tag('ins')
        ..className = 'adsbygoogle'
        ..style.display = 'block'
        ..setAttribute('data-ad-client', clientId)
        ..setAttribute('data-ad-slot', adSlot)
        // Horizontal format serves responsive 728x90 / 320x100 banner units
        // that fit the compact banner slots used on the landing/home screens.
        ..setAttribute('data-ad-format', 'horizontal')
        ..setAttribute('data-full-width-responsive', 'true');

      container.append(ins);

      // Trigger the ad request:
      //   (adsbygoogle = window.adsbygoogle || []).push({});
      // Push on a delay so the element is attached to the DOM first.
      Future<void>.delayed(const Duration(milliseconds: 150), () {
        try {
          final dynamic window = html.window;
          final adsbygoogle = (window['adsbygoogle'] ?? <dynamic>[])
              as List<dynamic>;
          adsbygoogle.add(<String, dynamic>{});
          window['adsbygoogle'] = adsbygoogle;
        } catch (_) {
          // Ad injection is best-effort — never crash the app for an ad.
        }
      });

      return container;
    });

    return viewType;
  } catch (_) {
    return null;
  }
}
