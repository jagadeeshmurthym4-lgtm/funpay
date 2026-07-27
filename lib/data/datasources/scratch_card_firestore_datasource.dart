import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cashspark/core/constants/app_constants.dart';
import 'package:cashspark/data/models/scratch_card_model.dart';
import 'package:flutter/foundation.dart' show debugPrint;

class ScratchCardFirestoreDataSource {
  final FirebaseFirestore _firestore;

  ScratchCardFirestoreDataSource({FirebaseFirestore? firestoreInstance})
      : _firestore = firestoreInstance ?? FirebaseFirestore.instance;

  Future<void> createScratchCard(ScratchCardModel card) async {
    await _firestore
        .collection(AppConstants.scratchCardsCollection)
        .doc(card.scratchCardId)
        .set(card.toFirestore());
  }

  Future<ScratchCardModel?> getScratchCard(String scratchCardId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.scratchCardsCollection)
          .doc(scratchCardId)
          .get();
      if (!doc.exists || doc.data() == null) return null;
      return ScratchCardModel.fromFirestore(doc.data()!);
    } catch (e) {
      debugPrint('getScratchCard error: $e');
      return null;
    }
  }

  /// Check if a scratch card already exists for a given submission.
  /// Prevents duplicate cards for the same approved submission.
  Future<bool> hasScratchCardForSubmission(String submissionId) async {
    try {
      final query = await _firestore
          .collection(AppConstants.scratchCardsCollection)
          .where('submissionId', isEqualTo: submissionId)
          .limit(1)
          .get();
      return query.docs.isNotEmpty;
    } catch (e) {
      debugPrint('hasScratchCardForSubmission error: $e');
      return false;
    }
  }

  /// Use a Firestore transaction to atomically mark a scratch card as used
  /// and set the reward amount.
  /// Returns true if the card was actually updated (was unused and is now marked used).
  /// Returns false if the card was already used or if transaction fails.
  Future<bool> scratchCard(ScratchCardModel card) async {
    try {
      bool wasUpdated = false;
      await _firestore.runTransaction((transaction) async {
        final ref = _firestore
            .collection(AppConstants.scratchCardsCollection)
            .doc(card.scratchCardId);

        final snapshot = await transaction.get(ref);
        if (!snapshot.exists) return;

        final existing = ScratchCardModel.fromFirestore(snapshot.data()!);
        if (existing.isUsed) return; // Already scratched — no-op; wasUpdated stays false

        transaction.update(ref, {
          'isUsed': true,
          'rewardAmount': card.rewardAmount,
          'usedAt': card.usedAt,
        });
        wasUpdated = true;
      });
      return wasUpdated;
    } catch (e) {
      debugPrint('scratchCard transaction error: $e');
      return false;
    }
  }

  Future<List<ScratchCardModel>> getScratchCards(String userId) async {
    try {
      final query = await _firestore
          .collection(AppConstants.scratchCardsCollection)
          .where('userId', isEqualTo: userId)
          .get();
      final cards = query.docs
          .map((doc) => ScratchCardModel.fromFirestore(doc.data()))
          .toList();
      cards.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return cards;
    } catch (e) {
      debugPrint('getScratchCards error: $e');
      return [];
    }
  }

  Stream<List<ScratchCardModel>> streamScratchCards(String userId) {
    return _firestore
        .collection(AppConstants.scratchCardsCollection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final cards = snapshot.docs
          .map((doc) => ScratchCardModel.fromFirestore(doc.data()))
          .toList();
      cards.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return cards;
    });
  }
}
