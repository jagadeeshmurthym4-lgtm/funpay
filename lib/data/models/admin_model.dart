import 'package:cashspark/domain/entities/admin_entity.dart';

class AdminModel extends AdminEntity {
  const AdminModel({
    required super.uid,
    required super.email,
    required super.fullName,
    super.role = AdminRole.admin,
    required super.createdAt,
    super.lastLoginAt,
    super.isActive = true,
  });

  AdminModel copyWithModel({
    String? uid,
    String? email,
    String? fullName,
    AdminRole? role,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isActive,
  }) {
    return AdminModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isActive: isActive ?? this.isActive,
    );
  }

  factory AdminModel.fromEntity(AdminEntity entity) {
    return AdminModel(
      uid: entity.uid,
      email: entity.email,
      fullName: entity.fullName,
      role: entity.role,
      createdAt: entity.createdAt,
      lastLoginAt: entity.lastLoginAt,
      isActive: entity.isActive,
    );
  }

  factory AdminModel.fromFirestore(Map<String, dynamic> map) {
    return AdminModel(
      uid: map['uid'] as String? ?? '',
      email: map['email'] as String? ?? '',
      fullName: map['fullName'] as String? ?? '',
      role: _parseRole(map['role'] as String? ?? 'admin'),
      createdAt: (map['createdAt'] as dynamic)?.toDate() as DateTime? ?? DateTime.now(),
      lastLoginAt: (map['lastLoginAt'] as dynamic)?.toDate() as DateTime?,
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'role': role.name,
      'createdAt': createdAt,
      if (lastLoginAt != null) 'lastLoginAt': lastLoginAt,
      'isActive': isActive,
    };
  }

  static AdminRole _parseRole(String value) {
    return AdminRole.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AdminRole.admin,
    );
  }
}

class AdminLogModel extends AdminLogEntity {
  const AdminLogModel({
    required super.logId,
    required super.adminUid,
    required super.action,
    required super.targetType,
    super.targetId,
    super.details,
    required super.createdAt,
  });

  factory AdminLogModel.fromFirestore(Map<String, dynamic> map) {
    return AdminLogModel(
      logId: map['logId'] as String? ?? '',
      adminUid: map['adminUid'] as String? ?? '',
      action: map['action'] as String? ?? '',
      targetType: map['targetType'] as String? ?? '',
      targetId: map['targetId'] as String?,
      details: map['details'] as String?,
      createdAt: (map['createdAt'] as dynamic)?.toDate() as DateTime? ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'logId': logId,
      'adminUid': adminUid,
      'action': action,
      'targetType': targetType,
      if (targetId != null) 'targetId': targetId,
      if (details != null) 'details': details,
      'createdAt': createdAt,
    };
  }
}

class AppSettingsModel extends AppSettingsEntity {
  const AppSettingsModel({
    required super.id,
    super.minWithdrawalAmount = 45.0,
    super.maxWithdrawalAmount = 999999.0,
    super.dailyWithdrawalLimit = 999999.0,
    super.referrerBonus = 10.0,
    super.referredBonus = 4.0,
    super.adRewardAmount = 2.0,
    super.dailyAdLimit = 10,
    super.dailyCheckInBaseReward = 0.10,
    super.streakRewards,
    super.taskRewardAmount = 0.25,
    super.isReferralActive = true,
    super.isRewardSystemActive = true,
    super.announcement,
    required super.updatedAt,
  });

  AppSettingsModel copyWithModel({
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
    return AppSettingsModel(
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

  factory AppSettingsModel.fromFirestore(Map<String, dynamic> map) {
    return AppSettingsModel(
      id: map['id'] as String? ?? 'settings',
      minWithdrawalAmount: (map['minWithdrawalAmount'] as num?)?.toDouble() ?? 45.0,
      maxWithdrawalAmount: (map['maxWithdrawalAmount'] as num?)?.toDouble() ?? 999999.0,
      dailyWithdrawalLimit: (map['dailyWithdrawalLimit'] as num?)?.toDouble() ?? 999999.0,
      referrerBonus: (map['referrerBonus'] as num?)?.toDouble() ?? 10.0,
      referredBonus: (map['referredBonus'] as num?)?.toDouble() ?? 4.0,
      adRewardAmount: (map['adRewardAmount'] as num?)?.toDouble() ?? 2.0,
      dailyAdLimit: map['dailyAdLimit'] as int? ?? 10,
      dailyCheckInBaseReward: (map['dailyCheckInBaseReward'] as num?)?.toDouble() ?? 0.10,
      taskRewardAmount: (map['taskRewardAmount'] as num?)?.toDouble() ?? 0.25,
      isReferralActive: map['isReferralActive'] as bool? ?? true,
      isRewardSystemActive: map['isRewardSystemActive'] as bool? ?? true,
      announcement: map['announcement'] as String?,
      updatedAt: (map['updatedAt'] as dynamic)?.toDate() as DateTime? ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'minWithdrawalAmount': minWithdrawalAmount,
      'maxWithdrawalAmount': maxWithdrawalAmount,
      'dailyWithdrawalLimit': dailyWithdrawalLimit,
      'referrerBonus': referrerBonus,
      'referredBonus': referredBonus,
      'adRewardAmount': adRewardAmount,
      'dailyAdLimit': dailyAdLimit,
      'dailyCheckInBaseReward': dailyCheckInBaseReward,
      'taskRewardAmount': taskRewardAmount,
      'isReferralActive': isReferralActive,
      'isRewardSystemActive': isRewardSystemActive,
      if (announcement != null) 'announcement': announcement,
      'updatedAt': updatedAt,
    };
  }
}
