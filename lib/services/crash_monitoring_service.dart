import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Service for crash reporting and error monitoring via Firebase Crashlytics.
///
/// Note: Crashlytics is not supported on Flutter Web. On web, this service
/// will gracefully degrade and simply log errors to the console.
class CrashMonitoringService {
  static final CrashMonitoringService _instance = CrashMonitoringService._();
  factory CrashMonitoringService() => _instance;
  CrashMonitoringService._();

  bool _initialized = false;

  /// Whether the current platform supports Crashlytics
  bool get _isSupported => !kIsWeb;

  /// Initialize Crashlytics with error handling
  Future<void> initialize() async {
    if (_initialized) return;

    if (!_isSupported) {
      // Crashlytics is not supported on web, just log errors to console
      FlutterError.onError = (errorDetails) {
        FlutterError.dumpErrorToConsole(errorDetails);
      };
      _initialized = true;
      debugPrint('CrashMonitoringService: Crashlytics not supported on web, using console logging');
      return;
    }

    try {
      // Pass all unhandled errors to Crashlytics
      FlutterError.onError = (errorDetails) {
        FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
      };

      // Pass all platform errors to Crashlytics
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };

      // Set user identifier when available
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
      _initialized = true;
      debugPrint('CrashMonitoringService initialized');
    } catch (e) {
      debugPrint('Failed to initialize Crashlytics: $e');
    }
  }

  /// Set the current user ID for crash reports
  Future<void> setUserId(String userId) async {
    if (!_isSupported) return;
    try {
      await FirebaseCrashlytics.instance.setUserIdentifier(userId);
    } catch (_) {}
  }

  /// Log a custom key-value pair for debugging crashes
  Future<void> setCustomKey(String key, String value) async {
    if (!_isSupported) return;
    try {
      await FirebaseCrashlytics.instance.setCustomKey(key, value);
    } catch (_) {}
  }

  /// Log a non-fatal error
  Future<void> logError({
    required String message,
    dynamic error,
    StackTrace? stackTrace,
  }) async {
    if (!_isSupported) {
      debugPrint('CrashMonitoringService error: $message');
      return;
    }
    try {
      await FirebaseCrashlytics.instance.recordError(
        error ?? message,
        stackTrace,
        reason: message,
      );
    } catch (_) {}
  }

  /// Log a custom message to Crashlytics
  Future<void> log(String message) async {
    if (!_isSupported) return;
    try {
      await FirebaseCrashlytics.instance.log(message);
    } catch (_) {}
  }
}
