class CouponEntity {
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

  const CouponEntity({
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

  CouponEntity copyWith({
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
    return CouponEntity(
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
