enum MessageSender { user, admin, system }

class ChatMessageEntity {
  final String messageId;
  final String ticketId;
  final String senderId;
  final String senderName;
  final MessageSender senderType;
  final String text;
  final DateTime createdAt;

  const ChatMessageEntity({
    required this.messageId,
    required this.ticketId,
    required this.senderId,
    required this.senderName,
    this.senderType = MessageSender.user,
    required this.text,
    required this.createdAt,
  });

  ChatMessageEntity copyWith({
    String? messageId,
    String? ticketId,
    String? senderId,
    String? senderName,
    MessageSender? senderType,
    String? text,
    DateTime? createdAt,
  }) {
    return ChatMessageEntity(
      messageId: messageId ?? this.messageId,
      ticketId: ticketId ?? this.ticketId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderType: senderType ?? this.senderType,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
