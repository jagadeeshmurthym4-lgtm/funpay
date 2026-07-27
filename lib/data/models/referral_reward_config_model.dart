import 'package:cashspark/domain/entities/referral_reward_config_entity.dart';

class ReferralRewardConfigModel extends ReferralRewardConfigEntity {
  const ReferralRewardConfigModel({
    required super.id,
    super.referrerBonus = 10.0,
    super.referredBonus = 4.0,
    super.isActive = true,
    required super.updatedAt,
  });

  factory ReferralRewardConfigModel.fromEntity(ReferralRewardConfigEntity entity) {
    return ReferralRewardConfigModel(
      id: entity.id,
      referrerBonus: entity.referrerBonus,
      referredBonus: entity.referredBonus,
      isActive: entity.isActive,
      updatedAt: entity.updatedAt,
    );
  }

  factory ReferralRewardConfigModel.fromFirestore(Map<String, dynamic> map) {
    return ReferralRewardConfigModel(
      id: map['id'] as String? ?? 'default',
      referrerBonus: (map['referrerBonus'] as num?)?.toDouble() ?? 10.0,
      referredBonus: (map['referredBonus'] as num?)?.toDouble() ?? 4.0,
      isActive: map['isActive'] as bool? ?? true,
      updatedAt: (map['updatedAt'] as dynamic)?.toDate() as DateTime? ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'referrerBonus': referrerBonus,
      'referredBonus': referredBonus,
      'isActive': isActive,
      'updatedAt': updatedAt,
    };
  }
}
