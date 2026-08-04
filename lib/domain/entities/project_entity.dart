import 'package:flutter/material.dart';

class ProjectEntity {
  final String projectId;
  final String name;
  final double rewardAmount;
  final String category;
  final String description;
  final int colorValue; // Hex color as int
  final String iconName; // Maps to Icons.* via helper
  final String status; // 'Available', 'New', 'Trending', 'Popular'
  final bool isActive;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProjectEntity({
    required this.projectId,
    required this.name,
    required this.rewardAmount,
    required this.category,
    required this.description,
    required this.colorValue,
    required this.iconName,
    this.status = 'Available',
    this.isActive = true,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  Color get color => Color(colorValue);
  String get reward => '₹${rewardAmount.toStringAsFixed(0)}';

  ProjectEntity copyWith({
    String? projectId,
    String? name,
    double? rewardAmount,
    String? category,
    String? description,
    int? colorValue,
    String? iconName,
    String? status,
    bool? isActive,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProjectEntity(
      projectId: projectId ?? this.projectId,
      name: name ?? this.name,
      rewardAmount: rewardAmount ?? this.rewardAmount,
      category: category ?? this.category,
      description: description ?? this.description,
      colorValue: colorValue ?? this.colorValue,
      iconName: iconName ?? this.iconName,
      status: status ?? this.status,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
