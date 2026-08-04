import 'package:cashspark/core/theme/app_theme.dart';
import 'package:cashspark/core/utils/helpers.dart';
import 'package:cashspark/core/widgets/premium_widgets.dart';
import 'package:cashspark/domain/entities/banner_entity.dart';
import 'package:cashspark/presentation/providers/admin_provider.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';


// ============================================================
// ANALYTICS TAB — fl_chart user growth + revenue trends
// ============================================================
class AdminAnalyticsTab extends StatefulWidget {
  final AdminProvider admin;
  final ThemeData theme;

  const AdminAnalyticsTab({super.key, required this.admin, required this.theme});

  @override
  State<AdminAnalyticsTab> createState() => _AdminAnalyticsTabState();
}

class _AdminAnalyticsTabState extends State<AdminAnalyticsTab> {
  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final isDark = theme.brightness == Brightness.dark;

    if (widget.admin.isLoading) return const Center(child: PremiumLoader());

    return RefreshIndicator(
      onRefresh: () => widget.admin.loadDashboard(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Revenue Overview chart
          PremiumGlass(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.account_balance_outlined, size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text('Revenue Overview',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _legendDot(Colors.green, 'Earnings', theme),
                    const SizedBox(width: 16),
                    _legendDot(theme.colorScheme.error, 'Withdrawn', theme),
                    const SizedBox(width: 16),
                    _legendDot(theme.colorScheme.primary, 'Balance', theme),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 180,
                  child: Center(
                    child: Text('Revenue: ${Helpers.formatCurrency(widget.admin.totalEarnings)}',
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // User Growth chart
          PremiumGlass(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.trending_up_rounded, size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text('User Growth',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Text('${widget.admin.totalUsers} total',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
                const SizedBox(height: 16),
                if (widget.admin.dailyUserGrowth.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text('No data available',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    ),
                  )
                else
                  SizedBox(
                    height: 180,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: widget.admin.dailyUserGrowth.reduce((a, b) => a > b ? a : b).toDouble() * 1.3,
                        barTouchData: BarTouchData(enabled: true),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final idx = value.toInt();
                                if (idx < 0 || idx >= widget.admin.dailyUserGrowth.length) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text('D${idx + 1}',
                                      style: TextStyle(fontSize: 9, color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8))),
                                );
                              },
                              reservedSize: 20,
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: true, reservedSize: 32, getTitlesWidget: (value, meta) {
                              return Text('${value.toInt()}',
                                  style: TextStyle(fontSize: 9, color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8)));
                            }),
                          ),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 1,
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: (isDark ? AppTheme.borderColor : const Color(0xFFE2E8F0)).withValues(alpha: 0.3),
                            strokeWidth: 1,
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: widget.admin.dailyUserGrowth.asMap().entries.map((entry) {
                          return BarChartGroupData(
                            x: entry.key,
                            barRods: [
                              BarChartRodData(
                                toY: entry.value.toDouble(),
                                color: theme.colorScheme.primary,
                                width: 14,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Key metrics
          PremiumGlass(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.analytics_outlined, size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text('Key Metrics',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 16),
                _metricRow(theme, 'Avg Earnings/User', widget.admin.totalUsers > 0
                    ? Helpers.formatCurrency(widget.admin.totalEarnings / widget.admin.totalUsers)
                    : '₹0.00'),
                const SizedBox(height: 8),
                _metricRow(theme, 'Conversion Rate',
                    '${widget.admin.totalUsers > 0 ? ((widget.admin.activeUsers / widget.admin.totalUsers) * 100).toStringAsFixed(1) : 0}%'),
                const SizedBox(height: 8),
                _metricRow(theme, 'Pending Withdrawals', '${widget.admin.pendingWithdrawals}'),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label, ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }

  Widget _metricRow(ThemeData theme, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        Text(value, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// ============================================================
// BANNERS TAB
// ============================================================
class AdminBannersTab extends StatefulWidget {
  final AdminProvider admin;
  final ThemeData theme;

  const AdminBannersTab({super.key, required this.admin, required this.theme});

  @override
  State<AdminBannersTab> createState() => _AdminBannersTabState();
}

class _AdminBannersTabState extends State<AdminBannersTab> {
  final _titleCtrl = TextEditingController();
  final _subtitleCtrl = TextEditingController();
  final _imageUrlCtrl = TextEditingController();
  final _linkUrlCtrl = TextEditingController();
  final _actionLabelCtrl = TextEditingController();
  final _sortOrderCtrl = TextEditingController(text: '0');
  bool _showForm = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.admin.loadBanners());
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _subtitleCtrl.dispose();
    _imageUrlCtrl.dispose();
    _linkUrlCtrl.dispose();
    _actionLabelCtrl.dispose();
    _sortOrderCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Banner Management',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              ),
              FilledButton.icon(
                onPressed: () => setState(() => _showForm = !_showForm),
                icon: Icon(_showForm ? Icons.close : Icons.add, size: 18),
                label: Text(_showForm ? 'Cancel' : 'New Banner'),
                style: FilledButton.styleFrom(
                  backgroundColor: _showForm ? null : AppTheme.accentGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_showForm)
            PremiumGlass(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Title *', isDense: true, border: OutlineInputBorder())),
                  const SizedBox(height: 8),
                  TextField(controller: _subtitleCtrl, decoration: const InputDecoration(labelText: 'Subtitle *', isDense: true, border: OutlineInputBorder())),
                  const SizedBox(height: 8),
                  TextField(controller: _imageUrlCtrl, decoration: const InputDecoration(labelText: 'Image URL *', isDense: true, border: OutlineInputBorder(), hintText: 'https://...')),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: TextField(controller: _linkUrlCtrl, decoration: const InputDecoration(labelText: 'Link URL', isDense: true, border: OutlineInputBorder()))),
                    const SizedBox(width: 8),
                    SizedBox(width: 80, child: TextField(controller: _sortOrderCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Order', isDense: true, border: OutlineInputBorder()))),
                  ]),
                  const SizedBox(height: 8),
                  TextField(controller: _actionLabelCtrl, decoration: const InputDecoration(labelText: 'Action Label', isDense: true, border: OutlineInputBorder(), hintText: 'Learn More')),
                  const SizedBox(height: 12),
                  GradientButton(
                    onPressed: _createBanner,
                    label: 'Create Banner',
                    icon: Icons.add_photo_alternate_outlined,
                    gradient: const LinearGradient(colors: [AppTheme.accentGreen, Color(0xFF43A047)]),
                  ),
                ],
              ),
            ),

          if (_showForm) const SizedBox(height: 16),

          // Banners list
          if (widget.admin.banners.isEmpty && !widget.admin.isLoading)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(children: [
                  Icon(Icons.view_carousel_outlined, size: 48, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
                  const SizedBox(height: 8),
                  Text('No banners yet', style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ]),
              ),
            )
          else
            ...widget.admin.banners.map((banner) => _BannerCard(
              banner: banner,
              theme: theme,
              isDark: isDark,
              admin: widget.admin,
            )),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _createBanner() async {
    if (_titleCtrl.text.trim().isEmpty || _imageUrlCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Title and Image URL are required'), behavior: SnackBarBehavior.floating));
      return;
    }
    final success = await widget.admin.createBanner(
      title: _titleCtrl.text.trim(),
      subtitle: _subtitleCtrl.text.trim(),
      imageUrl: _imageUrlCtrl.text.trim(),
      linkUrl: _linkUrlCtrl.text.trim().isNotEmpty ? _linkUrlCtrl.text.trim() : null,
      actionLabel: _actionLabelCtrl.text.trim().isNotEmpty ? _actionLabelCtrl.text.trim() : null,
      sortOrder: int.tryParse(_sortOrderCtrl.text) ?? 0,
    );
    if (success && mounted) {
      _titleCtrl.clear(); _subtitleCtrl.clear(); _imageUrlCtrl.clear();
      _linkUrlCtrl.clear(); _actionLabelCtrl.clear(); _sortOrderCtrl.text = '0';
      setState(() => _showForm = false);
    }
  }
}

class _BannerCard extends StatelessWidget {
  final BannerEntity banner;
  final ThemeData theme;
  final bool isDark;
  final AdminProvider admin;

  const _BannerCard({required this.banner, required this.theme, required this.isDark, required this.admin});

  @override
  Widget build(BuildContext context) {
    return PremiumGlass(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: AppTheme.accentPurple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.image_outlined, color: AppTheme.accentPurple, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(banner.title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                Text(banner.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: isDark ? AppTheme.textMuted : const Color(0xFF64748B))),
              ],
            ),
          ),
          Switch(
            value: banner.isActive,
            onChanged: (v) => admin.toggleBanner(banner.bannerId, v),
            activeColor: AppTheme.accentGreen,
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, size: 20, color: theme.colorScheme.error),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Banner?'),
        content: Text('Delete "${banner.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () { admin.deleteBanner(banner.bannerId); Navigator.pop(ctx); }, child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}

// ============================================================
// VERIFICATION TAB
// ============================================================
class AdminVerificationTab extends StatefulWidget {
  final AdminProvider admin;
  final ThemeData theme;

  const AdminVerificationTab({super.key, required this.admin, required this.theme});

  @override
  State<AdminVerificationTab> createState() => _AdminVerificationTabState();
}

class _AdminVerificationTabState extends State<AdminVerificationTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.admin.loadVerificationRequests());
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    if (widget.admin.isLoading && widget.admin.verificationRequests.isEmpty) {
      return const Center(child: PremiumLoader());
    }

    if (widget.admin.verificationRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified_outlined, size: 48, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text('No verification requests', style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 4),
            Text('User verification requests will appear here', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => widget.admin.loadVerificationRequests(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: widget.admin.verificationRequests.length,
        itemBuilder: (context, index) {
          final req = widget.admin.verificationRequests[index];
          return _VerificationCard(
            request: req,
            theme: theme,
            admin: widget.admin,
          );
        },
      ),
    );
  }
}

class _VerificationCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final ThemeData theme;
  final AdminProvider admin;

  const _VerificationCard({required this.request, required this.theme, required this.admin});

  @override
  Widget build(BuildContext context) {
    final userId = request['userId'] as String? ?? '';
    final userName = request['userName'] as String? ?? 'Unknown';
    final status = request['status'] as String? ?? 'pending';
    final isPending = status == 'pending';

    return PremiumGlass(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                    style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    Text('UID: ${userId.length > 12 ? userId.substring(0, 12) : userId}',
                        style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isPending ? Colors.orange.withValues(alpha: 0.1) : (status == 'approved' ? Colors.green.withValues(alpha: 0.1) : theme.colorScheme.error.withValues(alpha: 0.1)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(status.toUpperCase(),
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold,
                        color: isPending ? Colors.orange : (status == 'approved' ? Colors.green : theme.colorScheme.error))),
              ),
            ],
          ),
          if (request['note'] != null && (request['note'] as String).isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(request['note'] as String,
                style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant, fontStyle: FontStyle.italic)),
          ],
          if (isPending) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => admin.rejectVerification(request['requestId'] as String),
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Reject'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                    side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () => admin.approveVerification(request['requestId'] as String, userId),
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Approve'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.accentGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================
// AUDIT LOG TAB
// ============================================================
class AdminAuditLogTab extends StatefulWidget {
  final AdminProvider admin;
  final ThemeData theme;

  const AdminAuditLogTab({super.key, required this.admin, required this.theme});

  @override
  State<AdminAuditLogTab> createState() => _AdminAuditLogTabState();
}

class _AdminAuditLogTabState extends State<AdminAuditLogTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.admin.loadAdminLogs());
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final isDark = theme.brightness == Brightness.dark;

    if (widget.admin.isLoading && widget.admin.adminLogs.isEmpty) {
      return const Center(child: PremiumLoader());
    }

    if (widget.admin.adminLogs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_outlined, size: 48, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text('No audit logs yet', style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => widget.admin.loadAdminLogs(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: widget.admin.adminLogs.length,
        itemBuilder: (context, index) {
          final log = widget.admin.adminLogs[index];
          return PremiumGlass(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _actionColor(log.action).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(_actionIcon(log.action), size: 16, color: _actionColor(log.action)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(log.action.replaceAll('_', ' ').toUpperCase(),
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _actionColor(log.action))),
                      const SizedBox(height: 2),
                      Text('${log.targetType}${log.targetId != null ? ': ${(log.targetId!.length > 20 ? log.targetId!.substring(0, 20) : log.targetId)}' : ''}',
                          style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : const Color(0xFF475569))),
                      if (log.details != null && log.details!.isNotEmpty)
                        Text(log.details!, maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 11, color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8))),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(Helpers.formatDateTime(log.createdAt),
                    style: TextStyle(fontSize: 10, color: isDark ? AppTheme.textMuted.withValues(alpha: 0.5) : const Color(0xFF94A3B8).withValues(alpha: 0.5))),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _actionColor(String action) {
    if (action.contains('login')) return AppTheme.accentBlue;
    if (action.contains('create') || action.contains('approve')) return AppTheme.accentGreen;
    if (action.contains('delete') || action.contains('reject')) return Colors.red;
    if (action.contains('update') || action.contains('edit')) return AppTheme.accentOrange;
    return Colors.grey;
  }

  IconData _actionIcon(String action) {
    if (action.contains('login')) return Icons.login_outlined;
    if (action.contains('create')) return Icons.add_circle_outline;
    if (action.contains('delete')) return Icons.delete_outline;
    if (action.contains('approve') || action.contains('verify')) return Icons.check_circle_outline;
    if (action.contains('reject')) return Icons.cancel_outlined;
    if (action.contains('update') || action.contains('edit')) return Icons.edit_outlined;
    return Icons.circle_outlined;
  }
}
