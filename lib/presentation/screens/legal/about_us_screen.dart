import 'package:cashspark/core/widgets/premium_widgets.dart';
import 'package:flutter/material.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: PremiumAppBar(title: 'About Us', onBack: () => Navigator.pop(context)),
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
          Center(
            child: Column(
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(Icons.attach_money_rounded, size: 48, color: theme.colorScheme.primary),
                ),
                const SizedBox(height: 16),
                Text('Fun Pay', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Version ${const String.fromEnvironment("APP_VERSION", defaultValue: "1.0.0")}',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _section(theme, 'Our Mission',
              'Fun Pay is designed to help users earn and manage their finances through a simple, transparent reward platform. '
              'We believe in making financial growth accessible to everyone through engaging activities and a fair reward system.'),
          _section(theme, 'What We Offer',
              '• Daily rewards and bonuses\n'
              '• Referral program with generous bonuses\n'
              '• Secure wallet and withdrawal system\n'
              '• Real-time transaction tracking\n'
              '• 24/7 customer support\n'
              '• Fraud detection and account protection'),
          _section(theme, 'Our Values',
              'Transparency, security, and user trust are at the core of everything we build. '
              'We continuously improve our platform to provide the best possible experience for our users '
              'while maintaining the highest standards of data protection and fair practices.'),
          _section(theme, 'Contact',
              'Email: support@funpay.com\n'
              'Response time: Within 24 hours\n'
              'We\'re here to help with any questions or concerns.'),
          const SizedBox(height: 32),
        ],
      ),
      ),
    );
  }

  Widget _section(ThemeData theme, String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(body, style: theme.textTheme.bodyMedium?.copyWith(height: 1.5, color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
