import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cashspark/domain/entities/offer_entity.dart';

/// Result of a paginated offer query.
class PaginatedOfferResult {
  final List<OfferEntity> items;
  final DocumentSnapshot? lastDoc;
  final bool hasMore;

  const PaginatedOfferResult({
    required this.items,
    this.lastDoc,
    this.hasMore = false,
  });
}

abstract class OfferRepository {
  Future<List<OfferEntity>> getActiveOffers();
  Future<List<OfferEntity>> getAllOffers();

  /// Paginated variant using Firestore cursor-based pagination.
  Future<PaginatedOfferResult> getActiveOffersPaginated({
    DocumentSnapshot? startAfter,
    int limit = 10,
  });

  Stream<List<OfferEntity>> streamActiveOffers();

  Future<void> createOffer(OfferEntity offer);
  Future<void> updateOffer(OfferEntity offer);
  Future<void> deleteOffer(String offerId);
  Future<void> toggleOfferStatus(String offerId, bool isActive);
}
