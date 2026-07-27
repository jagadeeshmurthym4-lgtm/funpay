import 'package:cashspark/core/utils/helpers.dart';
import 'package:cashspark/core/widgets/premium_widgets.dart';
import 'package:cashspark/domain/entities/withdrawal_entity.dart';
import 'package:cashspark/presentation/providers/auth_provider.dart';
import 'package:cashspark/presentation/providers/withdrawal_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class WithdrawalScreen extends StatefulWidget {
  const WithdrawalScreen({super.key});

  @override
  State<WithdrawalScreen> createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends State<WithdrawalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  void _initialize() {
    final auth = context.read<AuthProvider>();
    final userId = auth.user?.uid;
    if (userId != null) {
      context.read<WithdrawalProvider>().initialize(userId);
    }
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
        title: 'Withdrawals',
        onBack: () => Navigator.pop(context),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
              tabs: const [
                Tab(text: 'Request'),
                Tab(text: 'History'),
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
        child: Consumer2<AuthProvider, WithdrawalProvider>(
          builder: (context, auth, withdrawalProvider, _) {
            if (withdrawalProvider.isLoading) {
              return const Center(child: PremiumLoader());
            }

            return TabBarView(
              controller: _tabController,
              children: [
                _WithdrawalRequestTab(
                  withdrawalProvider: withdrawalProvider,
                  auth: auth,
                  theme: theme,
                ),
                _WithdrawalHistoryTab(
                  withdrawals: withdrawalProvider.userWithdrawals,
                  theme: theme,
                  withdrawalProvider: withdrawalProvider,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _WithdrawalRequestTab extends StatefulWidget {
  final WithdrawalProvider withdrawalProvider;
  final AuthProvider auth;
  final ThemeData theme;

  const _WithdrawalRequestTab({
    required this.withdrawalProvider,
    required this.auth,
    required this.theme,
  });

  @override
  State<_WithdrawalRequestTab> createState() => _WithdrawalRequestTabState();
}

class _WithdrawalRequestTabState extends State<_WithdrawalRequestTab> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _accountDetailsController = TextEditingController();
  WithdrawalMethod _selectedMethod = WithdrawalMethod.upi;

  @override
  void dispose() {
    _amountController.dispose();
    _accountDetailsController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = widget.auth.user?.uid;
    if (userId == null) return;

    final amount = double.tryParse(_amountController.text) ?? 0;
    final accountDetails = _accountDetailsController.text.trim();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: PremiumCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.theme.colorScheme.primary.withValues(alpha: 0.1),
                ),
                child: Icon(Icons.payments_outlined, color: widget.theme.colorScheme.primary, size: 28),
              ),
              const SizedBox(height: 16),
              Text('Confirm Withdrawal',
                  style: widget.theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(
                'Are you sure you want to withdraw\n₹${amount.toStringAsFixed(2)} via ${_selectedMethod.name.toUpperCase()}?',
                textAlign: TextAlign.center,
                style: widget.theme.textTheme.bodyMedium?.copyWith(
                    color: widget.theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.account_balance_wallet_outlined, size: 16,
                        color: widget.theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(accountDetails,
                          style: widget.theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Confirm'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true && mounted) {
      await widget.withdrawalProvider.requestWithdrawal(
        userId: userId,
        amount: amount,
        method: _selectedMethod,
        accountDetails: accountDetails,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final wp = widget.withdrawalProvider;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Error/Success banners
          if (wp.errorMessage != null)
            PremiumGlass(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              gradient: LinearGradient(colors: [
                widget.theme.colorScheme.error.withValues(alpha: 0.15),
                widget.theme.colorScheme.error.withValues(alpha: 0.05),
              ]),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: widget.theme.colorScheme.error, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(wp.errorMessage!,
                        style: widget.theme.textTheme.bodyMedium
                            ?.copyWith(color: widget.theme.colorScheme.error)),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 18, color: widget.theme.colorScheme.error),
                    onPressed: wp.clearError,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

          if (wp.successMessage != null)
            PremiumGlass(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              gradient: LinearGradient(colors: [
                widget.theme.colorScheme.tertiary.withValues(alpha: 0.15),
                widget.theme.colorScheme.tertiary.withValues(alpha: 0.05),
              ]),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: widget.theme.colorScheme.tertiary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(wp.successMessage!,
                        style: widget.theme.textTheme.bodyMedium
                            ?.copyWith(color: widget.theme.colorScheme.onTertiaryContainer)),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 18,
                        color: widget.theme.colorScheme.onTertiaryContainer),
                    onPressed: wp.clearSuccess,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

          // Limits Card
          PremiumCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: widget.theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text('Withdrawal Limits',
                        style: widget.theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 12),
                _LimitRow(
                  label: 'Minimum Amount',
                  value: '₹${wp.minWithdrawalAmount.toStringAsFixed(2)}',
                  theme: widget.theme,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Withdrawal Form
          PremiumCard(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Request Withdrawal',
                      style: widget.theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 20),

                  // Amount
                  TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      prefixText: '₹ ',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      hintText: 'Enter amount',
                      filled: true,
                      fillColor: widget.theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Please enter an amount';
                      final amount = double.tryParse(value);
                      if (amount == null || amount <= 0) return 'Enter a valid amount';
                      if (amount < wp.minWithdrawalAmount) {
                        return 'Minimum withdrawal is ₹${wp.minWithdrawalAmount.toStringAsFixed(2)}';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Withdrawal Method
                  DropdownButtonFormField<WithdrawalMethod>(
                    value: _selectedMethod,
                    decoration: InputDecoration(
                      labelText: 'Withdrawal Method',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: widget.theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: WithdrawalMethod.upi,
                        child: Text('UPI Transfer'),
                      ),
                      DropdownMenuItem(
                        value: WithdrawalMethod.paytm,
                        child: Text('Paytm'),
                      ),
                      DropdownMenuItem(
                        value: WithdrawalMethod.bankTransfer,
                        child: Text('Bank Transfer'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _selectedMethod = value);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Account Details
                  TextFormField(
                    controller: _accountDetailsController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: _getAccountLabel(),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      hintText: _getAccountHint(),
                      filled: true,
                      fillColor: widget.theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your ${_getAccountLabel().toLowerCase()}';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  GradientButton(
                    onPressed: wp.isSubmitting || wp.hasPendingWithdrawal ? null : _submitRequest,
                    label: wp.hasPendingWithdrawal
                        ? 'Pending Request Exists'
                        : wp.isSubmitting
                            ? 'Submitting...'
                            : 'Submit Withdrawal Request',
                    isLoading: wp.isSubmitting,
                    icon: Icons.send_rounded,
                  ),

                  if (wp.hasPendingWithdrawal)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'You have a pending withdrawal request. Wait for it to be processed.',
                        style: widget.theme.textTheme.bodySmall?.copyWith(
                          color: widget.theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getAccountLabel() {
    switch (_selectedMethod) {
      case WithdrawalMethod.upi:
        return 'UPI ID';
      case WithdrawalMethod.paytm:
        return 'Paytm Number';
      case WithdrawalMethod.bankTransfer:
        return 'Bank Details (Account No, IFSC, Name)';
    }
  }

  String _getAccountHint() {
    switch (_selectedMethod) {
      case WithdrawalMethod.upi:
        return 'example@upi';
      case WithdrawalMethod.paytm:
        return 'Enter your Paytm registered number';
      case WithdrawalMethod.bankTransfer:
        return 'Account number, IFSC code, Account holder name';
    }
  }
}

class _LimitRow extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;

  const _LimitRow({required this.label, required this.value, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              )),
        ),
      ],
    );
  }
}

class _WithdrawalHistoryTab extends StatelessWidget {
  final List<WithdrawalEntity> withdrawals;
  final ThemeData theme;
  final WithdrawalProvider withdrawalProvider;

  const _WithdrawalHistoryTab({
    required this.withdrawals,
    required this.theme,
    required this.withdrawalProvider,
  });

  @override
  Widget build(BuildContext context) {
    if (withdrawals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 64,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text('No withdrawal requests yet',
                style: theme.textTheme.titleMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            Text('Submit your first withdrawal request above',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        final auth = context.read<AuthProvider>();
        final userId = auth.user?.uid;
        if (userId != null) await withdrawalProvider.initialize(userId);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: withdrawals.length,
        itemBuilder: (context, index) {
          final withdrawal = withdrawals[index];
          return _WithdrawalCard(
            withdrawal: withdrawal,
            theme: theme,
            onTap: () {
              withdrawalProvider.selectWithdrawal(withdrawal);
              _showWithdrawalDetail(context, withdrawal, theme);
            },
          );
        },
      ),
    );
  }

  void _showWithdrawalDetail(
      BuildContext context, WithdrawalEntity withdrawal, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => PremiumCard(
        margin: EdgeInsets.zero,
        borderRadius: 24,
        padding: const EdgeInsets.all(24),
        child: _WithdrawalDetailSheet(withdrawal: withdrawal, theme: theme),
      ),
    );
  }
}

class _WithdrawalCard extends StatelessWidget {
  final WithdrawalEntity withdrawal;
  final ThemeData theme;
  final VoidCallback onTap;

  const _WithdrawalCard({
    required this.withdrawal,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(withdrawal.status);
    final statusLabel = _statusLabel(withdrawal.status);

    return PremiumGlass(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            IconContainer(icon: _methodIcon(withdrawal.method), color: statusColor, containerSize: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_methodLabel(withdrawal.method),
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    Helpers.formatDateTime(withdrawal.requestedAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '-₹${withdrawal.amount.toStringAsFixed(2)}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.error,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(WithdrawalStatus status) {
    switch (status) {
      case WithdrawalStatus.pending:
        return Colors.orange;
      case WithdrawalStatus.paid:
        return Colors.teal;
      case WithdrawalStatus.approved:
        return Colors.green;
      case WithdrawalStatus.rejected:
        return theme.colorScheme.error;
    }
  }

  String _statusLabel(WithdrawalStatus status) {
    switch (status) {
      case WithdrawalStatus.pending:
        return 'Pending';
      case WithdrawalStatus.paid:
        return 'Paid';
      case WithdrawalStatus.approved:
        return 'Approved';
      case WithdrawalStatus.rejected:
        return 'Rejected';
    }
  }

  IconData _methodIcon(WithdrawalMethod method) {
    switch (method) {
      case WithdrawalMethod.upi:
        return Icons.phone_android_outlined;
      case WithdrawalMethod.paytm:
        return Icons.account_balance_wallet_outlined;
      case WithdrawalMethod.bankTransfer:
        return Icons.account_balance_outlined;
    }
  }

  String _methodLabel(WithdrawalMethod method) {
    switch (method) {
      case WithdrawalMethod.upi:
        return 'UPI Transfer';
      case WithdrawalMethod.paytm:
        return 'Paytm';
      case WithdrawalMethod.bankTransfer:
        return 'Bank Transfer';
    }
  }
}

class _WithdrawalDetailSheet extends StatelessWidget {
  final WithdrawalEntity withdrawal;
  final ThemeData theme;

  const _WithdrawalDetailSheet({required this.withdrawal, required this.theme});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(withdrawal.status);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Status badge
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _statusLabel(withdrawal.status).toUpperCase(),
              style: theme.textTheme.labelMedium?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Amount
        Center(
          child: Text(
            '-₹${withdrawal.amount.toStringAsFixed(2)}',
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.error,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            _methodLabel(withdrawal.method),
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        const SizedBox(height: 24),

        const Divider(),
        const SizedBox(height: 12),

        _DetailRow(label: 'Withdrawal ID', value: withdrawal.withdrawalId, theme: theme),
        const SizedBox(height: 8),
        _DetailRow(label: 'Account Details', value: withdrawal.accountDetails, theme: theme),
        const SizedBox(height: 8),
        _DetailRow(
          label: 'Requested',
          value: Helpers.formatDateTime(withdrawal.requestedAt),
          theme: theme,
        ),
        if (withdrawal.processedAt != null) ...[
          const SizedBox(height: 8),
          _DetailRow(
            label: 'Processed',
            value: Helpers.formatDateTime(withdrawal.processedAt!),
            theme: theme,
          ),
        ],
        if (withdrawal.adminRemarks != null) ...[
          const SizedBox(height: 8),
          _DetailRow(label: 'Admin Remarks', value: withdrawal.adminRemarks!, theme: theme),
        ],
        const SizedBox(height: 16),
      ],
    );
  }

  Color _statusColor(WithdrawalStatus status) {
    switch (status) {
      case WithdrawalStatus.pending:
        return Colors.orange;
      case WithdrawalStatus.paid:
        return Colors.teal;
      case WithdrawalStatus.approved:
        return Colors.green;
      case WithdrawalStatus.rejected:
        return theme.colorScheme.error;
    }
  }

  String _statusLabel(WithdrawalStatus status) {
    switch (status) {
      case WithdrawalStatus.pending:
        return 'Pending';
      case WithdrawalStatus.paid:
        return 'Paid';
      case WithdrawalStatus.approved:
        return 'Approved';
      case WithdrawalStatus.rejected:
        return 'Rejected';
    }
  }

  String _methodLabel(WithdrawalMethod method) {
    switch (method) {
      case WithdrawalMethod.upi:
        return 'UPI Transfer';
      case WithdrawalMethod.paytm:
        return 'Paytm';
      case WithdrawalMethod.bankTransfer:
        return 'Bank Transfer';
    }
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;

  const _DetailRow({required this.label, required this.value, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
