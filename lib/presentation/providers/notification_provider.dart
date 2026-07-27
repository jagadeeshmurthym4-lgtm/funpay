import 'dart:async';
import 'package:cashspark/core/errors/exceptions.dart';
import 'package:cashspark/data/repositories/notification_repository_impl.dart';
import 'package:cashspark/domain/entities/notification_entity.dart';
import 'package:cashspark/services/fcm_service.dart';
import 'package:flutter/foundation.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationRepositoryImpl _notificationRepository;
  final FcmService _fcmService;
  StreamSubscription? _notificationSubscription;

  List<NotificationEntity> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _errorMessage;
  bool _notificationsEnabled = true;
  bool _promotionalEnabled = true;
  bool _rewardNotificationsEnabled = true;

  // Track whether FCM has been initialized (permission + listeners)
  bool _fcmInitialized = false;

  // ═══════════════════════════════════════════════════════════
  // Lifecycle safety — prevents FlutterError crashes
  // ═══════════════════════════════════════════════════════════

  /// Set to true once [dispose] is called. All [notifyListeners] calls
  /// are gated behind this flag to prevent the "A NotificationProvider was
  /// used after being disposed" FlutterError.
  bool _disposed = false;

  /// Debounce completer for [setUser]: if a call is already in-flight,
  /// subsequent calls will await the same result instead of starting a
  /// new operation. This prevents race conditions when `setUser()` is
  /// called from multiple widgets in the same frame.
  Completer<void>? _setUserCompleter;

  /// Guards against re-entering [clearUser] while an async clear is in-flight.
  bool _clearingUser = false;

  /// Safe wrapper around [notifyListeners] that skips the call if the
  /// provider has been disposed and wraps notifyListeners in a try-catch
  /// to prevent unhandled FlutterError crashes when async callbacks fire
  /// during or after widget disposal.
  void _safeNotifyListeners() {
    if (_disposed) return;
    try {
      notifyListeners();
    } catch (e) {
      // Swallow — this can happen if the widget tree is mid-disposal when
      // an async stream event fires. Logging so it's visible in debug builds.
      debugPrint('NotificationProvider._safeNotifyListeners suppressed: $e');
    }
  }

  NotificationProvider({
    required NotificationRepositoryImpl notificationRepository,
    FcmService? fcmService,
  })  : _notificationRepository = notificationRepository,
        _fcmService = fcmService ?? FcmService();

  List<NotificationEntity> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get promotionalEnabled => _promotionalEnabled;
  bool get rewardNotificationsEnabled => _rewardNotificationsEnabled;
  bool get hasUnread => _unreadCount > 0;

  /// Returns notifications grouped by type, ordered by most recent unread first.
  /// Groups with unread notifications appear before fully-read groups.
  List<NotificationGroup> get groupedNotifications {
    try {
      if (_notifications.isEmpty) return [];

      // Group by type
      final Map<NotificationType, List<NotificationEntity>> grouped = {};
      for (final n in _notifications) {
        grouped.putIfAbsent(n.type, () => []).add(n);
      }

      // Sort within each group by createdAt descending
      for (final list in grouped.values) {
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }

      // Build groups with metadata and sort: unread groups first, then by latest message
      final groups = grouped.entries.map((e) {
        final unreadCount = e.value.where((n) => !n.isRead).length;
        final latest = e.value.first.createdAt;
        return NotificationGroup(
          type: e.key,
          notifications: e.value,
          unreadCount: unreadCount,
          latestAt: latest,
        );
      }).toList();

      // Sort: unread groups first, then by latest message
      groups.sort((a, b) {
        // Unread groups first
        if (a.unreadCount > 0 && b.unreadCount == 0) return -1;
        if (a.unreadCount == 0 && b.unreadCount > 0) return 1;
        // Within same unread status, sort by latest message
        return b.latestAt.compareTo(a.latestAt);
      });

      return groups;
    } catch (e) {
      debugPrint('NotificationProvider.groupedNotifications error: $e');
      return [];
    }
  }

  /// Initialize FCM once at app startup (permissions, listeners, token).
  /// Safe to call multiple times — FcmService guards against re-init.
  Future<void> initializeFcm() async {
    if (_fcmInitialized) {
      debugPrint('NotificationProvider: FCM already initialized, skipping');
      return;
    }
    try {
      await _fcmService.initialize();
      _fcmInitialized = true;
      debugPrint('NotificationProvider: FCM initialized');
    } catch (e) {
      debugPrint('NotificationProvider: FCM init failed: $e');
      // Don't mark as initialized so we can retry
      _fcmInitialized = false;
    }
  }

  /// Set the current user for notifications: subscribe to FCM topics
  /// and start listening to Firestore notifications.
  /// Call this on login / auth state change.
  ///
  /// Safe to call multiple times — concurrent calls are debounced via
  /// [_setUserCompleter] so only one operation runs at a time.
  Future<void> setUser(String userId) async {
    if (userId.isEmpty || _disposed) return;

    // Debounce: if a setUser() is already in-flight, return the existing future
    if (_setUserCompleter != null) {
      debugPrint('NotificationProvider.setUser: already in progress, awaiting');
      return _setUserCompleter!.future;
    }
    _setUserCompleter = Completer<void>();

    _clearError();
    try {
      // Ensure FCM is initialized first
      if (!_fcmInitialized) {
        await initializeFcm();
        if (_disposed) return; // Bail if disposed during the async gap
      }

      // Get fresh token and subscribe to user topics
      // Even if getToken() returns null (e.g. permissions denied),
      // we still start listening to Firestore notifications below.
      try {
        final token = await _fcmService.getToken();
        if (_disposed) return;
        if (token != null && token.isNotEmpty) {
          await _notificationRepository.saveFcmToken(userId, token);
          await _fcmService.setUserIdForToken(userId);
        }
      } catch (e) {
        // Non-fatal: token operations can fail (network, permissions),
        // but Firestore notifications should still work.
        debugPrint('NotificationProvider.setUser: token ops failed: $e');
      }

      if (_disposed) return;

      // Start listening to Firestore notifications
      _listenToNotifications(userId);

      _setUserCompleter?.complete();
    } catch (e) {
      _errorMessage = 'Failed to initialize notifications';
      _safeNotifyListeners();
      try {
        _setUserCompleter?.completeError(e);
      } catch (_) {
        // Ignore if already completed
      }
    } finally {
      _setUserCompleter = null;
    }
  }

  /// Remove the current user from FCM topics.
  /// Call this on logout.
  Future<void> clearUser(String userId) async {
    if (userId.isEmpty || _disposed || _clearingUser) return;
    _clearingUser = true;
    try {
      await _fcmService.removeUserIdFromToken(userId);
    } catch (_) {
      // Non-fatal
    }
    try {
      if (_disposed) return;
      _notificationSubscription?.cancel();
      _notificationSubscription = null;
      _notifications = [];
      _unreadCount = 0;
      _safeNotifyListeners();
    } finally {
      _clearingUser = false;
    }
  }

  /// Initialize FCM and start listening for notifications (legacy).
  /// Still kept for backward compatibility with existing callers.
  Future<void> initialize(String userId) async {
    if (_disposed) return;
    _setLoading(true);
    await initializeFcm();
    if (_disposed) return;
    await setUser(userId);
    if (_disposed) return;
    _setLoading(false);
  }

  void _listenToNotifications(String userId) {
    try {
      _notificationSubscription?.cancel();
      _notificationSubscription =
          _notificationRepository.streamNotifications(userId).listen(
        (notifications) {
          if (_disposed) return;
          try {
            _notifications = notifications;
            _updateUnreadCount();
            _safeNotifyListeners();
          } catch (e) {
            debugPrint('NotificationProvider: stream data handler error: $e');
          }
        },
        onError: (error) {
          if (_disposed) return;
          debugPrint('NotificationProvider: stream error: $error');
          _errorMessage = error.toString();
          _safeNotifyListeners();
        },
        cancelOnError: false,
      );
    } catch (e) {
      debugPrint('NotificationProvider: failed to listen to notifications: $e');
      _errorMessage = 'Failed to listen to notifications';
      _safeNotifyListeners();
    }
  }

  /// Mark a single notification as read
  Future<void> markAsRead(String notificationId) async {
    if (_disposed) return;
    _clearError();
    try {
      await _notificationRepository.markAsRead(notificationId);
      // Update local state
      final index = _notifications.indexWhere(
          (n) => n.notificationId == notificationId);
      if (index != -1) {
        final updated = _notifications[index].copyWith(isRead: true);
        _notifications[index] = updated;
        _updateUnreadCount();
        _safeNotifyListeners();
      }
    } on FirestoreException catch (e) {
      _errorMessage = e.message;
      _safeNotifyListeners();
    } catch (e) {
      debugPrint('NotificationProvider.markAsRead error: $e');
      _errorMessage = 'Failed to mark notification as read';
      _safeNotifyListeners();
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    if (_disposed) return;
    _clearError();
    try {
      await _notificationRepository.markAllAsRead(userId);
      _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
      _unreadCount = 0;
      _safeNotifyListeners();
    } on FirestoreException catch (e) {
      _errorMessage = e.message;
      _safeNotifyListeners();
    } catch (e) {
      debugPrint('NotificationProvider.markAllAsRead error: $e');
      _errorMessage = 'Failed to mark all as read';
      _safeNotifyListeners();
    }
  }

  /// Delete a single notification
  Future<void> deleteNotification(String notificationId) async {
    if (_disposed) return;
    _clearError();
    try {
      await _notificationRepository.deleteNotification(notificationId);
      _notifications.removeWhere((n) => n.notificationId == notificationId);
      _updateUnreadCount();
      _safeNotifyListeners();
    } on FirestoreException catch (e) {
      _errorMessage = e.message;
      _safeNotifyListeners();
    } catch (e) {
      debugPrint('NotificationProvider.deleteNotification error: $e');
      _errorMessage = 'Failed to delete notification';
      _safeNotifyListeners();
    }
  }

  /// Clear all notifications for a user
  Future<void> clearAll(String userId) async {
    if (_disposed) return;
    _clearError();
    try {
      await _notificationRepository.clearAll(userId);
      _notifications = [];
      _unreadCount = 0;
      _safeNotifyListeners();
    } on FirestoreException catch (e) {
      _errorMessage = e.message;
      _safeNotifyListeners();
    } catch (e) {
      debugPrint('NotificationProvider.clearAll error: $e');
      _errorMessage = 'Failed to clear notifications';
      _safeNotifyListeners();
    }
  }

  /// Toggle notification settings
  void toggleNotifications() {
    if (_disposed) return;
    _notificationsEnabled = !_notificationsEnabled;
    _safeNotifyListeners();
  }

  void togglePromotional() {
    if (_disposed) return;
    _promotionalEnabled = !_promotionalEnabled;
    _safeNotifyListeners();
  }

  void toggleRewardNotifications() {
    if (_disposed) return;
    _rewardNotificationsEnabled = !_rewardNotificationsEnabled;
    _safeNotifyListeners();
  }

  void _updateUnreadCount() {
    _unreadCount = _notifications.where((n) => !n.isRead).length;
  }

  void clearError() {
    _clearError();
  }

  void _setLoading(bool value) {
    if (_disposed) return;
    _isLoading = value;
    _safeNotifyListeners();
  }

  void _clearError() {
    if (_disposed) return;
    _errorMessage = null;
    _safeNotifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _notificationSubscription?.cancel();
    _notificationSubscription = null;
    // Silently complete any pending setUser to avoid unhandled
    // exceptions propagaging to callers awaiting the completer.
    try {
      _setUserCompleter?.complete();
    } catch (_) {
      // Ignore — the future may already have been completed.
    }
    _setUserCompleter = null;
    super.dispose();
  }
}

/// A group of notifications of the same type with metadata for display.
class NotificationGroup {
  final NotificationType type;
  final List<NotificationEntity> notifications;
  final int unreadCount;
  final DateTime latestAt;

  const NotificationGroup({
    required this.type,
    required this.notifications,
    required this.unreadCount,
    required this.latestAt,
  });
}
