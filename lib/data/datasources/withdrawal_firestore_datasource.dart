import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cashspark/core/constants/app_constants.dart';
import 'package:cashspark/data/models/withdrawal_model.dart';
import 'package:cashspark/domain/entities/withdrawal_entity.dart';
import 'package:flutter/foundation.dart' show debugPrint;

class WithdrawalFirestoreDataSource {
  final FirebaseFirestore _firestore;

  WithdrawalFirestoreDataSource({FirebaseFirestore? firestoreInstance})
      : _firestore = firestoreInstance ?? FirebaseFirestore.instance;

  Future<void> createWithdrawal(WithdrawalModel withdrawal) async {
    await _firestore
        .collection(AppConstants.withdrawalsCollection)
        .doc(withdrawal.withdrawalId)
        .set(withdrawal.toFirestore());
  }

  Future<WithdrawalModel?> getWithdrawal(String withdrawalId) async {
    final doc = await _firestore
        .collection(AppConstants.withdrawalsCollection)
        .doc(withdrawalId)
        .get();
    if (!doc.exists || doc.data() == null) return null;
    return WithdrawalModel.fromFirestore(doc.data()!);
  }

  Future<void> updateWithdrawal(WithdrawalModel withdrawal) async {
    await _firestore
        .collection(AppConstants.withdrawalsCollection)
        .doc(withdrawal.withdrawalId)
        .update(withdrawal.toFirestore());
  }

  Future<List<WithdrawalModel>> getUserWithdrawals(String userId,
      {int limit = 20}) async {
    try {
      final query = await _firestore
          .collection(AppConstants.withdrawalsCollection)
          .where('userId', isEqualTo: userId)
          .get();
      final withdrawals = query.docs
          .map((doc) => WithdrawalModel.fromFirestore(doc.data()))
          .toList();
      withdrawals.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
      return withdrawals.take(limit).toList();
    } catch (e) {
      debugPrint('getUserWithdrawals error: $e');
      return [];
    }
  }

  Stream<List<WithdrawalModel>> streamUserWithdrawals(String userId) {
    return _firestore
        .collection(AppConstants.withdrawalsCollection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final withdrawals = snapshot.docs
          .map((doc) => WithdrawalModel.fromFirestore(doc.data()))
          .toList();
      withdrawals.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
      return withdrawals.take(20).toList();
    });
  }

  Future<List<WithdrawalModel>> getAllWithdrawals({
    WithdrawalStatus? status,
    int limit = 50,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.withdrawalsCollection)
          .get();
      var withdrawals = snapshot.docs
          .map((doc) => WithdrawalModel.fromFirestore(doc.data()))
          .toList();

      if (status != null) {
        withdrawals = withdrawals.where((w) => w.status == status).toList();
      }

      withdrawals.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
      return withdrawals.take(limit).toList();
    } catch (e) {
      debugPrint('getAllWithdrawals error: $e');
      return [];
    }
  }

  Stream<List<WithdrawalModel>> streamAllWithdrawals({WithdrawalStatus? status}) {
    return _firestore
        .collection(AppConstants.withdrawalsCollection)
        .snapshots()
        .map((snapshot) {
      var withdrawals = snapshot.docs
          .map((doc) => WithdrawalModel.fromFirestore(doc.data()))
          .toList();

      if (status != null) {
        withdrawals = withdrawals.where((w) => w.status == status).toList();
      }

      withdrawals.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
      return withdrawals.take(50).toList();
    });
  }

  Future<bool> hasPendingWithdrawal(String userId) async {
    try {
      final query = await _firestore
          .collection(AppConstants.withdrawalsCollection)
          .where('userId', isEqualTo: userId)
          .get();
      for (final doc in query.docs) {
        if (doc.data()['status'] == WithdrawalStatus.pending.name) {
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('hasPendingWithdrawal error: $e');
      return false;
    }
  }
}
