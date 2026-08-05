import 'package:cashspark/core/widgets/premium_widgets.dart';
import 'package:flutter/material.dart';

class DisclaimerScreen extends StatelessWidget {
  const DisclaimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: PremiumAppBar(title: 'Disclaimer', onBack: () => Navigator.pop(context)),
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
          Text(
            'Disclaimer',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Please read this disclaimer carefully before using Fun Pay.',
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          _section(
            theme: theme,
            title: 'General Information',
            body:
                'Fun Pay is a reward-based platform that allows users to earn rewards by completing '
                'various activities such as watching advertisements, completing tasks, and referring new users. '
                'The information provided on this platform is for general informational and entertainment purposes only.',
          ),
          _section(
            theme: theme,
            title: 'Rewards Are Not Guaranteed',
            body:
                'Fun Pay does not guarantee any specific amount of earnings, rewards, or referral bonuses. '
                'Earnings may vary significantly based on:\n\n'
                '• User activity and engagement levels.\n'
                '• Availability of tasks and reward opportunities.\n'
                '• Geographic location and market conditions.\n'
                '• Changes to platform policies and reward structures.\n\n'
                'Past earnings or performance does not guarantee future results. '
                'Users should not rely on Fun Pay as a primary source of income.',
          ),
          _section(
            theme: theme,
            title: 'Ad Availability',
            body:
                'Fun Pay displays rewarded video advertisements through Google AdMob. '
                'Ad availability depends on several factors beyond our control:\n\n'
                '• Advertiser campaigns and budgets.\n'
                '• Geographic region and device compatibility.\n'
                '• Time of day and seasonality.\n'
                '• User demographics and advertising inventory.\n\n'
                'If no ads are currently available, the "Watch Ad" option may be temporarily disabled. '
                'Ad availability may fluctuate throughout the day. Fun Pay cannot guarantee that ads '
                'will always be available for viewing.',
          ),
          _section(
            theme: theme,
            title: 'Modification of Rewards and Features',
            body:
                'Fun Pay reserves the right to modify, suspend, or discontinue any aspect of the platform '
                'at any time without prior notice, including but not limited to:\n\n'
                '• Reward rates, bonus structures, and earning limits.\n'
                '• Daily ad watch limits and reward values per ad.\n'
                '• Referral program terms and bonus amounts.\n'
                '• Withdrawal thresholds, limits, and processing fees.\n'
                '• Features, functionality, and user interface.\n'
                '• Terms, conditions, and policies.\n\n'
                'Fun Pay is not liable for any impact that modifications may have on your existing rewards, '
                'pending withdrawals, or overall user experience.',
          ),
          _section(
            theme: theme,
            title: 'No Financial Advice',
            body:
                'Fun Pay does not provide financial, investment, or legal advice. '
                'Any information provided on the platform regarding earnings, rewards, or bonuses is '
                'for informational purposes only and should not be construed as financial advice. '
                'Users are encouraged to seek professional advice for any financial decisions.',
          ),
          _section(
            theme: theme,
            title: 'Third-Party Links and Services',
            body:
                'Fun Pay may contain links to third-party websites, services, or advertisements. '
                'We are not responsible for the content, privacy policies, or practices of any third-party '
                'sites or services. Accessing third-party links is at your own risk, and we encourage '
                'you to review their terms and policies.',
          ),
          _section(
            theme: theme,
            title: 'Accuracy of Information',
            body:
                'While we strive to keep all information on Fun Pay accurate and up-to-date, '
                'we make no representations or warranties of any kind, express or implied, about the '
                'completeness, accuracy, reliability, suitability, or availability of any information, '
                'products, services, or related graphics on the platform.',
          ),
          _section(
            theme: theme,
            title: 'Limitation of Liability',
            body:
                'To the fullest extent permitted by applicable law, Fun Pay, its developers, affiliates, '
                'officers, and employees shall not be liable for any direct, indirect, incidental, special, '
                'consequential, or punitive damages, including but not limited to loss of profits, data, use, '
                'goodwill, or other intangible losses resulting from:\n\n'
                '• Your access to or use of (or inability to access or use) the platform.\n'
                '• Any conduct or content of any third party on the platform.\n'
                '• Unauthorized access, use, or alteration of your transmissions or content.\n'
                '• Suspension or termination of your account.',
          ),
          _section(
            theme: theme,
            title: 'Contact Us',
            body:
                'If you have any questions about this disclaimer, please contact us:\n\n'
                'Email: jagadeeshmurthym4@gmail.com\n'
                'Or visit the Contact Us page in the app.',
          ),
          const SizedBox(height: 32),
        ],
      ),
      ),
    );
  }

  Widget _section({
    required ThemeData theme,
    required String title,
    required String body,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
