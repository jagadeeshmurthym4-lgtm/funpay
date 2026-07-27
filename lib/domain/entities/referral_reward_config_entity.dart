class ReferralRewardConfigEntity {
  final String id;
  final double referrerBonus;
  final double referredBonus;
  final bool isActive;
  final DateTime? updatedAt;

  const ReferralRewardConfigEntity({
    required this.id,
    this.referrerBonus = 10.0,
    this.referredBonus = 4.0,
    this.isActive = true,
    this.updatedAt,
  });

  ReferralRewardConfigEntity copyWith({
    String? id,
    double? referrerBonus,
    double? referredBonus,
    bool? isActive,
    DateTime? updatedAt,
  }) {
    return ReferralRewardConfigEntity(
      id: id ?? this.id,
      referrerBonus: referrerBonus ?? this.referrerBonus,
      referredBonus: referredBonus ?? this.referredBonus,
      isActive: isActive ?? this.isActive,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
