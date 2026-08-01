import 'package:cashspark/core/utils/helpers.dart';
import 'package:cashspark/core/widgets/premium_widgets.dart';
import 'package:cashspark/domain/entities/referral_entity.dart';
import 'package:cashspark/domain/entities/user_entity.dart';
import 'package:cashspark/domain/entities/withdrawal_entity.dart';
import 'package:cashspark/presentation/providers/admin_provider.dart';
import 'package:cashspark/presentation/providers/withdrawal_provider.dart';
import 'package:cashspark/presentation/screens/admin/admin_affiliate_projects_tab.dart';
import 'package:cashspark/presentation/screens/admin/admin_coupons_tab.dart';
import 'package:cashspark/presentation/screens/admin/admin_referral_levels_tab.dart';
import 'package:cashspark/presentation/screens/admin/admin_streak_multiplier_tab.dart';
import 'package:cashspark/presentation/screens/admin/admin_support_tab.dart';
import 'package:cashspark/presentation/screens/admin/admin_tabs.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 15, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  void _initialize() {
    final admin = context.read<AdminProvider>();
    admin.loadDashboard();
    admin.loadUsers();
    admin.loadReferrals();
    final withdrawal = context.read<WithdrawalProvider>();
    withdrawal.initializeAdmin();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final admin = context.watch<AdminProvider>();

    return Scaffold(
      appBar: PremiumAppBar(
        title: 'Admin Panel',
        onBack: () => Navigator.pop(context),
        actions: [
          // System health indicator (live dot)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Tooltip(
              message: 'System ${admin.systemOnline ? "Online" : "Offline"} · ${admin.responseTime.toStringAsFixed(0)}ms response · ${admin.errorRate.toStringAsFixed(1)}% error rate',
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: admin.systemOnline ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                  boxShadow: [
                    BoxShadow(
                      color: (admin.systemOnline ? const Color(0xFF22C55E) : const Color(0xFFEF4444)).withValues(alpha: 0.6),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Dark/Light theme toggle button
          IconButton(
            icon: Icon(
              admin.useDarkTheme ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              size: 20,
            ),
            tooltip: admin.useDarkTheme ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            onPressed: admin.toggleTheme,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicator: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
              tabs: const [
                Tab(text: 'Dashboard', icon: Icon(Icons.dashboard_outlined, size: 18)),
                Tab(text: 'Users', icon: Icon(Icons.people_outlined, size: 18)),
                Tab(text: 'Redemptions', icon: Icon(Icons.redeem_rounded, size: 18)),
                Tab(text: 'Wallet', icon: Icon(Icons.account_balance_wallet_outlined, size: 18)),
                Tab(text: 'Analytics', icon: Icon(Icons.analytics_outlined, size: 18)),
                Tab(text: 'Banners', icon: Icon(Icons.view_carousel_outlined, size: 18)),
                Tab(text: 'Verification', icon: Icon(Icons.verified_outlined, size: 18)),
                Tab(text: 'Audit', icon: Icon(Icons.history_outlined, size: 18)),
                Tab(text: 'Settings', icon: Icon(Icons.settings_outlined, size: 18)),
                Tab(text: 'Coupons', icon: Icon(Icons.local_offer_outlined, size: 18)),
                Tab(text: 'Projects', icon: Icon(Icons.folder_outlined, size: 18)),
                Tab(text: 'Referral Lvls', icon: Icon(Icons.emoji_events_outlined, size: 18)),
                Tab(text: 'Streak Mult', icon: Icon(Icons.trending_up_rounded, size: 18)),
                Tab(text: 'Referrals', icon: Icon(Icons.share_outlined, size: 18)),
                Tab(text: 'Support', icon: Icon(Icons.support_agent_outlined, size: 18)),
              ],
            ),
          ),
        ),
      ),
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
        child: Consumer<AdminProvider>(
          builder: (context, admin, _) {
            return TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _DashboardTab(admin: admin, theme: theme),
                _UsersTab(admin: admin, theme: theme),
                _WithdrawalsTab(admin: admin, withdrawal: context.watch<WithdrawalProvider>(), theme: theme),
                _WalletTab(admin: admin, theme: theme),
                AdminAnalyticsTab(admin: admin, theme: theme),
                AdminBannersTab(admin: admin, theme: theme),
                AdminVerificationTab(admin: admin, theme: theme),
                AdminAuditLogTab(admin: admin, theme: theme),
                _SettingsTab(admin: admin, theme: theme),
                const AdminCouponsTab(),
                AdminAffiliateProjectsTab(),
                const AdminReferralLevelsTab(),
                const AdminStreakMultiplierTab(),
                _ReferralsTab(admin: admin, theme: theme),
                AdminSupportTab(admin: admin, theme: theme),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ============================================================
// DASHBOARD TAB — Advanced Next-Gen Design
// ============================================================
class _DashboardTab extends StatefulWidget {
  final AdminProvider admin;
  final ThemeData theme;

  const _DashboardTab({required this.admin, required this.theme});

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final admin = widget.admin;
    final theme = widget.theme;

    if (admin.isLoading && admin.totalUsers == 0) {
      return const Center(child: PremiumLoader());
    }

    return RefreshIndicator(
      onRefresh: () async {
        await admin.loadDashboard();
        _animController.reset();
        _animController.forward();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Welcome Header ──────────────────────────────
          FadeTransition(
            opacity: _fadeAnim,
            child: PremiumGlass(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [theme.colorScheme.primary, theme.colorScheme.tertiary],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Command Center',
                              style: theme.textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          Text(admin.adminProfile?.fullName ?? 'Admin',
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                        ],
                      ),
                      const Spacer(),
                      // Last updated timestamp
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Icon(Icons.cloud_done_rounded, size: 18,
                              color: const Color(0xFF22C55E)),
                          Text('Live',
                              style: TextStyle(fontSize: 10,
                                  color: const Color(0xFF22C55E),
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── AI Insight Cards ────────────────────────────
          if (admin.insights.isNotEmpty)
            _AnimatedSection(
              animController: _animController,
              delay: 0.1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome_rounded, size: 16,
                          color: const Color(0xFF8B5CF6)),
                      const SizedBox(width: 6),
                      Text('AI Insights',
                          style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF8B5CF6))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...admin.insights.map((insight) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: PremiumGlass(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: insight.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(insight.icon, size: 18, color: insight.color),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(insight.title,
                                    style: const TextStyle(
                                        fontSize: 13, fontWeight: FontWeight.w600)),
                                Text(insight.subtitle,
                                    style: TextStyle(fontSize: 11,
                                        color: theme.colorScheme.onSurfaceVariant)),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right, size: 16,
                              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
                        ],
                      ),
                    ),
                  )),
                ],
              ),
            ),

          if (admin.insights.isNotEmpty) const SizedBox(height: 16),

          // ── KPI Sparkline Cards ─────────────────────────
          _AnimatedSection(
            animController: _animController,
            delay: 0.2,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _SparklineCard(
                        label: 'Total Users',
                        value: Helpers.formatNumber(admin.totalUsers),
                        icon: Icons.people_outlined,
                        color: theme.colorScheme.primary,
                        theme: theme,
                        sparkData: admin.dailyUserGrowth,
                        trend: admin.dailyUserGrowth.length >= 2
                            ? admin.dailyUserGrowth.last > admin.dailyUserGrowth.first
                            : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SparklineCard(
                        label: 'Active (30d)',
                        value: Helpers.formatNumber(admin.activeUsers),
                        icon: Icons.person_pin_outlined,
                        color: theme.colorScheme.tertiary,
                        theme: theme,
                        sparkData: admin.dailyUserGrowth,
                        trend: admin.activeUsers > 0 ? true : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _SparklineCard(
                        label: 'Revenue',
                        value: Helpers.formatCurrency(admin.totalEarnings),
                        icon: Icons.trending_up_outlined,
                        color: const Color(0xFF22C55E),
                        theme: theme,
                        sparkData: admin.dailyUserGrowth,
                        trend: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SparklineCard(
                        label: 'Pending Rdm',
                        value: Helpers.formatNumber(admin.pendingWithdrawals),
                        icon: Icons.hourglass_empty_outlined,
                        color: const Color(0xFFF59E0B),
                        theme: theme,
                        sparkData: admin.dailyUserGrowth,
                        trend: admin.pendingWithdrawals > 0 ? false : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Quick Actions Grid ───────────────────────────
          _AnimatedSection(
            animController: _animController,
            delay: 0.3,
            child: PremiumGlass(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.flash_on_rounded, size: 16, color: const Color(0xFFF59E0B)),
                      const SizedBox(width: 6),
                      Text('Quick Actions',
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(child: _ActionTile(
                        icon: Icons.people_outlined,
                        label: 'Refresh Users',
                        color: theme.colorScheme.primary,
                        onTap: admin.loadUsers,
                      )),
                      const SizedBox(width: 8),
                      Expanded(child: _ActionTile(
                        icon: Icons.refresh_rounded,
                        label: 'Reload Dashboard',
                        color: const Color(0xFF06B6D4),
                        onTap: () {
                          admin.loadDashboard();
                          _animController.reset();
                          _animController.forward();
                        },
                      )),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _ActionTile(
                        icon: Icons.file_copy_rounded,
                        label: 'Export Users CSV',
                        color: const Color(0xFF22C55E),
                        onTap: admin.copyUsersToClipboard,
                      )),
                      const SizedBox(width: 8),
                      Expanded(child: _ActionTile(
                        icon: Icons.notifications_outlined,
                        label: 'Send Announcement',
                        color: const Color(0xFF8B5CF6),
                        onTap: () {
                          // Navigate to Settings tab
                        },
                      )),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Revenue & System Health ──────────────────────
          _AnimatedSection(
            animController: _animController,
            delay: 0.4,
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: PremiumGlass(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.account_balance_outlined, size: 16,
                                color: theme.colorScheme.primary),
                            const SizedBox(width: 6),
                            Text('Revenue',
                                style: theme.textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _MiniMetric(
                          label: 'Earnings',
                          value: Helpers.formatCurrency(admin.revenueStats['totalEarnings'] ?? 0),
                          color: const Color(0xFF22C55E),
                          theme: theme,
                        ),
                        const SizedBox(height: 6),
                        _MiniMetric(
                          label: 'Redeemed',
                          value: Helpers.formatCurrency(admin.revenueStats['totalWithdrawn'] ?? 0),
                          color: const Color(0xFFEF4444),
                          theme: theme,
                        ),
                        const Divider(height: 16),
                        _MiniMetric(
                          label: 'Platform Balance',
                          value: Helpers.formatCurrency(admin.revenueStats['remainingBalance'] ?? 0),
                          color: theme.colorScheme.primary,
                          theme: theme,
                          bold: true,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: PremiumGlass(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.monitor_heart_rounded, size: 16,
                                color: const Color(0xFF22C55E)),
                            const SizedBox(width: 6),
                            Text('System',
                                style: theme.textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _HealthRow(
                          icon: Icons.check_circle_rounded,
                          label: 'Status',
                          value: 'Online',
                          valueColor: const Color(0xFF22C55E),
                          theme: theme,
                        ),
                        const SizedBox(height: 6),
                        _HealthRow(
                          icon: Icons.speed_rounded,
                          label: 'Response',
                          value: '${admin.responseTime.toStringAsFixed(0)}ms',
                          valueColor: admin.responseTime < 100
                              ? const Color(0xFF22C55E)
                              : const Color(0xFFF59E0B),
                          theme: theme,
                        ),
                        const SizedBox(height: 6),
                        _HealthRow(
                          icon: Icons.error_outline_rounded,
                          label: 'Errors',
                          value: '${admin.errorRate.toStringAsFixed(1)}%',
                          valueColor: admin.errorRate < 1
                              ? const Color(0xFF22C55E)
                              : const Color(0xFFEF4444),
                          theme: theme,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── User Growth Trend ────────────────────────────
          _AnimatedSection(
            animController: _animController,
            delay: 0.5,
            child: PremiumGlass(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.trending_up_rounded, size: 16, color: theme.colorScheme.primary),
                      const SizedBox(width: 6),
                      Text('User Growth (7 days)',
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Text('${admin.totalUsers} total',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (admin.dailyUserGrowth.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 30),
                      child: Center(
                        child: Text('No growth data yet',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      ),
                    )
                  else
                    SizedBox(
                      height: 80,
                      child: CustomPaint(
                        size: const Size(double.infinity, 80),
                        painter: _SparklinePainter(
                          data: admin.dailyUserGrowth,
                          lineColor: theme.colorScheme.primary,
                          fillColor: theme.colorScheme.primary.withValues(alpha: 0.08),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

/// A section that fades in with a delay.
class _AnimatedSection extends StatelessWidget {
  final AnimationController animController;
  final double delay;
  final Widget child;

  const _AnimatedSection({
    required this.animController,
    required this.delay,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animController,
        curve: Interval(delay, 1.0, curve: Curves.easeOutCubic),
      ),
      child: child,
    );
  }
}

/// KPI card with inline sparkline chart.
class _SparklineCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final ThemeData theme;
  final List<int> sparkData;
  final bool? trend; // true = up, false = down, null = neutral

  const _SparklineCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.theme,
    required this.sparkData,
    this.trend,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumGlass(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const Spacer(),
              if (trend != null)
                Container(
                  padding: const EdgeInsets.all(2),
                  child: Icon(
                    trend! ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                    size: 14,
                    color: trend! ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(value,
              style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold, color: color, fontSize: 18)),
          const SizedBox(height: 2),
          Text(label,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          if (sparkData.length >= 2) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 28,
              child: CustomPaint(
                size: const Size(double.infinity, 28),
                painter: _SparklinePainter(
                  data: sparkData,
                  lineColor: color,
                  fillColor: color.withValues(alpha: 0.06),
                  strokeWidth: 1.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Mini sparkline area chart painter.
class _SparklinePainter extends CustomPainter {
  final List<int> data;
  final Color lineColor;
  final Color fillColor;
  final double strokeWidth;

  _SparklinePainter({
    required this.data,
    required this.lineColor,
    required this.fillColor,
    this.strokeWidth = 2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxVal = data.reduce((a, b) => a > b ? a : b).toDouble();
    if (maxVal == 0) return;

    final path = Path();
    final stepX = size.width / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = size.height - (data[i] / maxVal) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Draw fill
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [fillColor, fillColor.withValues(alpha: 0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);

    // Draw line
    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);

    // Draw end dot
    final lastIdx = data.length - 1;
    canvas.drawCircle(
      Offset(lastIdx * stepX, size.height - (data[lastIdx] / maxVal) * size.height),
      3,
      Paint()..color = lineColor,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Quick action tile button.
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: color),
                textAlign: TextAlign.center,
                maxLines: 1),
          ],
        ),
      ),
    );
  }
}

/// Mini metric row for revenue card.
class _MiniMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final ThemeData theme;
  final bool bold;

  const _MiniMetric({
    required this.label,
    required this.value,
    required this.color,
    required this.theme,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(label,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ),
        Text(value,
            style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: bold ? FontWeight.bold : FontWeight.w600,
                color: color)),
      ],
    );
  }
}

/// System health indicator row.
class _HealthRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;
  final ThemeData theme;

  const _HealthRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.valueColor,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: valueColor),
        const SizedBox(width: 6),
        Text(label,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontSize: 10)),
        const Spacer(),
        Text(value,
            style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600, color: valueColor, fontSize: 10)),
      ],
    );
  }
}

// ============================================================
// USERS TAB — Advanced
// ============================================================
class _UsersTab extends StatefulWidget {
  final AdminProvider admin;
  final ThemeData theme;

  const _UsersTab({required this.admin, required this.theme});

  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayUsers = widget.admin.searchedUsers.isNotEmpty
        ? widget.admin.searchedUsers
        : widget.admin.users;

    return Column(
      children: [
        // Search + Export bar
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: PremiumGlass(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by name, email, or ID...',
                      prefixIcon: Icon(Icons.search, color: widget.theme.colorScheme.onSurfaceVariant, size: 20),
                      border: InputBorder.none,
                      filled: false,
                      isDense: true,
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                widget.admin.searchUsers('');
                              },
                            )
                          : null,
                    ),
                    onChanged: (value) => widget.admin.searchUsers(value),
                  ),
                ),
                const SizedBox(width: 8),
                // Export CSV button
                Tooltip(
                  message: 'Export users to CSV (copies to clipboard)',
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: InkWell(
                      onTap: () {
                        widget.admin.copyUsersToClipboard();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(widget.admin.successMessage ?? 'Users copied to clipboard!'),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: const Icon(Icons.file_copy_rounded, size: 20, color: Color(0xFF22C55E)),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // Refresh button
                Tooltip(
                  message: 'Refresh users',
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: InkWell(
                      onTap: () => widget.admin.loadUsers(),
                      borderRadius: BorderRadius.circular(8),
                      child: Icon(Icons.refresh_rounded, size: 20,
                          color: widget.theme.colorScheme.primary),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Stats bar
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Row(
            children: [
              _UserStatBadge(
                label: 'Total',
                value: '${widget.admin.users.length}',
                color: widget.theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              _UserStatBadge(
                label: 'Verified',
                value: '${widget.admin.users.where((u) => u.isEmailVerified).length}',
                color: const Color(0xFF22C55E),
              ),
              const SizedBox(width: 8),
              _UserStatBadge(
                label: 'Active',
                value: '${widget.admin.users.where((u) => u.isActive).length}',
                color: const Color(0xFF06B6D4),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        Expanded(
          child: widget.admin.isLoading && widget.admin.users.isEmpty
              ? const Center(child: PremiumLoader())
              : displayUsers.isEmpty
                  ? RefreshIndicator(
                      onRefresh: () => widget.admin.loadUsers(),
                      child: ListView(
                        children: [
                          SizedBox(
                            height: 200,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.people_outline, size: 48,
                                      color: widget.theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
                                  const SizedBox(height: 8),
                                  Text('No users found',
                                      style: widget.theme.textTheme.bodyLarge?.copyWith(
                                          color: widget.theme.colorScheme.onSurfaceVariant)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => widget.admin.loadUsers(),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: displayUsers.length,
                        itemBuilder: (context, index) {
                          final user = displayUsers[index];
                          return _UserCard(
                            user: user,
                            theme: widget.theme,
                            admin: widget.admin,
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}

class _UserStatBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _UserStatBadge({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _UserCard extends StatefulWidget {
  final UserEntity user;
  final ThemeData theme;
  final AdminProvider admin;

  const _UserCard({required this.user, required this.theme, required this.admin});

  @override
  State<_UserCard> createState() => _UserCardState();
}

class _UserCardState extends State<_UserCard> {
  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final theme = widget.theme;

    return PremiumGlass(
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                  style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
            ),
            if (user.isEmailVerified)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Color(0xFF22C55E),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, size: 10, color: Colors.white),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(user.fullName,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            ),
            if (!user.isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('INACTIVE',
                    style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700,
                        color: const Color(0xFFEF4444))),
              ),
          ],
        ),
        subtitle: Row(
          children: [
            Icon(Icons.email_outlined, size: 12, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Expanded(
              child: Text(user.email,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ),
          ],
        ),
        shape: const Border(),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          const Divider(),
          const SizedBox(height: 8),
          _UserDetail('UID', user.uid.length > 20 ? '...${user.uid.substring(user.uid.length - 20)}' : user.uid, theme),
          const SizedBox(height: 4),
          _UserDetail('Phone', user.phone ?? 'N/A', theme),
          const SizedBox(height: 4),
          _UserDetail('Referral', user.referralCode, theme),
          const SizedBox(height: 4),
          _UserDetail('Wallet', Helpers.formatCurrency(user.walletBalance), theme, valueColor: const Color(0xFF22C55E)),
          const SizedBox(height: 4),
          _UserDetail('Earnings', Helpers.formatCurrency(user.totalEarnings), theme),
          const SizedBox(height: 4),
          _UserDetail('Redeemed', Helpers.formatCurrency(user.totalWithdrawn), theme, valueColor: const Color(0xFFEF4444)),
          const SizedBox(height: 4),
          _UserDetail('Joined', Helpers.formatDateTime(user.createdAt), theme),
          const SizedBox(height: 10),
          // Inline toggle for user status
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: user.isEmailVerified
                      ? const Color(0xFF22C55E).withValues(alpha: 0.08)
                      : const Color(0xFFF59E0B).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      user.isEmailVerified ? Icons.verified_rounded : Icons.warning_amber_rounded,
                      size: 12,
                      color: user.isEmailVerified ? const Color(0xFF22C55E) : const Color(0xFFF59E0B),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      user.isEmailVerified ? 'Verified' : 'Unverified',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: user.isEmailVerified ? const Color(0xFF22C55E) : const Color(0xFFF59E0B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UserDetail extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;
  final Color? valueColor;

  const _UserDetail(this.label, this.value, this.theme, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(label, style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant)),
        ),
        Expanded(
          child: Text(value, style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500, color: valueColor)),
        ),
      ],
    );
  }
}

// ============================================================
// WITHDRAWALS TAB
// ============================================================
class _WithdrawalsTab extends StatefulWidget {
  final AdminProvider admin;
  final WithdrawalProvider withdrawal;
  final ThemeData theme;

  const _WithdrawalsTab({
    required this.admin,
    required this.withdrawal,
    required this.theme,
  });

  @override
  State<_WithdrawalsTab> createState() => _WithdrawalsTabState();
}

class _WithdrawalsTabState extends State<_WithdrawalsTab> {
  WithdrawalStatus? _filterStatus;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.withdrawal.initializeAdmin(status: _filterStatus);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<WithdrawalEntity> _filterWithdrawals(List<WithdrawalEntity> withdrawals) {
    if (_searchQuery.isEmpty) return withdrawals;
    final query = _searchQuery.toLowerCase();
    return withdrawals.where((w) {
      final user = _getUser(w.userId);
      return w.withdrawalId.toLowerCase().contains(query) ||
          w.accountDetails.toLowerCase().contains(query) ||
          w.amount.toString().contains(query) ||
          (w.userName?.toLowerCase().contains(query) ?? false) ||
          (w.userEmail?.toLowerCase().contains(query) ?? false) ||
          (w.userPhone?.contains(query) ?? false) ||
          (user?.fullName.toLowerCase().contains(query) ?? false) ||
          (user?.email.toLowerCase().contains(query) ?? false) ||
          (user?.phone?.contains(query) ?? false) ||
          (w.transactionId?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  UserEntity? _getUser(String userId) {
    try {
      return widget.admin.users.firstWhere((u) => u.uid == userId);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    var withdrawals = widget.withdrawal.allWithdrawals;
    withdrawals = _filterWithdrawals(withdrawals);

    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: PremiumGlass(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, email, or perk...',
                prefixIcon: Icon(Icons.search, color: widget.theme.colorScheme.onSurfaceVariant),
                border: InputBorder.none,
                filled: false,
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
        ),

        // Filter Chips
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  selected: _filterStatus == null,
                  onSelected: () {
                    setState(() => _filterStatus = null);
                    widget.withdrawal.initializeAdmin(status: null);
                  },
                  color: widget.theme.colorScheme.primary,
                  theme: widget.theme,
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Pending',
                  selected: _filterStatus == WithdrawalStatus.pending,
                  onSelected: () {
                    setState(() => _filterStatus = WithdrawalStatus.pending);
                    widget.withdrawal.initializeAdmin(status: WithdrawalStatus.pending);
                  },
                  color: Colors.orange,
                  theme: widget.theme,
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Granted',
                  selected: _filterStatus == WithdrawalStatus.paid,
                  onSelected: () {
                    setState(() => _filterStatus = WithdrawalStatus.paid);
                    widget.withdrawal.initializeAdmin(status: WithdrawalStatus.paid);
                  },
                  color: Colors.teal,
                  theme: widget.theme,
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Approved',
                  selected: _filterStatus == WithdrawalStatus.approved,
                  onSelected: () {
                    setState(() => _filterStatus = WithdrawalStatus.approved);
                    widget.withdrawal.initializeAdmin(status: WithdrawalStatus.approved);
                  },
                  color: Colors.green,
                  theme: widget.theme,
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Rejected',
                  selected: _filterStatus == WithdrawalStatus.rejected,
                  onSelected: () {
                    setState(() => _filterStatus = WithdrawalStatus.rejected);
                    widget.withdrawal.initializeAdmin(status: WithdrawalStatus.rejected);
                  },
                  color: widget.theme.colorScheme.error,
                  theme: widget.theme,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 8),

        Expanded(
          child: widget.withdrawal.isLoading
              ? const Center(child: PremiumLoader())
              : withdrawals.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long_outlined, size: 48,
                              color: widget.theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
                          const SizedBox(height: 12),
                          Text('No withdrawals found',
                              style: widget.theme.textTheme.bodyLarge?.copyWith(
                                  color: widget.theme.colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: withdrawals.length,
                      itemBuilder: (context, index) {
                        final w = withdrawals[index];
                        return _AdminWithdrawalCard(
                          withdrawal: w,
                          theme: widget.theme,
                          withdrawalProvider: widget.withdrawal,
                          admin: widget.admin,
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final Color color;
  final ThemeData theme;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    required this.color,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label, style: TextStyle(fontSize: 12, color: selected ? Colors.white : null)),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: color,
      checkmarkColor: Colors.white,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _AdminWithdrawalCard extends StatelessWidget {
  final WithdrawalEntity withdrawal;
  final ThemeData theme;
  final WithdrawalProvider withdrawalProvider;
  final AdminProvider admin;

  const _AdminWithdrawalCard({
    required this.withdrawal,
    required this.theme,
    required this.withdrawalProvider,
    required this.admin,
  });

  UserEntity? _getUser() {
    try {
      return admin.users.firstWhere((u) => u.uid == withdrawal.userId);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _getUser();
    final statusColor = _statusColor();
    final isPending = withdrawal.status == WithdrawalStatus.pending;
    final isFailed = withdrawal.status == WithdrawalStatus.rejected &&
        withdrawal.adminRemarks?.contains('Auto-payout failed') == true;

    // Risk assessment based on amount
    final riskLevel = _computeRiskLevel(withdrawal.amount);
    final hoursSinceRequest = DateTime.now().difference(withdrawal.requestedAt).inHours;
    final isUrgent = isPending && hoursSinceRequest > 48;

    return PremiumGlass(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: isPending || isFailed ? () => _showAdminActionDialog(context) : null,
        child: Row(
          children: [
            // Icon with risk ring
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: statusColor.withValues(alpha: 0.1),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.redeem_rounded, color: statusColor, size: 20),
                  if (isPending && riskLevel != null)
                    Positioned(
                      right: 2,
                      top: 2,
                      child: Container(
                        width: 10, height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: riskLevel == _RiskLevel.high
                              ? const Color(0xFFEF4444)
                              : riskLevel == _RiskLevel.medium
                                  ? const Color(0xFFF59E0B)
                                  : const Color(0xFF22C55E),
                          border: Border.all(color: theme.colorScheme.surface, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${withdrawal.amount.toStringAsFixed(2)} pts',
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 6),
                      // Risk badge for high amounts
                      if (isPending && riskLevel == _RiskLevel.high)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('HIGH',
                              style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700,
                                  color: Color(0xFFEF4444))),
                        )
                      else if (isPending && riskLevel == _RiskLevel.medium)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('MEDIUM',
                              style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700,
                                  color: Color(0xFFF59E0B))),
                        ),
                      // Urgency indicator
                      if (isUrgent)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('${hoursSinceRequest ~/ 24}d',
                              style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700,
                                  color: const Color(0xFF8B5CF6))),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('PERK',
                            style: TextStyle(fontSize: 9, color: Colors.white)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  if (user != null)
                    Text(
                      '${user.fullName} · ${user.phone ?? "No phone"}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  Row(
                    children: [
                      Text(
                        Helpers.formatDateTime(withdrawal.requestedAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                      ),
                      if (isUrgent) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.access_time_rounded, size: 10,
                            color: const Color(0xFF8B5CF6)),
                        Text(' ${hoursSinceRequest}h',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600,
                                color: const Color(0xFF8B5CF6))),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_statusLabel(),
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor)),
                ),
                if (isPending || isFailed) ...[
                  const SizedBox(height: 4),
                  Icon(Icons.chevron_right, size: 16,
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  _RiskLevel? _computeRiskLevel(double amount) {
    if (amount >= 10000) return _RiskLevel.high;
    if (amount >= 5000) return _RiskLevel.medium;
    return null;
  }

  Color _statusColor() {
    switch (withdrawal.status) {
      case WithdrawalStatus.pending: return Colors.orange;
      case WithdrawalStatus.paid: return Colors.teal;
      case WithdrawalStatus.approved: return Colors.green;
      case WithdrawalStatus.rejected: return theme.colorScheme.error;
    }
  }

  String _statusLabel() {
    switch (withdrawal.status) {
      case WithdrawalStatus.pending: return 'PENDING';
      case WithdrawalStatus.paid: return 'GRANTED';
      case WithdrawalStatus.approved: return 'APPROVED';
      case WithdrawalStatus.rejected: return 'REJECTED';
    }
  }

  void _showAdminActionDialog(BuildContext context) {
    final remarksController = TextEditingController();
    final transactionIdController = TextEditingController();
    final user = _getUser();
    final isSubmitting = ValueNotifier<bool>(false);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: PremiumCard(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.redeem_rounded, color: theme.colorScheme.primary, size: 22),
                    const SizedBox(width: 8),
                    Text('Process Redemption',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),

                // User Info
                if (user != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: theme.colorScheme.primary,
                              child: Text(
                                user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(user.fullName,
                                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                                  Text(user.email,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (user.phone != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.phone_outlined, size: 14, color: theme.colorScheme.onSurfaceVariant),
                              const SizedBox(width: 6),
                              Text(user.phone!,
                                  style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.account_balance_wallet_outlined, size: 14, color: theme.colorScheme.onSurfaceVariant),
                            const SizedBox(width: 6),
                            Text('Wallet: ${user.walletBalance.toStringAsFixed(2)} pts',
                                style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 12),
                _DialogDetailRow('Amount', '${withdrawal.amount.toStringAsFixed(2)} pts', theme, bold: true),
                const SizedBox(height: 4),
                _DialogDetailRow('Perk', withdrawal.accountDetails, theme),
                const SizedBox(height: 4),
                if (withdrawal.userName != null)
                  _DialogDetailRow('Name', withdrawal.userName!, theme),
                if (withdrawal.userEmail != null) ...[
                  const SizedBox(height: 4),
                  _DialogDetailRow('Email', withdrawal.userEmail!, theme),
                ],
                if (withdrawal.userPhone != null) ...[
                  const SizedBox(height: 4),
                  _DialogDetailRow('Phone', withdrawal.userPhone!, theme),
                ],
                const SizedBox(height: 4),
                _DialogDetailRow('Wallet Balance', '${withdrawal.walletBalanceAtRequest.toStringAsFixed(2)} pts', theme),
                const SizedBox(height: 12),

                // Transaction ID field
                TextField(
                  controller: transactionIdController,
                  decoration: InputDecoration(
                    labelText: 'Transaction / Reference ID',
                    hintText: 'e.g. TXN123456789',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    isDense: true,
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    prefixIcon: Icon(Icons.tag_rounded, size: 18),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: remarksController,
                  decoration: InputDecoration(
                    labelText: 'Admin Remarks',
                    hintText: 'Optional notes...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    isDense: true,
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  ),
                  maxLines: 2,
                ),

                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () async {
                        final success = await withdrawalProvider.rejectWithdrawal(
                          withdrawal.withdrawalId,
                          remarks: remarksController.text.isNotEmpty ? remarksController.text : 'Rejected by admin',
                        );
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          if (!success) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                content: Text(withdrawalProvider.errorMessage ?? 'Failed to reject redemption'),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                          }
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: BorderSide(color: Colors.red.withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Reject'),
                    ),
                    const SizedBox(width: 8),
                    ValueListenableBuilder<bool>(
                      valueListenable: isSubmitting,
                      builder: (context, submitting, _) {
                        return FilledButton.icon(
                          onPressed: submitting ? null : () async {
                            isSubmitting.value = true;
                            final txnId = transactionIdController.text.trim();
                            final success = await withdrawalProvider.markAsPaid(
                              withdrawal.withdrawalId,
                              remarks: remarksController.text.isNotEmpty ? remarksController.text : null,
                              transactionId: txnId.isNotEmpty ? txnId : null,
                            );
                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                              if (!success) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(
                                    content: Text(withdrawalProvider.errorMessage ?? 'Failed to process redemption'),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                );
                              }
                            }
                          },
                          icon: submitting
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.check_circle_outline, size: 18),
                          label: Text(submitting ? 'Processing...' : 'Mark Paid'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.teal,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  /// Process a redemption request (approve / grant points / reject).
}

class _DialogDetailRow extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;
  final bool bold;

  const _DialogDetailRow(this.label, this.value, this.theme, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
          child: Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ),
        Expanded(
          child: Text(value, style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: bold ? FontWeight.bold : FontWeight.w500)),
        ),
      ],
    );
  }
}

// ============================================================
// WALLET TAB
// ============================================================
class _WalletTab extends StatefulWidget {
  final AdminProvider admin;
  final ThemeData theme;

  const _WalletTab({required this.admin, required this.theme});

  @override
  State<_WalletTab> createState() => _WalletTabState();
}

class _WalletTabState extends State<_WalletTab> {
  final _userIdController = TextEditingController();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  bool _isCredit = true;

  @override
  void dispose() {
    _userIdController.dispose();
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final userId = _userIdController.text.trim();
    final amount = double.tryParse(_amountController.text);
    final desc = _descController.text.trim();

    if (userId.isEmpty || amount == null || amount <= 0 || desc.isEmpty) {
      _showSnackBar('Fill all fields with valid values');
      return;
    }

    final admin = widget.admin;
    bool success;
    if (_isCredit) {
      success = await admin.creditUserWallet(userId: userId, amount: amount, description: desc);
    } else {
      success = await admin.debitUserWallet(userId: userId, amount: amount, description: desc);
    }

    if (!mounted) return;

    if (success) {
      _userIdController.clear();
      _amountController.clear();
      _descController.clear();
      _showSnackBar(admin.successMessage ?? 'Done!');
    } else {
      _showSnackBar(admin.errorMessage ?? '${_isCredit ? "Credit" : "Debit"} failed. Check the user ID and your connection.');
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PremiumGlass(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.account_balance_wallet_outlined, color: widget.theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text('Wallet Management',
                        style: widget.theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 20),

                // Credit/Debit Toggle
                Row(
                  children: [
                    Expanded(
                      child: _ToggleButton(
                        label: 'Credit',
                        selected: _isCredit,
                        color: Colors.green,
                        onTap: () => setState(() => _isCredit = true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ToggleButton(
                        label: 'Debit',
                        selected: !_isCredit,
                        color: widget.theme.colorScheme.error,
                        onTap: () => setState(() => _isCredit = false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                TextField(
                  controller: _userIdController,
                  decoration: InputDecoration(
                    labelText: 'User ID',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: widget.theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    prefixText: 'pts ',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: widget.theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: widget.theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  ),
                ),
                const SizedBox(height: 24),
                GradientButton(
                  onPressed: widget.admin.isLoading ? null : _submit,
                  label: widget.admin.isLoading
                      ? 'Processing...'
                      : '${_isCredit ? "Credit" : "Debit"} Wallet',
                  isLoading: widget.admin.isLoading,
                  gradient: LinearGradient(
                    colors: [
                      _isCredit ? Colors.green : widget.theme.colorScheme.error,
                      (_isCredit ? Colors.green : widget.theme.colorScheme.error).withValues(alpha: 0.8),
                    ],
                  ),
                  icon: _isCredit ? Icons.add_circle_outlined : Icons.remove_circle_outlined,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdToggle extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final ThemeData theme;

  const _AdToggle({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      value: value,
      onChanged: onChanged,
      dense: true,
      shape: const Border(),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _ToggleButton({required this.label, required this.selected, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? color : color.withValues(alpha: 0.3)),
        ),
        child: Center(
          child: Text(label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: selected ? color : color.withValues(alpha: 0.7),
                fontSize: 15,
              )),
        ),
      ),
    );
  }
}

// ============================================================
// SETTINGS TAB
// ============================================================
class _SettingsTab extends StatefulWidget {
  final AdminProvider admin;
  final ThemeData theme;

  const _SettingsTab({required this.admin, required this.theme});

  @override
  State<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<_SettingsTab> {
  // Settings controllers
  final _bonusReferrerController = TextEditingController();
  final _bonusReferredController = TextEditingController();
  final _adRewardController = TextEditingController();
  final _dailyCheckInController = TextEditingController();
  final _minWithdrawalController = TextEditingController();
  final _announcementController = TextEditingController();

  // Ad config controllers
  bool _interstitialEnabled = true;
  bool _bannerAdsEnabled = true;
  bool _rewardedAdEnabled = true;
  bool _showAdsOnHome = true;
  bool _showAdsOnOffers = true;
  final _interstitialIntervalCtrl = TextEditingController(text: '3');
  final _maxBannerPerPageCtrl = TextEditingController(text: '2');
  final _adRewardAmountCtrl = TextEditingController(text: '0.50');
  final _minRewardForAdCtrl = TextEditingController(text: '0.10');
  bool _initialized = false;
  bool _adConfigInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      widget.admin.loadAppSettings();
      widget.admin.loadAdConfig();
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _bonusReferrerController.dispose();
    _bonusReferredController.dispose();
    _adRewardController.dispose();
    _dailyCheckInController.dispose();
    _minWithdrawalController.dispose();
    _announcementController.dispose();
    _interstitialIntervalCtrl.dispose();
    _maxBannerPerPageCtrl.dispose();
    _adRewardAmountCtrl.dispose();
    _minRewardForAdCtrl.dispose();
    super.dispose();
  }

  void _populateFields() {
    final s = widget.admin.appSettings;
    if (s == null) return;
    _bonusReferrerController.text = s.referrerBonus.toString();
    _bonusReferredController.text = s.referredBonus.toString();
    _adRewardController.text = s.adRewardAmount.toString();
    _dailyCheckInController.text = s.dailyCheckInBaseReward.toString();
    _minWithdrawalController.text = s.minWithdrawalAmount.toString();
    _announcementController.text = s.announcement ?? '';
  }

  void _populateAdConfig() {
    final config = widget.admin.adConfig;
    if (config.isEmpty) return;
    _interstitialEnabled = config['interstitialEnabled'] as bool? ?? true;
    _bannerAdsEnabled = config['bannerAdsEnabled'] as bool? ?? true;
    _rewardedAdEnabled = config['rewardedAdEnabled'] as bool? ?? true;
    _showAdsOnHome = config['showAdsOnHome'] as bool? ?? true;
    _showAdsOnOffers = config['showAdsOnOffers'] as bool? ?? true;
    _interstitialIntervalCtrl.text = (config['interstitialInterval'] as num? ?? 3).toString();
    _maxBannerPerPageCtrl.text = (config['maxBannerPerPage'] as num? ?? 2).toString();
    _adRewardAmountCtrl.text = (config['adRewardAmount'] as num? ?? 0.50).toStringAsFixed(2);
    _minRewardForAdCtrl.text = (config['minRewardForAd'] as num? ?? 0.10).toStringAsFixed(2);
  }

  Future<void> _saveSettings() async {
    final s = widget.admin.appSettings;
    if (s == null) return;

    final updated = s.copyWith(
      referrerBonus: double.tryParse(_bonusReferrerController.text) ?? s.referrerBonus,
      referredBonus: double.tryParse(_bonusReferredController.text) ?? s.referredBonus,
      adRewardAmount: double.tryParse(_adRewardController.text) ?? s.adRewardAmount,
      dailyCheckInBaseReward: double.tryParse(_dailyCheckInController.text) ?? s.dailyCheckInBaseReward,
      minWithdrawalAmount: double.tryParse(_minWithdrawalController.text) ?? s.minWithdrawalAmount,
      announcement: _announcementController.text.isNotEmpty ? _announcementController.text : null,
    );

    final admin = widget.admin;
    final success = await admin.saveSettings(updated);
    if (!mounted) return;

    if (success) {
      _showSnackBar(admin.successMessage ?? 'Settings saved!');
    } else {
      _showSnackBar(admin.errorMessage ?? 'Failed to save settings. Check your connection.');
    }
  }

  Future<void> _sendAnnouncement() async {
    if (_announcementController.text.trim().isEmpty) return;
    final admin = widget.admin;
    final success = await admin.sendAnnouncement(_announcementController.text.trim());
    if (!mounted) return;

    if (success) {
      _showSnackBar(admin.successMessage ?? 'Announcement sent!');
    } else {
      _showSnackBar(admin.errorMessage ?? 'Failed to send announcement. Check your connection.');
    }
  }

  Future<void> _saveAdConfig() async {
    final config = {
      'interstitialEnabled': _interstitialEnabled,
      'bannerAdsEnabled': _bannerAdsEnabled,
      'rewardedAdEnabled': _rewardedAdEnabled,
      'interstitialInterval': int.tryParse(_interstitialIntervalCtrl.text) ?? 3,
      'maxBannerPerPage': int.tryParse(_maxBannerPerPageCtrl.text) ?? 2,
      'adRewardAmount': double.tryParse(_adRewardAmountCtrl.text) ?? 0.50,
      'showAdsOnHome': _showAdsOnHome,
      'showAdsOnOffers': _showAdsOnOffers,
      'minRewardForAd': double.tryParse(_minRewardForAdCtrl.text) ?? 0.10,
    };
    final admin = widget.admin;
    final success = await admin.saveAdConfig(config);
    if (!mounted) return;

    if (success) {
      _showSnackBar(admin.successMessage ?? 'Ad config saved!');
    } else {
      _showSnackBar(admin.errorMessage ?? 'Failed to save ad config. Check your connection.');
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.admin.isLoading && widget.admin.appSettings == null) {
      return const Center(child: PremiumLoader());
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.admin.appSettings != null && _bonusReferrerController.text.isEmpty) {
        _populateFields();
      }
      if (widget.admin.adConfig.isNotEmpty && !_adConfigInitialized) {
        _populateAdConfig();
        _adConfigInitialized = true;
      }
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PremiumGlass(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.settings_rounded, color: widget.theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text('App Settings',
                        style: widget.theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 20),

                _SettingsSection(title: 'Referral Bonuses', theme: widget.theme, children: [
                  _SettingsField(label: 'Referrer Bonus (pts)', controller: _bonusReferrerController, theme: widget.theme),
                  const SizedBox(height: 8),
                  _SettingsField(label: 'Referred Bonus (pts)', controller: _bonusReferredController, theme: widget.theme),
                ]),
                const SizedBox(height: 16),

                _SettingsSection(title: 'Reward Amounts', theme: widget.theme, children: [
                  _SettingsField(label: 'Ad Reward (pts)', controller: _adRewardController, theme: widget.theme),
                  const SizedBox(height: 8),
                  _SettingsField(label: 'Daily Check-In (pts)', controller: _dailyCheckInController, theme: widget.theme),
                ]),
                const SizedBox(height: 16),

                _SettingsSection(title: 'Redemption Limits', theme: widget.theme, children: [
                  _SettingsField(label: 'Min Redemption (pts)', controller: _minWithdrawalController, theme: widget.theme),
                ]),
                const SizedBox(height: 24),

                GradientButton(
                  onPressed: widget.admin.isLoading ? null : _saveSettings,
                  label: 'Save Settings',
                  icon: Icons.save_outlined,
                ),

                const SizedBox(height: 24),

                _SettingsSection(title: 'Announcement', theme: widget.theme, children: [
                  TextField(
                    controller: _announcementController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Enter announcement message...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: widget.theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    ),
                  ),
                  const SizedBox(height: 8),
                  GradientButton(
                    onPressed: widget.admin.isLoading ? null : _sendAnnouncement,
                    label: 'Send Announcement',
                    icon: Icons.send_rounded,
                    gradient: LinearGradient(
                      colors: [widget.theme.colorScheme.secondary, widget.theme.colorScheme.secondary.withValues(alpha: 0.8)],
                    ),
                  ),
                ]),

                const SizedBox(height: 24),

                // ─── Ad Configuration ────────────────────────
                _SettingsSection(title: 'Ad Configuration', theme: widget.theme, children: [
                  _AdToggle(label: 'Interstitial Ads', value: _interstitialEnabled, onChanged: (v) => setState(() => _interstitialEnabled = v), theme: widget.theme),
                  _AdToggle(label: 'Banner Ads', value: _bannerAdsEnabled, onChanged: (v) => setState(() => _bannerAdsEnabled = v), theme: widget.theme),
                  _AdToggle(label: 'Rewarded Ads', value: _rewardedAdEnabled, onChanged: (v) => setState(() => _rewardedAdEnabled = v), theme: widget.theme),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _SettingsField(label: 'Interstitial Interval', controller: _interstitialIntervalCtrl, theme: widget.theme)),
                      const SizedBox(width: 8),
                      Expanded(child: _SettingsField(label: 'Max Banners/Page', controller: _maxBannerPerPageCtrl, theme: widget.theme)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _SettingsField(label: 'Ad Reward Amount (pts)', controller: _adRewardAmountCtrl, theme: widget.theme)),
                      const SizedBox(width: 8),
                      Expanded(child: _SettingsField(label: 'Min Reward for Ad (pts)', controller: _minRewardForAdCtrl, theme: widget.theme)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _AdToggle(label: 'Show Ads on Home', value: _showAdsOnHome, onChanged: (v) => setState(() => _showAdsOnHome = v), theme: widget.theme),
                  _AdToggle(label: 'Show Ads on Offers', value: _showAdsOnOffers, onChanged: (v) => setState(() => _showAdsOnOffers = v), theme: widget.theme),
                  const SizedBox(height: 12),
                  GradientButton(
                    onPressed: widget.admin.isLoading ? null : _saveAdConfig,
                    label: 'Save Ad Configuration',
                    icon: Icons.ads_click_outlined,
                    gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF6366F1)]),
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final ThemeData theme;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.theme, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 16,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }
}

class _SettingsField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final ThemeData theme;

  const _SettingsField({required this.label, required this.controller, required this.theme});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      ),
    );
  }
}



/// Risk level indicators for withdrawal amounts.
enum _RiskLevel { medium, high }

// ============================================================
// REFERRALS TAB — Track Referrals & First-Project Completion
// ============================================================
class _ReferralsTab extends StatefulWidget {
  final AdminProvider admin;
  final ThemeData theme;

  const _ReferralsTab({required this.admin, required this.theme});

  @override
  State<_ReferralsTab> createState() => _ReferralsTabState();
}

class _ReferralsTabState extends State<_ReferralsTab> {
  @override
  Widget build(BuildContext context) {
    final admin = widget.admin;
    final theme = widget.theme;

    // Compute stats
    final totalReferrals = admin.referrals.length;
    final completedFirstProject = admin.referrals.where((r) => r.approvedProjectCount > 0).length;
    final pendingCredit = admin.referrals.where((r) => r.approvedProjectCount > 0 && !r.firstProjectRewarded).length;
    final totalPaid = admin.referrals.where((r) => r.firstProjectRewarded).length;

    // Group referrals by referrer for display
    final referrerMap = <String, List<ReferralEntity>>{};
    for (final r in admin.referrals) {
      referrerMap.putIfAbsent(r.referrerUserId, () => []).add(r);
    }

    return Column(
      children: [
        // Stats bar
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _UserStatBadge(
                  label: 'Total Ref',
                  value: '$totalReferrals',
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                _UserStatBadge(
                  label: 'Completed',
                  value: '$completedFirstProject',
                  color: const Color(0xFF22C55E),
                ),
                const SizedBox(width: 8),
                _UserStatBadge(
                  label: 'Pending Credit',
                  value: '$pendingCredit',
                  color: const Color(0xFFF59E0B),
                ),
                const SizedBox(width: 8),
                _UserStatBadge(
                  label: 'Total Paid',
                  value: '$totalPaid',
                  color: const Color(0xFF8B5CF6),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Toolbar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${referrerMap.length} referrers · $totalReferrals referrals',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              // Bulk Credit button — only shown when there are pending credits
              if (pendingCredit > 0) ...[
                const SizedBox(width: 6),
                InkWell(
                  onTap: () => _showBulkCreditDialog(
                    context,
                    admin: admin,
                    theme: theme,
                    pendingCount: pendingCredit,
                    referrals: admin.referrals,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.card_giftcard_rounded, size: 18,
                        color: const Color(0xFF22C55E)),
                  ),
                ),
              ],
              const SizedBox(width: 6),
              InkWell(
                onTap: () {
                  admin.loadReferrals();
                  admin.loadUsers();
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.refresh_rounded, size: 18,
                      color: theme.colorScheme.primary),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Referral list
        Expanded(
          child: admin.isLoading && admin.referrals.isEmpty
              ? const Center(child: PremiumLoader())
              : referrerMap.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.share_outlined, size: 48,
                              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
                          const SizedBox(height: 12),
                          Text('No referrals found',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        await admin.loadReferrals();
                        await admin.loadUsers();
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: referrerMap.length,
                        itemBuilder: (context, index) {
                          final referrerId = referrerMap.keys.elementAt(index);
                          final referredList = referrerMap[referrerId]!;
                          return _ReferrerCard(
                            referrerId: referrerId,
                            referrals: referredList,
                            users: admin.users,
                            theme: theme,
                            admin: admin,
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}


class _ReferrerCard extends StatelessWidget {
  final String referrerId;
  final List<ReferralEntity> referrals;
  final List<UserEntity> users;
  final ThemeData theme;
  final AdminProvider admin;

  const _ReferrerCard({
    required this.referrerId,
    required this.referrals,
    required this.users,
    required this.theme,
    required this.admin,
  });

  UserEntity? _findUser(String userId) {
    try {
      return users.firstWhere((u) => u.uid == userId);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final referrer = _findUser(referrerId);
    final totalCommission = referrals.fold<double>(0, (sum, r) => sum + r.lifetimeProjectCommission);
    final projectsCompleted = referrals.where((r) => r.approvedProjectCount > 0).length;

    return PremiumGlass(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Referrer header
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  (referrer?.fullName ?? referrerId[0]).isNotEmpty
                      ? (referrer?.fullName ?? referrerId)[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      referrer?.fullName ?? 'Unknown User',
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    if (referrer?.email != null)
                      Text(
                        referrer!.email,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${totalCommission.toStringAsFixed(2)} pts',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF22C55E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Stats row
          Row(
            children: [
              _MiniBadge(
                label: 'Referred',
                value: '${referrals.length}',
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
              _MiniBadge(
                label: 'Completed',
                value: '$projectsCompleted',
                color: const Color(0xFF22C55E),
              ),
              const SizedBox(width: 6),
              _MiniBadge(
                label: 'Earned',
                value: '${totalCommission.toStringAsFixed(0)} pts',
                color: const Color(0xFF8B5CF6),
              ),
            ],
          ),

          const Divider(height: 16),

          // Referred users list
          ...referrals.map((r) => _ReferredUserTile(
            referral: r,
            referredUser: _findUser(r.referredUserId),
            theme: theme,
            admin: admin,
          )),
        ],
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniBadge({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(width: 2),
          Text(label,
              style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _ReferredUserTile extends StatelessWidget {
  final ReferralEntity referral;
  final UserEntity? referredUser;
  final ThemeData theme;
  final AdminProvider admin;

  const _ReferredUserTile({
    required this.referral,
    required this.referredUser,
    required this.theme,
    required this.admin,
  });

  @override
  Widget build(BuildContext context) {
    final hasCompletedProject = referral.approvedProjectCount > 0;
    final isRewarded = referral.firstProjectRewarded;
    final canCredit = hasCompletedProject && !isRewarded;
    final isCrediting = ValueNotifier<bool>(false);

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Referred user avatar
          CircleAvatar(
            radius: 12,
            backgroundColor: theme.colorScheme.secondaryContainer,
            child: Text(
              (referredUser?.fullName ?? '?')[0].toUpperCase(),
              style: TextStyle(
                color: theme.colorScheme.secondary,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  referredUser?.fullName ?? 'Unknown',
                  style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
                ),
                Row(
                  children: [
                    // First project status chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: hasCompletedProject
                            ? const Color(0xFF22C55E).withValues(alpha: 0.1)
                            : const Color(0xFFF59E0B).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            hasCompletedProject ? Icons.check_circle_rounded : Icons.access_time_rounded,
                            size: 8,
                            color: hasCompletedProject ? const Color(0xFF22C55E) : const Color(0xFFF59E0B),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            'Project: ${hasCompletedProject ? "Done" : "Pending"}',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                              color: hasCompletedProject ? const Color(0xFF22C55E) : const Color(0xFFF59E0B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Reward status chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: isRewarded
                            ? const Color(0xFF8B5CF6).withValues(alpha: 0.1)
                            : const Color(0xFF6B7280).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isRewarded ? Icons.card_giftcard_rounded : Icons.info_outline_rounded,
                            size: 8,
                            color: isRewarded ? const Color(0xFF8B5CF6) : const Color(0xFF6B7280),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            isRewarded ? 'Bonus: 7 pts' : 'Not credited',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                              color: isRewarded ? const Color(0xFF8B5CF6) : const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Credit button — opens a dialog to customize amount & notes
          if (canCredit)
            ValueListenableBuilder<bool>(
              valueListenable: isCrediting,
              builder: (context, crediting, _) {
                return SizedBox(
                  height: 28,
                  child: FilledButton.icon(
                    onPressed: crediting
                        ? null
                        : () => _showCreditDialog(
                              context,
                              admin: admin,
                              referral: referral,
                              referredUserName: referredUser?.fullName ?? 'Referred User',
                              isCrediting: isCrediting,
                            ),
                    icon: crediting
                        ? const SizedBox(
                            width: 12, height: 12,
                            child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white),
                          )
                        : const Icon(Icons.payments_rounded, size: 14),
                    label: Text(
                      crediting ? '...' : 'Credit',
                      style: const TextStyle(fontSize: 10),
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      backgroundColor: const Color(0xFF22C55E),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

/// Shows a dialog to customize the referral credit amount and notes
/// before committing the credit to the referrer's wallet.
Future<void> _showCreditDialog(
  BuildContext context, {
  required AdminProvider admin,
  required ReferralEntity referral,
  required String referredUserName,
  required ValueNotifier<bool> isCrediting,
}) async {
  final theme = Theme.of(context);
  final amountController = TextEditingController(text: '7');
  final notesController = TextEditingController(
    text: 'First-project referral bonus for $referredUserName',
  );
  final formKey = GlobalKey<FormState>();

  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.card_giftcard_rounded, color: const Color(0xFF8B5CF6), size: 22),
            const SizedBox(width: 8),
            Text(
              'Credit Referral Bonus',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Referred user info
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: theme.colorScheme.secondaryContainer,
                        child: Text(
                          referredUserName[0].toUpperCase(),
                          style: TextStyle(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              referredUserName,
                              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              'Referred user completed their first project',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Amount field
                TextFormField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Credit Amount (pts)',
                    prefixText: 'pts ',
                    prefixStyle: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    hintText: 'Enter amount',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Enter an amount';
                    final amount = double.tryParse(value);
                    if (amount == null || amount <= 0) return 'Enter a valid amount';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Notes field
                TextFormField(
                  controller: notesController,
                  maxLines: 2,
                  maxLength: 200,
                  decoration: InputDecoration(
                    labelText: 'Notes / Description',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    hintText: 'Reason for crediting...',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, true);
              }
            },
            icon: const Icon(Icons.check_circle_rounded, size: 18),
            label: const Text('Credit Now'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF22C55E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      );
    },
  );

  if (confirmed != true) return;

  final amount = double.tryParse(amountController.text) ?? 7.0;
  final notes = notesController.text.trim();

  isCrediting.value = true;
  final success = await admin.creditReferralBonus(
    referralId: referral.referralId,
    referrerUserId: referral.referrerUserId,
    referredUserName: referredUserName,
    amount: amount,
    notes: notes,
  );
  if (context.mounted) {
    isCrediting.value = false;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? '${amount.toStringAsFixed(2)} pts credited to referrer!'
              : admin.errorMessage ?? 'Failed to credit',
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

/// Shows a dialog to configure and execute bulk credit for all eligible
/// referral bonuses at once with a progress tracker.
Future<void> _showBulkCreditDialog(
  BuildContext context, {
  required AdminProvider admin,
  required ThemeData theme,
  required int pendingCount,
  required List<ReferralEntity> referrals,
}) async {
  final amountController = TextEditingController(text: '7');
  final notesController = TextEditingController(
    text: 'Bulk first-project referral bonus',
  );
  final formKey = GlobalKey<FormState>();

  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.card_giftcard_rounded, color: const Color(0xFF22C55E), size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Bulk Credit ($pendingCount)',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info banner
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, size: 18, color: const Color(0xFF22C55E)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Will credit $pendingCount referrers whose referred users completed their first project.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Amount field
                TextFormField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Credit Amount (pts) per Referral',
                    prefixText: 'pts ',
                    prefixStyle: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    hintText: 'Enter amount',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Enter an amount';
                    final amount = double.tryParse(value);
                    if (amount == null || amount <= 0) return 'Enter a valid amount';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Notes field
                TextFormField(
                  controller: notesController,
                  maxLines: 2,
                  maxLength: 200,
                  decoration: InputDecoration(
                    labelText: 'Notes / Description (applied to all)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    hintText: 'Reason for bulk crediting...',
                  ),
                ),

                const SizedBox(height: 4),
                Text(
                  'Total: ${(double.tryParse(amountController.text) ?? 7) * pendingCount} pts',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, true);
              }
            },
            icon: const Icon(Icons.rocket_launch_rounded, size: 18),
            label: Text('Credit All ($pendingCount)'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF22C55E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      );
    },
  );

  if (confirmed != true) return;

  final amount = double.tryParse(amountController.text) ?? 7.0;
  final notes = notesController.text.trim();

  // Build list of eligible pending referrals
  final pending = referrals
      .where((r) => r.approvedProjectCount > 0 && !r.firstProjectRewarded)
      .map((r) => <String, String>{
            'referralId': r.referralId,
            'referrerUserId': r.referrerUserId,
          })
      .toList();

  if (pending.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No pending referrals to credit'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
    return;
  }

  // Show progress dialog
  if (!context.mounted) return;
  final progressNotifier = ValueNotifier<int>(0);
  final totalPending = pending.length;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _BulkProgressDialog(
      total: totalPending,
      progressNotifier: progressNotifier,
      theme: theme,
    ),
  );

  // Execute bulk credit
  final result = await admin.bulkCreditReferralBonuses(
    pendingReferrals: pending,
    amount: amount,
    notes: notes,
    onProgress: (credited, total) {
      progressNotifier.value = credited;
    },
  );

  // Close progress dialog
  if (context.mounted) {
    Navigator.of(context).pop(); // closes the progress dialog

    final successCount = result['successCount'] ?? 0;
    final failCount = result['failCount'] ?? 0;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          failCount > 0
              ? 'Credited $successCount/$totalPending ($failCount failed)'
              : 'All $successCount/$totalPending credits successful!',
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );

    // Reload data to refresh UI
    admin.loadReferrals();
    admin.loadUsers();
  }
}

/// Full-screen progress dialog shown during bulk credit operations.
class _BulkProgressDialog extends StatefulWidget {
  final int total;
  final ValueNotifier<int> progressNotifier;
  final ThemeData theme;

  const _BulkProgressDialog({
    required this.total,
    required this.progressNotifier,
    required this.theme,
  });

  @override
  State<_BulkProgressDialog> createState() => _BulkProgressDialogState();
}

class _BulkProgressDialogState extends State<_BulkProgressDialog> {
  @override
  void initState() {
    super.initState();
    widget.progressNotifier.addListener(_onProgress);
  }

  @override
  void dispose() {
    widget.progressNotifier.removeListener(_onProgress);
    super.dispose();
  }

  void _onProgress() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.progressNotifier.value;
    final total = widget.total;
    final percent = total > 0 ? (progress / total) : 0.0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.rocket_launch_rounded, size: 40, color: Color(0xFF22C55E)),
            const SizedBox(height: 16),
            Text(
              'Crediting Referrals...',
              style: widget.theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '$progress of $total processed',
              style: widget.theme.textTheme.bodyMedium?.copyWith(
                color: widget.theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: percent,
                minHeight: 8,
                backgroundColor: widget.theme.colorScheme.surfaceContainerHighest,
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF22C55E)),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${(percent * 100).toStringAsFixed(0)}%',
              style: widget.theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFF22C55E),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
