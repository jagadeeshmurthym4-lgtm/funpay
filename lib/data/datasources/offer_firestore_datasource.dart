import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cashspark/core/constants/app_constants.dart';
import 'package:cashspark/data/models/offer_model.dart';
import 'package:flutter/foundation.dart' show debugPrint;

/// Result of a paginated Firestore query — contains the items and the last
/// document snapshot used as the cursor for the next page.
class PaginatedOffers {
  final List<OfferModel> items;
  final DocumentSnapshot? lastDoc;
  final bool hasMore;

  const PaginatedOffers({
    required this.items,
    this.lastDoc,
    this.hasMore = false,
  });
}

class OfferFirestoreDataSource {
  final FirebaseFirestore _firestore;

  OfferFirestoreDataSource({FirebaseFirestore? firestoreInstance})
      : _firestore = firestoreInstance ?? FirebaseFirestore.instance;

  Future<List<OfferModel>> getAllOffers() async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.offersCollection)
          .orderBy('sortOrder', descending: false)
          .get();
      return snapshot.docs
          .map((doc) => OfferModel.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('getAllOffers error: $e');
      return [];
    }
  }

  /// Paginated: fetches active offers sorted by sortOrder, using a cursor.
  ///
  /// NOTE: Pagination requires `orderBy` + cursors. If the composite index
  /// is missing, this query will fail and return empty (graceful degradation).
  /// The non-paginated queries (`getActiveOffers`, `streamActiveOffers`)
  /// work without composite indexes via client-side sorting.
  Future<PaginatedOffers> getActiveOffersPaginated({
    DocumentSnapshot? startAfter,
    int limit = 10,
  }) async {
    try {
      var query = _firestore
          .collection(AppConstants.offersCollection)
          .where('isActive', isEqualTo: true)
          .orderBy('sortOrder', descending: false)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();
      final offers = snapshot.docs
          .map((doc) => OfferModel.fromFirestore(doc.data()))
          .toList();

      return PaginatedOffers(
        items: offers,
        lastDoc: offers.length < limit ? null : snapshot.docs.last,
        hasMore: offers.length >= limit,
      );
    } catch (e) {
      debugPrint('getActiveOffersPaginated error: $e');
      return const PaginatedOffers(items: []);
    }
  }

  /// Non-paginated fallback (for admin use).
  Future<List<OfferModel>> getActiveOffers() async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.offersCollection)
          .where('isActive', isEqualTo: true)
          .get();
      final offers = snapshot.docs
          .map((doc) => OfferModel.fromFirestore(doc.data()))
          .toList();
      offers.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return offers;
    } catch (e) {
      debugPrint('getActiveOffers error: $e');
      return [];
    }
  }

  /// Real-time stream of active offers.
  /// Uses client-side sorting to avoid needing a composite index.
  Stream<List<OfferModel>> streamActiveOffers() {
    return _firestore
        .collection(AppConstants.offersCollection)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final offers = snapshot.docs
          .map((doc) => OfferModel.fromFirestore(doc.data()))
          .toList();
      offers.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return offers;
    });
  }

  Future<void> createOffer(OfferModel offer) async {
    await _firestore
        .collection(AppConstants.offersCollection)
        .doc(offer.offerId)
        .set(offer.toFirestore());
  }

  Future<void> updateOffer(OfferModel offer) async {
    await _firestore
        .collection(AppConstants.offersCollection)
        .doc(offer.offerId)
        .update(offer.toFirestore());
  }

  Future<void> deleteOffer(String offerId) async {
    await _firestore
        .collection(AppConstants.offersCollection)
        .doc(offerId)
        .delete();
  }

  Future<void> toggleOfferStatus(String offerId, bool isActive) async {
    await _firestore
        .collection(AppConstants.offersCollection)
        .doc(offerId)
        .update({'isActive': isActive, 'updatedAt': DateTime.now()});
  }
}
