import 'package:cashspark/domain/entities/custom_task_entity.dart';

class CustomTaskModel extends CustomTaskEntity {
  const CustomTaskModel({
    required super.taskId,
    required super.title,
    required super.description,
    required super.rewardAmount,
    super.taskLink,
    super.category = 'General',
    super.isActive = true,
    required super.createdBy,
    required super.createdAt,
    required super.updatedAt,
  });

  factory CustomTaskModel.fromEntity(CustomTaskEntity entity) {
    return CustomTaskModel(
      taskId: entity.taskId,
      title: entity.title,
      description: entity.description,
      rewardAmount: entity.rewardAmount,
      taskLink: entity.taskLink,
      category: entity.category,
      isActive: entity.isActive,
      createdBy: entity.createdBy,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  factory CustomTaskModel.fromFirestore(Map<String, dynamic> map) {
    return CustomTaskModel(
      taskId: map['taskId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      rewardAmount: (map['rewardAmount'] as num?)?.toDouble() ?? 0.0,
      taskLink: map['taskLink'] as String?,
      category: map['category'] as String? ?? 'General',
      isActive: map['isActive'] as bool? ?? true,
      createdBy: map['createdBy'] as String? ?? '',
      createdAt: (map['createdAt'] as dynamic)?.toDate() as DateTime? ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as dynamic)?.toDate() as DateTime? ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'taskId': taskId,
      'title': title,
      'description': description,
      'rewardAmount': rewardAmount,
      'taskLink': taskLink,
      'category': category,
      'isActive': isActive,
      'createdBy': createdBy,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  CustomTaskModel copyWithModel({
    String? taskId,
    String? title,
    String? description,
    double? rewardAmount,
    String? taskLink,
    String? category,
    bool? isActive,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CustomTaskModel(
      taskId: taskId ?? this.taskId,
      title: title ?? this.title,
      description: description ?? this.description,
      rewardAmount: rewardAmount ?? this.rewardAmount,
      taskLink: taskLink ?? this.taskLink,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class TaskSubmissionModel extends TaskSubmissionEntity {
  const TaskSubmissionModel({
    required super.submissionId,
    required super.taskId,
    required super.taskTitle,
    required super.userId,
    required super.userName,
    required super.rewardAmount,
    super.status = 'pending',
    super.note = '',
    super.rejectionReason,
    super.screenshotUrl,
    required super.submittedAt,
    super.reviewedAt,
    super.reviewedBy,
  });

  factory TaskSubmissionModel.fromEntity(TaskSubmissionEntity entity) {
    return TaskSubmissionModel(
      submissionId: entity.submissionId,
      taskId: entity.taskId,
      taskTitle: entity.taskTitle,
      userId: entity.userId,
      userName: entity.userName,
      rewardAmount: entity.rewardAmount,
      status: entity.status,
      note: entity.note,
      rejectionReason: entity.rejectionReason,
      screenshotUrl: entity.screenshotUrl,
      submittedAt: entity.submittedAt,
      reviewedAt: entity.reviewedAt,
      reviewedBy: entity.reviewedBy,
    );
  }

  factory TaskSubmissionModel.fromFirestore(Map<String, dynamic> map) {
    return TaskSubmissionModel(
      submissionId: map['submissionId'] as String? ?? '',
      taskId: map['taskId'] as String? ?? '',
      taskTitle: map['taskTitle'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      userName: map['userName'] as String? ?? '',
      rewardAmount: (map['rewardAmount'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] as String? ?? 'pending',
      note: map['note'] as String? ?? '',
      rejectionReason: map['rejectionReason'] as String?,
      screenshotUrl: map['screenshotUrl'] as String?,
      submittedAt: (map['submittedAt'] as dynamic)?.toDate() as DateTime? ?? DateTime.now(),
      reviewedAt: (map['reviewedAt'] as dynamic)?.toDate() as DateTime?,
      reviewedBy: map['reviewedBy'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'submissionId': submissionId,
      'taskId': taskId,
      'taskTitle': taskTitle,
      'userId': userId,
      'userName': userName,
      'rewardAmount': rewardAmount,
      'status': status,
      'note': note,
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
      if (screenshotUrl != null) 'screenshotUrl': screenshotUrl,
      'submittedAt': submittedAt,
      if (reviewedAt != null) 'reviewedAt': reviewedAt,
      if (reviewedBy != null) 'reviewedBy': reviewedBy,
    };
  }

  TaskSubmissionModel copyWithModel({
    String? submissionId,
    String? taskId,
    String? taskTitle,
    String? userId,
    String? userName,
    double? rewardAmount,
    String? status,
    String? note,
    String? rejectionReason,
    String? screenshotUrl,
    DateTime? submittedAt,
    DateTime? reviewedAt,
    String? reviewedBy,
  }) {
    return TaskSubmissionModel(
      submissionId: submissionId ?? this.submissionId,
      taskId: taskId ?? this.taskId,
      taskTitle: taskTitle ?? this.taskTitle,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      rewardAmount: rewardAmount ?? this.rewardAmount,
      status: status ?? this.status,
      note: note ?? this.note,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      screenshotUrl: screenshotUrl ?? this.screenshotUrl,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
    );
  }
}
