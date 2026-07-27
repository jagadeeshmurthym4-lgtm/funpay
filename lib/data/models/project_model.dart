import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cashspark/domain/entities/project_entity.dart';

class ProjectModel {
  final String projectId;
  final String name;
  final double rewardAmount;
  final String category;
  final String description;
  final int colorValue;
  final String iconName;
  final String status;
  final bool isActive;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProjectModel({
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

  factory ProjectModel.fromFirestore(Map<String, dynamic> data) {
    return ProjectModel(
      projectId: data['projectId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      rewardAmount: (data['rewardAmount'] as num?)?.toDouble() ?? 0.0,
      category: data['category'] as String? ?? 'General',
      description: data['description'] as String? ?? '',
      colorValue: data['colorValue'] as int? ?? 0xFF4ADE80,
      iconName: data['iconName'] as String? ?? 'app_shortcut',
      status: data['status'] as String? ?? 'Available',
      isActive: data['isActive'] as bool? ?? true,
      sortOrder: data['sortOrder'] as int? ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'projectId': projectId,
      'name': name,
      'rewardAmount': rewardAmount,
      'category': category,
      'description': description,
      'colorValue': colorValue,
      'iconName': iconName,
      'status': status,
      'isActive': isActive,
      'sortOrder': sortOrder,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  ProjectEntity toEntity() {
    return ProjectEntity(
      projectId: projectId,
      name: name,
      rewardAmount: rewardAmount,
      category: category,
      description: description,
      colorValue: colorValue,
      iconName: iconName,
      status: status,
      isActive: isActive,
      sortOrder: sortOrder,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory ProjectModel.fromEntity(ProjectEntity entity) {
    return ProjectModel(
      projectId: entity.projectId,
      name: entity.name,
      rewardAmount: entity.rewardAmount,
      category: entity.category,
      description: entity.description,
      colorValue: entity.colorValue,
      iconName: entity.iconName,
      status: entity.status,
      isActive: entity.isActive,
      sortOrder: entity.sortOrder,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
