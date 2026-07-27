import 'package:cashspark/core/widgets/premium_widgets.dart';
import 'package:flutter/material.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  int? _expandedIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: PremiumAppBar(title: 'FAQ', onBack: () => Navigator.pop(context)),
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
          Text('Frequently Asked Questions',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Find answers to common questions about Fun Pay.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 16),
          _buildItem(theme, 0, 'How do I earn rewards?',
              'You can earn rewards through daily check-ins, watching ads, completing tasks, referring friends, and participating in promotional events.'),
          _buildItem(theme, 1, 'How do I withdraw my earnings?',
              'Go to the Withdraw section from the home screen. Select your preferred method (UPI, Paytm, or Bank Transfer). Minimum withdrawal is \u20B945 and maximum is \u20B9500 per transaction.'),
          _buildItem(theme, 2, 'How long do withdrawals take?',
              'Withdrawals are reviewed and typically processed within 24-48 hours. Approved withdrawals are sent immediately.'),
          _buildItem(theme, 3, 'How does the referral program work?',
              'Share your unique referral code with friends. When they sign up using your code, both you and your friend receive a bonus. Track referrals in the Referral Dashboard.'),
          _buildItem(theme, 4, 'Is there a limit on daily earnings?',
              'Yes, there are daily limits to ensure fair usage. Check the Rewards section for current limits. Daily withdrawal limit is \u20B91,000.'),
          _buildItem(theme, 5, 'How do I reset my password?',
              'Go to the Login screen and tap "Forgot Password". Enter your email / Gmail address to receive a password reset link.'),
          _buildItem(theme, 6, 'Can I have multiple accounts?',
              'No, multiple accounts are strictly prohibited. Our fraud detection system monitors for duplicate accounts. Violations result in account suspension.'),
          _buildItem(theme, 7, 'How is my data protected?',
              'Your data is encrypted and stored securely with Firebase Firestore. We implement device fingerprinting, login monitoring, and fraud detection.'),
          _buildItem(theme, 8, 'What happens if I delete my account?',
              'Account deletion is permanent. All personal data, rewards, and wallet balance will be deleted. This action cannot be undone.'),
          _buildItem(theme, 9, 'How do I contact support?',
              'Email us at support@funpay.com or use the Contact Us page. We typically respond within 24 hours.'),
          const SizedBox(height: 32),
        ],
      ),
      ),
    );
  }

  Widget _buildItem(ThemeData theme, int index, String question, String answer) {
    final isExpanded = _expandedIndex == index;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          setState(() {
            _expandedIndex = isExpanded ? null : index;
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(question,
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w600)),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              if (isExpanded)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(answer,
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.5)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
