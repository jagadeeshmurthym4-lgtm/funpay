enum TransactionType { credit, debit }

enum TransactionStatus { pending, completed, failed, cancelled }

enum TransactionSource {
  referral,
  withdrawal,
  bonus,
  adminAdjustment,
  purchase,
  reward,
  offerwall,
  other
}

class TransactionEntity {
  final String transactionId;
  final String userId;
  final TransactionType type;
  final double amount;
  final TransactionSource source;
  final TransactionStatus status;
  final String description;
  final DateTime createdAt;

  const TransactionEntity({
    required this.transactionId,
    required this.userId,
    required this.type,
    required this.amount,
    this.source = TransactionSource.other,
    this.status = TransactionStatus.completed,
    this.description = '',
    required this.createdAt,
  });

  TransactionEntity copyWith({
    String? transactionId,
    String? userId,
    TransactionType? type,
    double? amount,
    TransactionSource? source,
    TransactionStatus? status,
    String? description,
    DateTime? createdAt,
  }) {
    return TransactionEntity(
      transactionId: transactionId ?? this.transactionId,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      source: source ?? this.source,
      status: status ?? this.status,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
