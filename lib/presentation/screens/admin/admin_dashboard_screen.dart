import 'package:cashspark/core/utils/helpers.dart';
import 'package:cashspark/core/widgets/premium_widgets.dart';
import 'package:cashspark/domain/entities/user_entity.dart';
import 'package:cashspark/domain/entities/withdrawal_entity.dart';
import 'package:cashspark/presentation/providers/admin_provider.dart';
import 'package:cashspark/presentation/providers/withdrawal_provider.dart';
import 'package:cashspark/presentation/screens/admin/admin_affiliate_projects_tab.dart';
import 'package:cashspark/presentation/screens/admin/admin_coupons_tab.dart';
import 'package:cashspark/presentation/screens/admin/admin_referral_levels_tab.dart';
import 'package:cashspark/presentation/screens/admin/admin_streak_multiplier_tab.dart';
import 'package:cashspark/presentation/screens/admin/admin_tabs.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    _tabController = TabController(length: 13, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  void _initialize() {
    final admin = context.read<AdminProvider>();
    admin.loadDashboard();
    admin.loadUsers();
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

    return Scaffold(
      appBar: PremiumAppBar(
        title: 'Admin Panel',
        onBack: () => Navigator.pop(context),
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
                Tab(text: 'Withdrawals', icon: Icon(Icons.receipt_outlined, size: 18)),
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
              ],
            );
          },
        ),
      ),
    );
  }
}

// ============================================================
// DASHBOARD TAB
// ============================================================
class _DashboardTab extends StatelessWidget {
  final AdminProvider admin;
  final ThemeData theme;

  const _DashboardTab({required this.admin, required this.theme});

