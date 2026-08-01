enum WithdrawalMethod { upi, upiId, paytm }

enum WithdrawalStatus { pending, paid, approved, rejected }

class WithdrawalEntity {
  final String withdrawalId;
  final String userId;
  final double amount;
  final WithdrawalMethod method;
  final String accountDetails;
  final String? qrCodeUrl;
  final String? userName;
  final String? userEmail;
  final String? userPhone;
  final double walletBalanceAtRequest;
  final String? transactionId;
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
    this.qrCodeUrl,
    this.userName,
    this.userEmail,
    this.userPhone,
    this.walletBalanceAtRequest = 0.0,
    this.transactionId,
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
    String? qrCodeUrl,
    String? userName,
    String? userEmail,
    String? userPhone,
    double? walletBalanceAtRequest,
    String? transactionId,
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
      qrCodeUrl: qrCodeUrl ?? this.qrCodeUrl,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      userPhone: userPhone ?? this.userPhone,
      walletBalanceAtRequest: walletBalanceAtRequest ?? this.walletBalanceAtRequest,
      transactionId: transactionId ?? this.transactionId,
      status: status ?? this.status,
      adminRemarks: adminRemarks ?? this.adminRemarks,
      requestedAt: requestedAt ?? this.requestedAt,
      processedAt: processedAt ?? this.processedAt,
    );
  }
}
