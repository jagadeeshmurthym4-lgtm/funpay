import 'package:cashspark/domain/entities/banner_entity.dart';

class BannerModel extends BannerEntity {
  const BannerModel({
    required super.bannerId,
    required super.title,
    required super.subtitle,
    required super.imageUrl,
    super.linkUrl,
    super.actionLabel,
    super.sortOrder = 0,
    super.isActive = true,
    required super.createdAt,
  });

  factory BannerModel.fromEntity(BannerEntity entity) {
    return BannerModel(
      bannerId: entity.bannerId,
      title: entity.title,
      subtitle: entity.subtitle,
      imageUrl: entity.imageUrl,
      linkUrl: entity.linkUrl,
      actionLabel: entity.actionLabel,
      sortOrder: entity.sortOrder,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
    );
  }

  factory BannerModel.fromFirestore(Map<String, dynamic> map) {
    return BannerModel(
      bannerId: map['bannerId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      subtitle: map['subtitle'] as String? ?? '',
      imageUrl: map['imageUrl'] as String? ?? '',
      linkUrl: map['linkUrl'] as String?,
      actionLabel: map['actionLabel'] as String?,
      sortOrder: (map['sortOrder'] as num?)?.toInt() ?? 0,
      isActive: map['isActive'] as bool? ?? true,
      createdAt: (map['createdAt'] as dynamic)?.toDate() as DateTime? ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'bannerId': bannerId,
      'title': title,
      'subtitle': subtitle,
      'imageUrl': imageUrl,
      if (linkUrl != null) 'linkUrl': linkUrl,
      if (actionLabel != null) 'actionLabel': actionLabel,
      'sortOrder': sortOrder,
      'isActive': isActive,
      'createdAt': createdAt,
    };
  }

  BannerModel copyWithModel({
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
    return BannerModel(
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
