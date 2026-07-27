class WalletEntity {
  final String userId;
  final double walletBalance;
  final double totalEarnings;
  final double totalWithdrawn;
  final DateTime updatedAt;

  const WalletEntity({
    required this.userId,
    this.walletBalance = 0.0,
    this.totalEarnings = 0.0,
    this.totalWithdrawn = 0.0,
    required this.updatedAt,
  });

  WalletEntity copyWith({
    String? userId,
    double? walletBalance,
    double? totalEarnings,
    double? totalWithdrawn,
    DateTime? updatedAt,
  }) {
    return WalletEntity(
      userId: userId ?? this.userId,
      walletBalance: walletBalance ?? this.walletBalance,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      totalWithdrawn: totalWithdrawn ?? this.totalWithdrawn,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
