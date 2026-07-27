import 'dart:async';
import 'package:cashspark/core/errors/exceptions.dart';
import 'package:cashspark/domain/entities/coupon_entity.dart';
import 'package:cashspark/domain/repositories/coupon_repository.dart';
import 'package:flutter/foundation.dart';

class CouponProvider extends ChangeNotifier {
  final CouponRepository _couponRepository;

  StreamSubscription? _couponSubscription;

  List<CouponEntity> _coupons = [];
  List<CouponEntity> _allCoupons = []; // Admin: all coupons
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  CouponProvider({required CouponRepository couponRepository})
      : _couponRepository = couponRepository;

  List<CouponEntity> get coupons => _coupons;
  List<CouponEntity> get allCoupons => _allCoupons;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  /// Get distinct categories from active coupons
  List<String> get categories {
    final cats = _coupons.map((c) => c.category).toSet().toList();
    cats.sort();
    return cats;
  }

  /// Get coupons by category
  List<CouponEntity> getCouponsByCategory(String category) {
    return _coupons.where((c) => c.category == category).toList();
  }

  /// Get featured coupons
  List<CouponEntity> get featuredCoupons {
    return _coupons.where((c) => c.isFeatured).toList();
  }

  // ─── User Facing ──────────────────────────────────────

  /// Start streaming active coupons (user-facing)
  void listenToCoupons() {
    _couponSubscription?.cancel();
    _setLoading(true);
    _couponSubscription = _couponRepository.streamActiveCoupons().listen(
      (coupons) {
        _coupons = coupons;
        _setLoading(false);
      },
      onError: (error) {
        _errorMessage = 'Failed to load coupons. Please check your connection.';
        _setLoading(false);
      },
    );
  }

  /// Refresh active coupons (one-time fetch)
  Future<void> refreshCoupons() async {
    _setLoading(true);
    _clearMessages();
    try {
      _coupons = await _couponRepository.getActiveCoupons();
    } catch (e) {
      _errorMessage = _friendlyErrorMessage(e, fallback: 'Failed to refresh coupons');
    } finally {
      _setLoading(false);
    }
  }

  // ─── Admin Operations ─────────────────────────────────

  /// Load all coupons (admin)
  Future<void> loadAllCoupons() async {
    _setLoading(true);
    _clearMessages();
    try {
      _allCoupons = await _couponRepository.getAllCoupons();
    } catch (e) {
      _errorMessage = _friendlyErrorMessage(e, fallback: 'Failed to load coupons');
    } finally {
      _setLoading(false);
    }
  }

  /// Create a new coupon (admin)
  Future<bool> createCoupon({
    required String brandName,
    required String category,
    required String offerTitle,
    String? shortDescription,
    required String discountText,
    required String destinationUrl,
    required String imageUrl,
    DateTime? expiryDate,
    bool isFeatured = false,
    bool isActive = true,
    int sortOrder = 0,
  }) async {
    _setLoading(true);
    _clearMessages();
    try {
      // Check for duplicates
      final exists = await _couponRepository.couponExists(brandName, offerTitle);
      if (exists) {
        _errorMessage = 'A coupon with this brand and offer already exists';
        notifyListeners();
        return false;
      }

      final couponId = 'cpn_${DateTime.now().millisecondsSinceEpoch}_${brandName.hashCode.abs()}';
      final coupon = CouponEntity(
        couponId: couponId,
        brandName: brandName,
        category: category,
        offerTitle: offerTitle,
        shortDescription: shortDescription,
        discountText: discountText,
        destinationUrl: destinationUrl,
        imageUrl: imageUrl,
        expiryDate: expiryDate,
        isFeatured: isFeatured,
        isActive: isActive,
        sortOrder: sortOrder,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _couponRepository.createCoupon(coupon);
      _allCoupons.insert(0, coupon);
      _successMessage = 'Coupon created successfully';
      notifyListeners();
      return true;
    } on FirestoreException catch (e) {
      // Repository already returns user-friendly message for known errors like
      // permission-denied. Use the message directly.
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = _friendlyErrorMessage(e, fallback: 'Failed to create coupon');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update a coupon (admin)
  Future<bool> updateCoupon(CouponEntity updated) async {
    _setLoading(true);
    _clearMessages();
    try {
      await _couponRepository.updateCoupon(updated.copyWith(
        updatedAt: DateTime.now(),
      ));
      final idx = _allCoupons.indexWhere((c) => c.couponId == updated.couponId);
      if (idx != -1) {
        _allCoupons[idx] = updated.copyWith(updatedAt: DateTime.now());
      }
      _successMessage = 'Coupon updated';
      notifyListeners();
      return true;
    } on FirestoreException catch (e) {
      // Repository already returns user-friendly message.
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = _friendlyErrorMessage(e, fallback: 'Failed to update coupon');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Toggle coupon active status (admin)
  Future<bool> toggleActive(String couponId, bool isActive) async {
    _clearMessages();
    try {
      await _couponRepository.toggleCouponActive(couponId, isActive);
      final idx = _allCoupons.indexWhere((c) => c.couponId == couponId);
      if (idx != -1) {
        _allCoupons[idx] = _allCoupons[idx].copyWith(
          isActive: isActive,
          updatedAt: DateTime.now(),
        );
      }
      notifyListeners();
      return true;
    } on FirestoreException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = _friendlyErrorMessage(e, fallback: 'Failed to toggle coupon');
      notifyListeners();
      return false;
    }
  }

  /// Delete a coupon (admin)
  Future<bool> deleteCoupon(String couponId) async {
    _clearMessages();
    try {
      await _couponRepository.deleteCoupon(couponId);
      _allCoupons.removeWhere((c) => c.couponId == couponId);
      _successMessage = 'Coupon deleted';
      notifyListeners();
      return true;
    } on FirestoreException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = _friendlyErrorMessage(e, fallback: 'Failed to delete coupon');
      notifyListeners();
      return false;
    }
  }

  /// Maps common Firestore / network errors to user-friendly messages.
  /// Never shows raw error codes like "permission-denied" to the user.
  String _friendlyErrorMessage(Object error, {String? fallback}) {
    final msg = error.toString().toLowerCase();

    if (msg.contains('permission denied') ||
        msg.contains('permission-denied') ||
        msg.contains('permission_denied')) {
      return 'Permission denied: Your admin account does not have permission to perform this operation. '
          'Please contact support to verify your admin access.';
    }
    if (msg.contains('network-request-failed') || msg.contains('network_error')) {
      return 'Network error. Please check your internet connection and try again.';
    }
    if (msg.contains('too-many-requests')) {
      return 'Too many requests. Please wait a moment and try again.';
    }
    if (msg.contains('unavailable') || msg.contains('deadline-exceeded')) {
      return 'Service is temporarily unavailable. Please try again shortly.';
    }

    return fallback ?? 'An unexpected error occurred. Please try again.';
  }

  void clearError() {
    _clearMessages();
  }

  void clearSuccess() {
    _successMessage = null;
    notifyListeners();
  }

  void disposeProvider() {
    _couponSubscription?.cancel();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearMessages() {
    _errorMessage = null;
    _successMessage = null;
  }

  @override
  void dispose() {
    _couponSubscription?.cancel();
    super.dispose();
  }
}
