import 'package:cashspark/domain/entities/reward_entity.dart';

class RewardModel extends RewardEntity {
  const RewardModel({
    required super.rewardId,
    required super.userId,
    required super.rewardType,
    super.rewardAmount = 0.0,
    super.status = RewardStatus.pending,
    required super.createdAt,
    super.claimedAt,
  });

  factory RewardModel.fromEntity(RewardEntity entity) {
    return RewardModel(
      rewardId: entity.rewardId,
      userId: entity.userId,
      rewardType: entity.rewardType,
      rewardAmount: entity.rewardAmount,
      status: entity.status,
      createdAt: entity.createdAt,
      claimedAt: entity.claimedAt,
    );
  }

  factory RewardModel.fromFirestore(Map<String, dynamic> map) {
    return RewardModel(
      rewardId: map['rewardId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      rewardType: _parseRewardType(map['rewardType'] as String? ?? 'adReward'),
      rewardAmount: (map['rewardAmount'] as num?)?.toDouble() ?? 0.0,
      status: _parseRewardStatus(map['status'] as String? ?? 'pending'),
      createdAt: (map['createdAt'] as dynamic)?.toDate() as DateTime? ?? DateTime.now(),
      claimedAt: (map['claimedAt'] as dynamic)?.toDate() as DateTime?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'rewardId': rewardId,
      'userId': userId,
      'rewardType': rewardType.name,
      'rewardAmount': rewardAmount,
      'status': status.name,
      'createdAt': createdAt,
      if (claimedAt != null) 'claimedAt': claimedAt,
    };
  }

  static RewardType _parseRewardType(String value) {
    return RewardType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => RewardType.adReward,
    );
  }

  static RewardStatus _parseRewardStatus(String value) {
    return RewardStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => RewardStatus.pending,
    );
  }
}

class DailyCheckInModel extends DailyCheckInEntity {
  const DailyCheckInModel({
    required super.id,
    required super.userId,
    required super.checkInDate,
    super.streakDay = 1,
    super.rewardAmount = 0.0,
    super.claimed = false,
  });

  factory DailyCheckInModel.fromEntity(DailyCheckInEntity entity) {
    return DailyCheckInModel(
      id: entity.id,
      userId: entity.userId,
      checkInDate: entity.checkInDate,
      streakDay: entity.streakDay,
      rewardAmount: entity.rewardAmount,
      claimed: entity.claimed,
    );
  }

  factory DailyCheckInModel.fromFirestore(Map<String, dynamic> map) {
    return DailyCheckInModel(
      id: map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      checkInDate: (map['checkInDate'] as dynamic)?.toDate() as DateTime? ?? DateTime.now(),
      streakDay: map['streakDay'] as int? ?? 1,
      rewardAmount: (map['rewardAmount'] as num?)?.toDouble() ?? 0.0,
      claimed: map['claimed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'userId': userId,
      'checkInDate': checkInDate,
      'streakDay': streakDay,
      'rewardAmount': rewardAmount,
      'claimed': claimed,
    };
  }
}

class StreakModel extends StreakEntity {
  const StreakModel({
    required super.userId,
    super.currentStreak = 0,
    super.longestStreak = 0,
    required super.lastCheckInDate,
    super.streakStartDate,
  });

  factory StreakModel.fromEntity(StreakEntity entity) {
    return StreakModel(
      userId: entity.userId,
      currentStreak: entity.currentStreak,
      longestStreak: entity.longestStreak,
      lastCheckInDate: entity.lastCheckInDate,
      streakStartDate: entity.streakStartDate,
    );
  }

  factory StreakModel.fromFirestore(Map<String, dynamic> map) {
    return StreakModel(
      userId: map['userId'] as String? ?? '',
      currentStreak: map['currentStreak'] as int? ?? 0,
      longestStreak: map['longestStreak'] as int? ?? 0,
      lastCheckInDate: (map['lastCheckInDate'] as dynamic)?.toDate() as DateTime? ?? DateTime.now(),
      streakStartDate: (map['streakStartDate'] as dynamic)?.toDate() as DateTime?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastCheckInDate': lastCheckInDate,
      if (streakStartDate != null) 'streakStartDate': streakStartDate,
    };
  }
}

class TaskModel extends TaskEntity {
  const TaskModel({
    required super.taskId,
    required super.userId,
    required super.title,
    super.description = '',
    super.category = TaskCategory.daily,
    super.status = TaskStatus.available,
    super.rewardAmount = 0.0,
    super.requiredCount = 1,
    super.progressCount = 0,
    required super.createdAt,
    super.completedAt,
  });

