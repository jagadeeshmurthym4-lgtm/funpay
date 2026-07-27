import 'package:cashspark/domain/entities/referral_entity.dart';

class ReferralModel extends ReferralEntity {
  const ReferralModel({
    required super.referralId,
    required super.referrerUserId,
    required super.referredUserId,
    required super.referralCode,
    super.rewardAmount = 0.0,
    super.status = ReferralStatus.pending,
    required super.createdAt,
    super.firstProjectRewarded = false,
    super.firstProjectId,
    super.firstProjectRewardDate,
    super.lifetimeProjectCommission = 0.0,
    super.rewardedProjectIds = const [],
    super.approvedProjectCount = 0,
    super.signupBonusCredited = false,
  });

  factory ReferralModel.fromEntity(ReferralEntity entity) {
    return ReferralModel(
      referralId: entity.referralId,
      referrerUserId: entity.referrerUserId,
      referredUserId: entity.referredUserId,
      referralCode: entity.referralCode,
      rewardAmount: entity.rewardAmount,
      status: entity.status,
      createdAt: entity.createdAt,
      firstProjectRewarded: entity.firstProjectRewarded,
      firstProjectId: entity.firstProjectId,
      firstProjectRewardDate: entity.firstProjectRewardDate,
      lifetimeProjectCommission: entity.lifetimeProjectCommission,
      rewardedProjectIds: entity.rewardedProjectIds,
      approvedProjectCount: entity.approvedProjectCount,
    );
  }

  factory ReferralModel.fromFirestore(Map<String, dynamic> map) {
    return ReferralModel(
      referralId: map['referralId'] as String? ?? '',
      referrerUserId: map['referrerUserId'] as String? ?? '',
      referredUserId: map['referredUserId'] as String? ?? '',
      referralCode: map['referralCode'] as String? ?? '',
      rewardAmount: (map['rewardAmount'] as num?)?.toDouble() ?? 0.0,
      status: _parseStatus(map['status'] as String? ?? 'pending'),
      createdAt: (map['createdAt'] as dynamic)?.toDate() as DateTime? ?? DateTime.now(),
      firstProjectRewarded: map['firstProjectRewarded'] as bool? ?? false,
      firstProjectId: map['firstProjectId'] as String?,
      firstProjectRewardDate: (map['firstProjectRewardDate'] as dynamic)?.toDate() as DateTime?,
      lifetimeProjectCommission: (map['lifetimeProjectCommission'] as num?)?.toDouble() ?? 0.0,
      rewardedProjectIds: (map['rewardedProjectIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      approvedProjectCount: map['approvedProjectCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'referralId': referralId,
      'referrerUserId': referrerUserId,
      'referredUserId': referredUserId,
      'referralCode': referralCode,
      'rewardAmount': rewardAmount,
      'status': status.name,
      'createdAt': createdAt,
      'firstProjectRewarded': firstProjectRewarded,
      if (firstProjectId != null) 'firstProjectId': firstProjectId,
      if (firstProjectRewardDate != null) 'firstProjectRewardDate': firstProjectRewardDate,
      'lifetimeProjectCommission': lifetimeProjectCommission,
      'rewardedProjectIds': rewardedProjectIds,
      'approvedProjectCount': approvedProjectCount,
      'signupBonusCredited': signupBonusCredited,
    };
  }

  ReferralModel copyWithModel({
    String? referralId,
    String? referrerUserId,
    String? referredUserId,
    String? referralCode,
    double? rewardAmount,
    ReferralStatus? status,
    DateTime? createdAt,
    bool? firstProjectRewarded,
    String? firstProjectId,
    DateTime? firstProjectRewardDate,
    double? lifetimeProjectCommission,
    List<String>? rewardedProjectIds,
    int? approvedProjectCount,
    bool? signupBonusCredited,
  }) {
    return ReferralModel(
      referralId: referralId ?? this.referralId,
      referrerUserId: referrerUserId ?? this.referrerUserId,
      referredUserId: referredUserId ?? this.referredUserId,
      referralCode: referralCode ?? this.referralCode,
      rewardAmount: rewardAmount ?? this.rewardAmount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      firstProjectRewarded: firstProjectRewarded ?? this.firstProjectRewarded,
      firstProjectId: firstProjectId ?? this.firstProjectId,
      firstProjectRewardDate: firstProjectRewardDate ?? this.firstProjectRewardDate,
      lifetimeProjectCommission: lifetimeProjectCommission ?? this.lifetimeProjectCommission,
      rewardedProjectIds: rewardedProjectIds ?? this.rewardedProjectIds,
      approvedProjectCount: approvedProjectCount ?? this.approvedProjectCount,
      signupBonusCredited: signupBonusCredited ?? this.signupBonusCredited,
    );
  }

  static ReferralStatus _parseStatus(String value) {
    return ReferralStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ReferralStatus.pending,
    );
  }
}
