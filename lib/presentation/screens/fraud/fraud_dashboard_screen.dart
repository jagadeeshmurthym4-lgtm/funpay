import 'package:cashspark/domain/entities/fraud_report_entity.dart';
import 'package:cashspark/presentation/providers/fraud_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FraudDashboardScreen extends StatefulWidget {
  const FraudDashboardScreen({super.key});

  @override
  State<FraudDashboardScreen> createState() => _FraudDashboardScreenState();
}

class _FraudDashboardScreenState extends State<FraudDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final fraud = context.read<FraudProvider>();
    await Future.wait([
      fraud.loadFlaggedUsers(),
      fraud.loadFraudReports(),
    ]);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fraud = context.watch<FraudProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fraud Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              text: 'Overview (${fraud.totalFlaggedUsers})',
              icon: const Icon(Icons.dashboard_outlined, size: 18),
            ),
            Tab(
              text: 'Flagged Users (${fraud.pendingReviewCount})',
              icon: const Icon(Icons.flag_outlined, size: 18),
            ),
            const Tab(
              text: 'Reports',
              icon: Icon(Icons.assessment_outlined, size: 18),
            ),
          ],
        ),
      ),
      body: fraud.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _OverviewTab(fraud: fraud),
                _FlaggedUsersTab(fraud: fraud),
                _FraudReportsTab(fraud: fraud),
              ],
            ),
    );
  }
}

// --- Overview Tab ---

class _OverviewTab extends StatelessWidget {
  final FraudProvider fraud;

