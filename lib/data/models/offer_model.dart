import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cashspark/domain/entities/offer_entity.dart';

class OfferModel {
  final String offerId;
  final String title;
  final String subtitle;
  final String iconName;
  final String reward;
  final int colorValue;
  final bool isActive;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  const OfferModel({
    required this.offerId,
    required this.title,
    required this.subtitle,
    required this.iconName,
    required this.reward,
    required this.colorValue,
    this.isActive = true,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OfferModel.fromFirestore(Map<String, dynamic> data) {
    return OfferModel(
      offerId: data['offerId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      subtitle: data['subtitle'] as String? ?? '',
      iconName: data['iconName'] as String? ?? 'stars',
      reward: data['reward'] as String? ?? '₹0',
      colorValue: data['colorValue'] as int? ?? 0xFF4ADE80,
      isActive: data['isActive'] as bool? ?? true,
      sortOrder: data['sortOrder'] as int? ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'offerId': offerId,
      'title': title,
      'subtitle': subtitle,
      'iconName': iconName,
      'reward': reward,
      'colorValue': colorValue,
      'isActive': isActive,
      'sortOrder': sortOrder,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  OfferEntity toEntity() {
    return OfferEntity(
      offerId: offerId,
      title: title,
      subtitle: subtitle,
      iconName: iconName,
      reward: reward,
      colorValue: colorValue,
      isActive: isActive,
      sortOrder: sortOrder,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory OfferModel.fromEntity(OfferEntity entity) {
    return OfferModel(
      offerId: entity.offerId,
      title: entity.title,
      subtitle: entity.subtitle,
      iconName: entity.iconName,
      reward: entity.reward,
      colorValue: entity.colorValue,
      isActive: entity.isActive,
      sortOrder: entity.sortOrder,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
