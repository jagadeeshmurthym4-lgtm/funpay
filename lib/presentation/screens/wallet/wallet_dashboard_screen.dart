import 'package:cashspark/core/theme/app_theme.dart';
import 'package:cashspark/core/utils/helpers.dart';
import 'package:cashspark/core/widgets/earnings_charts.dart';
import 'package:cashspark/core/widgets/premium_widgets.dart';
import 'package:cashspark/core/widgets/shimmer_loading.dart';
import 'package:cashspark/domain/entities/transaction_entity.dart';
import 'package:cashspark/presentation/providers/auth_provider.dart';
import 'package:cashspark/presentation/providers/wallet_provider.dart';
import 'package:cashspark/presentation/routes/app_router.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class WalletDashboardScreen extends StatefulWidget {
  const WalletDashboardScreen({super.key});

  @override
  State<WalletDashboardScreen> createState() => _WalletDashboardScreenState();
}

class _WalletDashboardScreenState extends State<WalletDashboardScreen> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeWallet());
  }

  Future<void> _initializeWallet() async {
    final userId = context.read<AuthProvider>().user?.uid;
    if (userId == null) return;
    final walletProvider = context.read<WalletProvider>();
    await walletProvider.ensureWalletExists(userId);
    walletProvider.listenToWallet(userId);
    walletProvider.loadEarningsBreakdown(userId);
    walletProvider.loadEarningsHistory(userId);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final userId = context.read<AuthProvider>().user?.uid;
    if (userId == null) return;
    final walletProvider = context.read<WalletProvider>();
    await walletProvider.loadWallet(userId);
    await walletProvider.loadTransactions(userId);
    await walletProvider.loadEarningsBreakdown(userId);
    await walletProvider.loadEarningsHistory(userId);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<WalletProvider>(
        builder: (context, wp, _) {
          if (wp.isLoading && wp.wallet == null) {
            return const WalletDashboardSkeleton();
          }

          final wallet = wp.wallet;
          final filteredTxns = _searchQuery.isEmpty
              ? wp.recentTransactions
              : wp.recentTransactions
                  .where((t) =>
                      t.description
                          .toLowerCase()
                          .contains(_searchQuery.toLowerCase()) ||
                      t.source.name
                          .toLowerCase()
                          .contains(_searchQuery.toLowerCase()))
                  .toList();

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ─── BALANCE CARD ──────────────────────────
                GlassContainer(
                  borderRadius: 24,
                  padding: const EdgeInsets.all(24),
                  gradient: const [Color(0xFF0F2740), Color(0xFF1A3350)],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Available Balance',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary)),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.accentGreen.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text('WALLET',
                                style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.accentGreen,
                                    letterSpacing: 1)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('₹',
                              style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.accentGreen)),
                          const SizedBox(width: 2),
                          AnimatedCounter(
                            value: wallet?.walletBalance ?? 0.0,
                            decimals: 2,
                            style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -1),
                          ),
                        ],
                      ),

                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ─── STATS CARDS 2×2 GRID ──────────────────
                Row(
                  children: [
                    Expanded(
                      child: PremiumStatCard(
                        icon: Icons.account_balance_wallet_outlined,
                        label: 'Available Balance',
                        value: Helpers.formatCurrency(
                            wallet?.walletBalance ?? 0.0),
                        color: AppTheme.accentGreen,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PremiumStatCard(
                        icon: Icons.trending_up_outlined,
                        label: 'Total Earned',
                        value: Helpers.formatCurrency(
                            wallet?.totalEarnings ?? 0.0),
                        color: AppTheme.accentPurple,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: PremiumStatCard(
                        icon: Icons.arrow_upward_outlined,
                        label: 'Total Redeemed',
                        value: Helpers.formatCurrency(
                            wallet?.totalWithdrawn ?? 0.0),
                        color: AppTheme.accentOrange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PremiumStatCard(
                        icon: Icons.update_outlined,
                        label: 'Last Updated',
                        value: wallet != null
                            ? Helpers.formatDateTime(wallet.updatedAt)
                            : '---',
                        color: AppTheme.accentBlue,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ─── WITHDRAW BUTTON (full-width) ──────────
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRouter.withdrawals),
                    icon: const Icon(Icons.redeem_rounded, size: 22),
                    label: const Text('Redeem Points',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4ADE80),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      elevation: 8,
                      shadowColor:
                          const Color(0xFF4ADE80).withValues(alpha: 0.4),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ─── EARNINGS BREAKDOWN PIE CHART ─────────
                PremiumCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppTheme.accentPurple.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.pie_chart_outline,
                                size: 18, color: AppTheme.accentPurple),
                          ),
                          const SizedBox(width: 10),
                          Text('Earnings Breakdown',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A))),
                        ],
                      ),
                      const SizedBox(height: 20),
                      if (wp.isHistoryLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: PremiumLoader(
                                size: 28, message: 'Loading...'),
                          ),
                        )
                      else
                        EarningsPieChart(breakdown: wp.rewardBreakdown),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // ─── ERROR ─────────────────────────────────
                if (wp.errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color:
                                const Color(0xFFEF4444).withValues(alpha: 0.2))),
                    child: Row(children: [
                      const Icon(Icons.error_outline,
                          color: Color(0xFFEF4444), size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(wp.errorMessage!,
                            style: const TextStyle(
                                color: Color(0xFFEF4444), fontSize: 13)),
                      ),
                      IconButton(
                          icon: const Icon(Icons.close,
                              size: 18, color: Color(0xFFEF4444)),
                          onPressed: wp.clearError,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints()),
                    ]),
                  ),

                // ─── SEARCH ────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppTheme.bgCardLight
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? AppTheme.borderColor.withValues(alpha: 0.3)
                            : const Color(0xFFCBD5E1).withValues(alpha: 0.3),
                      ),
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      decoration: InputDecoration(
                        hintText: 'Search transactions...',
                        prefixIcon: Icon(Icons.search_outlined,
                            color: isDark
                                ? AppTheme.textMuted
                                : const Color(0xFF94A3B8)),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear,
                                    color: isDark
                                        ? AppTheme.textMuted
                                        : const Color(0xFF94A3B8)),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() => _searchQuery = '');
                                })
                            : null,
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 14),
                      ),
                      style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A)),
                    ),
                  ),
                ),

                // ─── TRANSACTIONS ──────────────────────────
                const SectionHeader(title: 'Recent Transactions'),
                const SizedBox(height: 8),
                if (filteredTxns.isEmpty)
                  PremiumEmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No transactions yet',
                    subtitle: _searchQuery.isNotEmpty
                        ? 'No results for "$_searchQuery"'
                        : 'Your transaction history will appear here',
                  )
                else
                  ...filteredTxns.map((txn) => _TransactionCard(
                        txn: txn,
                        isDark: isDark,
                        onTap: () {
                          Navigator.pushNamed(context, '/transaction-detail',
                              arguments: txn);
                        },
                      )),
              ],
            ),
          );
        },
      ),
    );
  }

}

