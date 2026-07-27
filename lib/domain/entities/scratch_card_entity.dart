class ScratchCardEntity {
  final String scratchCardId;
  final String userId;
  final String submissionId;
  final double rewardAmount;
  final bool isUsed;
  final DateTime createdAt;
  final DateTime? usedAt;

  const ScratchCardEntity({
    required this.scratchCardId,
    required this.userId,
    required this.submissionId,
    this.rewardAmount = 0.0,
    this.isUsed = false,
    required this.createdAt,
    this.usedAt,
  });

  ScratchCardEntity copyWith({
    String? scratchCardId,
    String? userId,
    String? submissionId,
    double? rewardAmount,
    bool? isUsed,
    DateTime? createdAt,
    DateTime? usedAt,
  }) {
    return ScratchCardEntity(
      scratchCardId: scratchCardId ?? this.scratchCardId,
      userId: userId ?? this.userId,
      submissionId: submissionId ?? this.submissionId,
      rewardAmount: rewardAmount ?? this.rewardAmount,
      isUsed: isUsed ?? this.isUsed,
      createdAt: createdAt ?? this.createdAt,
      usedAt: usedAt ?? this.usedAt,
    );
  }
}
