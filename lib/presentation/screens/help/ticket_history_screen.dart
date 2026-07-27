import 'package:cashspark/core/theme/app_theme.dart';
import 'package:cashspark/core/utils/helpers.dart';
import 'package:cashspark/core/widgets/premium_widgets.dart';
import 'package:cashspark/domain/entities/support_ticket_entity.dart';
import 'package:cashspark/presentation/providers/auth_provider.dart';
import 'package:cashspark/presentation/providers/help_provider.dart';
import 'package:cashspark/presentation/routes/app_router.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TicketHistoryScreen extends StatefulWidget {
  const TicketHistoryScreen({super.key});

  @override
  State<TicketHistoryScreen> createState() => _TicketHistoryScreenState();
}

class _TicketHistoryScreenState extends State<TicketHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().user?.uid;
      if (userId != null) {
        context.read<HelpProvider>().loadTickets(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: PremiumAppBar(
        title: 'My Tickets',
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
            if (hp.ticketsLoading) {
              return const Center(child: PremiumLoader());
            }

            if (hp.tickets.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.accentPurple.withValues(alpha: 0.1),
                        ),
                        child: Icon(Icons.assignment_outlined, size: 40,
                            color: AppTheme.accentPurple.withValues(alpha: 0.5)),
                      ),
                      const SizedBox(height: 20),
                      Text('No tickets yet',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text('Your support tickets will appear here',
                          style: theme.textTheme.bodyMedium?.copyWith(
                              color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8))),
                    ],
                  ),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                final userId = context.read<AuthProvider>().user?.uid;
                if (userId != null) hp.loadTickets(userId);
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: hp.tickets.length,
                itemBuilder: (context, index) {
                  final ticket = hp.tickets[index];
                  return _TicketCard(ticket: ticket, theme: theme, isDark: isDark);
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final SupportTicketEntity ticket;
  final ThemeData theme;
  final bool isDark;

  const _TicketCard({
    required this.ticket,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PremiumGlass(
        padding: const EdgeInsets.all(16),
        child: InkWell(
          onTap: () => Navigator.pushNamed(
            context,
            AppRouter.ticketDetail,
            arguments: ticket,
          ),
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor(ticket.status).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(_statusLabel(ticket.status),
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                            color: _statusColor(ticket.status))),
                  ),
                  const Spacer(),
                  Text('#${ticket.ticketId.length > 12 ? ticket.ticketId.substring(0, 12) : ticket.ticketId}',
                      style: TextStyle(fontSize: 11,
                          color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8))),
                ],
              ),
              const SizedBox(height: 10),
              Text(ticket.subject,
                  style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF0F172A))),
              const SizedBox(height: 4),
              Text(ticket.message,
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13,
                      color: isDark ? AppTheme.textMuted : const Color(0xFF64748B))),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.category_outlined, size: 14,
                      color: isDark ? AppTheme.textMuted.withValues(alpha: 0.5) : const Color(0xFF94A3B8).withValues(alpha: 0.5)),
                  const SizedBox(width: 4),
                  Text(_categoryLabel(ticket.category),
                      style: TextStyle(fontSize: 11,
                          color: isDark ? AppTheme.textMuted.withValues(alpha: 0.5) : const Color(0xFF94A3B8).withValues(alpha: 0.5))),
                  const SizedBox(width: 16),
                  Icon(Icons.access_time_rounded, size: 14,
                      color: isDark ? AppTheme.textMuted.withValues(alpha: 0.5) : const Color(0xFF94A3B8).withValues(alpha: 0.5)),
                  const SizedBox(width: 4),
                  Text(Helpers.formatDateTime(ticket.createdAt),
                      style: TextStyle(fontSize: 11,
                          color: isDark ? AppTheme.textMuted.withValues(alpha: 0.5) : const Color(0xFF94A3B8).withValues(alpha: 0.5))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(TicketStatus status) {
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
