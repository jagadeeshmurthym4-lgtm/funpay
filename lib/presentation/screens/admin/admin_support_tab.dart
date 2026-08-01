import 'package:cashspark/core/theme/app_theme.dart';
import 'package:cashspark/core/utils/helpers.dart';
import 'package:cashspark/core/widgets/premium_widgets.dart';
import 'package:cashspark/domain/entities/chat_message_entity.dart';
import 'package:cashspark/domain/entities/support_ticket_entity.dart';
import 'package:cashspark/domain/entities/user_entity.dart';
import 'package:cashspark/presentation/providers/admin_provider.dart';
import 'package:flutter/material.dart';

/// Admin support inbox tab - shows all support tickets with real-time
/// message previews and inline admin reply capability.
class AdminSupportTab extends StatefulWidget {
  final AdminProvider admin;
  final ThemeData theme;

  const AdminSupportTab({super.key, required this.admin, required this.theme});

  @override
  State<AdminSupportTab> createState() => _AdminSupportTabState();
}

class _AdminSupportTabState extends State<AdminSupportTab> {
  final _replyController = TextEditingController();
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.admin.loadSupportTickets();
    });
  }

  @override
  void dispose() {
    _replyController.dispose();
    _searchController.dispose();
    widget.admin.closeChatTicket();
    super.dispose();
  }

  UserEntity? _findUser(String userId) {
    try {
      return widget.admin.users.firstWhere((u) => u.uid == userId);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = widget.admin;
    final theme = widget.theme;
    final isDark = theme.brightness == Brightness.dark;

    if (admin.activeChatTicket != null) {
      return _buildChatView(admin, theme, isDark);
    }

    final tickets = admin.supportTickets;
    final filteredTickets = _searchQuery.isEmpty
        ? tickets
        : tickets.where((t) {
            final user = _findUser(t.userId);
            final userName = user?.fullName.toLowerCase() ?? '';
            final q = _searchQuery.toLowerCase();
            return t.subject.toLowerCase().contains(q) ||
                t.ticketId.toLowerCase().contains(q) ||
                userName.contains(q);
          }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Row(
            children: [
              _StatBadge(
                label: 'All Tickets', value: '${tickets.length}',
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              _StatBadge(
                label: 'Open', value: '${admin.unreadSupportCount}',
                color: const Color(0xFFEF4444),
              ),
              const Spacer(),
              InkWell(
                onTap: () => admin.loadSupportTickets(),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.refresh_rounded, size: 18,
                      color: theme.colorScheme.primary),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: PremiumGlass(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            borderRadius: 12,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search user or subject...',
                prefixIcon: Icon(Icons.search, size: 18,
                    color: theme.colorScheme.onSurfaceVariant),
                border: InputBorder.none,
                isDense: true,
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: admin.supportLoading
              ? const Center(child: PremiumLoader())
              : filteredTickets.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.support_agent_outlined, size: 48,
                              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
                          const SizedBox(height: 8),
                          Text('No support tickets',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant)),
                          const SizedBox(height: 4),
                          Text('User messages will appear here in real-time',
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: filteredTickets.length,
                      itemBuilder: (context, index) {
                        final ticket = filteredTickets[index];
                        final user = _findUser(ticket.userId);
                        final isOpen = ticket.status == TicketStatus.open;
                        return _TicketCard(
                          ticket: ticket,
                          user: user,
                          theme: theme,
                          isDark: isDark,
                          hasNewMessage: isOpen,
                          onTap: () => admin.openChatTicket(ticket),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildChatView(AdminProvider admin, ThemeData theme, bool isDark) {
    final ticket = admin.activeChatTicket!;
    final user = _findUser(ticket.userId);

    return Column(
      children: [
        PremiumGlass(
          margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => admin.closeChatTicket(),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.arrow_back_rounded, size: 18,
                      color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 14,
                backgroundColor: AppTheme.accentPurple.withValues(alpha: 0.12),
                child: Text(
                  (user?.fullName ?? '?')[0].toUpperCase(),
                  style: TextStyle(color: AppTheme.accentPurple, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user?.fullName ?? 'Unknown',
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                    Text(ticket.subject,
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: ticket.status == TicketStatus.open
                      ? const Color(0xFF22C55E).withValues(alpha: 0.1)
                      : ticket.status == TicketStatus.resolved
                          ? const Color(0xFF8B5CF6).withValues(alpha: 0.1)
                          : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  ticket.status.name.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9, fontWeight: FontWeight.w700,
                    color: ticket.status == TicketStatus.open
                        ? const Color(0xFF22C55E)
                        : ticket.status == TicketStatus.resolved
                            ? const Color(0xFF8B5CF6)
                            : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Resolve/Close button — only for non-resolved tickets
              if (ticket.status != TicketStatus.resolved &&
                  ticket.status != TicketStatus.closed)
                GestureDetector(
                  onTap: () => _showResolveOptions(context, admin, theme, ticket),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.check_circle_outline_rounded, size: 18,
                        color: const Color(0xFF8B5CF6)),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: admin.activeChatMessages.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_outlined, size: 40,
                            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
                        const SizedBox(height: 8),
                        Text('No messages yet',
                            style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  reverse: false,
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  itemCount: admin.activeChatMessages.length,
                  itemBuilder: (context, index) {
                    final msg = admin.activeChatMessages[index];
                    return _ChatBubble(msg: msg, theme: theme, isDark: isDark);
                  },
                ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.bgDark : Colors.white,
            border: Border(top: BorderSide(
              color: (isDark ? AppTheme.borderColor : const Color(0xFFCBD5E1)).withValues(alpha: 0.3),
            )),
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
                      controller: _replyController,
                      decoration: const InputDecoration(
                        hintText: 'Type your reply...',
                        border: InputBorder.none,
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendReply(admin),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _sendReply(admin),
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
  }

  void _sendReply(AdminProvider admin) {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;
    _replyController.clear();
    admin.sendAdminReply(text);
  }

  void _showResolveOptions(
    BuildContext context,
    AdminProvider admin,
    ThemeData theme,
    SupportTicketEntity ticket,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text('Set Ticket Status',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(ticket.subject,
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13)),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.check_circle_rounded, color: Color(0xFF8B5CF6), size: 22),
                ),
                title: const Text('Mark as Resolved', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Issue is fixed — ticket archived'),
                onTap: () {
                  Navigator.pop(ctx);
                  _updateTicketStatus(admin, 'resolved');
                },
              ),
              const Divider(indent: 72, endIndent: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B7280).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.block_rounded, color: Color(0xFF6B7280), size: 22),
                ),
                title: const Text('Close Permanently', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('No further replies from user'),
                onTap: () {
                  Navigator.pop(ctx);
                  _updateTicketStatus(admin, 'closed');
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateTicketStatus(AdminProvider admin, String status) async {
    final messenger = ScaffoldMessenger.of(context);
    final success = await admin.resolveActiveTicket(status: status);
    final label = status == 'resolved' ? 'resolved' : 'closed';
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Ticket $label!' : admin.errorMessage ?? 'Failed to update',
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final SupportTicketEntity ticket;
  final UserEntity? user;
  final ThemeData theme;
  final bool isDark;
  final bool hasNewMessage;
  final VoidCallback onTap;

  const _TicketCard({
    required this.ticket,
    required this.user,
    required this.theme,
    required this.isDark,
    required this.hasNewMessage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumGlass(
      margin: const EdgeInsets.only(bottom: 6),
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppTheme.accentPurple.withValues(alpha: 0.12),
                    child: Text(
                      (user?.fullName ?? '?')[0].toUpperCase(),
                      style: TextStyle(color: AppTheme.accentPurple, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (hasNewMessage)
                    Positioned(
                      right: 0, top: 0,
                      child: Container(
                        width: 10, height: 10,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          shape: BoxShape.circle,
                          border: Border.all(color: theme.colorScheme.surface, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            user?.fullName ?? 'Unknown',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          Helpers.formatDateTime(ticket.createdAt),
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ticket.subject,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: hasNewMessage ? FontWeight.w600 : FontWeight.normal,
                        color: isDark ? AppTheme.textMuted.withValues(alpha: 0.9) : const Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 18,
                  color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessageEntity msg;
  final ThemeData theme;
  final bool isDark;

  const _ChatBubble({required this.msg, required this.theme, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isAdmin = msg.senderType == MessageSender.admin;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: isAdmin ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isAdmin ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isAdmin)
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: AppTheme.accentBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.person_rounded, size: 14, color: AppTheme.accentBlue),
                ),
              if (!isAdmin) const SizedBox(width: 6),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isAdmin
                        ? AppTheme.accentPurple
                        : (isDark ? AppTheme.borderColor : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(14),
                      topRight: const Radius.circular(14),
                      bottomLeft: Radius.circular(isAdmin ? 14 : 4),
                      bottomRight: Radius.circular(isAdmin ? 4 : 14),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isAdmin)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text('You (Admin)',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600,
                                  color: Colors.white70)),
                        ),
                      Text(msg.text,
                          style: TextStyle(
                            color: isAdmin ? Colors.white : (isDark ? Colors.white : const Color(0xFF0F172A)),
                            fontSize: 13,
                          )),
                      const SizedBox(height: 2),
                      Text(Helpers.formatDateTime(msg.createdAt),
                          style: TextStyle(fontSize: 9,
                              color: isAdmin ? Colors.white60 : (isDark ? AppTheme.textMuted : const Color(0xFF94A3B8)))),
                    ],
                  ),
                ),
              ),
              if (isAdmin) const SizedBox(width: 6),
              if (isAdmin)
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: AppTheme.accentPurple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.support_agent_rounded, size: 14, color: AppTheme.accentPurple),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBadge({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
