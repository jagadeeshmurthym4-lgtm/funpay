import 'dart:async';
import 'dart:convert';
import 'package:cashspark/core/constants/app_constants.dart';
import 'package:cashspark/domain/entities/chat_message_entity.dart';
import 'package:cashspark/domain/entities/support_ticket_entity.dart';
import 'package:cashspark/domain/repositories/support_ticket_repository.dart';
import 'package:cashspark/services/fcm_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:http/http.dart' as http;

class HelpProvider extends ChangeNotifier {
  final SupportTicketRepository _ticketRepository;

  // FAQ
  List<Map<String, dynamic>> _faqs = [];
  bool _faqsLoading = false;
  String _faqSearchQuery = '';
  String? _selectedFaqCategory;

  // Tickets
  List<SupportTicketEntity> _tickets = [];
  bool _ticketsLoading = false;

  // Chat
  List<ChatMessageEntity> _chatMessages = [];
  bool _chatLoading = false;
  StreamSubscription? _chatSubscription;
  StreamSubscription? _ticketSubscription;

  // Contact
  bool _submitting = false;
  String? _errorMessage;
  String? _successMessage;

  HelpProvider({required SupportTicketRepository ticketRepository})
      : _ticketRepository = ticketRepository;

  // --- Getters -----------------------------------------------------------
  List<Map<String, dynamic>> get faqs => _faqs;
  bool get faqsLoading => _faqsLoading;
  String get faqSearchQuery => _faqSearchQuery;
  String? get selectedFaqCategory => _selectedFaqCategory;

  List<SupportTicketEntity> get tickets => _tickets;
  bool get ticketsLoading => _ticketsLoading;

  List<ChatMessageEntity> get chatMessages => _chatMessages;
  bool get chatLoading => _chatLoading;

  bool get submitting => _submitting;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  // --- FAQ Categories ----------------------------------------------------
  static const List<Map<String, dynamic>> faqCategories = [
    {'name': 'All', 'icon': Icons.all_inclusive, 'key': null},
    {'name': 'Earnings', 'icon': Icons.monetization_on_outlined, 'key': 'earnings'},
    {'name': 'Withdrawals', 'icon': Icons.logout_outlined, 'key': 'withdrawals'},
    {'name': 'Account', 'icon': Icons.person_outlined, 'key': 'account'},
    {'name': 'Referrals', 'icon': Icons.share_outlined, 'key': 'referrals'},
    {'name': 'Technical', 'icon': Icons.build_outlined, 'key': 'technical'},
    {'name': 'Privacy', 'icon': Icons.lock_outlined, 'key': 'privacy'},
  ];

  // --- FAQ Methods -------------------------------------------------------
  Future<void> loadFAQs() async {
    _faqsLoading = true;
    notifyListeners();
    try {
      _faqs = await _ticketRepository.getFAQs();
      // If no FAQs from Firestore, use static defaults
      if (_faqs.isEmpty) {
        _faqs = _defaultFAQs();
      }
    } catch (e) {
      _faqs = _defaultFAQs();
    } finally {
      _faqsLoading = false;
      notifyListeners();
    }
  }

  void setFaqSearchQuery(String query) {
    _faqSearchQuery = query;
    notifyListeners();
  }

  void setFaqCategory(String? category) {
    _selectedFaqCategory = category;
    notifyListeners();
  }

  List<Map<String, dynamic>> get filteredFAQs {
    var items = _faqs;
    if (_selectedFaqCategory != null) {
      items = items.where((f) => f['category'] == _selectedFaqCategory).toList();
    }
    if (_faqSearchQuery.isNotEmpty) {
      final q = _faqSearchQuery.toLowerCase();
      items = items.where((f) {
        final title = (f['question'] as String? ?? '').toLowerCase();
        final answer = (f['answer'] as String? ?? '').toLowerCase();
        return title.contains(q) || answer.contains(q);
      }).toList();
    }
    return items;
  }

  // --- Ticket Methods ----------------------------------------------------
  void loadTickets(String userId) {
    _ticketsLoading = true;
    notifyListeners();
    _ticketSubscription?.cancel();
    _ticketSubscription = _ticketRepository.streamUserTickets(userId).listen(
      (tickets) {
        _tickets = tickets;
        _ticketsLoading = false;
        notifyListeners();
      },
      onError: (_) {
        _ticketsLoading = false;
        notifyListeners();
      },
    );
  }

