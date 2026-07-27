import 'package:cashspark/domain/entities/coupon_entity.dart';

abstract class CouponRepository {
  /// Fetch all coupons (admin use)
  Future<List<CouponEntity>> getAllCoupons();

  /// Fetch only active, non-expired coupons
  Future<List<CouponEntity>> getActiveCoupons();

  /// Real-time stream of active coupons
  Stream<List<CouponEntity>> streamActiveCoupons();

  /// Get a single coupon by ID
  Future<CouponEntity?> getCoupon(String couponId);

  /// Create a new coupon
  Future<void> createCoupon(CouponEntity coupon);

  /// Update an existing coupon
  Future<void> updateCoupon(CouponEntity coupon);

  /// Toggle coupon active status
  Future<void> toggleCouponActive(String couponId, bool isActive);

  /// Toggle coupon featured status
  Future<void> toggleCouponFeatured(String couponId, bool isFeatured);

  /// Delete a coupon
  Future<void> deleteCoupon(String couponId);

  /// Check if a duplicate coupon exists
  Future<bool> couponExists(String brandName, String offerTitle);
}
