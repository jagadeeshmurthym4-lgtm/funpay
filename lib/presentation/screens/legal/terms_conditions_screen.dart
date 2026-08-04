import 'package:cashspark/core/widgets/premium_widgets.dart';
import 'package:flutter/material.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: PremiumAppBar(title: 'Terms & Conditions', onBack: () => Navigator.pop(context)),
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
            'Terms & Conditions',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'By creating an account and using Fun Pay, you agree to be bound by these Terms & Conditions. '
            'If you do not agree with any part of these terms, please do not use the application.',
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5, color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          _section(
            theme: theme,
            title: '1. Acceptance of Terms',
            body:
                'By registering for, accessing, or using Fun Pay, you acknowledge that you have read, '
                'understood, and agree to be bound by these Terms & Conditions and our Privacy Policy. '
                'These terms constitute a legally binding agreement between you and Fun Pay.',
          ),
          _section(
            theme: theme,
            title: '2. Eligibility',
            body:
                'You must be at least 13 years of age to use Fun Pay. By creating an account, you represent that:\n\n'
                '• You meet the minimum age requirement.\n'
                '• All registration information you provide is accurate, current, and complete.\n'
                '• You will maintain and update your information as needed.\n'
                '• You have not been previously suspended or banned from using Fun Pay.',
          ),
          _section(
            theme: theme,
            title: '3. User Responsibilities',
            body:
                'As a Fun Pay user, you agree to:\n\n'
                '• Maintain the confidentiality of your account credentials and password.\n'
                '• Accept responsibility for all activities that occur under your account.\n'
                '• Notify us immediately of any unauthorized use of your account.\n'
                '• Use the app in compliance with all applicable laws and regulations.\n'
                '• Provide accurate information during registration and verification.\n'
                '• Not attempt to manipulate, exploit, or game the reward system.',
          ),
          _section(
            theme: theme,
            title: '4. Reward Rules',
            body:
                'Rewards are earned by completing eligible activities within Fun Pay:\n\n'
                '• Rewards are credited to your wallet upon successful completion of activities.\n'
                '• Reward amounts may vary based on availability, user activity, and platform factors.\n'
                '• Daily reward limits apply as defined in the app (e.g., ad watch limits).\n'
                '• Rewards are non-transferable and have no cash value outside the platform.\n'
                '• Fun Pay reserves the right to audit, adjust, or revoke rewards if fraudulent activity is detected.\n'
                '• Reward rates, bonus structures, and earning limits may be modified at any time without prior notice.',
          ),
          _section(
            theme: theme,
            title: '5. Referral Rules',
            body:
                'The Fun Pay referral program allows you to earn bonuses by inviting new users:\n\n'
                '• Referral bonuses are awarded only for legitimate, unique new user sign-ups.\n'
                '• Self-referrals (creating multiple accounts to earn referral bonuses) are strictly prohibited.\n'
                '• Using fake identities, temporary email addresses, or virtual phone numbers to create referrals is forbidden.\n'
                '• Referring the same person multiple times is not allowed.\n'
                '• Fun Pay reserves the right to withhold or claw back referral bonuses if abuse is detected.\n'
                '• The referral program terms may be modified or discontinued at any time.',
          ),
          _section(
            theme: theme,
            title: '6. Balance & Redemption Rules',
            body:
                'Your balance is in-platform only and has no real-world monetary value:\n\n'
                '• Balance is earned by completing eligible activities and is credited to your wallet.\n'
                '• Balance is non-transferable and cannot be exchanged for cash, cryptocurrency, gift cards, or any other monetary reward.\n'
                '• Balance may be redeemed for in-platform perks such as Premium access, bonus spins, exclusive themes, and boosters.\n'
                '• A minimum redemption threshold applies and is displayed in the Redeem section.\n'
                '• Redemptions are subject to verification and fraud review before processing.\n'
                '• Fun Pay reserves the right to cancel pending redemptions if suspicious activity is detected.',
          ),
          _section(
            theme: theme,
            title: '7. Prohibited Activities',
            body:
                'The following activities are strictly prohibited on Fun Pay:\n\n'
                '• Creating multiple user accounts.\n'
                '• Using automated scripts, bots, or software to interact with the platform.\n'
                '• Manipulating or exploiting the reward system, referral program, or any feature.\n'
                '• Engaging in any fraudulent, deceptive, or misleading activities.\n'
                '• Attempting to access another user\'s account without authorization.\n'
                '• Reverse engineering, decompiling, or tampering with the app.\n'
                '• Violating any applicable local, state, national, or international law.',
          ),
          _section(
            theme: theme,
            title: '8. Account Suspension for Fraud',
            body:
                'Fun Pay takes fraud prevention seriously. Accounts found to be in violation of these terms may face:\n\n'
                '• Warning: First-time minor violations may result in a warning.\n'
                '• Temporary Suspension: Accounts may be temporarily suspended pending investigation.\n'
                '• Permanent Suspension: Accounts engaged in fraudulent or abusive behavior will be permanently suspended.\n'
                '• Reward Forfeiture: All unredeemed rewards and pending redemptions will be forfeited upon suspension.\n'
                '• Legal Action: Fun Pay reserves the right to pursue legal action for severe violations.\n\n'
                'Users will be notified of suspension with a reason provided where possible. '
                'If you believe your account was suspended in error, please contact us.',
          ),
          _section(
            theme: theme,
            title: '9. Limitation of Liability',
            body:
                'Fun Pay is provided "as is" and "as available" without warranties of any kind. '
                'To the maximum extent permitted by law, Fun Pay, its developers, and affiliates shall not be liable for:\n\n'
                '• Any indirect, incidental, special, or consequential damages.\n'
                '• Loss of profits, data, or rewards.\n'
                '• Service interruptions, bugs, or errors.\n'
                '• Actions taken by third parties, including advertisers.',
          ),
          _section(
            theme: theme,
            title: '10. Modifications to Terms',
            body:
                'Fun Pay reserves the right to modify or replace these Terms & Conditions at any time. '
                'Material changes will be notified via in-app notification or email. '
                'Your continued use of Fun Pay after any changes constitute acceptance of the new terms. '
                'If you do not agree to the changes, you must stop using the app and may delete your account.',
          ),
          _section(
            theme: theme,
            title: '11. Governing Law',
            body:
                'These Terms & Conditions shall be governed by and construed in accordance with applicable laws. '
                'Any disputes arising from these terms shall be resolved through binding arbitration.',
          ),
          _section(
            theme: theme,
            title: '12. Contact Information',
            body:
                'For questions about these Terms & Conditions, please contact us:\n\n'
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
