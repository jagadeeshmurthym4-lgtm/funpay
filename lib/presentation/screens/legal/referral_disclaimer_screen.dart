import 'package:cashspark/core/widgets/premium_widgets.dart';
import 'package:flutter/material.dart';

class ReferralDisclaimerScreen extends StatelessWidget {
  const ReferralDisclaimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: PremiumAppBar(title: 'Referral Program', onBack: () => Navigator.pop(context)),
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
              'Referral Program Rules',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Last updated: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Text(
              'This page explains how the Fun Pay referral reward system works. '
              'By participating in the referral program, you agree to the terms outlined below.',
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.5,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),

            _section(
              theme: theme,
              title: '1. How It Works',
              body:
                  'When you refer a friend to Fun Pay using your unique referral code:\n\n'
                  '• Your friend enters your referral code during sign-up.\n'
                  '• The referral is recorded once your friend completes their profile.\n'
                  '• No reward is given at sign-up. Rewards are only earned when your referred user\n'
                  '  completes real earning activities.',
            ),
            _section(
              theme: theme,
              title: '2. First Approved Project Bonus (₹7)',
              body:
                  'The referrer earns ₹7 only after the referred user completes their FIRST approved project.\n\n'
                  '• The referred user must start a project, submit proof of completion, and have that '
                  'submission reviewed and approved by our admin team.\n'
                  '• The ₹7 bonus is credited to the referrer\'s wallet automatically upon approval.\n'
                  '• Only one ₹7 bonus per referred user. Duplicate rewards for the same referred user '
                  'are prevented.\n'
                  '• If the referred user\'s project submission is rejected, no bonus is awarded.',
            ),
            _section(
              theme: theme,
              title: '3. Ongoing Commission (5%)',
              body:
                  'After the first approved project, the referrer earns a 5% commission on every future '
                  'approved project reward earned by that referred user.\n\n'
                  '• Commission is calculated as 5% of the project reward amount.\n'
                  '• Commission is credited to the referrer\'s wallet immediately upon project approval.\n'
                  '• There is no limit to how many commissions you can earn from a single referred user.\n'
                  '• Commission applies to all approved projects your referred user completes.',
            ),
            _section(
              theme: theme,
              title: '4. Duplicate Reward Prevention',
              body:
                  'The system tracks every project that generates a referral reward:\n\n'
                  '• Each approved project is recorded with a unique project ID.\n'
                  '• If a project ID is already associated with a referral reward, no additional reward '
                  'is given.\n'
                  '• This prevents the same project from generating multiple referral bonuses.',
            ),
            _section(
              theme: theme,
              title: '5. Referral History & Tracking',
              body:
                  'Your referral dashboard displays:\n\n'
                  '• Total Referrals: The number of users who signed up using your code.\n'
                  '• Active Referrals: Referred users who have completed at least one approved project.\n'
                  '• Referral Earnings: Total ₹7 first-project bonuses earned.\n'
                  '• Lifetime Commission: Total 5% commissions earned from all referred users.',
            ),
            _section(
              theme: theme,
              title: '6. Prohibited Activities',
              body:
                  'The following activities are strictly prohibited:\n\n'
                  '• Self-referrals: Creating multiple accounts to earn referral bonuses from yourself.\n'
                  '• Fake referrals: Using temporary email addresses, virtual phone numbers, or fake identities.\n'
                  '• Incentivized sign-ups: Paying or offering incentives to others to sign up using your code.\n'
                  '• Referral spam: Mass-sharing your referral code in inappropriate places.\n'
                  '• Duplicate referrals: Referring the same person multiple times.',
            ),
            _section(
              theme: theme,
              title: '7. Reward Forfeiture & Suspension',
              body:
                  'If fraudulent referral activity is detected:\n\n'
                  '• Referral bonuses and commissions may be revoked without notice.\n'
                  '• The referrer\'s account may be temporarily or permanently suspended.\n'
                  '• All unredeemed rewards and pending redemptions may be forfeited.\n'
                  '• Fun Pay reserves the right to audit referral activity at any time.\n\n'
                  'If you believe a referral reward was incorrectly withheld, please contact our support team.',
            ),
            _section(
              theme: theme,
              title: '8. Program Modifications',
              body:
                  'Fun Pay reserves the right to modify, suspend, or discontinue the referral program '
                  'at any time without prior notice. Changes may include:\n\n'
                  '• Reward amounts and commission rates.\n'
                  '• Eligibility criteria and program rules.\n'
                  '• Redemption thresholds and processing timelines.\n\n'
                  'Your continued participation in the referral program after any changes constitutes '
                  'acceptance of the new terms.',
            ),
            _section(
              theme: theme,
              title: '9. Contact Information',
              body:
                  'If you have questions about the referral program or believe a reward was processed '
                  'incorrectly, please contact us:\n\n'
                  'Email: jagadeeshmurthym4@gmail.com\n'
                  'Or visit the Help Center in the app.',
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
