/// Non-web stub — AdSense display ads are only injected on the web build.
///
/// Returning null tells [AdSenseBanner] to render nothing on mobile platforms
/// and inside the Dart VM test environment.
String? registerAdBanner(String clientId, String adSlot) => null;
