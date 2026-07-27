import 'package:cashspark/core/widgets/premium_widgets.dart';
import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: PremiumAppBar(title: 'Privacy Policy', onBack: () => Navigator.pop(context)),
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
            'Last updated: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Text(
            'Privacy Policy',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'This Privacy Policy explains how Fun Pay collects, uses, and protects your personal information.',
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          _section(
            theme: theme,
            title: '1. Information We Collect',
            body:
                'We collect the following types of information to provide and improve our services:\n\n'
                '• Account Information: Name, email address, phone number, and profile details provided during registration.\n'
                '• Authentication Data: Firebase Authentication manages your login credentials securely.\n'
                '• Transaction History: Records of rewards earned, withdrawals made, and referral activities.\n'
                '• Device Information: Device type, operating system, and unique device identifiers for fraud prevention.\n'
                '• Ad Interaction Data: Ad views and interactions for analytics and reward calculation.',
          ),
          _section(
            theme: theme,
            title: '2. Firebase Services',
            body:
                'Fun Pay uses the following Firebase services, operated by Google LLC:\n\n'
                '• Firebase Authentication: Manages user registration and secure login. We store your email, hashed password, and phone number.\n'
                '• Cloud Firestore: Stores user profiles, wallet balances, reward history, referral data, and consent agreements.\n'
                '• Firebase Cloud Messaging: Sends push notifications about rewards, withdrawals, and account updates.\n'
                '• Firebase Crashlytics: Collects crash reports and performance data to improve app stability.\n\n'
                'For more information on how Firebase processes data, visit the Google Privacy Policy.',
          ),
          _section(
            theme: theme,
            title: '3. AdMob Advertising',
            body:
                'Fun Pay integrates Google AdMob to serve rewarded video ads. AdMob may collect:\n\n'
                '• Device advertising identifiers (e.g., Google Advertising ID)\n'
                '• IP address and device location (approximate)\n'
                '• Ad interaction data (views, clicks, engagement)\n\n'
                'AdMob uses this data to deliver relevant ads and measure ad performance. '
                'You can opt out of interest-based advertising through your device settings. '
                'By using Fun Pay, you consent to AdMob\'s data collection as described in Google\'s Privacy Policy.',
          ),
          _section(
            theme: theme,
            title: '4. User Rewards System',
            body:
                'Fun Pay operates a rewards-based system where users earn rewards for:\n\n'
                '• Watching rewarded video advertisements\n'
                '• Completing daily check-ins and maintaining streaks\n'
                '• Completing tasks and challenges\n'
                '• Referring new users to the platform\n\n'
                'Reward data (type, amount, timestamps) is stored in Firestore to track your earnings. '
                'Referral information is recorded to verify legitimate referrals and prevent abuse.',
          ),
          _section(
            theme: theme,
            title: '5. How We Use Your Information',
            body:
                'We use your information to:\n\n'
                '• Operate, maintain, and improve Fun Pay\n'
                '• Process and track rewards, withdrawals, and referral bonuses\n'
                '• Detect, prevent, and investigate fraudulent or prohibited activities\n'
                '• Send notifications about rewards, account updates, and policy changes\n'
                '• Comply with legal obligations and enforce our Terms & Conditions',
          ),
          _section(
            theme: theme,
            title: '6. Data Security',
            body:
                'We implement industry-standard security measures to protect your data:\n\n'
                '• Encryption in Transit: All data transmitted between the app and Firebase is encrypted using TLS/SSL.\n'
                '• Encryption at Rest: Data stored in Firestore is encrypted using AES-256.\n'
                '• Firebase Security Rules: Access to Firestore documents is restricted based on user authentication and data ownership.\n'
                '• Secure Authentication: Passwords are never stored in plain text; Firebase handles hashing and salting.\n'
                '• Fraud Monitoring: Automated systems monitor for suspicious activity to protect user accounts.',
          ),
          _section(
            theme: theme,
            title: '7. Data Sharing and Third Parties',
            body:
                'We do not sell your personal information to third parties. Data may be shared with:\n\n'
                '• Firebase (Google): For authentication, database, notifications, and crash reporting.\n'
                '• Google AdMob: For serving advertisements.\n'
                '• Law Enforcement: If required by law or to protect our legal rights.\n\n'
                'All third-party service providers are contractually obligated to protect your data.',
          ),
          _section(
            theme: theme,
            title: '8. Your Rights',
            body:
                'You have the following rights regarding your personal data:\n\n'
                '• Access: View your account data anytime in the app.\n'
                '• Update: Edit your profile information in Settings.\n'
                '• Export: Request a copy of your data by contacting us.\n'
                '• Delete: Delete your account and associated data through the Profile screen.\n'
                '• Withdraw Consent: Uninstall the app and contact us to request data removal.',
          ),
          _section(
            theme: theme,
            title: '9. Account Deletion',
            body:
                'You can delete your account at any time through the Profile screen in the app. '
                'Upon account deletion:\n\n'
                '• Your profile, wallet, and reward data will be permanently removed from Firestore within 30 days.\n'
                '• Transaction records may be retained for legal and compliance purposes.\n'
                '• Firebase Authentication account will be deleted.\n'
                '• Any pending withdrawals will be cancelled.',
          ),
          _section(
            theme: theme,
            title: '10. Children\'s Privacy',
            body:
                'Fun Pay is not intended for users under 13 years of age. '
                'We do not knowingly collect personal information from children under 13. '
                'If we discover that a child under 13 has provided us with personal data, '
                'we will take steps to delete that information immediately.',
          ),
          _section(
            theme: theme,
            title: '11. Changes to This Policy',
            body:
                'We may update this Privacy Policy from time to time. '
                'Users will be notified of material changes via in-app notification or email. '
                'Continued use of Fun Pay after changes constitutes acceptance of the updated policy. '
                'We encourage you to review this page periodically.',
          ),
          _section(
            theme: theme,
            title: '12. Contact Us',
            body:
                'For privacy-related inquiries, data requests, or questions about this policy, please contact us:\n\n'
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
