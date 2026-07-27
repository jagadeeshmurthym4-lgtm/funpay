import 'package:cashspark/domain/entities/notification_entity.dart';

class NotificationModel extends NotificationEntity {
  const NotificationModel({
    required super.notificationId,
    required super.userId,
    required super.title,
    required super.message,
    super.type = NotificationType.other,
    super.isRead = false,
    required super.createdAt,
  });

  factory NotificationModel.fromEntity(NotificationEntity entity) {
    return NotificationModel(
      notificationId: entity.notificationId,
      userId: entity.userId,
      title: entity.title,
      message: entity.message,
      type: entity.type,
      isRead: entity.isRead,
      createdAt: entity.createdAt,
    );
  }

  factory NotificationModel.fromFirestore(Map<String, dynamic> map) {
    return NotificationModel(
      notificationId: map['notificationId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      message: map['message'] as String? ?? '',
      type: _parseType(map['type'] as String? ?? 'other'),
      isRead: map['isRead'] as bool? ?? false,
      createdAt: _parseCreatedAt(map['createdAt']),
    );
  }

  /// Parse [createdAt] from Firestore Timestamp, DateTime, or null.
  /// Returns [DateTime.now()] as a safe fallback if the value is missing or
  /// in an unexpected format.
  static DateTime _parseCreatedAt(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    try {
      // Firestore Timestamps have a .toDate() method
      final date = (value as dynamic).toDate() as DateTime?;
      if (date != null) return date;
    } catch (_) {
      // Fall through to default
    }
    return DateTime.now();
  }

  Map<String, dynamic> toFirestore() {
    return {
      'notificationId': notificationId,
      'userId': userId,
      'title': title,
      'message': message,
      'type': type.name,
      'isRead': isRead,
      'createdAt': createdAt,
    };
  }

  static NotificationType _parseType(String value) {
    return NotificationType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => NotificationType.other,
    );
  }
}