  @override
  Widget build(BuildContext context) {
    if (admin.isLoading) {
      return const Center(child: PremiumLoader());
    }

    return RefreshIndicator(
      onRefresh: () => admin.loadDashboard(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          PremiumGlass(
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
                        Text('Admin Dashboard',
                            style: theme.textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        Text(admin.adminProfile?.fullName ?? 'Admin',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Stats Grid
          Row(
            children: [
              Expanded(child: _StatCard(
                label: 'Total Users',
                value: Helpers.formatNumber(admin.totalUsers),
                icon: Icons.people_outlined,
                color: theme.colorScheme.primary,
                theme: theme, chart: null,
              )),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(
                label: 'Active (30d)',
                value: Helpers.formatNumber(admin.activeUsers),
                icon: Icons.person_pin_outlined,
                color: theme.colorScheme.tertiary,
                theme: theme, chart: null,
              )),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _StatCard(
                label: 'Total Earnings',
                value: Helpers.formatCurrency(admin.totalEarnings),
                icon: Icons.trending_up_outlined,
                color: Colors.green,
                theme: theme, chart: null,
              )),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(
                label: 'Total Withdrawn',
                value: Helpers.formatCurrency(admin.totalWithdrawn),
                icon: Icons.logout_outlined,
                color: theme.colorScheme.error,
                theme: theme, chart: null,
              )),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _StatCard(
                label: 'Pending W/D',
                value: Helpers.formatNumber(admin.pendingWithdrawals),
                icon: Icons.hourglass_empty_outlined,
                color: Colors.orange,
                theme: theme, chart: null,
              )),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(
                label: 'Referrals',
                value: Helpers.formatNumber(admin.totalReferrals),
                icon: Icons.share_outlined,
                color: theme.colorScheme.secondary,
                theme: theme, chart: null,
              )),
            ],
          ),

          const SizedBox(height: 24),

          // Revenue Card
          PremiumCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.account_balance_outlined, size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text('Revenue Overview',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 16),
                _RevenueRow(
                  label: 'Total Earnings',
                  value: Helpers.formatCurrency(admin.revenueStats['totalEarnings'] ?? 0),
                  color: Colors.green,
                  theme: theme,
                ),
                const SizedBox(height: 8),
                _RevenueRow(
                  label: 'Total Withdrawn',
                  value: Helpers.formatCurrency(admin.revenueStats['totalWithdrawn'] ?? 0),
                  color: theme.colorScheme.error,
                  theme: theme,
                ),
                const Divider(height: 24),
                _RevenueRow(
                  label: 'Platform Balance',
                  value: Helpers.formatCurrency(admin.revenueStats['remainingBalance'] ?? 0),
                  color: theme.colorScheme.primary,
                  theme: theme,
                  bold: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Daily Growth Card
          PremiumCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.trending_up_rounded, size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text('Daily User Growth (7 days)',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 16),
                if (admin.dailyUserGrowth.isEmpty)
                  Text('No data available',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant))
                else
                  SizedBox(
                    height: 120,
                    child: CustomPaint(
                      size: const Size(double.infinity, 120),
                      painter: _BarChartPainter(
                        data: admin.dailyUserGrowth,
                        barColor: theme.colorScheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final ThemeData theme;
  final Widget? chart;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.theme,
    required this.chart,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumGlass(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Icon(Icons.trending_up, size: 16, color: color.withValues(alpha: 0.5)),
            ],
          ),
          const SizedBox(height: 12),
          Text(value,
              style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _RevenueRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final ThemeData theme;
  final bool bold;

  const _RevenueRow({
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
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label, style: theme.textTheme.bodyMedium
            ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const Spacer(),
        Text(value, style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: bold ? FontWeight.bold : FontWeight.w600, color: color)),
      ],
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<int> data;
  final Color barColor;

  _BarChartPainter({required this.data, required this.barColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxVal = data.reduce((a, b) => a > b ? a : b).toDouble();
    if (maxVal == 0) return;

    final barWidth = size.width / (data.length * 2);
    final paint = Paint()..color = barColor;

    for (int i = 0; i < data.length; i++) {
      final barHeight = (data[i] / maxVal) * (size.height - 10);
      final x = i * barWidth * 2 + barWidth / 2;
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(x, size.height - barHeight, barWidth, barHeight),
          topLeft: const Radius.circular(4),
          topRight: const Radius.circular(4),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ============================================================
// USERS TAB
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
        Padding(
          padding: const EdgeInsets.all(12),
          child: PremiumGlass(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users by name, email, or ID',
                prefixIcon: Icon(Icons.search, color: widget.theme.colorScheme.onSurfaceVariant),
                border: InputBorder.none,
                filled: false,
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
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
        ),

        Expanded(
          child: widget.admin.isLoading
              ? const Center(child: PremiumLoader())
              : displayUsers.isEmpty
                  ? Center(
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
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: displayUsers.length,
                      itemBuilder: (context, index) {
                        final user = displayUsers[index];
                        return _UserCard(user: user, theme: widget.theme);
                      },
                    ),
        ),
      ],
    );
  }
}

class _UserCard extends StatelessWidget {
  final UserEntity user;
  final ThemeData theme;

  const _UserCard({required this.user, required this.theme});

  @override
  Widget build(BuildContext context) {
    return PremiumGlass(
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Text(user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
              style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
        ),
        title: Text(user.fullName,
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
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
          _UserDetail(label: 'UID', value: user.uid, theme: theme),
          const SizedBox(height: 4),
          _UserDetail(label: 'Phone', value: user.phone ?? 'N/A', theme: theme),
          const SizedBox(height: 4),
          _UserDetail(label: 'Referral Code', value: user.referralCode, theme: theme),
          const SizedBox(height: 4),
          _UserDetail(label: 'Wallet', value: Helpers.formatCurrency(user.walletBalance), theme: theme),
          const SizedBox(height: 4),
          _UserDetail(label: 'Earnings', value: Helpers.formatCurrency(user.totalEarnings), theme: theme),
          const SizedBox(height: 4),
          _UserDetail(label: 'Joined', value: Helpers.formatDateTime(user.createdAt), theme: theme),
          const SizedBox(height: 4),
          _UserDetail(label: 'Verified', value: user.isEmailVerified ? 'Yes ✓' : 'No', theme: theme,
              valueColor: user.isEmailVerified ? Colors.green : null),
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

  const _UserDetail({required this.label, required this.value, required this.theme, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.withdrawal.initializeAdmin(status: _filterStatus);
    });
  }

  @override
  Widget build(BuildContext context) {
    final withdrawals = widget.withdrawal.allWithdrawals;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
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
                  label: 'Paid',
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

    return PremiumGlass(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: isPending || isFailed ? () => _showAdminActionDialog(context) : null,
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: statusColor.withValues(alpha: 0.1),
              ),
              child: Icon(_methodIcon(withdrawal.method), color: statusColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '₹${withdrawal.amount.toStringAsFixed(2)}',
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(withdrawal.method.name.toUpperCase(),
                            style: TextStyle(fontSize: 9, color: theme.colorScheme.onSurfaceVariant)),
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
                  Text(
                    Helpers.formatDateTime(withdrawal.requestedAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
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
      case WithdrawalStatus.paid: return 'PAID';
      case WithdrawalStatus.approved: return 'APPROVED';
      case WithdrawalStatus.rejected: return 'REJECTED';
    }
  }

  IconData _methodIcon(WithdrawalMethod method) {
    switch (method) {
      case WithdrawalMethod.upi: return Icons.phone_android_outlined;
      case WithdrawalMethod.paytm: return Icons.account_balance_wallet_outlined;
      case WithdrawalMethod.bankTransfer: return Icons.account_balance_outlined;
    }
  }

  void _copyToClipboard(String text, BuildContext dialogContext) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(dialogContext).showSnackBar(
      SnackBar(
        content: const Text('UPI ID copied!'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showAdminActionDialog(BuildContext context) {
    final remarksController = TextEditingController();
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
                    Icon(Icons.payments_outlined, color: theme.colorScheme.primary, size: 22),
                    const SizedBox(width: 8),
                    Text('Process Withdrawal',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),

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
                      ],
                    ),
                  ),

                const SizedBox(height: 12),
                _DialogDetailRow('Amount', '₹${withdrawal.amount.toStringAsFixed(2)}', theme, bold: true),
                const SizedBox(height: 4),
                _DialogDetailRow('Method', withdrawal.method.name.toUpperCase(), theme),
                const SizedBox(height: 4),
                _DialogDetailRow('Account', withdrawal.accountDetails, theme),
                const SizedBox(height: 12),

                if (withdrawal.method == WithdrawalMethod.upi)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.payments_outlined, size: 18, color: theme.colorScheme.primary),
                            const SizedBox(width: 8),
                            Text('UPI Payment',
                                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _copyToClipboard(withdrawal.accountDetails, ctx),
                            icon: const Icon(Icons.copy_outlined, size: 16),
                            label: Text(
                              'Copy UPI ID: ${withdrawal.accountDetails}',
                              style: const TextStyle(fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: theme.colorScheme.primary,
                              side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.5)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Send ₹${withdrawal.amount.toStringAsFixed(2)} to this UPI ID, then click "Mark as Paid".',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 12),
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
                                content: Text(withdrawalProvider.errorMessage ?? 'Failed to reject withdrawal'),
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
                            final success = await withdrawalProvider.markAsPaid(
                              withdrawal.withdrawalId,
                              remarks: remarksController.text.isNotEmpty ? remarksController.text : null,
                            );
                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                              if (!success) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(
                                    content: Text(withdrawalProvider.errorMessage ?? 'Failed to process withdrawal'),
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
                    prefixText: '₹ ',
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
                  _SettingsField(label: 'Referrer Bonus (₹)', controller: _bonusReferrerController, theme: widget.theme),
                  const SizedBox(height: 8),
                  _SettingsField(label: 'Referred Bonus (₹)', controller: _bonusReferredController, theme: widget.theme),
                ]),
                const SizedBox(height: 16),

                _SettingsSection(title: 'Reward Amounts', theme: widget.theme, children: [
                  _SettingsField(label: 'Ad Reward (₹)', controller: _adRewardController, theme: widget.theme),
                  const SizedBox(height: 8),
                  _SettingsField(label: 'Daily Check-In (₹)', controller: _dailyCheckInController, theme: widget.theme),
                ]),
                const SizedBox(height: 16),

                _SettingsSection(title: 'Withdrawal Limits', theme: widget.theme, children: [
                  _SettingsField(label: 'Min Withdrawal (₹)', controller: _minWithdrawalController, theme: widget.theme),
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
                      Expanded(child: _SettingsField(label: 'Ad Reward Amount (₹)', controller: _adRewardAmountCtrl, theme: widget.theme)),
                      const SizedBox(width: 8),
                      Expanded(child: _SettingsField(label: 'Min Reward for Ad (₹)', controller: _minRewardForAdCtrl, theme: widget.theme)),
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


