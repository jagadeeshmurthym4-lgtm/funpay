class WeeklyBonusModel {
  final String userId;
  final DateTime weekStartDate;
  final List<int> checkedDays; // 1=Mon ... 7=Sun
  final bool claimed;
  final String? claimedWeekStartKey;
  final bool recoveryUsedThisWeek;
  final DateTime lastUpdated;

  const WeeklyBonusModel({
    required this.userId,
    required this.weekStartDate,
    this.checkedDays = const [],
    this.claimed = false,
    this.claimedWeekStartKey,
    this.recoveryUsedThisWeek = false,
    required this.lastUpdated,
  });

  factory WeeklyBonusModel.fromFirestore(Map<String, dynamic> map) {
    return WeeklyBonusModel(
      userId: map['userId'] as String? ?? '',
      weekStartDate: (map['weekStartDate'] as dynamic)?.toDate() as DateTime? ?? DateTime.now(),
      checkedDays: (map['checkedDays'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          [],
      claimed: map['claimed'] as bool? ?? false,
      claimedWeekStartKey: map['claimedWeekStartKey'] as String?,
      recoveryUsedThisWeek: map['recoveryUsedThisWeek'] as bool? ?? false,
      lastUpdated: (map['lastUpdated'] as dynamic)?.toDate() as DateTime? ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'weekStartDate': weekStartDate,
      'checkedDays': checkedDays,
      'claimed': claimed,
      if (claimedWeekStartKey != null) 'claimedWeekStartKey': claimedWeekStartKey,
      'recoveryUsedThisWeek': recoveryUsedThisWeek,
      'lastUpdated': lastUpdated,
    };
  }

  WeeklyBonusModel copyWith({
    String? userId,
    DateTime? weekStartDate,
    List<int>? checkedDays,
    bool? claimed,
    String? claimedWeekStartKey,
    bool? recoveryUsedThisWeek,
    DateTime? lastUpdated,
  }) {
    return WeeklyBonusModel(
      userId: userId ?? this.userId,
      weekStartDate: weekStartDate ?? this.weekStartDate,
      checkedDays: checkedDays ?? this.checkedDays,
      claimed: claimed ?? this.claimed,
      claimedWeekStartKey: claimedWeekStartKey ?? this.claimedWeekStartKey,
      recoveryUsedThisWeek: recoveryUsedThisWeek ?? this.recoveryUsedThisWeek,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class MonthlyBonusModel {
  final String userId;
  final String monthKey; // "2024-01" format
  final List<int> checkedDays; // day numbers
  final bool claimed;
  final String? claimedMonthKey;
  final bool recoveryUsedThisMonth;
  final DateTime lastUpdated;

  const MonthlyBonusModel({
    required this.userId,
    required this.monthKey,
    this.checkedDays = const [],
    this.claimed = false,
    this.claimedMonthKey,
    this.recoveryUsedThisMonth = false,
    required this.lastUpdated,
  });

  factory MonthlyBonusModel.fromFirestore(Map<String, dynamic> map) {
    return MonthlyBonusModel(
      userId: map['userId'] as String? ?? '',
      monthKey: map['monthKey'] as String? ?? '',
      checkedDays: (map['checkedDays'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          [],
      claimed: map['claimed'] as bool? ?? false,
      claimedMonthKey: map['claimedMonthKey'] as String?,
      recoveryUsedThisMonth: map['recoveryUsedThisMonth'] as bool? ?? false,
      lastUpdated: (map['lastUpdated'] as dynamic)?.toDate() as DateTime? ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'monthKey': monthKey,
      'checkedDays': checkedDays,
      'claimed': claimed,
      if (claimedMonthKey != null) 'claimedMonthKey': claimedMonthKey,
      'recoveryUsedThisMonth': recoveryUsedThisMonth,
      'lastUpdated': lastUpdated,
    };
  }

  MonthlyBonusModel copyWith({
    String? userId,
    String? monthKey,
    List<int>? checkedDays,
    bool? claimed,
    String? claimedMonthKey,
    bool? recoveryUsedThisMonth,
    DateTime? lastUpdated,
  }) {
    return MonthlyBonusModel(
      userId: userId ?? this.userId,
      monthKey: monthKey ?? this.monthKey,
      checkedDays: checkedDays ?? this.checkedDays,
      claimed: claimed ?? this.claimed,
      claimedMonthKey: claimedMonthKey ?? this.claimedMonthKey,
      recoveryUsedThisMonth: recoveryUsedThisMonth ?? this.recoveryUsedThisMonth,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
