import 'package:cashspark/core/widgets/premium_widgets.dart';
import 'package:cashspark/domain/entities/transaction_entity.dart';
import 'package:flutter/material.dart';

class TransactionDetailScreen extends StatelessWidget {
  const TransactionDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final transaction =
        ModalRoute.of(context)?.settings.arguments as TransactionEntity?;

    if (transaction == null) {
      return Scaffold(
        appBar: PremiumAppBar(title: 'Transaction Details', onBack: () => Navigator.pop(context)),
        body: const Center(child: Text('Transaction not found')),
      );
    }

    final isCredit = transaction.type == TransactionType.credit;
    final statusColor = _getStatusColor(transaction.status, theme);

    return Scaffold(
      appBar: PremiumAppBar(
        title: 'Transaction Details',
        onBack: () => Navigator.pop(context),
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
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Amount & Status Header
            PremiumCard(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          (isCredit ? theme.colorScheme.tertiary : theme.colorScheme.error),
                          (isCredit ? theme.colorScheme.tertiary : theme.colorScheme.error).withValues(alpha: 0.7),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isCredit ? theme.colorScheme.tertiary : theme.colorScheme.error).withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                      size: 36,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '${isCredit ? '+' : '-'}₹${transaction.amount.toStringAsFixed(2)}',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isCredit ? theme.colorScheme.tertiary : theme.colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isCredit ? 'Money Received' : 'Money Sent',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      transaction.status.name.toUpperCase(),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Transaction Details
            PremiumCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.receipt_long_outlined,
                            color: theme.colorScheme.primary, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Transaction Information',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _DetailRow(
                    label: 'Transaction ID',
                    value: transaction.transactionId.length > 20
                        ? '...${transaction.transactionId.substring(transaction.transactionId.length - 20)}'
                        : transaction.transactionId,
                    theme: theme,
                  ),
                  const Divider(height: 24),
                  _DetailRow(
                    label: 'Type',
                    value: isCredit ? 'Credit' : 'Debit',
                    theme: theme,
                    valueColor: isCredit ? theme.colorScheme.tertiary : theme.colorScheme.error,
                  ),
                  const Divider(height: 24),
                  _DetailRow(
                    label: 'Source',
                    value: _formatSource(transaction.source),
                    theme: theme,
                  ),
                  const Divider(height: 24),
                  _DetailRow(
                    label: 'Status',
                    value: _formatStatus(transaction.status),
                    theme: theme,
                    valueColor: statusColor,
                  ),
                  const Divider(height: 24),
                  _DetailRow(
                    label: 'Amount',
                    value: '₹${transaction.amount.toStringAsFixed(2)}',
                    theme: theme,
                    valueColor: isCredit ? theme.colorScheme.tertiary : theme.colorScheme.error,
                  ),
                  const Divider(height: 24),
                  _DetailRow(
                    label: 'Date & Time',
                    value: _formatDateTime(transaction.createdAt),
                    theme: theme,
                  ),
                  if (transaction.description.isNotEmpty) ...[
                    const Divider(height: 24),
                    _DetailRow(
                      label: 'Description',
                      value: transaction.description,
                      theme: theme,
                    ),
                  ],
                ],
              ),
            ),
          ],
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
        return 'Sign-up Bonus';
      case TransactionSource.adminAdjustment:
        return 'Admin Adjustment';
      case TransactionSource.purchase:
        return 'Purchase';
      case TransactionSource.reward:
        return 'Reward';
      case TransactionSource.offerwall:
        return 'Survey Reward';
      case TransactionSource.other:
        return 'General';
    }
  }

  String _formatStatus(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.pending:
        return 'Pending';
      case TransactionStatus.completed:
        return 'Completed';
      case TransactionStatus.failed:
        return 'Failed';
      case TransactionStatus.cancelled:
        return 'Cancelled';
    }
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} at ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Color _getStatusColor(TransactionStatus status, ThemeData theme) {
    switch (status) {
      case TransactionStatus.pending:
        return theme.colorScheme.secondary;
      case TransactionStatus.completed:
        return theme.colorScheme.tertiary;
      case TransactionStatus.failed:
        return theme.colorScheme.error;
      case TransactionStatus.cancelled:
        return theme.colorScheme.onSurfaceVariant;
    }
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;
  final Color? valueColor;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.theme,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
