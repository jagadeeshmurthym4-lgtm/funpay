import 'package:cashspark/data/datasources/ticket_firestore_datasource.dart';
import 'package:cashspark/data/models/chat_message_model.dart';
import 'package:cashspark/data/models/support_ticket_model.dart';
import 'package:cashspark/domain/entities/chat_message_entity.dart';
import 'package:cashspark/domain/entities/support_ticket_entity.dart';
import 'package:cashspark/domain/repositories/support_ticket_repository.dart';

class SupportTicketRepositoryImpl implements SupportTicketRepository {
  final TicketFirestoreDataSource _dataSource;

  SupportTicketRepositoryImpl({required TicketFirestoreDataSource dataSource})
      : _dataSource = dataSource;

  @override
  Future<void> createTicket(SupportTicketEntity ticket) async {
    await _dataSource.createTicket(SupportTicketModel.fromEntity(ticket));
  }

  @override
  Future<List<SupportTicketEntity>> getUserTickets(String userId) async {
    return await _dataSource.getUserTickets(userId);
  }

  @override
  Stream<List<SupportTicketEntity>> streamUserTickets(String userId) {
    return _dataSource.streamUserTickets(userId);
  }

  @override
  Future<SupportTicketEntity?> getTicket(String ticketId) async {
    return await _dataSource.getTicket(ticketId);
  }

  @override
  Future<void> sendMessage(ChatMessageEntity message) async {
    await _dataSource.sendMessage(ChatMessageModel.fromEntity(message));
  }

  @override
  Stream<List<ChatMessageEntity>> streamMessages(String ticketId) {
    return _dataSource.streamMessages(ticketId);
  }

  @override
  Future<List<Map<String, dynamic>>> getFAQs() async {
    return await _dataSource.getFAQs();
  }
}
