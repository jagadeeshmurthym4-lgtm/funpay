enum WithdrawalMethod { upi, paytm, bankTransfer }

enum WithdrawalStatus { pending, paid, approved, rejected }

class WithdrawalEntity {
  final String withdrawalId;
  final String userId;
  final double amount;
  final WithdrawalMethod method;
  final String accountDetails;
  final WithdrawalStatus status;
  final String? adminRemarks;
  final DateTime requestedAt;
  final DateTime? processedAt;

  const WithdrawalEntity({
    required this.withdrawalId,
    required this.userId,
    required this.amount,
    required this.method,
    required this.accountDetails,
    this.status = WithdrawalStatus.pending,
    this.adminRemarks,
    required this.requestedAt,
    this.processedAt,
  });

  WithdrawalEntity copyWith({
    String? withdrawalId,
    String? userId,
    double? amount,
    WithdrawalMethod? method,
    String? accountDetails,
    WithdrawalStatus? status,
    String? adminRemarks,
    DateTime? requestedAt,
    DateTime? processedAt,
  }) {
    return WithdrawalEntity(
      withdrawalId: withdrawalId ?? this.withdrawalId,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      method: method ?? this.method,
      accountDetails: accountDetails ?? this.accountDetails,
      status: status ?? this.status,
      adminRemarks: adminRemarks ?? this.adminRemarks,
      requestedAt: requestedAt ?? this.requestedAt,
      processedAt: processedAt ?? this.processedAt,
    );
  }
}
