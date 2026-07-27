class BannerEntity {
  final String bannerId;
  final String title;
  final String subtitle;
  final String imageUrl;
  final String? linkUrl;
  final String? actionLabel;
  final int sortOrder;
  final bool isActive;
  final DateTime createdAt;

  const BannerEntity({
    required this.bannerId,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    this.linkUrl,
    this.actionLabel,
    this.sortOrder = 0,
    this.isActive = true,
    required this.createdAt,
  });

  BannerEntity copyWith({
    String? bannerId,
    String? title,
    String? subtitle,
    String? imageUrl,
    String? linkUrl,
    String? actionLabel,
    int? sortOrder,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return BannerEntity(
      bannerId: bannerId ?? this.bannerId,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      imageUrl: imageUrl ?? this.imageUrl,
      linkUrl: linkUrl ?? this.linkUrl,
      actionLabel: actionLabel ?? this.actionLabel,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
