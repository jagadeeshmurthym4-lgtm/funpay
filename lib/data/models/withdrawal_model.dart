import 'package:cashspark/domain/entities/withdrawal_entity.dart';

class WithdrawalModel extends WithdrawalEntity {
  const WithdrawalModel({
    required super.withdrawalId,
    required super.userId,
    required super.amount,
    required super.method,
    required super.accountDetails,
    super.qrCodeUrl,
    super.userName,
    super.userEmail,
    super.userPhone,
    super.walletBalanceAtRequest = 0.0,
    super.transactionId,
    super.status = WithdrawalStatus.pending,
    super.adminRemarks,
    required super.requestedAt,
    super.processedAt,
  });

  factory WithdrawalModel.fromEntity(WithdrawalEntity entity) {
    return WithdrawalModel(
      withdrawalId: entity.withdrawalId,
      userId: entity.userId,
      amount: entity.amount,
      method: entity.method,
      accountDetails: entity.accountDetails,
      qrCodeUrl: entity.qrCodeUrl,
      userName: entity.userName,
      userEmail: entity.userEmail,
      userPhone: entity.userPhone,
      walletBalanceAtRequest: entity.walletBalanceAtRequest,
      transactionId: entity.transactionId,
      status: entity.status,
      adminRemarks: entity.adminRemarks,
      requestedAt: entity.requestedAt,
      processedAt: entity.processedAt,
    );
  }

  factory WithdrawalModel.fromFirestore(Map<String, dynamic> map) {
    return WithdrawalModel(
      withdrawalId: map['withdrawalId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      method: _parseMethod(map['method'] as String? ?? 'upi'),
      accountDetails: map['accountDetails'] as String? ?? '',
      qrCodeUrl: map['qrCodeUrl'] as String?,
      userName: map['userName'] as String?,
      userEmail: map['userEmail'] as String?,
      userPhone: map['userPhone'] as String?,
      walletBalanceAtRequest: (map['walletBalanceAtRequest'] as num?)?.toDouble() ?? 0.0,
      transactionId: map['transactionId'] as String?,
      status: _parseStatus(map['status'] as String? ?? 'pending'),
      adminRemarks: map['adminRemarks'] as String?,
      requestedAt: (map['requestedAt'] as dynamic)?.toDate() as DateTime? ?? DateTime.now(),
      processedAt: (map['processedAt'] as dynamic)?.toDate() as DateTime?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'withdrawalId': withdrawalId,
      'userId': userId,
      'amount': amount,
      'method': method.name,
      'accountDetails': accountDetails,
      if (qrCodeUrl != null) 'qrCodeUrl': qrCodeUrl,
      if (userName != null) 'userName': userName,
      if (userEmail != null) 'userEmail': userEmail,
      if (userPhone != null) 'userPhone': userPhone,
      'walletBalanceAtRequest': walletBalanceAtRequest,
      if (transactionId != null) 'transactionId': transactionId,
      'status': status.name,
      if (adminRemarks != null) 'adminRemarks': adminRemarks,
      'requestedAt': requestedAt,
      if (processedAt != null) 'processedAt': processedAt,
    };
  }

  static WithdrawalMethod _parseMethod(String value) {
    return WithdrawalMethod.values.firstWhere(
      (e) => e.name == value,
      orElse: () => WithdrawalMethod.upi,
    );
  }

  static WithdrawalStatus _parseStatus(String value) {
    return WithdrawalStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => WithdrawalStatus.pending,
    );
  }
}
