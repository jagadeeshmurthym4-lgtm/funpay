import 'package:cashspark/core/theme/app_theme.dart';
import 'package:cashspark/core/utils/helpers.dart';
import 'package:cashspark/core/widgets/premium_widgets.dart';
import 'package:cashspark/domain/entities/chat_message_entity.dart';
import 'package:cashspark/domain/entities/support_ticket_entity.dart';
import 'package:cashspark/presentation/providers/auth_provider.dart';
import 'package:cashspark/presentation/providers/help_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TicketDetailScreen extends StatefulWidget {
  final SupportTicketEntity ticket;

  const TicketDetailScreen({super.key, required this.ticket});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  final _messageController = TextEditingController();
  late SupportTicketEntity _ticket;

  @override
  void initState() {
    super.initState();
    _ticket = widget.ticket;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HelpProvider>().loadChatMessages(_ticket.ticketId);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: PremiumAppBar(
        title: 'Ticket #${_ticket.ticketId.length > 8 ? _ticket.ticketId.substring(0, 8) : _ticket.ticketId}',
        onBack: () => Navigator.pop(context),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.05),
              theme.colorScheme.surface,
              theme.colorScheme.tertiary.withValues(alpha: 0.03),
            ],
          ),
        ),
        child: Consumer<HelpProvider>(
          builder: (context, hp, _) {
            return Column(
              children: [
                // Ticket info header
                PremiumGlass(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _statusColor(_ticket.status, isDark).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(_statusLabel(_ticket.status),
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                                    color: _statusColor(_ticket.status, isDark))),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.accentBlue.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(_categoryLabel(_ticket.category),
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                                    color: AppTheme.accentBlue)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(_ticket.subject,
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16,
                              color: isDark ? Colors.white : const Color(0xFF0F172A))),
                      const SizedBox(height: 4),
                      Text(_ticket.message,
                          style: TextStyle(fontSize: 13,
                              color: isDark ? AppTheme.textMuted : const Color(0xFF64748B))),
                      const SizedBox(height: 8),
                      Text(Helpers.formatDateTime(_ticket.createdAt),
                          style: TextStyle(fontSize: 11,
                              color: isDark ? AppTheme.textMuted.withValues(alpha: 0.5) : const Color(0xFF94A3B8).withValues(alpha: 0.5))),
                    ],
                  ),
                ),

                // Chat messages
                Expanded(
                  child: hp.chatLoading
                      ? const Center(child: PremiumLoader())
                      : hp.chatMessages.isEmpty
                          ? Center(
                              child: Text('No messages yet. Send a message to start the conversation.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8))),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: hp.chatMessages.length,
                              itemBuilder: (context, index) {
                                final msg = hp.chatMessages[index];
                                return _buildMessageBubble(msg, isDark, theme);
                              },
                            ),
                ),

                // Message input
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.bgDark : Colors.white,
                    border: Border(
                      top: BorderSide(
                        color: isDark ? AppTheme.borderColor.withValues(alpha: 0.3) : const Color(0xFFCBD5E1).withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      children: [
                        Expanded(
                          child: PremiumGlass(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            borderRadius: 14,
                            child: TextField(
                              controller: _messageController,
                              decoration: const InputDecoration(
                                hintText: 'Type a message...',
                                border: InputBorder.none,
                              ),
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _sendMessage(hp),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _sendMessage(hp),
                          child: Container(
                            width: 48, height: 48,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppTheme.accentPurple, AppTheme.accentBlue],
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _sendMessage(HelpProvider hp) {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final auth = context.read<AuthProvider>();
    final userId = auth.user?.uid;
    final userName = auth.user?.fullName ?? 'User';
    if (userId == null) return;

    hp.sendChatMessage(
      ticketId: _ticket.ticketId,
      userId: userId,
      userName: userName,
      text: text,
    );
    _messageController.clear();
  }

  Widget _buildMessageBubble(ChatMessageEntity msg, bool isDark, ThemeData theme) {
    final isUser = msg.senderType == MessageSender.user;
    final bgColor = isUser ? AppTheme.accentPurple : (isDark ? AppTheme.borderColor : const Color(0xFFF1F5F9));
    final textColor = isUser ? Colors.white : (isDark ? Colors.white : const Color(0xFF0F172A));
    final timeColor = isUser ? Colors.white70 : (isDark ? AppTheme.textMuted : const Color(0xFF94A3B8));

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isUser && msg.senderType == MessageSender.admin)
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 2),
              child: Text('Support Agent', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.accentBlue)),
            ),
          Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isUser)
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.accentBlue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.support_agent_rounded, size: 16, color: AppTheme.accentBlue),
                ),
              if (!isUser) const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(msg.text, style: TextStyle(color: textColor, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(Helpers.formatDateTime(msg.createdAt),
                          style: TextStyle(fontSize: 10, color: timeColor)),
                    ],
                  ),
                ),
              ),
              if (isUser) const SizedBox(width: 8),
              if (isUser)
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.accentPurple.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.person_rounded, size: 16, color: AppTheme.accentPurple),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _statusColor(TicketStatus status, bool isDark) {
    switch (status) {
      case TicketStatus.open: return AppTheme.accentBlue;
      case TicketStatus.inProgress: return AppTheme.accentOrange;
      case TicketStatus.resolved: return AppTheme.accentGreen;
      case TicketStatus.closed: return isDark ? AppTheme.textMuted : const Color(0xFF94A3B8);
    }
  }

  String _statusLabel(TicketStatus status) {
    switch (status) {
      case TicketStatus.open: return 'OPEN';
      case TicketStatus.inProgress: return 'IN PROGRESS';
      case TicketStatus.resolved: return 'RESOLVED';
      case TicketStatus.closed: return 'CLOSED';
    }
  }

  String _categoryLabel(TicketCategory cat) {
    switch (cat) {
      case TicketCategory.account: return 'Account';
      case TicketCategory.withdrawal: return 'Withdrawal';
      case TicketCategory.task: return 'Task';
      case TicketCategory.reward: return 'Reward';
      case TicketCategory.referral: return 'Referral';
      case TicketCategory.technical: return 'Technical';
      case TicketCategory.feature: return 'Feature';
      case TicketCategory.other: return 'Other';
    }
  }
}
