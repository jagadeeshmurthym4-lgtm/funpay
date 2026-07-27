import 'package:cashspark/domain/entities/support_ticket_entity.dart';

class SupportTicketModel extends SupportTicketEntity {
  const SupportTicketModel({
    required super.ticketId,
    required super.userId,
    required super.subject,
    required super.message,
    super.category = TicketCategory.other,
    super.status = TicketStatus.open,
    super.screenshotUrl,
    super.deviceInfo,
    super.adminReply,
    required super.createdAt,
    required super.updatedAt,
  });

  factory SupportTicketModel.fromEntity(SupportTicketEntity entity) {
    return SupportTicketModel(
      ticketId: entity.ticketId,
      userId: entity.userId,
      subject: entity.subject,
      message: entity.message,
      category: entity.category,
      status: entity.status,
      screenshotUrl: entity.screenshotUrl,
      deviceInfo: entity.deviceInfo,
      adminReply: entity.adminReply,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  factory SupportTicketModel.fromFirestore(Map<String, dynamic> map) {
    return SupportTicketModel(
      ticketId: map['ticketId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      subject: map['subject'] as String? ?? '',
      message: map['message'] as String? ?? '',
      category: _parseCategory(map['category'] as String? ?? 'other'),
      status: _parseStatus(map['status'] as String? ?? 'open'),
      screenshotUrl: map['screenshotUrl'] as String?,
      deviceInfo: map['deviceInfo'] as String?,
      adminReply: map['adminReply'] as String?,
      createdAt: (map['createdAt'] as dynamic)?.toDate() as DateTime? ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as dynamic)?.toDate() as DateTime? ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'ticketId': ticketId,
      'userId': userId,
      'subject': subject,
      'message': message,
      'category': category.name,
      'status': status.name,
      if (screenshotUrl != null) 'screenshotUrl': screenshotUrl,
      if (deviceInfo != null) 'deviceInfo': deviceInfo,
      if (adminReply != null) 'adminReply': adminReply,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  static TicketCategory _parseCategory(String value) {
    return TicketCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TicketCategory.other,
    );
  }

  static TicketStatus _parseStatus(String value) {
    return TicketStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TicketStatus.open,
    );
  }
}
