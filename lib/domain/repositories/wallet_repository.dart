import 'package:cashspark/domain/entities/transaction_entity.dart';
import 'package:cashspark/domain/entities/wallet_entity.dart';

abstract class WalletRepository {
  Future<WalletEntity> getWallet(String userId);
  Future<WalletEntity> createWallet(WalletEntity wallet);
  Future<WalletEntity> addFunds({
    required String userId,
    required double amount,
    required TransactionSource source,
    required String description,
  });
  Future<WalletEntity> deductFunds({
    required String userId,
    required double amount,
    required TransactionSource source,
    required String description,
  });
  Future<List<TransactionEntity>> getTransactions(String userId, {int limit = 20});
  Future<TransactionEntity?> getTransaction(String transactionId);
  Stream<List<TransactionEntity>> streamRecentTransactions(String userId, {int limit = 20});
  Stream<WalletEntity?> streamWallet(String userId);
}
