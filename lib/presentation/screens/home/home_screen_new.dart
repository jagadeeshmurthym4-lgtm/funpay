import 'package:cashspark/core/theme/app_theme.dart';
import 'package:cashspark/core/widgets/adsense_banner.dart';
import 'package:cashspark/core/widgets/premium_widgets.dart';
import 'package:cashspark/domain/entities/notification_entity.dart';
import 'package:cashspark/presentation/providers/auth_provider.dart';
import 'package:cashspark/presentation/providers/notification_provider.dart';
import 'package:cashspark/presentation/providers/referral_provider.dart';
import 'package:cashspark/presentation/providers/reward_provider.dart';
import 'package:cashspark/presentation/providers/wallet_provider.dart';
import 'package:cashspark/presentation/routes/app_router.dart';
import 'package:cashspark/core/utils/responsive.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  void _initialize() {
    final auth = context.read<AuthProvider>();
    final userId = auth.user?.uid;
    if (userId != null) {
      context.read<WalletProvider>().listenToWallet(userId);
      context.read<WalletProvider>().loadEarningsBreakdown(userId);
      // Notification init is handled by app.dart auth state listener —
      // setUser() is already called by app.dart on auth state change.
      context.read<RewardProvider>().initialize(userId);
      final refCode = auth.user?.referralCode;
      if (refCode != null) {
        context.read<ReferralProvider>().listenToReferrals(userId);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    final rs = context.responsive;
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          final uid = auth.user?.uid;
          if (uid != null) {
            context.read<WalletProvider>().listenToWallet(uid);
          }
        },
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            rs.spaceLg, rs.spaceMd, rs.spaceLg, rs.height(80),),
          child: Column(
            children: [
              _buildHeader(isDark, user?.fullName ?? 'User'),
              SizedBox(height: rs.spaceLg),
              _buildWalletCard(isDark),
              SizedBox(height: rs.spaceMd),
              _buildWithdrawButton(isDark),
              SizedBox(height: rs.spaceLg),
              const AdSenseBanner(adSlot: '6222511573', height: 110),
              SizedBox(height: rs.spaceLg),
              _buildRecentNotifications(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, String userName) {
    final rs = context.responsive;
    int unreadCount = 0;
    try {
      final notifProv = context.watch<NotificationProvider>();
      unreadCount = notifProv.unreadCount;
    } catch (e) {
      debugPrint('HomeScreen: notification provider unavailable ($e)');
    }
    return Row(
      children: [
        Container(
          width: rs.avatarMd,
          height: rs.avatarMd,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF4ADE80), Color(0xFF22C55E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4ADE80).withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.auto_awesome, size: 20, color: Colors.black),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fun Pay',
              style: rs.h2.copyWith(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
            Text(
              'Hello, ${userName.split(' ').first}',
              style: rs.bodySmall.copyWith(
                color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
        const Spacer(),
        // Notification bell
        SizedBox(
          width: rs.avatarMd,
          height: rs.avatarMd,
          child: Stack(
            children: [
              Positioned.fill(
                child: IconButton(
                  icon: Icon(
                    Icons.notifications_outlined,
                    color: isDark ? AppTheme.textSecondary : const Color(0xFF475569),
                  ),
                  onPressed: () => Navigator.pushNamed(context, AppRouter.notifications),
                ),
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 4),
        // Profile avatar
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, AppRouter.profile),
          child: Container(
            width: rs.avatarSm,
            height: rs.avatarSm,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: isDark
                    ? [AppTheme.borderColor, AppTheme.bgCard]
                    : [const Color(0xFFDBEAFE), const Color(0xFFF1F5F9)],
              ),
              border: Border.all(
                color: AppTheme.accentGreen.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                (userName.isNotEmpty ? userName[0] : 'U').toUpperCase(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.accentGreen,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWalletCard(bool isDark) {
    final walletProv = context.watch<WalletProvider>();
    final wallet = walletProv.wallet;
    final balance = wallet?.walletBalance ?? 0.0;
    final earnings = wallet?.totalEarnings ?? 0.0;
    const target = 2000.0;
    final progress = (earnings / target).clamp(0.0, 1.0);

    final rs = context.responsive;
    return GlassContainer(
      borderRadius: rs.cardRadiusXl,
      padding: rs.pad(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Wallet Balance',
                    style: rs.bodySmall.copyWith(
                      color: isDark ? AppTheme.textSecondary : const Color(0xFF64748B),
                    ),
                  ),
                  SizedBox(height: rs.spaceXs),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'pts',
                        style: rs.h1.copyWith(
                          fontSize: rs.fs(18),
                          fontWeight: FontWeight.w600,
                          color: AppTheme.accentGreen,
                        ),
                      ),
                      const SizedBox(width: 2),
                      AnimatedCounter(
                        value: balance,
                        decimals: 2,
                        style: rs.h1.copyWith(
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          letterSpacing: -1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: rs.padSym(h: 14, v: 8),
                decoration: BoxDecoration(
                  color: AppTheme.accentGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(rs.cardRadiusMd),
                  border: Border.all(
                    color: AppTheme.accentGreen.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${earnings.toStringAsFixed(0)} pts',
                      style: rs.bodySmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF4ADE80),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'earned',
                      style: rs.caption.copyWith(
                        color: isDark ? AppTheme.textSecondary : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: rs.spaceLg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Monthly Goal',
                style: rs.bodySmall.copyWith(
                  color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8),
                ),
              ),
              Text(
                '${earnings.toStringAsFixed(0)} pts / $target pts',
                style: rs.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.accentGreen,
                ),
              ),
            ],
          ),
          SizedBox(height: rs.spaceSm),
          PremiumProgressBar(value: progress),
          SizedBox(height: rs.spaceMd),
          Row(
            children: [
              _quickStat(Icons.work_outline, 'Tasks', walletProv.projectEarnings, AppTheme.accentBlue, isDark),
              SizedBox(width: rs.spaceSm),
              _quickStat(Icons.people_outline, 'Referrals', walletProv.referralEarnings, AppTheme.accentPurple, isDark),
              SizedBox(width: rs.spaceSm),
              _quickStat(Icons.casino_outlined, 'Bonuses', walletProv.spinEarnings, AppTheme.accentPink, isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickStat(IconData icon, String label, double amount, Color color, bool isDark) {
    final rs = context.responsive;
    return Expanded(
      child: Column(
        children: [
          Container(
            width: rs.avatarXs,
            height: rs.avatarXs,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(rs.cardRadiusSm),
            ),
            child: Icon(icon, size: rs.iconXs, color: color),
          ),
          SizedBox(height: rs.spaceXs),
          Text(
            label,
            style: rs.micro.copyWith(
              fontWeight: FontWeight.w500,
              color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8),
            ),
          ),
          AnimatedCounter(
            value: amount,
            decimals: 0,
            style: rs.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWithdrawButton(bool isDark) {
    final rs = context.responsive;
    return SizedBox(
      width: double.infinity,
      height: rs.height(52),
      child: ElevatedButton.icon(
        onPressed: () => Navigator.pushNamed(context, AppRouter.withdrawals),
        icon: Icon(Icons.redeem_rounded, size: rs.iconSm),
        label: Text(
          'Redeem Points',
          style: rs.button,
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4ADE80),
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(rs.cardRadiusLg),
          ),
          elevation: 6,
          shadowColor: const Color(0xFF4ADE80).withValues(alpha: 0.4),
        ),
      ),
    );
  }

  Widget _notificationCard(NotificationEntity notif, bool isDark) {
    final rs = context.responsive;
    return Container(
      margin: EdgeInsets.only(bottom: rs.spaceSm),
      padding: rs.pad(12),
      decoration: BoxDecoration(
        color: !notif.isRead
            ? (isDark
                ? AppTheme.bgCardLight.withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.8))
            : Colors.transparent,
        borderRadius: BorderRadius.circular(rs.cardRadiusMd),
        border: Border.all(
          color: (isDark ? AppTheme.borderColor : const Color(0xFFE2E8F0))
              .withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: rs.avatarXs,
            height: rs.avatarXs,
            decoration: BoxDecoration(
              color: _notifColor(notif.type).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(rs.cardRadiusSm),
            ),
            child: Icon(
              _notifIcon(notif.type),
              size: rs.iconXs + 1,
              color: _notifColor(notif.type),
            ),
          ),
          SizedBox(width: rs.spaceSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notif.title,
                  style: rs.bodySmall.copyWith(
                    fontWeight: notif.isRead ? FontWeight.w500 : FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  notif.message,
                  style: rs.caption.copyWith(
                    color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentNotifications(bool isDark) {
    final rs = context.responsive;
    List<NotificationEntity> notifications = [];
    try {
      final notifProv = context.watch<NotificationProvider>();
      notifications = notifProv.notifications;
    } catch (e) {
      debugPrint('HomeScreen: notification provider unavailable ($e)');
    }
    final recent = notifications.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: rs.height(16),
              decoration: BoxDecoration(
                color: AppTheme.accentGreen,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(width: rs.spaceSm),
            Text(
              'Recent Notifications',
              style: rs.h3.copyWith(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const Spacer(),
            if (recent.isNotEmpty)
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, AppRouter.notifications),
                child: Text(
                  'See All',
                  style: rs.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.accentGreen,
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: rs.spaceMd),
        if (recent.isEmpty)
          GlassContainer(
            borderRadius: rs.cardRadiusMd,
            padding: rs.padSym(v: 24),
            child: Column(
              children: [
                Icon(
                  Icons.notifications_none_outlined,
                  size: rs.iconLg,
                  color: isDark
                      ? AppTheme.textMuted.withValues(alpha: 0.4)
                      : const Color(0xFF94A3B8).withValues(alpha: 0.4),
                ),
                SizedBox(height: rs.spaceXs + 2),
                Text(
                  'No notifications yet',
                  style: rs.body.copyWith(
                    color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          )
        else
          ...recent.map((n) => _notificationCard(n, isDark)),
      ],
    );
  }

  Color _notifColor(NotificationType type) {
    switch (type) {
      case NotificationType.reward: return Colors.amber;
      case NotificationType.referral: return Colors.blue;
      case NotificationType.withdrawal: return Colors.red;
      case NotificationType.dailyBonus: return Colors.green;
      case NotificationType.announcement: return Colors.purple;
      case NotificationType.promotional: return Colors.orange;
      case NotificationType.other: return Colors.grey;
    }
  }

  IconData _notifIcon(NotificationType type) {
    switch (type) {
      case NotificationType.reward: return Icons.monetization_on_outlined;
      case NotificationType.referral: return Icons.people_outline;
      case NotificationType.withdrawal: return Icons.payments_outlined;
      case NotificationType.dailyBonus: return Icons.card_giftcard_outlined;
      case NotificationType.announcement: return Icons.campaign_outlined;
      case NotificationType.promotional: return Icons.local_offer_outlined;
      case NotificationType.other: return Icons.notifications_outlined;
    }
  }
}
