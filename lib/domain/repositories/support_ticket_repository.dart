import 'package:cashspark/domain/entities/chat_message_entity.dart';
import 'package:cashspark/domain/entities/support_ticket_entity.dart';

abstract class SupportTicketRepository {
  Future<void> createTicket(SupportTicketEntity ticket);
  Future<List<SupportTicketEntity>> getUserTickets(String userId);
  Stream<List<SupportTicketEntity>> streamUserTickets(String userId);
  Future<SupportTicketEntity?> getTicket(String ticketId);

  Future<void> sendMessage(ChatMessageEntity message);
  Stream<List<ChatMessageEntity>> streamMessages(String ticketId);

  Future<List<Map<String, dynamic>>> getFAQs();
}