  const _OverviewTab({required this.fraud});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: () async => await context.read<FraudProvider>().loadFlaggedUsers(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary Cards
          Text('Risk Overview', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'High Risk',
                  value: '${fraud.highRiskUsers}',
                  color: Colors.red,
                  icon: Icons.warning_amber_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCard(
                  label: 'Medium Risk',
                  value: '${fraud.mediumRiskUsers}',
                  color: Colors.orange,
                  icon: Icons.info_outline,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCard(
                  label: 'Low Risk',
                  value: '${fraud.lowRiskUsers}',
                  color: Colors.amber,
                  icon: Icons.check_circle_outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Flagged Users',
                  value: '${fraud.totalFlaggedUsers}',
                  color: theme.colorScheme.error,
                  icon: Icons.flag_outlined,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCard(
                  label: 'Confirmed',
                  value: '${fraud.confirmedFraud}',
                  color: theme.colorScheme.tertiary,
                  icon: Icons.gavel_outlined,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCard(
                  label: 'Pending Review',
                  value: '${fraud.pendingReviewCount}',
                  color: theme.colorScheme.secondary,
                  icon: Icons.pending_outlined,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Network Security Card
          Text('Network Security', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        fraud.isVpnActive ? Icons.vpn_lock : Icons.wifi,
                        color: fraud.isVpnActive ? Colors.orange : Colors.green,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('VPN Status',
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant)),
                          const SizedBox(height: 2),
                          Text(fraud.isVpnActive ? 'VPN Detected' : 'No VPN',
                              style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: fraud.isVpnActive
                              ? Colors.orange.withValues(alpha: 0.1)
                              : Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          fraud.isVpnActive ? '⚠️ Active' : '✅ Safe',
                          style: theme.textTheme.labelSmall,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        fraud.isProxyDetected ? Icons.shield_outlined : Icons.shield,
                        color: fraud.isProxyDetected ? Colors.orange : Colors.green,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Proxy Status',
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant)),
                          const SizedBox(height: 2),
                          Text(fraud.isProxyDetected ? 'Proxy Detected' : 'No Proxy',
                              style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Network Risk Score',
                          style: theme.textTheme.bodyMedium),
                      Text(
                        '${(fraud.networkRiskScore * 100).toStringAsFixed(0)}%',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: fraud.networkRiskScore > 0.5
                              ? Colors.red
                              : fraud.networkRiskScore > 0.2
                                  ? Colors.orange
                                  : Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: fraud.networkRiskScore,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      color: fraud.networkRiskScore > 0.5
                          ? Colors.red
                          : fraud.networkRiskScore > 0.2
                              ? Colors.orange
                              : Colors.green,
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Quick Actions
          Text('Quick Actions', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.people_outline),
                  title: const Text('Review Flagged Users'),
                  subtitle: Text('${fraud.pendingReviewCount} pending review'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Switch to Flagged Users tab
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.assessment_outlined),
                  title: const Text('View All Reports'),
                  subtitle: Text('${fraud.totalFraudReports} total'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Switch to Reports tab
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- Flagged Users Tab ---

class _FlaggedUsersTab extends StatelessWidget {
  final FraudProvider fraud;

  const _FlaggedUsersTab({required this.fraud});

  @override
  Widget build(BuildContext context) {
    if (fraud.flaggedReports.isEmpty) {
      final theme = Theme.of(context);
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shield_outlined, size: 64,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text('No flagged users',
                style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            Text('All accounts are currently in good standing',
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async =>
          await context.read<FraudProvider>().loadFlaggedUsers(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: fraud.flaggedReports.length,
        itemBuilder: (context, index) {
          final report = fraud.flaggedReports[index];
          return _FlaggedUserCard(report: report);
        },
      ),
    );
  }
}

class _FlaggedUserCard extends StatelessWidget {
  final FraudReportEntity report;

  const _FlaggedUserCard({required this.report});

  Color _riskColor(RiskLevel level) {
    switch (level) {
      case RiskLevel.high:
        return Colors.red;
      case RiskLevel.medium:
        return Colors.orange;
      case RiskLevel.low:
        return Colors.amber;
    }
  }

  IconData _riskIcon(RiskLevel level) {
    switch (level) {
      case RiskLevel.high:
        return Icons.warning_amber_rounded;
      case RiskLevel.medium:
        return Icons.info_outline;
      case RiskLevel.low:
        return Icons.check_circle_outline;
    }
  }

  String _statusLabel(FraudStatus status) {
    switch (status) {
      case FraudStatus.underReview:
        return 'Under Review';
      case FraudStatus.confirmed:
        return 'Confirmed';
      case FraudStatus.dismissed:
        return 'Dismissed';
    }
  }

  Color _statusColor(FraudStatus status) {
    switch (status) {
      case FraudStatus.underReview:
        return Colors.orange;
      case FraudStatus.confirmed:
        return Colors.red;
      case FraudStatus.dismissed:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _riskColor(report.riskLevel).withValues(alpha: 0.1),
          child: Icon(_riskIcon(report.riskLevel),
              color: _riskColor(report.riskLevel), size: 20),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                'User: ${report.userId.length > 10 ? '${report.userId.substring(0, 10)}...' : report.userId}',
                style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _statusColor(report.status).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _statusLabel(report.status),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: _statusColor(report.status),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(report.reason,
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 4),
            Row(
              children: [
                Text('Score: ${report.fraudScore.toStringAsFixed(0)}',
                    style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _riskColor(report.riskLevel))),
                const SizedBox(width: 12),
                Text(
                    'Risk: ${report.riskLevel.name.toUpperCase()}',
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: _riskColor(report.riskLevel))),
              ],
            ),
          ],
        ),
        children: [
          if (report.adminNotes != null)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.note_outlined, size: 16,
                      color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Admin: ${report.adminNotes}',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (report.status == FraudStatus.underReview) ...[
                  OutlinedButton.icon(
                    onPressed: () => _showActionDialog(context, report),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Review'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _showUserDetailDialog(context, report),
                  icon: const Icon(Icons.person_outline, size: 16),
                  label: const Text('View User'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _showActionDialog(BuildContext context, FraudReportEntity report) {
    final fraud = context.read<FraudProvider>();
    final adminNotesController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Review Fraud Report'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('User ID: ${report.userId}'),
            Text('Reason: ${report.reason}'),
            const SizedBox(height: 12),
            TextField(
              controller: adminNotesController,
              decoration: const InputDecoration(
                labelText: 'Admin Notes',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              fraud.updateFraudReportStatus(
                reportId: report.reportId,
                status: FraudStatus.dismissed,
                adminNotes: adminNotesController.text.isNotEmpty
                    ? adminNotesController.text
                    : null,
              );
              Navigator.pop(ctx);
            },
            child: const Text('Dismiss'),
          ),
          FilledButton(
            onPressed: () {
              fraud.updateFraudReportStatus(
                reportId: report.reportId,
                status: FraudStatus.confirmed,
                adminNotes: adminNotesController.text.isNotEmpty
                    ? adminNotesController.text
                    : null,
              );
              Navigator.pop(ctx);
            },
            child: const Text('Confirm Fraud'),
          ),
        ],
      ),
    );
  }

  void _showUserDetailDialog(BuildContext context, FraudReportEntity report) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('User Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('UID', report.userId),
            _detailRow('Risk Level', report.riskLevel.name.toUpperCase()),
            _detailRow('Fraud Score', report.fraudScore.toStringAsFixed(1)),
            _detailRow('Status', report.status.name),
            _detailRow('Reason', report.reason),
            _detailRow('Detected By', report.detectedBy ?? 'N/A'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () {
              final fraud = context.read<FraudProvider>();
              fraud.unflagUser(report.userId);
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Unflag User'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text('$label:',
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

// --- Reports Tab ---

class _FraudReportsTab extends StatelessWidget {
  final FraudProvider fraud;

  const _FraudReportsTab({required this.fraud});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (fraud.fraudReports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assessment_outlined, size: 64,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text('No fraud reports',
                style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            Text('All transactions and activities are normal',
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async =>
          await context.read<FraudProvider>().loadFraudReports(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: fraud.fraudReports.length,
        itemBuilder: (context, index) {
          final report = fraud.fraudReports[index];
          return _ReportCard(report: report);
        },
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final FraudReportEntity report;

  const _ReportCard({required this.report});

  Color _riskColor(RiskLevel level) {
    switch (level) {
      case RiskLevel.high:
        return Colors.red;
      case RiskLevel.medium:
        return Colors.orange;
      case RiskLevel.low:
        return Colors.amber;
    }
  }

  String _statusLabel(FraudStatus status) {
    switch (status) {
      case FraudStatus.underReview:
        return 'Under Review';
      case FraudStatus.confirmed:
        return 'Confirmed';
      case FraudStatus.dismissed:
        return 'Dismissed';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _riskColor(report.riskLevel).withValues(alpha: 0.1),
          child: Icon(Icons.assessment_outlined,
              color: _riskColor(report.riskLevel), size: 20),
        ),
        title: Text(report.reason,
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis),
        subtitle: Text(
          'User: ${report.userId.length > 15 ? '${report.userId.substring(0, 15)}...' : report.userId} | Score: ${report.fraudScore.toStringAsFixed(0)}',
          style: theme.textTheme.bodySmall,
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: _riskColor(report.riskLevel).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _statusLabel(report.status),
            style: theme.textTheme.labelSmall?.copyWith(
              color: _riskColor(report.riskLevel),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        onTap: () => _showReportDetail(context),
      ),
    );
  }

  void _showReportDetail(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Fraud Report',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('Report ID', report.reportId),
            _detailRow('User ID', report.userId),
            _detailRow('Reason', report.reason),
            _detailRow('Risk Level', report.riskLevel.name.toUpperCase()),
            _detailRow('Fraud Score', report.fraudScore.toStringAsFixed(1)),
            _detailRow('Status', _statusLabel(report.status)),
            _detailRow(
                'Detected By', report.detectedBy ?? 'System'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text('$label:',
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

// --- Shared Widgets ---

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.1),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
