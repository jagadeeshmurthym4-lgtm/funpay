import 'package:cashspark/domain/entities/scratch_card_entity.dart';

class ScratchCardModel extends ScratchCardEntity {
  const ScratchCardModel({
    required super.scratchCardId,
    required super.userId,
    required super.submissionId,
    super.rewardAmount = 0.0,
    super.isUsed = false,
    required super.createdAt,
    super.usedAt,
  });

  factory ScratchCardModel.fromEntity(ScratchCardEntity entity) {
    return ScratchCardModel(
      scratchCardId: entity.scratchCardId,
      userId: entity.userId,
      submissionId: entity.submissionId,
      rewardAmount: entity.rewardAmount,
      isUsed: entity.isUsed,
      createdAt: entity.createdAt,
      usedAt: entity.usedAt,
    );
  }

  factory ScratchCardModel.fromFirestore(Map<String, dynamic> map) {
    return ScratchCardModel(
      scratchCardId: map['scratchCardId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      submissionId: map['submissionId'] as String? ?? '',
      rewardAmount: (map['rewardAmount'] as num?)?.toDouble() ?? 0.0,
      isUsed: map['isUsed'] as bool? ?? false,
      createdAt: (map['createdAt'] as dynamic)?.toDate() as DateTime? ?? DateTime.now(),
      usedAt: (map['usedAt'] as dynamic)?.toDate() as DateTime?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'scratchCardId': scratchCardId,
      'userId': userId,
      'submissionId': submissionId,
      'rewardAmount': rewardAmount,
      'isUsed': isUsed,
      'createdAt': createdAt,
      if (usedAt != null) 'usedAt': usedAt,
    };
  }
}
