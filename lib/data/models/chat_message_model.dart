import 'package:cashspark/domain/entities/chat_message_entity.dart';

class ChatMessageModel extends ChatMessageEntity {
  const ChatMessageModel({
    required super.messageId,
    required super.ticketId,
    required super.senderId,
    required super.senderName,
    super.senderType = MessageSender.user,
    required super.text,
    required super.createdAt,
  });

  factory ChatMessageModel.fromEntity(ChatMessageEntity entity) {
    return ChatMessageModel(
      messageId: entity.messageId,
      ticketId: entity.ticketId,
      senderId: entity.senderId,
      senderName: entity.senderName,
      senderType: entity.senderType,
      text: entity.text,
      createdAt: entity.createdAt,
    );
  }

  factory ChatMessageModel.fromFirestore(Map<String, dynamic> map) {
    return ChatMessageModel(
      messageId: map['messageId'] as String? ?? '',
      ticketId: map['ticketId'] as String? ?? '',
      senderId: map['senderId'] as String? ?? '',
      senderName: map['senderName'] as String? ?? '',
      senderType: _parseSender(map['senderType'] as String? ?? 'user'),
      text: map['text'] as String? ?? '',
      createdAt: (map['createdAt'] as dynamic)?.toDate() as DateTime? ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'messageId': messageId,
      'ticketId': ticketId,
      'senderId': senderId,
      'senderName': senderName,
      'senderType': senderType.name,
      'text': text,
      'createdAt': createdAt,
    };
  }

  static MessageSender _parseSender(String value) {
    return MessageSender.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MessageSender.user,
    );
  }
}
