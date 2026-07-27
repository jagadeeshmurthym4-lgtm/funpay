/// A single referral milestone level definition (configured by admin).
class ReferralLevelEntity {
  final String id;
  final int levelNumber;
  final String title;
  final String description;
  final int requiredReferrals;
  final double rewardAmount;
  final String badgeIcon;
  final bool isActive;

  const ReferralLevelEntity({
    required this.id,
    required this.levelNumber,
    this.title = '',
    this.description = '',
    this.requiredReferrals = 0,
    this.rewardAmount = 0.0,
    this.badgeIcon = '🏆',
    this.isActive = true,
  });

  ReferralLevelEntity copyWith({
    String? id,
    int? levelNumber,
    String? title,
    String? description,
    int? requiredReferrals,
    double? rewardAmount,
    String? badgeIcon,
    bool? isActive,
  }) {
    return ReferralLevelEntity(
      id: id ?? this.id,
      levelNumber: levelNumber ?? this.levelNumber,
      title: title ?? this.title,
      description: description ?? this.description,
      requiredReferrals: requiredReferrals ?? this.requiredReferrals,
      rewardAmount: rewardAmount ?? this.rewardAmount,
      badgeIcon: badgeIcon ?? this.badgeIcon,
      isActive: isActive ?? this.isActive,
    );
  }
}

/// Which levels a user has already claimed (one-time milestone rewards).
class ClaimedMilestoneEntity {
  final String id;
  final String userId;
  final int levelNumber;
  final DateTime claimedAt;

  const ClaimedMilestoneEntity({
    required this.id,
    required this.userId,
    required this.levelNumber,
    required this.claimedAt,
  });
}
