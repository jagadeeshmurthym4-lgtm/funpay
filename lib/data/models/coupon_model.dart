import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cashspark/domain/entities/coupon_entity.dart';

class CouponModel {
  final String couponId;
  final String brandName;
  final String category;
  final String offerTitle;
  final String? shortDescription;
  final String discountText;
  final String destinationUrl;
  final String imageUrl;
  final DateTime? expiryDate;
  final bool isFeatured;
  final bool isActive;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CouponModel({
    required this.couponId,
    required this.brandName,
    required this.category,
    required this.offerTitle,
    this.shortDescription,
    required this.discountText,
    required this.destinationUrl,
    required this.imageUrl,
    this.expiryDate,
    this.isFeatured = false,
    this.isActive = true,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CouponModel.fromFirestore(Map<String, dynamic> data) {
    return CouponModel(
      couponId: data['couponId'] as String? ?? '',
      brandName: data['brandName'] as String? ?? '',
      category: data['category'] as String? ?? 'Other',
      offerTitle: data['offerTitle'] as String? ?? '',
      shortDescription: data['shortDescription'] as String?,
      discountText: data['discountText'] as String? ?? '',
      destinationUrl: data['destinationUrl'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      expiryDate: (data['expiryDate'] as Timestamp?)?.toDate(),
      isFeatured: data['isFeatured'] as bool? ?? false,
      isActive: data['isActive'] as bool? ?? true,
      sortOrder: data['sortOrder'] as int? ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'couponId': couponId,
      'brandName': brandName,
      'category': category,
      'offerTitle': offerTitle,
      'shortDescription': shortDescription,
      'discountText': discountText,
      'destinationUrl': destinationUrl,
      'imageUrl': imageUrl,
      'expiryDate': expiryDate != null ? Timestamp.fromDate(expiryDate!) : null,
      'isFeatured': isFeatured,
      'isActive': isActive,
      'sortOrder': sortOrder,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  CouponEntity toEntity() {
    return CouponEntity(
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
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory CouponModel.fromEntity(CouponEntity entity) {
    return CouponModel(
      couponId: entity.couponId,
      brandName: entity.brandName,
      category: entity.category,
      offerTitle: entity.offerTitle,
      shortDescription: entity.shortDescription,
      discountText: entity.discountText,
      destinationUrl: entity.destinationUrl,
      imageUrl: entity.imageUrl,
      expiryDate: entity.expiryDate,
      isFeatured: entity.isFeatured,
      isActive: entity.isActive,
      sortOrder: entity.sortOrder,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  CouponModel copyWithModel({
    String? couponId,
    String? brandName,
    String? category,
    String? offerTitle,
    String? shortDescription,
    String? discountText,
    String? destinationUrl,
    String? imageUrl,
    DateTime? expiryDate,
    bool? isFeatured,
    bool? isActive,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CouponModel(
      couponId: couponId ?? this.couponId,
      brandName: brandName ?? this.brandName,
      category: category ?? this.category,
      offerTitle: offerTitle ?? this.offerTitle,
      shortDescription: shortDescription ?? this.shortDescription,
      discountText: discountText ?? this.discountText,
      destinationUrl: destinationUrl ?? this.destinationUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      expiryDate: expiryDate ?? this.expiryDate,
      isFeatured: isFeatured ?? this.isFeatured,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
