import 'package:cashspark/core/errors/exceptions.dart';
import 'package:cashspark/data/datasources/notification_firestore_datasource.dart';
import 'package:cashspark/data/models/notification_model.dart';
import 'package:cashspark/domain/entities/notification_entity.dart';
import 'package:cashspark/domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationFirestoreDataSource _dataSource;

  NotificationRepositoryImpl({
    required NotificationFirestoreDataSource dataSource,
  }) : _dataSource = dataSource;

  @override
  Future<void> createNotification(NotificationEntity notification) async {
    final model = NotificationModel.fromEntity(notification);
    await _dataSource.createNotification(model);
  }

  @override
  Stream<List<NotificationEntity>> streamNotifications(String userId) {
    return _dataSource.streamNotifications(userId);
  }

  @override
  Future<List<NotificationEntity>> getNotifications(String userId,
      {int limit = 50}) async {
    try {
      return await _dataSource.getNotifications(userId, limit: limit);
    } catch (e) {
      throw FirestoreException('Failed to get notifications: $e');
    }
  }

  @override
  Future<NotificationEntity> markAsRead(String notificationId) async {
    try {
      await _dataSource.markAsRead(notificationId);
      // Return a minimal entity — callers typically ignore the return value
      // and update their local state via the stream snapshot instead.
      return NotificationModel(
        notificationId: notificationId,
        userId: '',
        title: '',
        message: '',
        isRead: true,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      // Re-throw as FirestoreException for consistent error handling
      throw FirestoreException('Failed to mark notification as read: $e');
    }
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    try {
      await _dataSource.markAllAsRead(userId);
    } catch (e) {
      throw FirestoreException('Failed to mark all as read: $e');
    }
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _dataSource.deleteNotification(notificationId);
    } catch (e) {
      throw FirestoreException('Failed to delete notification: $e');
    }
  }

  @override
  Future<void> clearAll(String userId) async {
    try {
      await _dataSource.clearAll(userId);
    } catch (e) {
      throw FirestoreException('Failed to clear notifications: $e');
    }
  }

  @override
  Future<int> getUnreadCount(String userId) async {
    try {
      return await _dataSource.getUnreadCount(userId);
    } catch (e) {
      return 0;
    }
  }

  @override
  Future<void> saveFcmToken(String userId, String token) async {
    try {
      await _dataSource.saveFcmToken(userId, token);
    } catch (e) {
      throw FirestoreException('Failed to save FCM token: $e');
    }
  }

  @override
  Future<String?> getFcmToken(String userId) async {
    try {
      return await _dataSource.getFcmToken(userId);
    } catch (e) {
      return null;
    }
  }
}
