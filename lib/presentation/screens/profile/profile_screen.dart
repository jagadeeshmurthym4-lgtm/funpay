import 'package:cashspark/core/theme/app_theme.dart';
import 'package:cashspark/core/utils/helpers.dart';
import 'package:cashspark/core/widgets/premium_widgets.dart';
import 'package:cashspark/presentation/providers/auth_provider.dart';
import 'package:cashspark/presentation/providers/wallet_provider.dart';
import 'package:cashspark/presentation/routes/app_router.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Consumer2<AuthProvider, WalletProvider>(
        builder: (context, auth, walletProv, _) {
          final user = auth.user;
          final liveBalance = walletProv.wallet?.walletBalance ?? user?.walletBalance ?? 0.0;
          final liveEarnings = walletProv.wallet?.totalEarnings ?? user?.totalEarnings ?? 0.0;
          final liveWithdrawn = walletProv.wallet?.totalWithdrawn ?? user?.totalWithdrawn ?? 0.0;

          return SingleChildScrollView(
            child: Column(
              children: [
                // ─── COVER & AVATAR ──────────────────────────
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Cover image
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: user?.coverImage != null
                              ? [AppTheme.accentBlue, AppTheme.accentPurple]
                              : [AppTheme.accentGreen.withValues(alpha: 0.6), AppTheme.accentBlue.withValues(alpha: 0.4)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.accentGreen.withValues(alpha: 0.2),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Positioned(
                            right: -40, top: -40,
                            child: Icon(Icons.auto_awesome, size: 180, color: Colors.white.withValues(alpha: 0.06)),
                          ),
                          Positioned(
                            left: -20, bottom: -20,
                            child: Icon(Icons.monetization_on, size: 140, color: Colors.white.withValues(alpha: 0.04)),
                          ),
                          // Edit & Settings
                          Positioned(
                            top: MediaQuery.of(context).padding.top + 8,
                            right: 8,
                            child: Row(
                              children: [
                                Container(
                                  width: 38, height: 38,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.settings_outlined, size: 20, color: Colors.white),
                                    onPressed: () => Navigator.pushNamed(context, AppRouter.appSettings),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Avatar
                    Positioned(
                      left: 24,
                      bottom: -50,
                      child: Container(
                        width: 100, height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: isDark ? AppTheme.bgDark : Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.accentGreen.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          backgroundColor: AppTheme.accentGreen.withValues(alpha: 0.15),
                          child: user?.profilePicture != null
                              ? ClipOval(child: Image.network(user!.profilePicture!, fit: BoxFit.cover))
                              : Text(
                                  (user?.fullName.isNotEmpty == true ? user!.fullName[0] : 'U').toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? AppTheme.accentGreen : AppTheme.accentGreen,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 60),

                // ─── NAME & VERIFICATION ─────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      user?.fullName ?? 'User',
                                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                                    ),
                                    const SizedBox(width: 8),
                                    if (user?.isVerified == true)
                                      const VerifiedBadge(size: 22),
                                  ],
                                ),
                                if (user?.username != null) ...[
                                  const SizedBox(height: 2),
                                  Text('@${user!.username}', style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
                                ],
                                const SizedBox(height: 4),
                                Text(user?.email ?? '', style: TextStyle(fontSize: 13, color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8))),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () async {
                              await Navigator.pushNamed(context, AppRouter.editProfile);
                              if (context.mounted) context.read<AuthProvider>().refreshUser();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Color(0xFF4ADE80), Color(0xFF22C55E)]),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [BoxShadow(color: const Color(0xFF4ADE80).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
                              ),
                              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                                Icon(Icons.edit_outlined, size: 16, color: Colors.black),
                                SizedBox(width: 4),
                                Text('Edit', style: TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.w700)),
                              ]),
                            ),
                          ),
                        ],
                      ),

                      // About Me
                      if ((user?.aboutMe?.isNotEmpty == true)) ...[
                        const SizedBox(height: 16),
                        GlassContainer(
                          borderRadius: 16,
                          padding: const EdgeInsets.all(16),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('About', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                            const SizedBox(height: 6),
                            Text(user!.aboutMe!, style: TextStyle(fontSize: 13, color: isDark ? AppTheme.textSecondary : const Color(0xFF475569), height: 1.4)),
                          ]),
                        ),
                      ],

                      const SizedBox(height: 20),

                      // ─── PROFILE COMPLETION ────────────────
                      GlassContainer(
                        borderRadius: 16,
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 48, height: 48,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    value: (user?.profileCompletionPercentage ?? 0) / 100,
                                    strokeWidth: 4,
                                    backgroundColor: isDark ? AppTheme.borderColor : const Color(0xFFE2E8F0),
                                    valueColor: const AlwaysStoppedAnimation(AppTheme.accentGreen),
                                  ),
                                  Text('${user?.profileCompletionPercentage ?? 0}%',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text('Profile Completion', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                                const SizedBox(height: 2),
                                Text('Complete your profile to earn a verified badge',
                                    style: TextStyle(fontSize: 12, color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8))),
                              ]),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ─── STATS GRID ────────────────────────
                      Row(
                        children: [
                          Expanded(child: PremiumStatCard(icon: Icons.account_balance_wallet_outlined, label: 'Balance', value: Helpers.formatCurrency(liveBalance), color: AppTheme.accentGreen,
                              onTap: () => Navigator.pushNamed(context, AppRouter.wallet))),
                          const SizedBox(width: 12),
                          Expanded(child: PremiumStatCard(icon: Icons.trending_up_outlined, label: 'Earnings', value: Helpers.formatCurrency(liveEarnings), color: AppTheme.accentPurple)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: PremiumStatCard(icon: Icons.arrow_upward_outlined, label: 'Redeemed', value: Helpers.formatCurrency(liveWithdrawn), color: AppTheme.accentOrange)),
                          const SizedBox(width: 12),
                          Expanded(child: PremiumStatCard(icon: Icons.calendar_today_outlined, label: 'Joined', value: user != null ? '${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}' : '---', color: AppTheme.accentBlue)),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // ─── PERSONAL INFO ─────────────────────
                      const SectionHeader(title: 'Personal Information'),
                      GlassContainer(
                        borderRadius: 16,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _infoTile(Icons.phone_outlined, 'Phone', user?.phone ?? 'Not set', isDark),
                            if (user?.dateOfBirth != null) _infoTile(Icons.cake_outlined, 'Date of Birth', user!.dateOfBirth!, isDark),
                            if (user?.gender != null) _infoTile(Icons.wc_outlined, 'Gender', user!.gender!, isDark),
                            if (user?.address != null) _infoTile(Icons.home_outlined, 'Address', user!.address!, isDark),
                            if (user?.city != null || user?.state != null || user?.country != null)
                              _infoTile(Icons.location_city_outlined, 'Location',
                                  [user?.city, user?.state, user?.country].whereType<String>().join(', '), isDark),
                            if (user?.education != null) _infoTile(Icons.school_outlined, 'Education', user!.education!, isDark),
                            if (user?.experience != null) _infoTile(Icons.work_outlined, 'Experience', user!.experience!, isDark),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ─── REFERRAL CODE ─────────────────────
                      const SectionHeader(title: 'Referral Program'),
                      GlassContainer(
                        borderRadius: 16,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(color: AppTheme.accentOrange.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                                child: const Icon(Icons.card_giftcard_outlined, color: AppTheme.accentOrange, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text('Your Referral Code', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                                  Text('Share & earn rewards', style: TextStyle(fontSize: 12, color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8))),
                                ]),
                              ),
                            ]),
                            const SizedBox(height: 16),
                            Row(children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppTheme.bgCardLight : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    user?.referralCode ?? '---',
                                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF0F172A), letterSpacing: 4),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Referral code copied!')),
                                  );
                                },
                                child: Container(
                                  width: 48, height: 48,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(colors: [Color(0xFF4ADE80), Color(0xFF22C55E)]),
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [BoxShadow(color: const Color(0xFF4ADE80).withValues(alpha: 0.3), blurRadius: 8)],
                                  ),
                                  child: const Icon(Icons.copy_outlined, size: 20, color: Colors.black),
                                ),
                              ),
                            ]),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ─── ACCOUNT ACTIONS ───────────────────
                      const SectionHeader(title: 'Account'),
                      GlassContainer(
                        borderRadius: 16,
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            _actionTile(context, Icons.person_outline, 'Profile', AppRouter.profile, isDark, showDivider: true),
                            _actionTile(context, Icons.logout_outlined, 'Sign Out', null, isDark, isDestructive: false, showDivider: true,
                              onTap: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Sign Out'),
                                    content: const Text('Are you sure you want to sign out?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                      FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sign Out')),
                                    ],
                                  ),
                                );
                                if (confirmed == true && context.mounted) {
                                  await auth.signOut();
                                  if (context.mounted) {
                                    Navigator.of(context).pushNamedAndRemoveUntil(
                                      AppRouter.login,
                                      (route) => false,
                                    );
                                  }
                                }
                              }),
                            _actionTile(context, Icons.delete_outline, 'Delete Account', null, isDark, isDestructive: true,
                              onTap: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Delete Account'),
                                    content: const Text('This action is permanent. All your data will be deleted.'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                      FilledButton(
                                        style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.error),
                                        onPressed: () => Navigator.pop(ctx, true),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirmed == true && context.mounted) {
                                  try {
                                    await auth.deleteAccount();
                                    if (context.mounted) {
                                      Navigator.of(context).pushNamedAndRemoveUntil(
                                        AppRouter.login,
                                        (route) => false,
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Failed: ${e.toString()}')),
                                      );
                                    }
                                  }
                                }
                              }),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),
                      Center(
                        child: Text('Fun Pay v1.0.0',
                            style: TextStyle(fontSize: 12, color: isDark ? AppTheme.textMuted.withValues(alpha: 0.6) : const Color(0xFF94A3B8).withValues(alpha: 0.6))),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: isDark ? AppTheme.borderColor.withValues(alpha: 0.5) : const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 16, color: isDark ? AppTheme.textSecondary : const Color(0xFF64748B)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: TextStyle(fontSize: 11, color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8))),
              const SizedBox(height: 1),
              Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF0F172A))),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _actionTile(BuildContext context, IconData icon, String title, String? route, bool isDark, {bool isDestructive = false, bool showDivider = false, VoidCallback? onTap}) {
    return Column(
      children: [
        ListTile(
          leading: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: isDestructive ? const Color(0xFFEF4444).withValues(alpha: 0.1) : (isDark ? AppTheme.borderColor.withValues(alpha: 0.5) : const Color(0xFFF1F5F9)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: isDestructive ? const Color(0xFFEF4444) : (isDark ? AppTheme.textSecondary : const Color(0xFF64748B))),
          ),
          title: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
              color: isDestructive ? const Color(0xFFEF4444) : (isDark ? Colors.white : const Color(0xFF0F172A)))),
          trailing: route != null || onTap != null
              ? Icon(Icons.chevron_right, size: 20, color: isDestructive ? const Color(0xFFEF4444).withValues(alpha: 0.5) : (isDark ? AppTheme.textMuted : const Color(0xFF94A3B8)))
              : null,
          onTap: onTap ?? (route != null ? () => Navigator.pushNamed(context, route) : null),
        ),
        if (showDivider)
          Divider(height: 1, indent: 56, color: isDark ? AppTheme.borderColor.withValues(alpha: 0.3) : const Color(0xFFE2E8F0)),
      ],
    );
  }
}