class _TransactionCard extends StatelessWidget {
  final TransactionEntity txn;
  final bool isDark;
  final VoidCallback onTap;

  const _TransactionCard(
      {required this.txn, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isCredit = txn.type == TransactionType.credit;
    final color = isCredit ? AppTheme.accentGreen : const Color(0xFFEF4444);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassContainer(
        borderRadius: 16,
        padding: const EdgeInsets.all(14),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Row(children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle, color: color.withValues(alpha: 0.1)),
                  child: Icon(
                      isCredit
                          ? Icons.arrow_downward
                          : Icons.arrow_upward,
                      color: color,
                      size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_formatSource(txn.source),
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A))),
                      const SizedBox(height: 2),
                      Text(
                          txn.description.isNotEmpty
                              ? txn.description
                              : _formatSource(txn.source),
                          style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppTheme.textMuted
                                  : const Color(0xFF94A3B8)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(Helpers.formatDateTime(txn.createdAt),
                          style: TextStyle(
                              fontSize: 10,
                              color: isDark
                                  ? AppTheme.textMuted.withValues(alpha: 0.7)
                                  : const Color(0xFF94A3B8)
                                      .withValues(alpha: 0.7))),
                    ],
                  ),
                ),
                Text(
                    '${isCredit ? '+' : '-'}₹${txn.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: color)),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right,
                    size: 18,
                    color: isDark
                        ? AppTheme.textMuted.withValues(alpha: 0.4)
                        : const Color(0xFF94A3B8).withValues(alpha: 0.4)),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  String _formatSource(TransactionSource source) {
    switch (source) {
      case TransactionSource.referral:
        return 'Referral Bonus';
      case TransactionSource.withdrawal:
        return 'Redemption';
      case TransactionSource.bonus:
        return 'Bonus';
      case TransactionSource.adminAdjustment:
        return 'Admin Adjustment';
      case TransactionSource.reward:
        return 'Reward';
      case TransactionSource.purchase:
        return 'Purchase';
      case TransactionSource.offerwall:
        return 'Survey Reward';
      case TransactionSource.other:
        return 'Transaction';
    }
  }
}
