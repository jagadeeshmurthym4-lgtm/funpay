import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cashspark/core/constants/app_constants.dart';
import 'package:cashspark/data/models/chat_message_model.dart';
import 'package:cashspark/data/models/support_ticket_model.dart';
import 'package:flutter/foundation.dart' show debugPrint;

class TicketFirestoreDataSource {
  final FirebaseFirestore _firestore;

  TicketFirestoreDataSource({FirebaseFirestore? firestoreInstance})
      : _firestore = firestoreInstance ?? FirebaseFirestore.instance;

  // ─── Tickets ─────────────────────────────────────────────

  /// Streams ALL support tickets for the admin panel (no userId filter).
  Stream<List<SupportTicketModel>> streamAllTickets() {
    return _firestore
        .collection(AppConstants.ticketsCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => SupportTicketModel.fromFirestore(doc.data()))
          .toList();
    });
  }

  Future<void> createTicket(SupportTicketModel ticket) async {
    await _firestore
        .collection(AppConstants.ticketsCollection)
        .doc(ticket.ticketId)
        .set(ticket.toFirestore());
  }

  Future<List<SupportTicketModel>> getUserTickets(String userId) async {
    try {
      final query = await _firestore
          .collection(AppConstants.ticketsCollection)
          .where('userId', isEqualTo: userId)
          .get();
      final tickets = query.docs
          .map((doc) => SupportTicketModel.fromFirestore(doc.data()))
          .toList();
      tickets.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return tickets;
    } catch (e) {
      debugPrint('getUserTickets error: $e');
      return [];
    }
  }

  Stream<List<SupportTicketModel>> streamUserTickets(String userId) {
    return _firestore
        .collection(AppConstants.ticketsCollection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final tickets = snapshot.docs
          .map((doc) => SupportTicketModel.fromFirestore(doc.data()))
          .toList();
      tickets.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return tickets;
    });
  }

  Future<SupportTicketModel?> getTicket(String ticketId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.ticketsCollection)
          .doc(ticketId)
          .get();
      if (!doc.exists || doc.data() == null) return null;
      return SupportTicketModel.fromFirestore(doc.data()!);
    } catch (e) {
      debugPrint('getTicket error: $e');
      return null;
    }
  }

  Future<void> updateTicketStatus(String ticketId, String status) async {
    await _firestore
        .collection(AppConstants.ticketsCollection)
        .doc(ticketId)
        .update({'status': status, 'updatedAt': DateTime.now()});
  }

  // ─── Chat Messages ───────────────────────────────────────

  Future<void> sendMessage(ChatMessageModel message) async {
    await _firestore
        .collection(AppConstants.chatMessagesCollection)
        .doc(message.messageId)
        .set(message.toFirestore());
  }

  Stream<List<ChatMessageModel>> streamMessages(String ticketId) {
    return _firestore
        .collection(AppConstants.chatMessagesCollection)
        .where('ticketId', isEqualTo: ticketId)
        .snapshots()
        .map((snapshot) {
      final messages = snapshot.docs
          .map((doc) => ChatMessageModel.fromFirestore(doc.data()))
          .toList();
      messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return messages;
    });
  }



  // ─── FAQs ────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getFAQs() async {
    try {
      final query = await _firestore
          .collection(AppConstants.faqsCollection)
        .orderBy('order', descending: false)
        .get();
      return query.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('getFAQs error: $e');
      return [];
    }
  }
}
