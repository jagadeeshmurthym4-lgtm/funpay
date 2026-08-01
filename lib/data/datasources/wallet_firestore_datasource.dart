import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cashspark/core/constants/app_constants.dart';
import 'package:cashspark/core/errors/exceptions.dart';
import 'package:cashspark/data/models/transaction_model.dart';
import 'package:cashspark/data/models/wallet_model.dart';
import 'package:flutter/foundation.dart' show debugPrint;

class WalletFirestoreDataSource {
  final FirebaseFirestore _firestore;

  WalletFirestoreDataSource({FirebaseFirestore? firestoreInstance})
      : _firestore = firestoreInstance ?? FirebaseFirestore.instance;

  // --- Wallet Operations ---

  Future<WalletModel?> getWallet(String userId) async {
    final doc = await _firestore
        .collection(AppConstants.walletsCollection)
        .doc(userId)
        .get();
    if (!doc.exists || doc.data() == null) return null;
    return WalletModel.fromFirestore(doc.data()!);
  }

  Future<void> createWallet(WalletModel wallet) async {
    await _firestore
        .collection(AppConstants.walletsCollection)
        .doc(wallet.userId)
        .set(wallet.toFirestore());
  }

  Future<void> updateWallet(WalletModel wallet) async {
    await _firestore
        .collection(AppConstants.walletsCollection)
        .doc(wallet.userId)
        .update(wallet.toFirestore());
  }

  Future<void> deleteWallet(String userId) async {
    await _firestore
        .collection(AppConstants.walletsCollection)
        .doc(userId)
        .delete();
  }

  Stream<WalletModel?> streamWallet(String userId) {
    return _firestore
        .collection(AppConstants.walletsCollection)
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      return WalletModel.fromFirestore(snapshot.data()!);
    });
  }

  /// Atomically updates wallet balance. Uses Firestore transaction
  /// to prevent race conditions on the wallet balance.
  Future<WalletModel> updateWalletBalance({
    required String userId,
    required double amountChange,
    required double earningsChange,
    required double withdrawnChange,
  }) async {
    final walletRef =
        _firestore.collection(AppConstants.walletsCollection).doc(userId);

    final result = await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(walletRef);
      if (!snapshot.exists) {
        throw FirestoreException('Wallet not found for user $userId');
      }

      final currentBalance =
          (snapshot.data()!['walletBalance'] as num?)?.toDouble() ?? 0.0;
      final currentEarnings =
          (snapshot.data()!['totalEarnings'] as num?)?.toDouble() ?? 0.0;
      final currentWithdrawn =
          (snapshot.data()!['totalWithdrawn'] as num?)?.toDouble() ?? 0.0;

      final newBalance = currentBalance + amountChange;
      final newEarnings = currentEarnings + earningsChange;
      final newWithdrawn = currentWithdrawn + withdrawnChange;

      // Prevent negative balance
      if (newBalance < 0) {
        throw InsufficientBalanceException();
      }

      transaction.update(walletRef, {
        'walletBalance': newBalance,
        'totalEarnings': newEarnings,
        'totalWithdrawn': newWithdrawn,
        'updatedAt': DateTime.now(),
      });

      return WalletModel(
        userId: userId,
        walletBalance: newBalance,
        totalEarnings: newEarnings,
        totalWithdrawn: newWithdrawn,
        updatedAt: DateTime.now(),
      );
    });

    return result;
  }

  // --- Transaction Operations ---

  Future<void> createTransaction(TransactionModel transaction) async {
    await _firestore
        .collection(AppConstants.transactionsCollection)
        .doc(transaction.transactionId)
        .set(transaction.toFirestore());
  }

  Future<TransactionModel?> getTransaction(String transactionId) async {
    final doc = await _firestore
        .collection(AppConstants.transactionsCollection)
        .doc(transactionId)
        .get();
    if (!doc.exists || doc.data() == null) return null;
    return TransactionModel.fromFirestore(doc.data()!);
  }

  Future<List<TransactionModel>> getTransactions(String userId,
      {int limit = 20}) async {
    try {
      final query = await _firestore
          .collection(AppConstants.transactionsCollection)
          .where('userId', isEqualTo: userId)
          .get();
      final transactions = query.docs
          .map((doc) => TransactionModel.fromFirestore(doc.data()))
          .toList();
      transactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return transactions.take(limit).toList();
    } catch (e) {
      debugPrint('getTransactions error: $e');
      return [];
    }
  }

  Future<List<TransactionModel>> getAllTransactions(String userId) async {
    try {
      final query = await _firestore
          .collection(AppConstants.transactionsCollection)
          .where('userId', isEqualTo: userId)
          .get();
      return query.docs
          .map((doc) => TransactionModel.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('getAllTransactions error: $e');
      return [];
    }
  }

  Future<void> deleteTransaction(String transactionId) async {
    await _firestore
        .collection(AppConstants.transactionsCollection)
        .doc(transactionId)
        .delete();
  }

  /// Credits the referrer's wallet with 10 pts sign-up bonus.
  /// Includes the _referralId field for Firestore rule verification.
  Future<void> creditReferralSignupBonus({
    required String referrerUserId,
    required String referralId,
  }) async {
    final walletRef =
        _firestore.collection(AppConstants.walletsCollection).doc(referrerUserId);

    await walletRef.set({
      'walletBalance': FieldValue.increment(10.0),
      'totalEarnings': FieldValue.increment(10.0),
      '_referralId': referralId,
    }, SetOptions(merge: true));
  }

  Stream<List<TransactionModel>> streamRecentTransactions(String userId,
      {int limit = 20}) {
    return _firestore
        .collection(AppConstants.transactionsCollection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final transactions = snapshot.docs
          .map((doc) => TransactionModel.fromFirestore(doc.data()))
          .toList();
      transactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return transactions.take(limit).toList();
    });
  }
}
