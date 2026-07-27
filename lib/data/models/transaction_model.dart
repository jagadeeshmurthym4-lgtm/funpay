import 'package:cashspark/domain/entities/transaction_entity.dart';

class TransactionModel extends TransactionEntity {
  const TransactionModel({
    required super.transactionId,
    required super.userId,
    required super.type,
    required super.amount,
    super.source = TransactionSource.other,
    super.status = TransactionStatus.completed,
    super.description = '',
    required super.createdAt,
  });

  factory TransactionModel.fromEntity(TransactionEntity entity) {
    return TransactionModel(
      transactionId: entity.transactionId,
      userId: entity.userId,
      type: entity.type,
      amount: entity.amount,
      source: entity.source,
      status: entity.status,
      description: entity.description,
      createdAt: entity.createdAt,
    );
  }

  factory TransactionModel.fromFirestore(Map<String, dynamic> map) {
    return TransactionModel(
      transactionId: map['transactionId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      type: _parseType(map['type'] as String? ?? 'credit'),
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      source: _parseSource(map['source'] as String? ?? 'other'),
      status: _parseStatus(map['status'] as String? ?? 'completed'),
      description: map['description'] as String? ?? '',
      createdAt: (map['createdAt'] as dynamic)?.toDate() as DateTime? ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'transactionId': transactionId,
      'userId': userId,
      'type': type.name,
      'amount': amount,
      'source': source.name,
      'status': status.name,
      'description': description,
      'createdAt': createdAt,
    };
  }

  TransactionModel copyWithModel({
    String? transactionId,
    String? userId,
    TransactionType? type,
    double? amount,
    TransactionSource? source,
    TransactionStatus? status,
    String? description,
    DateTime? createdAt,
  }) {
    return TransactionModel(
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

  static TransactionType _parseType(String value) {
    return TransactionType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TransactionType.credit,
    );
  }

  static TransactionSource _parseSource(String value) {
    return TransactionSource.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TransactionSource.other,
    );
  }

  static TransactionStatus _parseStatus(String value) {
    return TransactionStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TransactionStatus.completed,
    );
  }
}
