import 'package:cashspark/domain/entities/withdrawal_entity.dart';

abstract class WithdrawalRepository {
  // User features
  Future<WithdrawalEntity> requestWithdrawal({
    required String userId,
    required double amount,
    required WithdrawalMethod method,
    required String accountDetails,
  });
  Future<List<WithdrawalEntity>> getWithdrawalHistory(String userId, {int limit = 20});
  Future<WithdrawalEntity?> getWithdrawal(String withdrawalId);
  Stream<List<WithdrawalEntity>> streamUserWithdrawals(String userId);

  // Validation
  Future<bool> hasPendingWithdrawal(String userId);
  Future<void> validateWithdrawalRules({
    required String userId,
    required double amount,
  });

  // Admin features
  Future<List<WithdrawalEntity>> getAllWithdrawals({WithdrawalStatus? status, int limit = 50});
  Stream<List<WithdrawalEntity>> streamAllWithdrawals({WithdrawalStatus? status});
  Future<WithdrawalEntity> markAsPaid(String withdrawalId, {String? remarks});
  Future<WithdrawalEntity> approveWithdrawal(String withdrawalId, {String? remarks});
  Future<WithdrawalEntity> rejectWithdrawal(String withdrawalId, {required String remarks});
}
