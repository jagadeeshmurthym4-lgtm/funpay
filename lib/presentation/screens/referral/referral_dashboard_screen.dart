import 'package:cashspark/core/theme/app_theme.dart';
import 'package:cashspark/core/utils/helpers.dart';
import 'package:cashspark/core/widgets/premium_widgets.dart';
import 'package:cashspark/domain/entities/referral_entity.dart';
import 'package:cashspark/presentation/providers/auth_provider.dart';
import 'package:cashspark/presentation/providers/referral_level_provider.dart';
import 'package:cashspark/presentation/providers/referral_provider.dart';
import 'package:cashspark/presentation/routes/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class ReferralDashboardScreen extends StatefulWidget {
  const ReferralDashboardScreen({super.key});

  @override
  State<ReferralDashboardScreen> createState() => _ReferralDashboardScreenState();
}

class _ReferralDashboardScreenState extends State<ReferralDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().user?.uid;
      if (userId != null) {
        context.read<ReferralProvider>().loadRewardConfig();
        context.read<ReferralProvider>().listenToReferrals(userId);
      }
      context.read<ReferralLevelProvider>().loadLevels();
    });
  }

  Future<void> _shareReferral(String code) async {
    final link = context.read<ReferralProvider>().generateReferralLink(code);
    final msg = 'Join Fun Pay and start earning! Use my referral code: $code\n\n$link';
    await Clipboard.setData(ClipboardData(text: msg));
    try {
      await SharePlus.instance.share(ShareParams(text: msg));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Referral code copied! Share it with your friends.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Referrals'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
      ),
      body: Consumer2<AuthProvider, ReferralProvider>(
        builder: (context, auth, rp, _) {
          final user = auth.user;
          final code = user?.referralCode ?? '---';

          return RefreshIndicator(
            onRefresh: () async { if (user != null) await rp.loadReferrals(user.uid); },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ─── REFERRAL CODE CARD ─────────────────────
                GlassContainer(
                  borderRadius: 24,
                  padding: const EdgeInsets.all(24),
                  gradient: [AppTheme.accentGreen.withValues(alpha: 0.15), AppTheme.accentGreen.withValues(alpha: 0.1)],
                  child: Column(
                    children: [
                      Container(
                        width: 64, height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]),
                          boxShadow: [BoxShadow(color: const Color(0xFFF59E0B).withValues(alpha: 0.3), blurRadius: 16)],
                        ),
                        child: const Icon(Icons.card_giftcard_outlined, size: 32, color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      Text('Your Referral Code',
                          style: TextStyle(fontSize: 14, color: isDark ? AppTheme.textSecondary : const Color(0xFF64748B))),
                      const SizedBox(height: 8),
                      Text(code,
                          style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 6,
                              color: isDark ? Colors.white : const Color(0xFF0F172A))),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: code));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Referral code copied!')),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                                Icon(Icons.copy_outlined, size: 18, color: Colors.white),
                                SizedBox(width: 6),
                                Text('Copy', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                              ]),
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () => _shareReferral(code),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                                Icon(Icons.share_outlined, size: 18, color: Colors.black),
                                SizedBox(width: 6),
                                Text('Share', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
                              ]),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ─── REWARD INFO ───────────────────────────
                GlassContainer(
                  borderRadius: 16,
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(color: AppTheme.accentOrange.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
                      child: const Icon(Icons.emoji_events_outlined, color: AppTheme.accentOrange, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Referral Rewards', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15,
                            color: isDark ? Colors.white : const Color(0xFF0F172A))),
                        const SizedBox(height: 4),
                        Text('Earn ₹7 when a referred user completes their FIRST project!\n'
                            'Then earn 5% commission on every future project reward!',
                            style: TextStyle(fontSize: 12, color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8))),
                      ]),
                    ),
                  ]),
                ),

                const SizedBox(height: 20),
                // ─── STATISTICS ────────────────────────────
                const SectionHeader(title: 'Referral Statistics'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: PremiumStatCard(icon: Icons.people_outlined, label: 'Total Referrals', value: '${rp.referralCount}', color: AppTheme.accentGreen)),
                    const SizedBox(width: 12),
                    Expanded(child: PremiumStatCard(icon: Icons.person_pin_outlined, label: 'Completed Projects', value: '${rp.completedProjectUsers}', color: AppTheme.accentBlue)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: PremiumStatCard(icon: Icons.trending_up_outlined, label: 'Total Earnings', value: Helpers.formatCurrency(rp.totalEarnings), color: AppTheme.accentPurple)),
                    const SizedBox(width: 12),
                    Expanded(child: PremiumStatCard(icon: Icons.percent_outlined, label: 'Project Commission', value: Helpers.formatCurrency(rp.lifetimeProjectCommission), color: AppTheme.accentOrange)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: PremiumStatCard(icon: Icons.emoji_events_outlined, label: 'First Project Bonus', value: Helpers.formatCurrency(rp.firstProjectBonusTotal), color: const Color(0xFFF59E0B))),
                    const SizedBox(width: 12),
                    Expanded(child: PremiumStatCard(icon: Icons.monetization_on_outlined, label: 'Project History', value: '${rp.referrals.fold<int>(0, (sum, r) => sum + r.rewardedProjectIds.length)} rewards', color: AppTheme.accentPink)),
                  ],
                ),

                const SizedBox(height: 20),
                // ─── REFERRAL LEVELS PROGRESS ──────────────
                Consumer<ReferralLevelProvider>(
                  builder: (context, levelProv, _) {
                    final levels = levelProv.levels;
                    if (levels.isEmpty) return const SizedBox.shrink();
                    final currentLevel = levelProv.getCurrentLevel(rp.referralCount);
                    final nextLevel = levelProv.getNextLevel(rp.referralCount);
                    final progress = levelProv.getProgressToNext(rp.referralCount);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const SectionHeader(title: 'Milestone Levels'),
                              GestureDetector(
                                onTap: () => Navigator.pushNamed(context, AppRouter.referralLevels),
                                child: Text(
                                  'View All',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.accentGreen,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          GlassContainer(
                            borderRadius: 16,
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 44, height: 44,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(colors: [
                                          currentLevel != null ? const Color(0xFFF59E0B) : const Color(0xFF64748B),
                                          currentLevel != null ? const Color(0xFFD97706) : const Color(0xFF475569),
                                        ]),
                                      ),
                                      child: Center(
                                        child: Text(
                                          currentLevel?.badgeIcon ?? '⭐',
                                          style: const TextStyle(fontSize: 22),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            currentLevel?.title ?? 'Getting Started',
                                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15,
                                                color: isDark ? Colors.white : const Color(0xFF0F172A)),
                                          ),
                                          if (nextLevel != null)
                                            Text(
                                              '${nextLevel.requiredReferrals - rp.referralCount} more referrals to ${nextLevel.title}',
                                              style: TextStyle(fontSize: 12,
                                                  color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8)),
                                            )
                                          else
                                            Text('All levels completed!',
                                                style: TextStyle(fontSize: 12, color: AppTheme.accentGreen)),
                                        ],
                                      ),
                                    ),
                                    if (nextLevel != null)
                                      Text(
                                        '₹${nextLevel.rewardAmount.toStringAsFixed(0)}',
                                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                                            color: AppTheme.accentGreen),
                                      ),
                                  ],
                                ),
                                if (nextLevel != null) ...[
                                  const SizedBox(height: 12),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      minHeight: 8,
                                      backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentGreen),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('${currentLevel?.requiredReferrals ?? 0}',
                                          style: TextStyle(fontSize: 10,
                                              color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8))),
                                      Text('${nextLevel.requiredReferrals}',
                                          style: TextStyle(fontSize: 10,
                                              color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8))),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 4),
                // ─── SHARE SECTION ─────────────────────────
                const SectionHeader(title: 'Share & Earn'),
                const SizedBox(height: 8),
                GlassContainer(
                  borderRadius: 16,
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Share your referral code with friends and earn rewards when they join!',
                        style: TextStyle(fontSize: 13, color: isDark ? AppTheme.textSecondary : const Color(0xFF475569))),
                    const SizedBox(height: 16),
                    GradientButton(
                      label: 'Share Referral Link',
                      onPressed: () => _shareReferral(code),
                      icon: Icons.share_outlined,
                    ),
                  ]),
                ),

                const SizedBox(height: 20),
                // ─── HISTORY ───────────────────────────────
                const SectionHeader(title: 'Referral History'),
                const SizedBox(height: 8),
                if (rp.isLoading && rp.referrals.isEmpty)
                  const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
                else if (rp.referrals.isEmpty)
                  const PremiumEmptyState(icon: Icons.people_outline, title: 'No referrals yet',
                      subtitle: 'Share your code with friends and earn rewards when they join!')
                else
                  ...rp.referrals.map((ref) => _ReferralCard(ref: ref, isDark: isDark)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ReferralCard extends StatelessWidget {
  final ReferralEntity ref;
  final bool isDark;
  const _ReferralCard({required this.ref, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isRewarded = ref.status == ReferralStatus.rewarded || ref.status == ReferralStatus.completed;
    final color = isRewarded ? AppTheme.accentGreen : AppTheme.accentOrange;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassContainer(
        borderRadius: 16,
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          IconContainer(icon: Icons.person_add_outlined, color: color, containerSize: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Referred User', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: isDark ? Colors.white : const Color(0xFF0F172A))),
              const SizedBox(height: 2),
              Text('Code: ${ref.referralCode}', style: TextStyle(fontSize: 12, color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8))),
              Text(Helpers.formatDateTime(ref.createdAt), style: TextStyle(fontSize: 10, color: isDark ? AppTheme.textMuted.withValues(alpha: 0.6) : const Color(0xFF94A3B8).withValues(alpha: 0.6))),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('+₹${ref.rewardAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.accentGreen)),
            const SizedBox(height: 4),
            _StatusBadge(_statusLabel(ref.status), color),
          ]),
        ]),
      ),
    );
  }

  String _statusLabel(ReferralStatus s) => switch (s) {
    ReferralStatus.pending => 'Pending', ReferralStatus.completed => 'Completed',
    ReferralStatus.rewarded => 'Rewarded', ReferralStatus.cancelled => 'Cancelled',
  };
}

class _StatusBadge extends StatelessWidget {
  final String label; final Color color;
  const _StatusBadge(this.label, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
    child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color)),
  );
}