  Future<String> createTicket({
    required String userId,
    required String subject,
    required String message,
    TicketCategory category = TicketCategory.other,
    String? screenshotUrl,
    String? deviceInfo,
  }) async {
    _submitting = true;
    _clearMessages();

    try {
      final ticketId = _generateId('tkt');
      final now = DateTime.now();
      final ticket = SupportTicketEntity(
        ticketId: ticketId,
        userId: userId,
        subject: subject,
        message: message,
        category: category,
        status: TicketStatus.open,
        screenshotUrl: screenshotUrl,
        deviceInfo: deviceInfo,
        createdAt: now,
        updatedAt: now,
      );
      await _ticketRepository.createTicket(ticket);
      _successMessage = 'Ticket #$ticketId created successfully!';
      debugPrint('[HelpProvider] Ticket created: $ticketId for user $userId');

      // Also save the initial message as a chat message so it appears in the chat
      final msgId = _generateId('msg');
      final initialMsg = ChatMessageEntity(
        messageId: msgId,
        ticketId: ticketId,
        ticketUserId: userId,
        senderId: userId,
        senderName: 'User',
        text: message,
        createdAt: now,
      );
      await _ticketRepository.sendMessage(initialMsg);

      // Notify admin via FCM and email (best-effort)
      _notifyAdminViaFcm('A User', subject);
      _notifyAdminViaEmail(ticketId, userId, subject, message, category, deviceInfo);

      return ticketId;
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      debugPrint('[HelpProvider] createTicket error for user $userId: $e');
      if (errorStr.contains('permission-denied') || errorStr.contains('permission_denied')) {
        _errorMessage = 'Unable to submit ticket due to a server configuration issue. Please try again later or contact support@funpay.com directly.';
      } else if (errorStr.contains('network-request-failed') || errorStr.contains('network_error')) {
        _errorMessage = 'Network error. Please check your internet connection and try again.';
      } else {
        _errorMessage = 'Failed to submit ticket. Please try again.';
      }
      rethrow;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }

  // --- Chat Methods ------------------------------------------------------
  void loadChatMessages(String ticketId) {
    _chatLoading = true;
    notifyListeners();
    _chatSubscription?.cancel();
    _chatSubscription = _ticketRepository.streamMessages(ticketId).listen(
      (messages) {
        _chatMessages = messages;
        _chatLoading = false;
        notifyListeners();
      },
      onError: (_) {
        _chatLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> sendChatMessage({
    required String ticketId,
    required String userId,
    required String userName,
    required String text,
    String? ticketUserId,
    MessageSender senderType = MessageSender.user,
  }) async {
    _clearMessages();
    try {
      final messageId = _generateId('msg');
      final message = ChatMessageEntity(
        messageId: messageId,
        ticketId: ticketId,
        ticketUserId: ticketUserId ?? userId,
        senderId: userId,
        senderName: userName,
        senderType: senderType,
        text: text,
        createdAt: DateTime.now(),
      );
      await _ticketRepository.sendMessage(message);

      // Notify admin via FCM push about the new message
      _notifyAdminViaFcm(userName, text);
    } catch (e) {
      _errorMessage = 'Failed to send message';
      notifyListeners();
    }
  }

  void clearMessages() {
    _chatMessages = [];
    _chatSubscription?.cancel();
  }

  /// Sends an FCM push notification to all admins when a user sends
  /// a new chat message. Queries the admins collection to find admin UIDs
  /// and sends a targeted push to each admin's `user_{adminId}` FCM topic.
  /// Best-effort — failures are silently logged.
  Future<void> _notifyAdminViaFcm(String userName, String text) async {
    try {
      final adminsSnapshot = await FirebaseFirestore.instance
          .collection(AppConstants.adminsCollection)
          .get();
      for (final doc in adminsSnapshot.docs) {
        final adminId = doc.id;
        if (adminId.isNotEmpty) {
          await FcmService.sendTargetedPush(
            userId: adminId,
            title: 'New message from $userName',
            message: text,
            type: 'chat_message',
          );
        }
      }
    } catch (e) {
      debugPrint('[HelpProvider] FCM admin notification error: $e');
    }
  }

  /// Sends a ticket notification email to the admin via the CPX server.
  /// This is best-effort — failures are silently logged so they don't
  /// affect the ticket creation flow.
  Future<void> _notifyAdminViaEmail(
    String ticketId,
    String userId,
    String subject,
    String message,
    TicketCategory category,
    String? deviceInfo,
  ) async {
    try {
      final url = Uri.parse('${AppConstants.backendUrl}/email/support-ticket');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': AppConstants.fcmApiKey,
        },
        body: jsonEncode({
          'ticketId': ticketId,
          'userId': userId,
          'subject': subject,
          'message': message,
          'category': category.name,
          'deviceInfo': deviceInfo,
        }),
      );
      if (response.statusCode == 200) {
        debugPrint('[HelpProvider] Admin notified via email for ticket $ticketId');
      } else {
        debugPrint('[HelpProvider] Admin notification failed (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      debugPrint('[HelpProvider] Admin notification error: $e');
      // Non-critical — the ticket is already saved in Firestore
    }
  }

  void clearErrors() {
    _clearMessages();
  }

  void _clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _chatSubscription?.cancel();
    _ticketSubscription?.cancel();
    super.dispose();
  }

  // --- Helpers -----------------------------------------------------------
  String _generateId(String prefix) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return '${prefix}_${timestamp}_$random';
  }

  /// Static default FAQs when Firestore collection is empty
  List<Map<String, dynamic>> _defaultFAQs() {
    return [
      {'question': 'How do I earn rewards?', 'answer': 'You can earn rewards through daily check-ins, watching ads, completing tasks, referring friends, and participating in promotional events.', 'category': 'earnings', 'order': 1},
      {'question': 'How do I redeem my balance?', 'answer': 'Go to the Redeem section from the home screen. Choose an in-platform perk such as Premium access, bonus spins, exclusive themes, or boosters. Minimum redemption is ₹10.', 'category': 'withdrawals', 'order': 2},
      {'question': 'How long do redemptions take?', 'answer': 'Redemption requests are reviewed and typically processed within 24-48 hours. Once approved, your chosen perk is granted to your account.', 'category': 'withdrawals', 'order': 3},
      {'question': 'How does the referral program work?', 'answer': 'Share your unique referral code with friends. When they sign up using your code, both you and your friend receive a bonus. Track referrals in the Referral Dashboard.', 'category': 'referrals', 'order': 4},
      {'question': 'Is there a limit on daily earnings?', 'answer': 'Yes, there are daily limits to ensure fair usage. Check the Rewards section for current limits. Your balance has no cash value and can only be spent on in-platform perks.', 'category': 'earnings', 'order': 5},
      {'question': 'How do I reset my password?', 'answer': 'Go to the Login screen and tap "Forgot Password". Enter your email / Gmail address to receive a password reset link.', 'category': 'account', 'order': 6},
      {'question': 'Can I have multiple accounts?', 'answer': 'No, multiple accounts are strictly prohibited. Our fraud detection system monitors for duplicate accounts. Violations result in account suspension.', 'category': 'account', 'order': 7},
      {'question': 'How is my data protected?', 'answer': 'Your data is encrypted and stored securely with Firebase Firestore. We implement device fingerprinting, login monitoring, and fraud detection.', 'category': 'privacy', 'order': 8},
      {'question': 'What happens if I delete my account?', 'answer': 'Account deletion is permanent. All personal data, rewards, and wallet balance will be deleted. This action cannot be undone.', 'category': 'account', 'order': 9},
      {'question': 'How do I contact support?', 'answer': 'Email us at support@funpay.com or use the Help Center to raise a ticket. We typically respond within 24 hours.', 'category': 'technical', 'order': 10},
      {'question': 'Why was my redemption rejected?', 'answer': 'Redemptions may be rejected due to incomplete profile, suspicious activity, or exceeding limits. Contact support for details.', 'category': 'withdrawals', 'order': 11},
      {'question': 'How do I update my profile?', 'answer': 'Go to your Profile screen and tap the Edit button. You can update your name, phone, email, and other details there.', 'category': 'account', 'order': 12},
    ];
  }
}
