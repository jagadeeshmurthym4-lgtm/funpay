import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Service for crash reporting and error monitoring via Firebase Crashlytics.
///
/// On web, gracefully degrades to console logging.
/// All error handlers are wrapped in try-catch to prevent handler crashes from
/// propagating and causing ClientException / unhandled error crashes.
class CrashMonitoringService {
  static final CrashMonitoringService _instance = CrashMonitoringService._();
  factory CrashMonitoringService() => _instance;
  CrashMonitoringService._();

  bool _initialized = false;

  /// Whether the current platform supports Crashlytics
  bool get _isSupported => !kIsWeb;

  /// Initialize Crashlytics with safe error handling.
  /// All error callbacks are wrapped to prevent crashes in the handler itself.
  Future<void> initialize() async {
    if (_initialized) return;

    if (!_isSupported) {
      FlutterError.onError = (errorDetails) {
        try {
          FlutterError.dumpErrorToConsole(errorDetails);
        } catch (_) {
          // Last-resort safety — never crash in the error handler
        }
      };
      _initialized = true;
      debugPrint('CrashMonitoringService: Crashlytics not supported on web, using console logging');
      return;
    }

    try {
      // ── Flutter framework errors ──────────────────────────
      // Catch all Flutter errors (RenderFlex, RenderBox, Provider, etc.)
      // and forward to Crashlytics. The handler itself is wrapped in try-catch
      // to prevent infinite crash loops.
      FlutterError.onError = (errorDetails) {
        try {
          FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
        } catch (reportError) {
          // Crashlytics itself failed to report — fall back to console
          try {
            FlutterError.dumpErrorToConsole(errorDetails);
            debugPrint('CrashMonitoringService: Crashlytics report failed: $reportError');
          } catch (_) {}
        }
      };

      // ── Platform / Dart errors ────────────────────────────
      // Catch unhandled async errors, format errors, and native crashes.
      // Wrapped in try-catch to prevent the error handler itself from crashing.
      PlatformDispatcher.instance.onError = (error, stack) {
        try {
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        } catch (reportError) {
          try {
            debugPrint('CrashMonitoringService: Platform error handler failed: $reportError');
            debugPrint('Original error: $error');
            debugPrint('Stack: $stack');
          } catch (_) {}
        }
        // Return true to indicate the error was handled (prevents app termination
        // on web, but on mobile the app may still terminate for fatal errors).
        return true;
      };

      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
      _initialized = true;
      debugPrint('CrashMonitoringService initialized');
    } catch (e) {
      // If Crashlytics fails to initialize (e.g. on emulators without Play Services),
      // fall back to basic console error logging so the app still works.
      try {
        FlutterError.onError = (errorDetails) {
          try {
            FlutterError.dumpErrorToConsole(errorDetails);
          } catch (_) {}
        };
      } catch (_) {}
      debugPrint('CrashMonitoringService: Init failed (non-fatal): $e');
    }
  }

  /// Set the current user ID for crash reports
  Future<void> setUserId(String userId) async {
    if (!_isSupported || !_initialized) return;
    try {
      await FirebaseCrashlytics.instance.setUserIdentifier(userId);
    } catch (_) {}
  }

  /// Log a custom key-value pair for debugging crashes
  Future<void> setCustomKey(String key, String value) async {
    if (!_isSupported || !_initialized) return;
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
