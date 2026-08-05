enum AdminRole { superAdmin, admin, moderator }

class AdminEntity {
  final String uid;
  final String email;
  final String fullName;
  final AdminRole role;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final bool isActive;

  const AdminEntity({
    required this.uid,
    required this.email,
    required this.fullName,
    this.role = AdminRole.admin,
    required this.createdAt,
    this.lastLoginAt,
    this.isActive = true,
  });

  AdminEntity copyWith({
    String? uid,
    String? email,
    String? fullName,
    AdminRole? role,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isActive,
  }) {
    return AdminEntity(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isActive: isActive ?? this.isActive,
    );
  }
}

class AdminLogEntity {
  final String logId;
  final String adminUid;
  final String action;
  final String targetType;
  final String? targetId;
  final String? details;
  final DateTime createdAt;

  const AdminLogEntity({
    required this.logId,
    required this.adminUid,
    required this.action,
    required this.targetType,
    this.targetId,
    this.details,
    required this.createdAt,
  });
}

class AppSettingsEntity {
  final String id;
  final double minWithdrawalAmount;
  final double maxWithdrawalAmount;
  final double dailyWithdrawalLimit;
  final double referrerBonus;
  final double referredBonus;
  final double adRewardAmount;
  final int dailyAdLimit;
  final double dailyCheckInBaseReward;
  final List<double> streakRewards;
  final double taskRewardAmount;
  final bool isReferralActive;
  final bool isRewardSystemActive;
  final String? announcement;
  final DateTime updatedAt;

  const AppSettingsEntity({
    required this.id,
    this.minWithdrawalAmount = 85.0,
    this.maxWithdrawalAmount = 999999.0,
    this.dailyWithdrawalLimit = 999999.0,
    this.referrerBonus = 10.0,
    this.referredBonus = 4.0,
    this.adRewardAmount = 2.0,
    this.dailyAdLimit = 10,
    this.dailyCheckInBaseReward = 0.10,
    this.streakRewards = const [0.10, 0.15, 0.20, 0.25, 0.30, 0.40, 0.50],
    this.taskRewardAmount = 0.25,
    this.isReferralActive = true,
    this.isRewardSystemActive = true,
    this.announcement,
    required this.updatedAt,
  });

  AppSettingsEntity copyWith({
    String? id,
    double? minWithdrawalAmount,
    double? maxWithdrawalAmount,
    double? dailyWithdrawalLimit,
    double? referrerBonus,
    double? referredBonus,
    double? adRewardAmount,
    int? dailyAdLimit,
    double? dailyCheckInBaseReward,
    List<double>? streakRewards,
    double? taskRewardAmount,
    bool? isReferralActive,
    bool? isRewardSystemActive,
    String? announcement,
    DateTime? updatedAt,
  }) {
    return AppSettingsEntity(
      id: id ?? this.id,
      minWithdrawalAmount: minWithdrawalAmount ?? this.minWithdrawalAmount,
      maxWithdrawalAmount: maxWithdrawalAmount ?? this.maxWithdrawalAmount,
      dailyWithdrawalLimit: dailyWithdrawalLimit ?? this.dailyWithdrawalLimit,
      referrerBonus: referrerBonus ?? this.referrerBonus,
      referredBonus: referredBonus ?? this.referredBonus,
      adRewardAmount: adRewardAmount ?? this.adRewardAmount,
      dailyAdLimit: dailyAdLimit ?? this.dailyAdLimit,
      dailyCheckInBaseReward: dailyCheckInBaseReward ?? this.dailyCheckInBaseReward,
      streakRewards: streakRewards ?? this.streakRewards,
      taskRewardAmount: taskRewardAmount ?? this.taskRewardAmount,
      isReferralActive: isReferralActive ?? this.isReferralActive,
      isRewardSystemActive: isRewardSystemActive ?? this.isRewardSystemActive,
      announcement: announcement ?? this.announcement,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
