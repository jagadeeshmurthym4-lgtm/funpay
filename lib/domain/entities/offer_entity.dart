import 'package:flutter/material.dart';

class OfferEntity {
  final String offerId;
  final String title;
  final String subtitle;
  final String iconName; // Maps to Icons.* via helper
  final String reward;
  final int colorValue; // Hex color as int
  final bool isActive;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  const OfferEntity({
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

  Color get color => Color(colorValue);

  OfferEntity copyWith({
    String? offerId,
    String? title,
    String? subtitle,
    String? iconName,
    String? reward,
    int? colorValue,
    bool? isActive,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OfferEntity(
      offerId: offerId ?? this.offerId,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      iconName: iconName ?? this.iconName,
      reward: reward ?? this.reward,
      colorValue: colorValue ?? this.colorValue,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
