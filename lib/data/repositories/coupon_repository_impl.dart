import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cashspark/core/errors/exceptions.dart';
import 'package:cashspark/data/datasources/coupon_firestore_datasource.dart';
import 'package:cashspark/data/models/coupon_model.dart';
import 'package:cashspark/domain/entities/coupon_entity.dart';
import 'package:cashspark/domain/repositories/coupon_repository.dart';

class CouponRepositoryImpl implements CouponRepository {
  final CouponFirestoreDataSource _dataSource;

  CouponRepositoryImpl({required CouponFirestoreDataSource dataSource})
      : _dataSource = dataSource;

  /// Extracts a user-friendly error message from a caught exception.
  /// If the error is a FirebaseException with code 'permission-denied',
  /// returns a clear message indicating the admin check likely failed.
  String _friendlyError(String operation, Object error) {
    if (error is FirebaseException &&
        (error.code == 'permission-denied' ||
         error.code == 'PermissionDenied')) {
      return 'Permission denied: Your admin account does not have permission to $operation coupons. '
          'Please ensure your UID is registered in the admins collection with isActive=true.';
    }
    if (error is FirebaseException &&
        (error.code == 'unavailable' || error.code == 'deadline-exceeded')) {
      return 'Service temporarily unavailable. Please try again shortly.';
    }
    return '$error';
  }

  @override
  Future<List<CouponEntity>> getAllCoupons() async {
    try {
      final models = await _dataSource.getAllCoupons();
      return models.map((m) => m.toEntity()).toList();
    } catch (e) {
      throw FirestoreException(_friendlyError('fetch', e));
    }
  }

  @override
  Future<List<CouponEntity>> getActiveCoupons() async {
    try {
      final models = await _dataSource.getActiveCoupons();
      return models.map((m) => m.toEntity()).toList();
    } catch (e) {
      throw FirestoreException(_friendlyError('fetch', e));
    }
  }

  @override
  Stream<List<CouponEntity>> streamActiveCoupons() {
    return _dataSource.streamActiveCoupons().map(
      (models) => models.map((m) => m.toEntity()).toList(),
    );
  }

  @override
  Future<CouponEntity?> getCoupon(String couponId) async {
    try {
      final model = await _dataSource.getCoupon(couponId);
      return model?.toEntity();
    } catch (e) {
      throw FirestoreException(_friendlyError('get', e));
    }
  }

  @override
  Future<void> createCoupon(CouponEntity coupon) async {
    try {
      final model = CouponModel.fromEntity(coupon);
      await _dataSource.createCoupon(model);
    } catch (e) {
      throw FirestoreException(_friendlyError('create', e));
    }
  }

  @override
  Future<void> updateCoupon(CouponEntity coupon) async {
    try {
      final model = CouponModel.fromEntity(coupon);
      await _dataSource.updateCoupon(model);
    } catch (e) {
      throw FirestoreException(_friendlyError('update', e));
    }
  }

  @override
  Future<void> toggleCouponActive(String couponId, bool isActive) async {
    try {
      await _dataSource.toggleCouponActive(couponId, isActive);
    } catch (e) {
      throw FirestoreException(_friendlyError('toggle', e));
    }
  }

  @override
  Future<void> toggleCouponFeatured(String couponId, bool isFeatured) async {
    try {
      await _dataSource.toggleCouponFeatured(couponId, isFeatured);
    } catch (e) {
      throw FirestoreException(_friendlyError('toggle', e));
    }
  }

  @override
  Future<void> deleteCoupon(String couponId) async {
    try {
      await _dataSource.deleteCoupon(couponId);
    } catch (e) {
      throw FirestoreException(_friendlyError('delete', e));
    }
  }

  @override
  Future<bool> couponExists(String brandName, String offerTitle) async {
    try {
      return await _dataSource.couponExists(brandName, offerTitle);
    } catch (e) {
      return false;
    }
  }
}
