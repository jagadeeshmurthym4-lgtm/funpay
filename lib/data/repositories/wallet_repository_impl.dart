import 'package:cashspark/core/errors/exceptions.dart';
import 'package:cashspark/data/datasources/wallet_firestore_datasource.dart';
import 'package:cashspark/data/models/transaction_model.dart';
import 'package:cashspark/data/models/wallet_model.dart';
import 'package:cashspark/domain/entities/transaction_entity.dart';
import 'package:cashspark/domain/entities/wallet_entity.dart';
import 'package:cashspark/domain/repositories/wallet_repository.dart';
import 'package:uuid/uuid.dart';

class WalletRepositoryImpl implements WalletRepository {
  final WalletFirestoreDataSource _dataSource;
  final Uuid _uuid;

  WalletRepositoryImpl({
    required WalletFirestoreDataSource dataSource,
    Uuid? uuid,
  })  : _dataSource = dataSource,
        _uuid = uuid ?? const Uuid();

  @override
  Future<WalletEntity> getWallet(String userId) async {
    try {
      final wallet = await _dataSource.getWallet(userId);
      if (wallet == null) {
        throw FirestoreException('Wallet not found');
      }
      return wallet;
    } on FirestoreException {
      rethrow;
    } catch (e) {
      throw FirestoreException('Failed to get wallet: $e');
    }
  }

  @override
  Future<WalletEntity> createWallet(WalletEntity wallet) async {
    try {
      final model = WalletModel.fromEntity(wallet);
      await _dataSource.createWallet(model);
      return model;
    } catch (e) {
      throw FirestoreException('Failed to create wallet: $e');
    }
  }

  @override
  Future<WalletEntity> addFunds({
    required String userId,
    required double amount,
    required TransactionSource source,
    required String description,
  }) async {
    if (amount <= 0) {
      throw FirestoreException('Amount must be positive');
    }

    try {
      // Update wallet balance atomically
      final updatedWallet = await _dataSource.updateWalletBalance(
        userId: userId,
        amountChange: amount,
        earningsChange: amount,
        withdrawnChange: 0,
      );

      // Create transaction record
      final transaction = TransactionModel(
        transactionId: _uuid.v4(),
        userId: userId,
        type: TransactionType.credit,
        amount: amount,
        source: source,
        status: TransactionStatus.completed,
        description: description,
        createdAt: DateTime.now(),
      );
      await _dataSource.createTransaction(transaction);

      return updatedWallet;
    } on FirestoreException {
      rethrow;
    } catch (e) {
      throw FirestoreException('Failed to add funds: $e');
    }
  }

  @override
  Future<WalletEntity> deductFunds({
    required String userId,
    required double amount,
    required TransactionSource source,
    required String description,
  }) async {
    if (amount <= 0) {
      throw FirestoreException('Amount must be positive');
    }

    try {
      // Update wallet balance atomically
      final updatedWallet = await _dataSource.updateWalletBalance(
        userId: userId,
        amountChange: -amount,
        earningsChange: 0,
        withdrawnChange: amount,
      );

      // Create transaction record
      final transaction = TransactionModel(
        transactionId: _uuid.v4(),
        userId: userId,
        type: TransactionType.debit,
        amount: amount,
        source: source,
        status: TransactionStatus.completed,
        description: description,
        createdAt: DateTime.now(),
      );
      await _dataSource.createTransaction(transaction);

      return updatedWallet;
    } on FirestoreException {
      rethrow;
    } on InsufficientBalanceException {
      rethrow;
    } catch (e) {
      throw FirestoreException('Failed to deduct funds: $e');
    }
  }

  @override
  Future<List<TransactionEntity>> getTransactions(String userId,
      {int limit = 20}) async {
    try {
      return await _dataSource.getTransactions(userId, limit: limit);
    } catch (e) {
      throw FirestoreException('Failed to get transactions: $e');
    }
  }

  @override
  Future<TransactionEntity?> getTransaction(String transactionId) async {
    try {
      return await _dataSource.getTransaction(transactionId);
    } catch (e) {
      throw FirestoreException('Failed to get transaction: $e');
    }
  }

  @override
  Stream<List<TransactionEntity>> streamRecentTransactions(String userId,
      {int limit = 20}) {
    return _dataSource
        .streamRecentTransactions(userId, limit: limit)
        ;
  }

  @override
  Stream<WalletEntity?> streamWallet(String userId) {
    return _dataSource.streamWallet(userId);
  }
}
