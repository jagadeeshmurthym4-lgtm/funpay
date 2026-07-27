/// A single streak milestone that grants a reward multiplier.
class StreakMilestoneEntity {
  final String id;
  final int targetStreakDays;
  final double multiplier;
  final String label;
  final bool isActive;

  const StreakMilestoneEntity({
    required this.id,
    required this.targetStreakDays,
    this.multiplier = 1.0,
    this.label = '',
    this.isActive = true,
  });

  StreakMilestoneEntity copyWith({
    String? id,
    int? targetStreakDays,
    double? multiplier,
    String? label,
    bool? isActive,
  }) {
    return StreakMilestoneEntity(
      id: id ?? this.id,
      targetStreakDays: targetStreakDays ?? this.targetStreakDays,
      multiplier: multiplier ?? this.multiplier,
      label: label ?? this.label,
      isActive: isActive ?? this.isActive,
    );
  }
}

/// The global streak multiplier configuration (admin-managed).
class StreakMultiplierConfigEntity {
  final String id;
  final bool isEnabled;
  final bool streakRecoveryEnabled;
  final bool streakRecoveryUsesAd;
  final List<StreakMilestoneEntity> milestones;
  final DateTime? updatedAt;

  const StreakMultiplierConfigEntity({
    required this.id,
    this.isEnabled = true,
    this.streakRecoveryEnabled = true,
    this.streakRecoveryUsesAd = true,
    this.milestones = const [],
    this.updatedAt,
  });

  StreakMultiplierConfigEntity copyWith({
    String? id,
    bool? isEnabled,
    bool? streakRecoveryEnabled,
    bool? streakRecoveryUsesAd,
    List<StreakMilestoneEntity>? milestones,
    DateTime? updatedAt,
  }) {
    return StreakMultiplierConfigEntity(
      id: id ?? this.id,
      isEnabled: isEnabled ?? this.isEnabled,
      streakRecoveryEnabled: streakRecoveryEnabled ?? this.streakRecoveryEnabled,
      streakRecoveryUsesAd: streakRecoveryUsesAd ?? this.streakRecoveryUsesAd,
      milestones: milestones ?? this.milestones,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Returns the multiplier value for a given streak day count.
  double getMultiplierForStreak(int streakDays) {
    double multiplier = 1.0;
    if (!isEnabled) return multiplier;

    final sorted = [...milestones]
      ..sort((a, b) => a.targetStreakDays.compareTo(b.targetStreakDays));

    for (final milestone in sorted) {
      if (!milestone.isActive) continue;
      if (streakDays >= milestone.targetStreakDays) {
        multiplier = milestone.multiplier;
      }
    }
    return multiplier;
  }

  /// Returns the next milestone that the user hasn't reached yet.
  StreakMilestoneEntity? getNextMilestone(int currentStreak) {
    final sorted = [...milestones]
      ..sort((a, b) => a.targetStreakDays.compareTo(b.targetStreakDays));
    for (final m in sorted) {
      if (m.isActive && currentStreak < m.targetStreakDays) return m;
    }
    return null;
  }
}
