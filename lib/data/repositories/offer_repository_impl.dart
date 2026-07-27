import 'package:cashspark/data/datasources/offer_firestore_datasource.dart';
import 'package:cashspark/data/models/offer_model.dart';
import 'package:cashspark/domain/entities/offer_entity.dart';
import 'package:cashspark/domain/repositories/offer_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OfferRepositoryImpl implements OfferRepository {
  final OfferFirestoreDataSource _dataSource;

  OfferRepositoryImpl({
    required OfferFirestoreDataSource dataSource,
  }) : _dataSource = dataSource;

  @override
  Future<List<OfferEntity>> getActiveOffers() async {
    final models = await _dataSource.getActiveOffers();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<OfferEntity>> getAllOffers() async {
    final models = await _dataSource.getAllOffers();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<PaginatedOfferResult> getActiveOffersPaginated({
    DocumentSnapshot? startAfter,
    int limit = 10,
  }) async {
    final result = await _dataSource.getActiveOffersPaginated(
      startAfter: startAfter,
      limit: limit,
    );
    return PaginatedOfferResult(
      items: result.items.map((m) => m.toEntity()).toList(),
      lastDoc: result.lastDoc,
      hasMore: result.hasMore,
    );
  }

  @override
  Stream<List<OfferEntity>> streamActiveOffers() {
    return _dataSource.streamActiveOffers().map((models) =>
        models.map((m) => m.toEntity()).toList());
  }

  @override
  Future<void> createOffer(OfferEntity offer) async {
    final model = OfferModel.fromEntity(offer);
    await _dataSource.createOffer(model);
  }

  @override
  Future<void> updateOffer(OfferEntity offer) async {
    final model = OfferModel.fromEntity(offer);
    await _dataSource.updateOffer(model);
  }

  @override
  Future<void> deleteOffer(String offerId) async {
    await _dataSource.deleteOffer(offerId);
  }

  @override
  Future<void> toggleOfferStatus(String offerId, bool isActive) async {
    await _dataSource.toggleOfferStatus(offerId, isActive);
  }
}
