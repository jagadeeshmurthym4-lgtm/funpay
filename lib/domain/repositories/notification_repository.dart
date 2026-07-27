import 'package:cashspark/domain/entities/notification_entity.dart';

abstract class NotificationRepository {
  Future<void> createNotification(NotificationEntity notification);
  Stream<List<NotificationEntity>> streamNotifications(String userId);
  Future<List<NotificationEntity>> getNotifications(String userId, {int limit = 50});
  Future<NotificationEntity> markAsRead(String notificationId);
  Future<void> markAllAsRead(String userId);
  Future<void> deleteNotification(String notificationId);
  Future<void> clearAll(String userId);
  Future<int> getUnreadCount(String userId);

  // FCM Token
  Future<void> saveFcmToken(String userId, String token);
  Future<String?> getFcmToken(String userId);
}
