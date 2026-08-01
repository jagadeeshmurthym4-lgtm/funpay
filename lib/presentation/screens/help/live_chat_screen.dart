import 'package:cashspark/core/theme/app_theme.dart';
import 'package:cashspark/core/utils/helpers.dart';
import 'package:cashspark/core/widgets/premium_widgets.dart';
import 'package:cashspark/domain/entities/chat_message_entity.dart';
import 'package:cashspark/domain/entities/support_ticket_entity.dart';
import 'package:cashspark/presentation/providers/auth_provider.dart';
import 'package:cashspark/presentation/providers/help_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LiveChatScreen extends StatefulWidget {
  final String? ticketId;

  const LiveChatScreen({super.key, this.ticketId});

  @override
  State<LiveChatScreen> createState() => _LiveChatScreenState();
}

class _LiveChatScreenState extends State<LiveChatScreen> {
  final _messageController = TextEditingController();
  final _subjectController = TextEditingController();
  bool _showNewChat = false;
  String? _activeTicketId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final hp = context.read<HelpProvider>();
      if (widget.ticketId != null) {
        _activeTicketId = widget.ticketId;
        hp.loadChatMessages(widget.ticketId!);
      }
      // Load tickets so the start screen can show recent ones
      final auth = context.read<AuthProvider>();
      final userId = auth.user?.uid;
      if (userId != null) {
        hp.loadTickets(userId);
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _subjectController.dispose();
    context.read<HelpProvider>().clearMessages();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: PremiumAppBar(
        title: _activeTicketId != null ? 'Live Chat' : 'New Chat',
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
            if (_activeTicketId == null && !_showNewChat) {
              return _buildStartScreen(hp, isDark, theme);
            }

            if (_showNewChat && _activeTicketId == null) {
              return _buildNewChatForm(hp, isDark, theme);
            }

            return Column(
              children: [
                // Chat header
                PremiumGlass(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        width: 10, height: 10,
                        decoration: BoxDecoration(
                          color: AppTheme.accentGreen,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: AppTheme.accentGreen.withValues(alpha: 0.4), blurRadius: 4)],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('Support Team',
                          style: TextStyle(fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : const Color(0xFF0F172A))),
                      const Spacer(),
                      const Text('Online',
                          style: TextStyle(fontSize: 11, color: AppTheme.accentGreen)),
                    ],
                  ),
                ),

                // Messages
                Expanded(
                  child: hp.chatLoading
                      ? const Center(child: PremiumLoader())
                      : hp.chatMessages.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.chat_outlined, size: 48,
                                        color: isDark ? AppTheme.textMuted.withValues(alpha: 0.3) : const Color(0xFF94A3B8).withValues(alpha: 0.3)),
                                    const SizedBox(height: 16),
                                    Text('Start the conversation',
                                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 8),
                                    Text('Send a message and our team will respond shortly.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8))),
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
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

  Widget _buildStartScreen(HelpProvider hp, bool isDark, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            width: 80, height: 80,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.accentPurple, AppTheme.accentBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.chat_rounded, size: 36, color: Colors.white),
          ),
          const SizedBox(height: 24),
          Text('Live Chat Support',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Chat with our support team in real time.\nAverage response: under 2 minutes.',
              textAlign: TextAlign.center,
              style: TextStyle(color: isDark ? AppTheme.textMuted : const Color(0xFF64748B))),
          const SizedBox(height: 32),
          GradientButton(
            onPressed: () {
              final userId = context.read<AuthProvider>().user?.uid;
              if (userId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please log in first'), behavior: SnackBarBehavior.floating),
                );
                return;
              }
              setState(() => _showNewChat = true);
            },
            label: 'Start New Chat',
            icon: Icons.chat_outlined,
          ),
          if (hp.tickets.isNotEmpty) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Text('Recent Tickets',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: hp.tickets.take(3).length,
                itemBuilder: (context, index) {
                  final ticket = hp.tickets[index];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _activeTicketId = ticket.ticketId;
                        _showNewChat = false;
                        hp.loadChatMessages(ticket.ticketId);
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: (isDark ? AppTheme.borderColor : const Color(0xFFF1F5F9)).withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(ticket.subject,
                                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A))),
                                Text(Helpers.formatDateTime(ticket.createdAt),
                                    style: TextStyle(fontSize: 11,
                                        color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8))),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right, size: 18,
                              color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNewChatForm(HelpProvider hp, bool isDark, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What do you need help with?',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          PremiumGlass(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            borderRadius: 14,
            child: TextField(
              controller: _subjectController,
              decoration: const InputDecoration(
                hintText: 'Brief subject...',
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Please include details about your issue. Once you send the first message, a ticket will be created and our team will respond.',
              style: TextStyle(fontSize: 12, color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8))),
          const Spacer(),
          GradientButton(
            onPressed: () async {
              final subject = _subjectController.text.trim();
              if (subject.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a subject'), behavior: SnackBarBehavior.floating),
                );
                return;
              }
              final auth = context.read<AuthProvider>();
              final userId = auth.user?.uid;
              if (userId == null) return;

              try {
                final ticketId = await hp.createTicket(
                  userId: userId,
                  subject: subject,
                  message: 'Started via live chat',
                  category: TicketCategory.technical,
                );
                setState(() {
                  _activeTicketId = ticketId;
                  _showNewChat = false;
                });
                hp.loadChatMessages(ticketId);
              } catch (_) {}
            },
            label: 'Start Chat',
            icon: Icons.chat_outlined,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _sendMessage(HelpProvider hp) {
    final text = _messageController.text.trim();
    if (text.isEmpty || _activeTicketId == null) return;

    final auth = context.read<AuthProvider>();
    final userId = auth.user?.uid;
    final userName = auth.user?.fullName ?? 'User';
    if (userId == null) return;

    _messageController.clear();

    // Send asynchronously — errors are handled inside sendChatMessage
    hp.sendChatMessage(
      ticketId: _activeTicketId!,
      ticketUserId: userId,
      userId: userId,
      userName: userName,
      text: text,
    ).then((_) {
      if (mounted && hp.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(hp.errorMessage!),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    });
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
}