  factory TaskModel.fromEntity(TaskEntity entity) {
    return TaskModel(
      taskId: entity.taskId,
      userId: entity.userId,
      title: entity.title,
      description: entity.description,
      category: entity.category,
      status: entity.status,
      rewardAmount: entity.rewardAmount,
      requiredCount: entity.requiredCount,
      progressCount: entity.progressCount,
      createdAt: entity.createdAt,
      completedAt: entity.completedAt,
    );
  }

  factory TaskModel.fromFirestore(Map<String, dynamic> map) {
    return TaskModel(
      taskId: map['taskId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      category: _parseTaskCategory(map['category'] as String? ?? 'daily'),
      status: _parseTaskStatus(map['status'] as String? ?? 'available'),
      rewardAmount: (map['rewardAmount'] as num?)?.toDouble() ?? 0.0,
      requiredCount: map['requiredCount'] as int? ?? 1,
      progressCount: map['progressCount'] as int? ?? 0,
      createdAt: (map['createdAt'] as dynamic)?.toDate() as DateTime? ?? DateTime.now(),
      completedAt: (map['completedAt'] as dynamic)?.toDate() as DateTime?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'taskId': taskId,
      'userId': userId,
      'title': title,
      'description': description,
      'category': category.name,
      'status': status.name,
      'rewardAmount': rewardAmount,
      'requiredCount': requiredCount,
      'progressCount': progressCount,
      'createdAt': createdAt,
      if (completedAt != null) 'completedAt': completedAt,
    };
  }

  static TaskCategory _parseTaskCategory(String value) {
    return TaskCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TaskCategory.daily,
    );
  }

  static TaskStatus _parseTaskStatus(String value) {
    return TaskStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TaskStatus.available,
    );
  }
}

class RewardConfigModel extends RewardConfigEntity {
  const RewardConfigModel({
    required super.id,
    super.adRewardAmount = 2.0,
    super.dailyAdLimit = 10,
    super.adCooldownSeconds = 30,
    super.dailyCheckInBaseReward = 0.10,
    super.streakRewards,
    super.taskRewardAmount = 0.25,
    super.isActive = true,
  });

  factory RewardConfigModel.fromEntity(RewardConfigEntity entity) {
    return RewardConfigModel(
      id: entity.id,
      adRewardAmount: entity.adRewardAmount,
      dailyAdLimit: entity.dailyAdLimit,
      adCooldownSeconds: entity.adCooldownSeconds,
      dailyCheckInBaseReward: entity.dailyCheckInBaseReward,
      streakRewards: entity.streakRewards,
      taskRewardAmount: entity.taskRewardAmount,
      isActive: entity.isActive,
    );
  }

  factory RewardConfigModel.fromFirestore(Map<String, dynamic> map) {
    return RewardConfigModel(
      id: map['id'] as String? ?? 'config',
      adRewardAmount: (map['adRewardAmount'] as num?)?.toDouble() ?? 2.0,
      dailyAdLimit: map['dailyAdLimit'] as int? ?? 10,
      adCooldownSeconds: map['adCooldownSeconds'] as int? ?? 30,
      dailyCheckInBaseReward: (map['dailyCheckInBaseReward'] as num?)?.toDouble() ?? 0.10,
      streakRewards: (map['streakRewards'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [0.10, 0.15, 0.20, 0.25, 0.30, 0.40, 0.50],
      taskRewardAmount: (map['taskRewardAmount'] as num?)?.toDouble() ?? 0.25,
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'adRewardAmount': adRewardAmount,
      'dailyAdLimit': dailyAdLimit,
      'adCooldownSeconds': adCooldownSeconds,
      'dailyCheckInBaseReward': dailyCheckInBaseReward,
      'streakRewards': streakRewards,
      'taskRewardAmount': taskRewardAmount,
      'isActive': isActive,
    };
  }
}
