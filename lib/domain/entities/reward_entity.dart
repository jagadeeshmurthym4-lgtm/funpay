enum RewardType { adReward, dailyCheckIn, streakBonus, taskReward, bonus, spinReward }
enum RewardStatus { pending, claimed, expired }
enum TaskCategory { daily, weekly, achievement }
enum TaskStatus { available, inProgress, completed, claimed }

class RewardEntity {
  final String rewardId;
  final String userId;
  final RewardType rewardType;
  final double rewardAmount;
  final RewardStatus status;
  final DateTime createdAt;
  final DateTime? claimedAt;

  const RewardEntity({
    required this.rewardId,
    required this.userId,
    required this.rewardType,
    this.rewardAmount = 0.0,
    this.status = RewardStatus.pending,
    required this.createdAt,
    this.claimedAt,
  });

  RewardEntity copyWith({
    String? rewardId,
    String? userId,
    RewardType? rewardType,
    double? rewardAmount,
    RewardStatus? status,
    DateTime? createdAt,
    DateTime? claimedAt,
  }) {
    return RewardEntity(
      rewardId: rewardId ?? this.rewardId,
      userId: userId ?? this.userId,
      rewardType: rewardType ?? this.rewardType,
      rewardAmount: rewardAmount ?? this.rewardAmount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      claimedAt: claimedAt ?? this.claimedAt,
    );
  }
}

class DailyCheckInEntity {
  final String id;
  final String userId;
  final DateTime checkInDate;
  final int streakDay;
  final double rewardAmount;
  final bool claimed;

  const DailyCheckInEntity({
    required this.id,
    required this.userId,
    required this.checkInDate,
    this.streakDay = 1,
    this.rewardAmount = 0.0,
    this.claimed = false,
  });

  DailyCheckInEntity copyWith({
    String? id,
    String? userId,
    DateTime? checkInDate,
    int? streakDay,
    double? rewardAmount,
    bool? claimed,
  }) {
    return DailyCheckInEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      checkInDate: checkInDate ?? this.checkInDate,
      streakDay: streakDay ?? this.streakDay,
      rewardAmount: rewardAmount ?? this.rewardAmount,
      claimed: claimed ?? this.claimed,
    );
  }
}

class StreakEntity {
  final String userId;
  final int currentStreak;
  final int longestStreak;
  final DateTime lastCheckInDate;
  final DateTime? streakStartDate;

  const StreakEntity({
    required this.userId,
    this.currentStreak = 0,
    this.longestStreak = 0,
    required this.lastCheckInDate,
    this.streakStartDate,
  });

  StreakEntity copyWith({
    String? userId,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastCheckInDate,
    DateTime? streakStartDate,
  }) {
    return StreakEntity(
      userId: userId ?? this.userId,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastCheckInDate: lastCheckInDate ?? this.lastCheckInDate,
      streakStartDate: streakStartDate ?? this.streakStartDate,
    );
  }
}

class TaskEntity {
  final String taskId;
  final String userId;
  final String title;
  final String description;
  final TaskCategory category;
  final TaskStatus status;
  final double rewardAmount;
  final int requiredCount;
  final int progressCount;
  final DateTime createdAt;
  final DateTime? completedAt;

  const TaskEntity({
    required this.taskId,
    required this.userId,
    required this.title,
    this.description = '',
    this.category = TaskCategory.daily,
    this.status = TaskStatus.available,
    this.rewardAmount = 0.0,
    this.requiredCount = 1,
    this.progressCount = 0,
    required this.createdAt,
    this.completedAt,
  });

  TaskEntity copyWith({
    String? taskId,
    String? userId,
    String? title,
    String? description,
    TaskCategory? category,
    TaskStatus? status,
    double? rewardAmount,
    int? requiredCount,
    int? progressCount,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return TaskEntity(
      taskId: taskId ?? this.taskId,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      status: status ?? this.status,
      rewardAmount: rewardAmount ?? this.rewardAmount,
      requiredCount: requiredCount ?? this.requiredCount,
      progressCount: progressCount ?? this.progressCount,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

class RewardConfigEntity {
  final String id;
  final double adRewardAmount;
  final int dailyAdLimit;
  final int adCooldownSeconds;
  final double dailyCheckInBaseReward;
  final List<double> streakRewards;
  final double taskRewardAmount;
  final bool isActive;

  const RewardConfigEntity({
    required this.id,
    this.adRewardAmount = 2.0,
    this.dailyAdLimit = 10,
    this.adCooldownSeconds = 30,
    this.dailyCheckInBaseReward = 0.10,
    this.streakRewards = const [0.10, 0.15, 0.20, 0.25, 0.30, 0.40, 0.50],
    this.taskRewardAmount = 0.25,
    this.isActive = true,
  });
}
