import 'package:cashspark/domain/entities/wallet_entity.dart';

class WalletModel extends WalletEntity {
  const WalletModel({
    required super.userId,
    super.walletBalance = 0.0,
    super.totalEarnings = 0.0,
    super.totalWithdrawn = 0.0,
    required super.updatedAt,
  });

  factory WalletModel.fromEntity(WalletEntity entity) {
    return WalletModel(
      userId: entity.userId,
      walletBalance: entity.walletBalance,
      totalEarnings: entity.totalEarnings,
      totalWithdrawn: entity.totalWithdrawn,
      updatedAt: entity.updatedAt,
    );
  }

  factory WalletModel.fromFirestore(Map<String, dynamic> map) {
    return WalletModel(
      userId: map['userId'] as String? ?? '',
      walletBalance: (map['walletBalance'] as num?)?.toDouble() ?? 0.0,
      totalEarnings: (map['totalEarnings'] as num?)?.toDouble() ?? 0.0,
      totalWithdrawn: (map['totalWithdrawn'] as num?)?.toDouble() ?? 0.0,
      updatedAt: (map['updatedAt'] as dynamic)?.toDate() as DateTime? ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'walletBalance': walletBalance,
      'totalEarnings': totalEarnings,
      'totalWithdrawn': totalWithdrawn,
      'updatedAt': updatedAt,
    };
  }

  WalletModel copyWithModel({
    String? userId,
    double? walletBalance,
    double? totalEarnings,
    double? totalWithdrawn,
    DateTime? updatedAt,
  }) {
    return WalletModel(
      userId: userId ?? this.userId,
      walletBalance: walletBalance ?? this.walletBalance,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      totalWithdrawn: totalWithdrawn ?? this.totalWithdrawn,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
