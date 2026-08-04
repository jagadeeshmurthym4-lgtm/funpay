import 'package:cashspark/core/theme/app_theme.dart';
import 'package:cashspark/core/utils/responsive.dart';
import 'package:cashspark/core/widgets/adsense_banner.dart';
import 'package:cashspark/core/widgets/premium_widgets.dart';
import 'package:cashspark/presentation/routes/app_router.dart';
import 'package:flutter/material.dart';

/// Public landing page shown to unauthenticated visitors.
///
/// Provides substantial public content (features, how it works, FAQ, legal
/// links) so site reviewers and search engines see real content without
/// requiring a login.
class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.bgDark : const Color(0xFFF0F5FF),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context, isDark),
              _buildHero(context, isDark),
              _buildStatsStrip(context, isDark),
              const AdSenseBanner(adSlot: '6222511573', height: 110),
              _buildFeatures(context, isDark),
              _buildHowItWorks(context, isDark),
              _buildFaq(context, isDark),
              _buildCta(context, isDark),
              _buildFooter(context, isDark),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════════════════════════

  Widget _buildHeader(BuildContext context, bool isDark) {
    final rs = context.responsive;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: rs.w(20), vertical: rs.h(14)),
      child: Row(
        children: [
          // Logo
          Container(
            width: rs.avatarSm,
            height: rs.avatarSm,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF4ADE80), Color(0xFF22C55E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(Icons.auto_awesome, size: 18, color: Colors.black),
          ),
          const SizedBox(width: 10),
          Text(
            'Fun Pay',
            style: rs.h3.copyWith(
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const Spacer(),
          // Sign In button
          TextButton(
            onPressed: () =>
                Navigator.pushNamed(context, AppRouter.login),
            style: TextButton.styleFrom(
              foregroundColor:
                  isDark ? AppTheme.textSecondary : const Color(0xFF475569),
              padding: EdgeInsets.symmetric(horizontal: rs.w(10)),
            ),
            child: Text('Sign In', style: rs.buttonSmall),
          ),
          const SizedBox(width: 4),
          // Get Started button
          GradientButton(
            label: 'Get Started',
            onPressed: () =>
                Navigator.pushNamed(context, AppRouter.registration),
            height: rs.h(40),
            icon: Icons.arrow_forward_rounded,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // HERO
  // ═══════════════════════════════════════════════════════════

  Widget _buildHero(BuildContext context, bool isDark) {
    final rs = context.responsive;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: rs.w(20)),
      padding: EdgeInsets.all(rs.w(24)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(rs.r(24)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF0F2740), Color(0xFF1A3350)]
              : const [Color(0xFF0F2740), Color(0xFF1E4E6B)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4ADE80).withValues(alpha: 0.15),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: rs.w(10), vertical: rs.h(5)),
            decoration: BoxDecoration(
              color: const Color(0xFF4ADE80).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified_rounded,
                    size: 14, color: Color(0xFF4ADE80)),
                const SizedBox(width: 6),
                Text(
                  'Earn rewards for everyday activities',
                  style: rs.tiny.copyWith(color: const Color(0xFF4ADE80)),
                ),
              ],
            ),
          ),
          SizedBox(height: rs.spaceLg),
          Text(
            'Turn your daily\nroutine into rewards',
            style: rs.h1.copyWith(
              color: Colors.white,
              fontSize: rs.fs(30),
              height: 1.15,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: rs.spaceMd),
          Text(
            'Complete tasks, watch videos, check in daily, and refer friends '
            'to earn rewards. Redeem them for premium features, bonus '
            'spins, exclusive themes and boosters — all inside the app.',
            style: rs.body.copyWith(
              color: Colors.white.withValues(alpha: 0.75),
              height: 1.5,
            ),
          ),
          SizedBox(height: rs.spaceXxl),
          Row(
            children: [
              Expanded(
                child: GradientButton(
                  label: 'Create Free Account',
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRouter.registration),
                  icon: Icons.person_add_alt_1_rounded,
                  height: rs.h(46),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRouter.login),
                  icon: const Icon(Icons.lock_open_rounded, size: 16),
                  label: Text('Log In', style: rs.buttonSmall),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                    padding: EdgeInsets.symmetric(vertical: rs.h(13)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(rs.r(14)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // STATS STRIP
  // ═══════════════════════════════════════════════════════════

  Widget _buildStatsStrip(BuildContext context, bool isDark) {
    final rs = context.responsive;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: rs.w(20), vertical: rs.h(20)),
      padding: EdgeInsets.symmetric(vertical: rs.h(16)),
      decoration: BoxDecoration(
        color: (isDark ? AppTheme.bgCard : Colors.white).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(rs.r(16)),
        border: Border.all(
          color: (isDark ? AppTheme.borderColor : const Color(0xFFE2E8F0))
              .withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          _statItem(context, 'Watch', 'Rewarded Videos'),
          _divider(isDark, rs),
          _statItem(context, 'Daily', 'Check-ins & Streaks'),
          _divider(isDark, rs),
          _statItem(context, 'Instant', 'Reward Credit'),
        ],
      ),
    );
  }

  Widget _statItem(BuildContext context, String value, String label) {
    final rs = context.responsive;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: rs.h3.copyWith(
              color: AppTheme.accentGreen,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: rs.caption.copyWith(
              color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _divider(bool isDark, ResponsiveSize rs) {
    return Container(
      width: 1,
      height: rs.h(30),
      color: (isDark ? AppTheme.borderColor : const Color(0xFFE2E8F0))
          .withValues(alpha: 0.6),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // FEATURES
  // ═══════════════════════════════════════════════════════════

  Widget _buildFeatures(BuildContext context, bool isDark) {
    final rs = context.responsive;

    final features = [
      (
        icon: Icons.play_circle_fill_rounded,
        color: const Color(0xFF4ADE80),
        title: 'Watch & Earn',
        desc: 'Watch short rewarded videos to earn rewards quickly.',
      ),
      (
        icon: Icons.event_available_rounded,
        color: const Color(0xFF3B82F6),
        title: 'Daily Check-ins',
        desc: 'Check in every day and build streaks for bonus rewards.',
      ),
      (
        icon: Icons.checklist_rounded,
        color: const Color(0xFF8B5CF6),
        title: 'Tasks & Challenges',
        desc: 'Complete fun tasks and challenges for bigger rewards.',
      ),
      (
        icon: Icons.people_alt_rounded,
        color: const Color(0xFFF59E0B),
        title: 'Refer & Earn',
        desc: 'Invite friends and earn rewards when they join and participate.',
      ),
      (
        icon: Icons.casino_rounded,
        color: const Color(0xFFEC4899),
        title: 'Lucky Wheel',
        desc: 'Spin the wheel for bonus rewards and exciting prizes.',
      ),
      (
        icon: Icons.redeem_rounded,
        color: const Color(0xFF06B6D4),
        title: 'Redeem Perks',
        desc: 'Spend rewards on premium features, themes, spins and boosters.',
      ),
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: rs.w(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(context, 'Why Fun Pay?', 'Everything you need to earn'),
          SizedBox(height: rs.spaceLg),
          ...features.map(
            (f) => Padding(
              padding: EdgeInsets.only(bottom: rs.spaceMd),
              child: _featureCard(context, f.icon, f.color, f.title, f.desc),
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureCard(BuildContext context, IconData icon, Color color,
      String title, String desc) {
    final rs = context.responsive;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PremiumGlass(
      padding: EdgeInsets.all(rs.w(16)),
      child: Row(
        children: [
          Container(
            width: rs.avatarMd,
            height: rs.avatarMd,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(rs.r(12)),
            ),
            child: Icon(icon, size: rs.iconMd, color: color),
          ),
          SizedBox(width: rs.spaceLg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: rs.body.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  desc,
                  style: rs.bodySmall.copyWith(
                    color:
                        isDark ? AppTheme.textMuted : const Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // HOW IT WORKS
  // ═══════════════════════════════════════════════════════════

  Widget _buildHowItWorks(BuildContext context, bool isDark) {
    final rs = context.responsive;

    final steps = [
      (
        num: '1',
        title: 'Create your account',
        desc: 'Sign up free with email or Google in under a minute.',
        icon: Icons.person_add_alt_1_rounded,
      ),
      (
        num: '2',
        title: 'Earn Rewards',
        desc: 'Watch videos, complete tasks, check in, and refer friends.',
        icon: Icons.stars_rounded,
      ),
      (
        num: '3',
        title: 'Redeem for perks',
        desc: 'Unlock premium features, themes, spins and boosters.',
        icon: Icons.auto_awesome_rounded,
      ),
    ];

    return Container(
      margin: EdgeInsets.symmetric(horizontal: rs.w(20), vertical: rs.h(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(context, 'How It Works', 'Three simple steps'),
          SizedBox(height: rs.spaceLg),
          ...steps.map(
            (s) => Padding(
              padding: EdgeInsets.only(bottom: rs.spaceMd),
              child: _stepCard(context, s.num, s.title, s.desc, s.icon),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepCard(BuildContext context, String num, String title, String desc,
      IconData icon) {
    final rs = context.responsive;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PremiumGlass(
      padding: EdgeInsets.all(rs.w(16)),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: rs.avatarLg,
                height: rs.avatarLg,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.accentGreen.withValues(alpha: 0.1),
                ),
              ),
              Text(
                num,
                style: rs.h2.copyWith(
                  color: AppTheme.accentGreen,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          SizedBox(width: rs.spaceLg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: rs.body.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  desc,
                  style: rs.bodySmall.copyWith(
                    color:
                        isDark ? AppTheme.textMuted : const Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded,
              size: 20,
              color: (isDark ? AppTheme.textMuted : const Color(0xFF94A3B8))
                  .withValues(alpha: 0.5)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // FAQ
  // ═══════════════════════════════════════════════════════════

  Widget _buildFaq(BuildContext context, bool isDark) {
    final rs = context.responsive;

    final faqs = [
      (
        q: 'Is Fun Pay free to use?',
        a: 'Yes! Creating an account and earning rewards is completely free. '
            'Just sign up and start completing activities.',
      ),
      (
        q: 'How do I earn rewards?',
        a: 'Watch rewarded videos, complete daily check-ins, finish tasks and '
            'challenges, and refer friends. Rewards are credited to your '
            'wallet automatically.',
      ),
      (
        q: 'What can I redeem my rewards for?',
        a: 'Rewards can be spent on in-platform perks such as Premium access, '
            'bonus spins, exclusive themes and booster packs. Rewards have no '
            'cash value and cannot be exchanged for money.',
      ),
      (
        q: 'Is my data safe?',
        a: 'Yes. We use Firebase security rules, encrypted connections and '
            'fraud monitoring to protect your account and personal data.',
      ),
    ];

    return Container(
      margin: EdgeInsets.symmetric(horizontal: rs.w(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(context, 'FAQ', 'Frequently asked questions'),
          SizedBox(height: rs.spaceLg),
          ...faqs.map(
            (f) => Padding(
              padding: EdgeInsets.only(bottom: rs.spaceMd),
              child: _faqCard(context, f.q, f.a),
            ),
          ),
          SizedBox(height: rs.spaceSm),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pushNamed(context, AppRouter.faq),
              child: Text(
                'View all FAQs',
                style: rs.buttonSmall.copyWith(color: AppTheme.accentGreen),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _faqCard(BuildContext context, String q, String a) {
    final rs = context.responsive;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PremiumGlass(
      padding: EdgeInsets.all(rs.w(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.help_outline_rounded,
                  size: 18, color: AppTheme.accentGreen),
              SizedBox(width: rs.spaceSm),
              Expanded(
                child: Text(
                  q,
                  style: rs.body.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.only(left: rs.w(26)),
            child: Text(
              a,
              style: rs.bodySmall.copyWith(
                color: isDark ? AppTheme.textMuted : const Color(0xFF64748B),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // CTA
  // ═══════════════════════════════════════════════════════════

  Widget _buildCta(BuildContext context, bool isDark) {
    final rs = context.responsive;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: rs.w(20), vertical: rs.h(28)),
      padding: EdgeInsets.all(rs.w(24)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(rs.r(24)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4ADE80), Color(0xFF22C55E)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4ADE80).withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Ready to start earning rewards?',
            textAlign: TextAlign.center,
            style: rs.h2.copyWith(
              color: Colors.black,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Join thousands of members earning rewards every day.',
            textAlign: TextAlign.center,
            style: rs.bodySmall.copyWith(
              color: Colors.black.withValues(alpha: 0.7),
            ),
          ),
          SizedBox(height: rs.spaceLg),
          SizedBox(
            width: double.infinity,
            height: rs.h(46),
            child: ElevatedButton.icon(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRouter.registration),
              icon: const Icon(Icons.rocket_launch_rounded, size: 18),
              label: Text('Get Started Free', style: rs.button),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(rs.r(14)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // FOOTER
  // ═══════════════════════════════════════════════════════════

  Widget _buildFooter(BuildContext context, bool isDark) {
    final rs = context.responsive;
    final linkColor =
        isDark ? AppTheme.textSecondary : const Color(0xFF475569);

    final links = [
      (label: 'About Us', route: AppRouter.about),
      (label: 'Privacy Policy', route: AppRouter.privacy),
      (label: 'Terms & Conditions', route: AppRouter.terms),
      (label: 'Contact Us', route: AppRouter.contact),
      (label: 'FAQ', route: AppRouter.faq),
      (label: 'Disclaimer', route: AppRouter.disclaimer),
    ];

    return Container(
      padding: EdgeInsets.fromLTRB(
          rs.w(20), rs.h(24), rs.w(20), rs.h(32)),
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF0A1A2E) : const Color(0xFFE8EEF9))
            .withValues(alpha: 0.6),
      ),
      child: Column(
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            spacing: rs.w(8),
            runSpacing: rs.h(8),
            children: links.map((l) {
              return InkWell(
                onTap: () => Navigator.pushNamed(context, l.route),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: rs.w(6), vertical: rs.h(4)),
                  child: Text(l.label, style: rs.bodySmall.copyWith(color: linkColor)),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: rs.spaceLg),
          Text(
            'Fun Pay · Rewards are in-platform only and have no cash value.',
            textAlign: TextAlign.center,
            style: rs.caption.copyWith(
              color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '© ${DateTime.now().year} Fun Pay. All rights reserved.',
            textAlign: TextAlign.center,
            style: rs.caption.copyWith(
              color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // SHARED
  // ═══════════════════════════════════════════════════════════

  Widget _sectionTitle(BuildContext context, String title, String subtitle) {
    final rs = context.responsive;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: rs.h2.copyWith(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: rs.bodySmall.copyWith(
            color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }
}
