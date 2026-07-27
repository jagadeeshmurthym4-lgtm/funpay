import 'package:cashspark/domain/entities/streak_multiplier_entity.dart';

class StreakMilestoneModel extends StreakMilestoneEntity {
  const StreakMilestoneModel({
    required super.id,
    required super.targetStreakDays,
    super.multiplier,
    super.label,
    super.isActive,
  });

  factory StreakMilestoneModel.fromEntity(StreakMilestoneEntity entity) {
    return StreakMilestoneModel(
      id: entity.id,
      targetStreakDays: entity.targetStreakDays,
      multiplier: entity.multiplier,
      label: entity.label,
      isActive: entity.isActive,
    );
  }

  factory StreakMilestoneModel.fromFirestore(Map<String, dynamic> map) {
    return StreakMilestoneModel(
      id: map['id'] as String? ?? '',
      targetStreakDays: map['targetStreakDays'] as int? ?? 0,
      multiplier: (map['multiplier'] as num?)?.toDouble() ?? 1.0,
      label: map['label'] as String? ?? '',
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'targetStreakDays': targetStreakDays,
      'multiplier': multiplier,
      'label': label,
      'isActive': isActive,
    };
  }
}

class StreakMultiplierConfigModel extends StreakMultiplierConfigEntity {
  const StreakMultiplierConfigModel({
    required super.id,
    super.isEnabled,
    super.streakRecoveryEnabled,
    super.streakRecoveryUsesAd,
    super.milestones,
    super.updatedAt,
  });

  factory StreakMultiplierConfigModel.fromEntity(StreakMultiplierConfigEntity entity) {
    return StreakMultiplierConfigModel(
      id: entity.id,
      isEnabled: entity.isEnabled,
      streakRecoveryEnabled: entity.streakRecoveryEnabled,
      streakRecoveryUsesAd: entity.streakRecoveryUsesAd,
      milestones: entity.milestones
          .map((m) => m is StreakMilestoneModel
              ? m
              : StreakMilestoneModel.fromEntity(m))
          .toList(),
      updatedAt: entity.updatedAt,
    );
  }

  factory StreakMultiplierConfigModel.fromFirestore(Map<String, dynamic> map) {
    final milestonesList = (map['milestones'] as List<dynamic>?)
            ?.map((e) =>
                StreakMilestoneModel.fromFirestore(e as Map<String, dynamic>))
            .toList() ??
        [];
    return StreakMultiplierConfigModel(
      id: map['id'] as String? ?? 'config',
      isEnabled: map['isEnabled'] as bool? ?? true,
      streakRecoveryEnabled: map['streakRecoveryEnabled'] as bool? ?? true,
      streakRecoveryUsesAd: map['streakRecoveryUsesAd'] as bool? ?? true,
      milestones: milestonesList,
      updatedAt: (map['updatedAt'] as dynamic)?.toDate() as DateTime?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'isEnabled': isEnabled,
      'streakRecoveryEnabled': streakRecoveryEnabled,
      'streakRecoveryUsesAd': streakRecoveryUsesAd,
      'milestones':
          milestones.map((m) => StreakMilestoneModel.fromEntity(m).toFirestore()).toList(),
      if (updatedAt != null) 'updatedAt': updatedAt,
    };
  }

}
