enum TicketStatus { open, inProgress, resolved, closed }

enum TicketCategory {
  account,
  withdrawal,
  task,
  reward,
  referral,
  technical,
  feature,
  other,
}

class SupportTicketEntity {
  final String ticketId;
  final String userId;
  final String subject;
  final String message;
  final TicketCategory category;
  final TicketStatus status;
  final String? screenshotUrl;
  final String? deviceInfo;
  final String? adminReply;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SupportTicketEntity({
    required this.ticketId,
    required this.userId,
    required this.subject,
    required this.message,
    this.category = TicketCategory.other,
    this.status = TicketStatus.open,
    this.screenshotUrl,
    this.deviceInfo,
    this.adminReply,
    required this.createdAt,
    required this.updatedAt,
  });

  SupportTicketEntity copyWith({
    String? ticketId,
    String? userId,
    String? subject,
    String? message,
    TicketCategory? category,
    TicketStatus? status,
    String? screenshotUrl,
    String? deviceInfo,
    String? adminReply,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SupportTicketEntity(
      ticketId: ticketId ?? this.ticketId,
      userId: userId ?? this.userId,
      subject: subject ?? this.subject,
      message: message ?? this.message,
      category: category ?? this.category,
      status: status ?? this.status,
      screenshotUrl: screenshotUrl ?? this.screenshotUrl,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      adminReply: adminReply ?? this.adminReply,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
