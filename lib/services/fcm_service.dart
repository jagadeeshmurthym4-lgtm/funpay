import 'dart:async';
import 'dart:convert';
import 'package:cashspark/core/constants/app_constants.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class FcmService {
  final FirebaseMessaging _messaging;
  final Function(String userId, String token)? onTokenRefresh;
  final Function(Map<String, dynamic> message)? onForegroundMessage;

  // Track subscriptions so we can cancel them before re-adding
  StreamSubscription? _tokenRefreshSubscription;
  StreamSubscription? _onMessageSubscription;
  StreamSubscription? _onMessageOpenedAppSubscription;
  bool _initialized = false;
  bool _disposed = false;

  FcmService({
    FirebaseMessaging? messaging,
    this.onTokenRefresh,
    this.onForegroundMessage,
  }) : _messaging = messaging ?? FirebaseMessaging.instance;

  /// Request notification permissions (iOS) — safe to call on all platforms.
  /// On Android 12- (API < 33), `requestPermission` is a no-op.
  Future<void> requestPermission() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      debugPrint('FCM permission: ${settings.authorizationStatus}');
    } catch (e) {
      // Gracefully handle permission failures (e.g. on very old Android versions)
      debugPrint('FCM requestPermission failed (non-fatal): $e');
    }
  }

  /// Get the current FCM token
  Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }

  /// Whether FCM has been initialized at least once.
  bool get isInitialized => _initialized;

  /// Initialize FCM: request permission, get token, set up listeners.
  /// Safe to call multiple times — old listeners are cancelled first.
  Future<String?> initialize() async {
    if (_disposed) return null;

    await requestPermission();
    if (_disposed) return null;

    // Get initial token
    final token = await getToken();
    if (_disposed) return token;

    // Cancel old subscriptions before creating new ones (prevent listener leaks)
    _cancelSubscriptions();

    // Listen for token refresh
    try {
      _tokenRefreshSubscription = _messaging.onTokenRefresh.listen((newToken) {
        if (_disposed) return;
        try {
          debugPrint('FCM token refreshed: $newToken');
          onTokenRefresh?.call('', newToken);
        } catch (e) {
          debugPrint('FCM onTokenRefresh handler error: $e');
        }
      });
    } catch (e) {
      debugPrint('FCM onTokenRefresh listener setup failed: $e');
    }

    // Handle foreground messages
    try {
      _onMessageSubscription =
          FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (_disposed) return;
        try {
          debugPrint('Foreground message: ${message.notification?.title}');
          onForegroundMessage?.call(message.data);
        } catch (e) {
          debugPrint('FCM onMessage handler error: $e');
        }
      });
    } catch (e) {
      debugPrint('FCM onMessage listener setup failed: $e');
    }

    // Handle when app is opened from a terminated state
    try {
      final initialMessage = await _messaging.getInitialMessage();
      if (_disposed) return token;
      if (initialMessage != null) {
        debugPrint(
            'App opened from terminated state: ${initialMessage.notification?.title}');
      }
    } catch (e) {
      debugPrint('FCM getInitialMessage failed: $e');
    }

    if (_disposed) return token;

    // Handle when app is opened from background
    try {
      _onMessageOpenedAppSubscription =
          FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        if (_disposed) return;
        try {
          debugPrint('App opened from background: ${message.notification?.title}');
        } catch (e) {
          debugPrint('FCM onMessageOpenedApp handler error: $e');
        }
      });
    } catch (e) {
      debugPrint('FCM onMessageOpenedApp listener setup failed: $e');
    }

    _initialized = true;
    return token;
  }

  /// Cancel all active stream subscriptions.
  void _cancelSubscriptions() {
    _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
    _onMessageSubscription?.cancel();
    _onMessageSubscription = null;
    _onMessageOpenedAppSubscription?.cancel();
    _onMessageOpenedAppSubscription = null;
  }

  /// Cancel all FCM listeners and reset initialization state.
  void dispose() {
    _disposed = true;
    _cancelSubscriptions();
    _initialized = false;
  }

  /// Set FCM token in Firebase (called when user signs in)
  Future<void> setUserIdForToken(String userId) async {
    if (_disposed || userId.isEmpty) return;
    // Subscribing to a topic based on userId for targeted notifications
    try {
      await _messaging.subscribeToTopic('user_$userId');
      await _messaging.subscribeToTopic('all_users');
    } catch (e) {
      debugPrint('Error subscribing to topics: $e');
    }
  }

  /// Remove user from topics (called when user signs out)
  Future<void> removeUserIdFromToken(String userId) async {
    if (_disposed || userId.isEmpty) return;
    try {
      await _messaging.unsubscribeFromTopic('user_$userId');
    } catch (e) {
      debugPrint('Error unsubscribing from topic: $e');
    }
  }

  /// Send an FCM push notification to the all_users topic via the CPX server.
  /// The CPX server (deployed on Render free tier) uses Firebase Admin SDK
  /// to send the push, so no Cloud Functions are needed.
  ///
  /// Gracefully handles the server not being deployed or unreachable.
  static Future<void> sendBroadcastPush({
    required String title,
    required String message,
    required String type,
  }) async {
    try {
      final url = Uri.parse('${AppConstants.backendUrl}/fcm/broadcast');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': AppConstants.fcmApiKey,
        },
        body: jsonEncode({
          'title': title,
          'message': message,
          'type': type,
        }),
      );
      if (response.statusCode == 200) {
        debugPrint('FCM push sent via CPX server: ${response.body}');
      } else {
        debugPrint(
            'FCM push failed (status ${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      // Log but don't fail — CPX server might not be deployed yet
      debugPrint(
          'Failed to send FCM push (is the CPX server running?): $e');
    }
  }

  /// Send an FCM push notification to a specific user's `user_{userId}` topic
  /// via the CPX server.
  ///
  /// Used for targeted notifications (e.g., bonus claimable, reward credited).
  /// Gracefully handles the server not being deployed or unreachable.
  static Future<void> sendTargetedPush({
    required String userId,
    required String title,
    required String message,
    required String type,
  }) async {
    try {
      final url = Uri.parse('${AppConstants.backendUrl}/fcm/targeted');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': AppConstants.fcmApiKey,
        },
        body: jsonEncode({
          'userId': userId,
          'title': title,
          'message': message,
          'type': type,
        }),
      );
      if (response.statusCode == 200) {
        debugPrint('FCM targeted push sent via CPX server: ${response.body}');
      } else {
        debugPrint(
            'FCM targeted push failed (status ${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      // Log but don't fail — CPX server might not be deployed yet
      debugPrint(
          'Failed to send targeted FCM push (is the CPX server running?): $e');
    }
  }
}
