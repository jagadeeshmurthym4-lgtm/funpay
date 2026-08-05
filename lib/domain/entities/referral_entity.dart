enum ReferralStatus { pending, completed, rewarded, cancelled }

class ReferralEntity {
  final String referralId;
  final String referrerUserId;
  final String referredUserId;
  final String referralCode;
  final double rewardAmount;
  final ReferralStatus status;
  final DateTime createdAt;

  // ─── New referral system fields ──────────────────────────
  /// Whether the ₹7 first-approved-project bonus has been rewarded.
  final bool firstProjectRewarded;
  /// The project ID of the first approved project that triggered the ₹7 bonus.
  final String? firstProjectId;
  /// When the ₹7 first-project bonus was rewarded.
  final DateTime? firstProjectRewardDate;
  /// Lifetime 5% commission earned from this referred user's approved projects.
  final double lifetimeProjectCommission;
  /// IDs of projects that have generated commission rewards (for dedup).
  final List<String> rewardedProjectIds;
  /// How many approved projects the referred user has completed.
  final int approvedProjectCount;

  /// Whether the ₹10 sign-up bonus has been credited to the referrer.
  /// Used as a guard flag to prevent double-credit if the server-side
  /// `onReferralCreated` Cloud Function is deployed later.
  final bool signupBonusCredited;

  const ReferralEntity({
    required this.referralId,
    required this.referrerUserId,
    required this.referredUserId,
    required this.referralCode,
    this.rewardAmount = 0.0,
    this.status = ReferralStatus.pending,
    required this.createdAt,
    this.firstProjectRewarded = false,
    this.firstProjectId,
    this.firstProjectRewardDate,
    this.lifetimeProjectCommission = 0.0,
    this.rewardedProjectIds = const [],
    this.approvedProjectCount = 0,
    this.signupBonusCredited = false,
  });

  ReferralEntity copyWith({
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
    return ReferralEntity(
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
}
