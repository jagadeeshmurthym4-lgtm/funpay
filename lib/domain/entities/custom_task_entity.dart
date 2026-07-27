class CustomTaskEntity {
  final String taskId;
  final String title;
  final String description;
  final double rewardAmount;
  final String? taskLink;
  final String category;
  final bool isActive;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CustomTaskEntity({
    required this.taskId,
    required this.title,
    required this.description,
    required this.rewardAmount,
    this.taskLink,
    this.category = 'General',
    this.isActive = true,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  CustomTaskEntity copyWith({
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
    return CustomTaskEntity(
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

class TaskSubmissionEntity {
  final String submissionId;
  final String taskId;
  final String taskTitle;
  final String userId;
  final String userName;
  final double rewardAmount;
  final String status; // 'pending', 'approved', 'rejected'
  final String note;
  final String? rejectionReason;
  final String? screenshotUrl;
  final DateTime submittedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;

  const TaskSubmissionEntity({
    required this.submissionId,
    required this.taskId,
    required this.taskTitle,
    required this.userId,
    required this.userName,
    required this.rewardAmount,
    this.status = 'pending',
    this.note = '',
    this.rejectionReason,
    this.screenshotUrl,
    required this.submittedAt,
    this.reviewedAt,
    this.reviewedBy,
  });

  TaskSubmissionEntity copyWith({
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
    return TaskSubmissionEntity(
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
