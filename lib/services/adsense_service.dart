// AdSense display-ad injection for the web build.
//
// This service is a thin conditional-export wrapper:
// - On **web**, [registerAdBanner] creates a platform-view factory that injects
//   a real `<ins class="adsbygoogle">` element and triggers the `adsbygoogle`
//   push so Google renders the ad.
// - On **mobile / tests**, [registerAdBanner] returns null and the widget
//   renders nothing (Flutter apps don't show AdSense display ads natively).
library;

export 'adsense_service_stub.dart'
    if (dart.library.html) 'adsense_service_web.dart';
