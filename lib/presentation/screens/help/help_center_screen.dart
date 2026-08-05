import 'package:cashspark/core/theme/app_theme.dart';
import 'package:cashspark/core/widgets/premium_widgets.dart';
import 'package:cashspark/presentation/routes/app_router.dart';
import 'package:flutter/material.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: PremiumAppBar(
        title: 'Help Center',
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
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header
            PremiumGlass(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [AppTheme.accentPurple, AppTheme.accentBlue],
                      ),
                    ),
                    child: const Icon(Icons.support_agent_rounded, size: 36, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Text('How can we help you?',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Find answers, raise tickets, or chat with our support team.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark ? AppTheme.textMuted : const Color(0xFF64748B))),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Quick action cards
            _HelpCard(
              icon: Icons.help_outline_rounded,
              title: 'FAQ',
              subtitle: 'Browse frequently asked questions',
              color: AppTheme.accentGreen,
              onTap: () => Navigator.pushNamed(context, AppRouter.faq),
            ),
            const SizedBox(height: 12),
            _HelpCard(
              icon: Icons.assignment_outlined,
              title: 'My Tickets',
              subtitle: 'View your support ticket history',
              color: AppTheme.accentPurple,
              onTap: () => Navigator.pushNamed(context, AppRouter.ticketHistory),
            ),
            const SizedBox(height: 12),
            _HelpCard(
              icon: Icons.add_circle_outline,
              title: 'Contact Support',
              subtitle: 'Raise a new support ticket',
              color: AppTheme.accentBlue,
              onTap: () => Navigator.pushNamed(context, AppRouter.contactSupport),
            ),
            const SizedBox(height: 12),
            _HelpCard(
              icon: Icons.chat_outlined,
              title: 'Live Chat',
              subtitle: 'Chat with our support team in real time',
              color: AppTheme.accentOrange,
              onTap: () => Navigator.pushNamed(context, AppRouter.liveChat),
            ),

            const SizedBox(height: 24),

            // Response times
            PremiumGlass(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Response Times',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  _responseRow(theme, 'General Inquiries', 'Within 24 hrs'),
                  const Divider(height: 16),
                  _responseRow(theme, 'Account Issues', 'Within 12 hrs'),
                  const Divider(height: 16),
                  _responseRow(theme, 'Withdrawal Issues', 'Within 6 hrs'),
                  const Divider(height: 16),
                  _responseRow(theme, 'Urgent Security', 'Within 2 hrs'),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _responseRow(ThemeData theme, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodySmall),
        Text(value,
            style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600, color: theme.colorScheme.primary)),
      ],
    );
  }
}

class _HelpCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _HelpCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PremiumGlass(
      padding: const EdgeInsets.all(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            IconContainer(icon: icon, color: color, containerSize: 44),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15,
                          color: isDark ? Colors.white : const Color(0xFF0F172A))),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(fontSize: 12,
                          color: isDark ? AppTheme.textMuted : const Color(0xFF64748B))),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 20,
                color: isDark ? AppTheme.textMuted.withValues(alpha: 0.4) : const Color(0xFF94A3B8).withValues(alpha: 0.4)),
          ],
        ),
      ),
    );
  }
}
