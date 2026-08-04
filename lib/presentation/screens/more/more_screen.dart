import 'package:cashspark/core/theme/app_theme.dart';
import 'package:cashspark/core/widgets/premium_widgets.dart';
import 'package:cashspark/presentation/providers/auth_provider.dart';
import 'package:cashspark/presentation/providers/notification_provider.dart';
import 'package:cashspark/presentation/providers/referral_provider.dart';
import 'package:cashspark/presentation/providers/wallet_provider.dart';
import 'package:cashspark/presentation/routes/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Consumer2<AuthProvider, WalletProvider>(
        builder: (context, auth, walletProv, _) {
          final user = auth.user;
          final balance = walletProv.wallet?.walletBalance ?? user?.walletBalance ?? 0.0;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppTheme.accentPurple.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.more_horiz_rounded, size: 20, color: Color(0xFF8B5CF6)),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'More',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Profile card
                _buildProfileCard(user, balance, isDark, context),
                const SizedBox(height: 16),

                // Wallet summary
                _buildWalletSummaryCard(walletProv, isDark, context),
                const SizedBox(height: 16),

                // Referral section
                _buildReferralSection(isDark, context),
                const SizedBox(height: 16),

                // Menu items
                const SectionHeader(title: 'Account'),
                _buildMenuItems(isDark, context),

                const SizedBox(height: 20),
                const SectionHeader(title: 'Support'),
                _buildSupportItems(isDark, context),

                const SizedBox(height: 20),
                const SectionHeader(title: 'Legal'),
                _buildLegalItems(isDark, context),

                const SizedBox(height: 24),
                Center(
                  child: Text(
                    'Fun Pay v1.0.0',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppTheme.textMuted.withValues(alpha: 0.6) : const Color(0xFF94A3B8).withValues(alpha: 0.6),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileCard(dynamic user, double balance, bool isDark, BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRouter.profile),
      child: GlassContainer(
        borderRadius: 18,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF4ADE80), Color(0xFF22C55E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Text(
                  (user?.fullName?.isNotEmpty == true ? user!.fullName[0] : 'U')
                      .toString()
                      .toUpperCase(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.fullName ?? 'User',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user?.email ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletSummaryCard(dynamic walletProv, bool isDark, BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to Wallet tab (index 3)
      },
      child: GlassContainer(
        borderRadius: 16,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            _miniStat(Icons.account_balance_wallet_outlined, 'Balance',
                '₹${(walletProv.wallet?.walletBalance ?? 0).toStringAsFixed(0)}',
                AppTheme.accentGreen, isDark),
            Container(height: 32, width: 1,
                color: isDark ? AppTheme.borderColor : const Color(0xFFCBD5E1)),
            _miniStat(Icons.trending_up_outlined, 'Earnings',
                '₹${(walletProv.wallet?.totalEarnings ?? 0).toStringAsFixed(0)}',
                AppTheme.accentPurple, isDark),
            Container(height: 32, width: 1,
                color: isDark ? AppTheme.borderColor : const Color(0xFFCBD5E1)),
            _miniStat(Icons.people_outline, 'Ref. Earnings',
                '₹${walletProv.referralEarnings.toStringAsFixed(0)}',
                AppTheme.accentOrange, isDark),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(IconData icon, String label, String value, Color color, bool isDark) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A))),
          Text(label, style: TextStyle(fontSize: 9, color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8))),
        ],
      ),
    );
  }

  Widget _buildReferralSection(bool isDark, BuildContext context) {
    return Consumer<ReferralProvider>(
      builder: (context, refProv, _) {
        return GestureDetector(
          onTap: () => Navigator.pushNamed(context, AppRouter.referrals),
          child: GlassContainer(
            borderRadius: 16,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: AppTheme.accentOrange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.person_add_outlined, size: 18, color: AppTheme.accentOrange),
                    ),
                    const SizedBox(width: 10),
                    Text('Refer & Earn',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF0F172A))),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, AppRouter.referrals),
                      child: Text('View All',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.accentGreen)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _refStat('Referrals', '${refProv.referralCount}', AppTheme.accentBlue, isDark)),
                    Expanded(child: _refStat('Earned', '₹${refProv.totalEarnings.toStringAsFixed(0)}', AppTheme.accentGreen, isDark)),
                    Expanded(child: _refStat('Completed', '${refProv.completedProjectUsers}', AppTheme.accentOrange, isDark)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _refStat(String label, String value, Color color, bool isDark) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF0F172A))),
        Text(label, style: TextStyle(fontSize: 10, color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8))),
      ],
    );
  }

  Widget _buildMenuItems(bool isDark, BuildContext context) {
    final notifProv = context.watch<NotificationProvider>();
    final unreadCount = notifProv.unreadCount;
    final iconColor = isDark ? AppTheme.textSecondary : const Color(0xFF64748B);

    final items = [
      _MenuItem(Icons.notifications_outlined, 'Notifications', AppRouter.notifications, badge: unreadCount),
      _MenuItem(Icons.account_balance_wallet_outlined, 'Wallet', null),
      _MenuItem(Icons.redeem_rounded, 'Redeem Rewards', AppRouter.withdrawals),
      _MenuItem(Icons.person_add_outlined, 'Referrals', AppRouter.referrals),
      _MenuItem(Icons.settings_outlined, 'Settings', AppRouter.appSettings),
      _MenuItem(Icons.account_circle_outlined, 'Account', AppRouter.accountManagement),
    ];

    return GlassContainer(
      borderRadius: 14,
      padding: EdgeInsets.zero,
      child: Column(
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return Column(
            children: [
              ListTile(
                leading: Stack(
                  children: [
                    IconContainer(icon: item.icon, color: iconColor, containerSize: 44),
                    if (item.badge != null && item.badge! > 0)
                      Positioned(
                        right: 2, top: 2,
                        child: Container(
                          width: 16, height: 16,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${item.badge! > 9 ? '9+' : item.badge}',
                              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                title: Text(item.label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF0F172A))),
                trailing: Icon(Icons.chevron_right, size: 20,
                    color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8)),
                onTap: () {
                  HapticFeedback.lightImpact();
                  if (item.route != null) {
                    Navigator.pushNamed(context, item.route!);
                  }
                },
                visualDensity: VisualDensity.standard,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              if (i < items.length - 1)
                Divider(height: 1, indent: 72,
                    color: isDark ? AppTheme.borderColor.withValues(alpha: 0.3) : const Color(0xFFE2E8F0)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSupportItems(bool isDark, BuildContext context) {
    final iconColor = isDark ? AppTheme.textSecondary : const Color(0xFF64748B);
    final items = [
      _MenuItem(Icons.help_outline, 'Help Center', AppRouter.helpCenter),
      _MenuItem(Icons.chat_outlined, 'Contact Support', AppRouter.contactSupport),
      _MenuItem(Icons.help_outline, 'FAQ', AppRouter.faq),
    ];

    return GlassContainer(
      borderRadius: 14,
      padding: EdgeInsets.zero,
      child: Column(
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return Column(
            children: [
              ListTile(
                leading: IconContainer(icon: item.icon, color: iconColor, containerSize: 44),
                title: Text(item.label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF0F172A))),
                trailing: Icon(Icons.chevron_right, size: 20,
                    color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8)),
                onTap: () {
                  HapticFeedback.lightImpact();
                  if (item.route != null) Navigator.pushNamed(context, item.route!);
                },
                visualDensity: VisualDensity.standard,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              if (i < items.length - 1)
                Divider(height: 1, indent: 72,
                    color: isDark ? AppTheme.borderColor.withValues(alpha: 0.3) : const Color(0xFFE2E8F0)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLegalItems(bool isDark, BuildContext context) {
    final iconColor = isDark ? AppTheme.textSecondary : const Color(0xFF64748B);
    final items = [
      _MenuItem(Icons.description_outlined, 'Terms & Conditions', AppRouter.terms),
      _MenuItem(Icons.privacy_tip_outlined, 'Privacy Policy', AppRouter.privacy),
      _MenuItem(Icons.card_giftcard_outlined, 'Referral Program', AppRouter.referralDisclaimer),
      _MenuItem(Icons.info_outline, 'About Us', AppRouter.about),
    ];

    return GlassContainer(
      borderRadius: 14,
      padding: EdgeInsets.zero,
      child: Column(
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return Column(
            children: [
              ListTile(
                leading: IconContainer(icon: item.icon, color: iconColor, containerSize: 44),
                title: Text(item.label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF0F172A))),
                trailing: Icon(Icons.chevron_right, size: 20,
                    color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8)),
                onTap: () {
                  HapticFeedback.lightImpact();
                  if (item.route != null) Navigator.pushNamed(context, item.route!);
                },
                visualDensity: VisualDensity.standard,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              if (i < items.length - 1)
                Divider(height: 1, indent: 72,
                    color: isDark ? AppTheme.borderColor.withValues(alpha: 0.3) : const Color(0xFFE2E8F0)),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final String? route;
  final int? badge;

  const _MenuItem(this.icon, this.label, this.route, {this.badge});
}
