enum MessageSender { user, admin, system }

class ChatMessageEntity {
  final String messageId;
  final String ticketId;
  /// The userId of the ticket owner. Stored on each message so Firestore
  /// security rules can verify read access without a get() lookup on the
  /// parent ticket document (avoids the 20-get-per-query limit).
  final String ticketUserId;
  final String senderId;
  final String senderName;
  final MessageSender senderType;
  final String text;
  final DateTime createdAt;

  const ChatMessageEntity({
    required this.messageId,
    required this.ticketId,
    required this.ticketUserId,
    required this.senderId,
    required this.senderName,
    this.senderType = MessageSender.user,
    required this.text,
    required this.createdAt,
  });

  ChatMessageEntity copyWith({
    String? messageId,
    String? ticketId,
    String? ticketUserId,
    String? senderId,
    String? senderName,
    MessageSender? senderType,
    String? text,
    DateTime? createdAt,
  }) {
    return ChatMessageEntity(
      messageId: messageId ?? this.messageId,
      ticketId: ticketId ?? this.ticketId,
      ticketUserId: ticketUserId ?? this.ticketUserId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderType: senderType ?? this.senderType,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
