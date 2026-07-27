import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cashspark/core/constants/app_constants.dart';
import 'package:cashspark/data/models/coupon_model.dart';
import 'package:flutter/foundation.dart' show debugPrint;

class CouponFirestoreDataSource {
  final FirebaseFirestore _firestore;

  CouponFirestoreDataSource({FirebaseFirestore? firestoreInstance})
      : _firestore = firestoreInstance ?? FirebaseFirestore.instance;

  CollectionReference get _couponsRef =>
      _firestore.collection(AppConstants.couponsCollection);

  /// Fetch all coupons ordered by sortOrder and createdAt
  Future<List<CouponModel>> getAllCoupons() async {
    try {
      final snapshot = await _couponsRef
          .orderBy('sortOrder', descending: false)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => CouponModel.fromFirestore(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('getAllCoupons error: $e');
      return [];
    }
  }

  /// Fetch only active, non-expired coupons
  Future<List<CouponModel>> getActiveCoupons() async {
    try {
      final now = DateTime.now();
      final snapshot = await _couponsRef
          .where('isActive', isEqualTo: true)
          .orderBy('sortOrder', descending: false)
          .orderBy('createdAt', descending: true)
          .get();

      final coupons = snapshot.docs
          .map((doc) => CouponModel.fromFirestore(doc.data() as Map<String, dynamic>))
          .toList();

      // Filter out expired coupons client-side (Firestore doesn't support complex date filtering easily)
      return coupons.where((c) {
        if (c.expiryDate == null) return true;
        return c.expiryDate!.isAfter(now);
      }).toList();
    } catch (e) {
      debugPrint('getActiveCoupons error: $e');
      return [];
    }
  }

  /// Real-time stream of active coupons
  Stream<List<CouponModel>> streamActiveCoupons() {
    final now = DateTime.now();
    return _couponsRef
        .where('isActive', isEqualTo: true)
        .orderBy('sortOrder', descending: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => CouponModel.fromFirestore(doc.data() as Map<String, dynamic>))
              .where((c) {
                if (c.expiryDate == null) return true;
                return c.expiryDate!.isAfter(now);
              })
              .toList();
        });
  }

  /// Get a single coupon by ID
  Future<CouponModel?> getCoupon(String couponId) async {
    try {
      final doc = await _couponsRef.doc(couponId).get();
      if (!doc.exists || doc.data() == null) return null;
      return CouponModel.fromFirestore(doc.data() as Map<String, dynamic>);
    } catch (e) {
      debugPrint('getCoupon error: $e');
      return null;
    }
  }

  /// Create a new coupon
  Future<void> createCoupon(CouponModel coupon) async {
    await _couponsRef.doc(coupon.couponId).set(coupon.toFirestore());
  }

  /// Update an existing coupon
  Future<void> updateCoupon(CouponModel coupon) async {
    await _couponsRef.doc(coupon.couponId).update(coupon.toFirestore());
  }

  /// Toggle coupon active status
  Future<void> toggleCouponActive(String couponId, bool isActive) async {
    await _couponsRef.doc(couponId).update({
      'isActive': isActive,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Toggle coupon featured status
  Future<void> toggleCouponFeatured(String couponId, bool isFeatured) async {
    await _couponsRef.doc(couponId).update({
      'isFeatured': isFeatured,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Delete a coupon
  Future<void> deleteCoupon(String couponId) async {
    await _couponsRef.doc(couponId).delete();
  }

  /// Check if a coupon with the same brand + offer title already exists (prevent duplicates)
  Future<bool> couponExists(String brandName, String offerTitle) async {
    try {
      final snapshot = await _couponsRef
          .where('brandName', isEqualTo: brandName)
          .where('offerTitle', isEqualTo: offerTitle)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('couponExists error: $e');
      return false;
    }
  }
}
