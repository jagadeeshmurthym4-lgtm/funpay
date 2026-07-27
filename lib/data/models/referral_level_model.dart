import 'package:cashspark/domain/entities/referral_level_entity.dart';

class ReferralLevelModel extends ReferralLevelEntity {
  const ReferralLevelModel({
    required super.id,
    required super.levelNumber,
    super.title,
    super.description,
    super.requiredReferrals,
    super.rewardAmount,
    super.badgeIcon,
    super.isActive,
  });

  factory ReferralLevelModel.fromEntity(ReferralLevelEntity entity) {
    return ReferralLevelModel(
      id: entity.id,
      levelNumber: entity.levelNumber,
      title: entity.title,
      description: entity.description,
      requiredReferrals: entity.requiredReferrals,
      rewardAmount: entity.rewardAmount,
      badgeIcon: entity.badgeIcon,
      isActive: entity.isActive,
    );
  }

  factory ReferralLevelModel.fromFirestore(Map<String, dynamic> map) {
    return ReferralLevelModel(
      id: map['id'] as String? ?? '',
      levelNumber: map['levelNumber'] as int? ?? 0,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      requiredReferrals: map['requiredReferrals'] as int? ?? 0,
      rewardAmount: (map['rewardAmount'] as num?)?.toDouble() ?? 0.0,
      badgeIcon: map['badgeIcon'] as String? ?? '🏆',
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'levelNumber': levelNumber,
      'title': title,
      'description': description,
      'requiredReferrals': requiredReferrals,
      'rewardAmount': rewardAmount,
      'badgeIcon': badgeIcon,
      'isActive': isActive,
    };
  }
}

class ClaimedMilestoneModel extends ClaimedMilestoneEntity {
  const ClaimedMilestoneModel({
    required super.id,
    required super.userId,
    required super.levelNumber,
    required super.claimedAt,
  });

  factory ClaimedMilestoneModel.fromEntity(ClaimedMilestoneEntity entity) {
    return ClaimedMilestoneModel(
      id: entity.id,
      userId: entity.userId,
      levelNumber: entity.levelNumber,
      claimedAt: entity.claimedAt,
    );
  }

  factory ClaimedMilestoneModel.fromFirestore(Map<String, dynamic> map) {
    return ClaimedMilestoneModel(
      id: map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      levelNumber: map['levelNumber'] as int? ?? 0,
      claimedAt: (map['claimedAt'] as dynamic)?.toDate() as DateTime? ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'userId': userId,
      'levelNumber': levelNumber,
      'claimedAt': claimedAt,
    };
  }
}
