class SpinHistoryEntry {
  final double amount;
  final DateTime timestamp;

  const SpinHistoryEntry({
    required this.amount,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'amount': amount,
        'timestamp': timestamp,
      };

  factory SpinHistoryEntry.fromJson(Map<String, dynamic> json) {
    return SpinHistoryEntry(
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      timestamp: (json['timestamp'] as dynamic)?.toDate() as DateTime? ??
          DateTime.now(),
    );
  }
}

class SpinDataEntity {
  final String userId;
  final int totalSpins;
  final int spinsToday;
  final int bonusSpins;
  final DateTime lastSpinDate;
  final DateTime lastResetDate;
  final double totalRewardsEarned;
  final int totalSpinsWon;
  final List<SpinHistoryEntry> spinHistory;

  const SpinDataEntity({
    required this.userId,
    this.totalSpins = 0,
    this.spinsToday = 0,
    this.bonusSpins = 0,
    required this.lastSpinDate,
    DateTime? lastResetDate,
    this.totalRewardsEarned = 0.0,
    this.totalSpinsWon = 0,
    this.spinHistory = const [],
  }) : lastResetDate = lastResetDate ?? lastSpinDate;

  SpinDataEntity copyWith({
    String? userId,
    int? totalSpins,
    int? spinsToday,
    int? bonusSpins,
    DateTime? lastSpinDate,
    DateTime? lastResetDate,
    double? totalRewardsEarned,
    int? totalSpinsWon,
    List<SpinHistoryEntry>? spinHistory,
  }) {
    return SpinDataEntity(
      userId: userId ?? this.userId,
      totalSpins: totalSpins ?? this.totalSpins,
      spinsToday: spinsToday ?? this.spinsToday,
      bonusSpins: bonusSpins ?? this.bonusSpins,
      lastSpinDate: lastSpinDate ?? this.lastSpinDate,
      lastResetDate: lastResetDate ?? this.lastResetDate,
      totalRewardsEarned: totalRewardsEarned ?? this.totalRewardsEarned,
      totalSpinsWon: totalSpinsWon ?? this.totalSpinsWon,
      spinHistory: spinHistory ?? this.spinHistory,
    );
  }
}

class SpinDataModel extends SpinDataEntity {
  const SpinDataModel({
    required super.userId,
    super.totalSpins = 0,
    super.spinsToday = 0,
    super.bonusSpins = 0,
    required super.lastSpinDate,
    super.lastResetDate,
    super.totalRewardsEarned = 0.0,
    super.totalSpinsWon = 0,
    super.spinHistory = const [],
  });

  factory SpinDataModel.fromEntity(SpinDataEntity entity) {
    return SpinDataModel(
      userId: entity.userId,
      totalSpins: entity.totalSpins,
      spinsToday: entity.spinsToday,
      bonusSpins: entity.bonusSpins,
      lastSpinDate: entity.lastSpinDate,
      lastResetDate: entity.lastResetDate,
      totalRewardsEarned: entity.totalRewardsEarned,
      totalSpinsWon: entity.totalSpinsWon,
      spinHistory: entity.spinHistory,
    );
  }

  factory SpinDataModel.fromFirestore(Map<String, dynamic> map) {
    final historyList = (map['spinHistory'] as List<dynamic>?)
            ?.map((e) =>
                SpinHistoryEntry.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return SpinDataModel(
      userId: map['userId'] as String? ?? '',
      totalSpins: map['totalSpins'] as int? ?? 0,
      spinsToday: map['spinsToday'] as int? ?? 0,
      bonusSpins: map['bonusSpins'] as int? ?? 0,
      lastSpinDate:
          (map['lastSpinDate'] as dynamic)?.toDate() as DateTime? ??
              DateTime.now(),
      lastResetDate:
          (map['lastResetDate'] as dynamic)?.toDate() as DateTime?,
      totalRewardsEarned:
          (map['totalRewardsEarned'] as num?)?.toDouble() ?? 0.0,
      totalSpinsWon: map['totalSpinsWon'] as int? ?? 0,
      spinHistory: historyList,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'totalSpins': totalSpins,
      'spinsToday': spinsToday,
      'bonusSpins': bonusSpins,
      'lastSpinDate': lastSpinDate,
      'lastResetDate': lastResetDate,
      'totalRewardsEarned': totalRewardsEarned,
      'totalSpinsWon': totalSpinsWon,
      'spinHistory': spinHistory.map((e) => e.toJson()).toList(),
    };
  }
}
