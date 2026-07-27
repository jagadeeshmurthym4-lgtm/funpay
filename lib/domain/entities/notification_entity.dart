enum NotificationType {
  reward,
  referral,
  withdrawal,
  dailyBonus,
  announcement,
  promotional,
  other,
}

class NotificationEntity {
  final String notificationId;
  final String userId;
  final String title;
  final String message;
  final NotificationType type;
  final bool isRead;
  final DateTime createdAt;

  const NotificationEntity({
    required this.notificationId,
    required this.userId,
    required this.title,
    required this.message,
    this.type = NotificationType.other,
    this.isRead = false,
    required this.createdAt,
  });

  NotificationEntity copyWith({
    String? notificationId,
    String? userId,
    String? title,
    String? message,
    NotificationType? type,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationEntity(
      notificationId: notificationId ?? this.notificationId,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
