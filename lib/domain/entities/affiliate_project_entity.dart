import 'package:flutter/material.dart';

enum ProjectDifficulty { easy, medium, hard }

enum ProjectType {
  affiliateOffer,
  installApp,
  registration,
  kycVerification,
  purchase,
  survey,
  watchVideo,
  quiz,
  uploadScreenshot,
  uploadPdf,
  uploadImage,
  submitText,
  customTask,
}

extension ProjectTypeX on ProjectType {
  String get label {
    switch (this) {
      case ProjectType.affiliateOffer: return 'Affiliate Offer';
      case ProjectType.installApp: return 'Install App';
      case ProjectType.registration: return 'Registration';
      case ProjectType.kycVerification: return 'KYC Verification';
      case ProjectType.purchase: return 'Purchase';
      case ProjectType.survey: return 'Survey';
      case ProjectType.watchVideo: return 'Watch Video';
      case ProjectType.quiz: return 'Quiz';
      case ProjectType.uploadScreenshot: return 'Upload Screenshot';
      case ProjectType.uploadPdf: return 'Upload PDF';
      case ProjectType.uploadImage: return 'Upload Image';
      case ProjectType.submitText: return 'Submit Text';
      case ProjectType.customTask: return 'Custom Task';
    }
  }

  Color get iconColor {
    switch (this) {
      case ProjectType.affiliateOffer: return const Color(0xFF3B82F6);
      case ProjectType.installApp: return const Color(0xFF22C55E);
      case ProjectType.registration: return const Color(0xFF8B5CF6);
      case ProjectType.kycVerification: return const Color(0xFFF59E0B);
      case ProjectType.purchase: return const Color(0xFFEC4899);
      case ProjectType.survey: return const Color(0xFF06B6D4);
      case ProjectType.watchVideo: return const Color(0xFFEF4444);
      case ProjectType.quiz: return const Color(0xFF4ADE80);
      case ProjectType.uploadScreenshot: return const Color(0xFF94A3B8);
      case ProjectType.uploadPdf: return const Color(0xFFEF4444);
      case ProjectType.uploadImage: return const Color(0xFF8B5CF6);
      case ProjectType.submitText: return const Color(0xFFF59E0B);
      case ProjectType.customTask: return const Color(0xFF64748B);
    }
  }

  IconData get icon {
    switch (this) {
      case ProjectType.affiliateOffer: return Icons.link_outlined;
      case ProjectType.installApp: return Icons.download_outlined;
      case ProjectType.registration: return Icons.person_add_outlined;
      case ProjectType.kycVerification: return Icons.verified_outlined;
      case ProjectType.purchase: return Icons.shopping_cart_outlined;
      case ProjectType.survey: return Icons.quiz_outlined;
      case ProjectType.watchVideo: return Icons.play_circle_outlined;
      case ProjectType.quiz: return Icons.lightbulb_outlined;
      case ProjectType.uploadScreenshot: return Icons.screenshot_outlined;
      case ProjectType.uploadPdf: return Icons.picture_as_pdf_outlined;
      case ProjectType.uploadImage: return Icons.image_outlined;
      case ProjectType.submitText: return Icons.text_fields_outlined;
      case ProjectType.customTask: return Icons.task_alt_outlined;
    }
  }
}

enum ProjectStatus {
  notStarted,
  applied,
  inProgress,
  submitted,
  pendingReview,
  underReview,
  approved,
  rejected,
  completed,
}

extension ProjectStatusX on ProjectStatus {
  String get label {
    switch (this) {
      case ProjectStatus.notStarted: return 'Not Started';
      case ProjectStatus.applied: return 'Applied';
      case ProjectStatus.inProgress: return 'In Progress';
      case ProjectStatus.submitted: return 'Submitted';
      case ProjectStatus.pendingReview: return 'Pending Review';
      case ProjectStatus.underReview: return 'Under Review';
      case ProjectStatus.approved: return 'Approved';
      case ProjectStatus.rejected: return 'Rejected';
      case ProjectStatus.completed: return 'Completed';
    }
  }

  Color get color {
    switch (this) {
      case ProjectStatus.notStarted: return const Color(0xFF94A3B8);
      case ProjectStatus.applied: return const Color(0xFF06B6D4);
      case ProjectStatus.inProgress: return const Color(0xFF3B82F6);
      case ProjectStatus.submitted: return const Color(0xFF8B5CF6);
      case ProjectStatus.pendingReview: return const Color(0xFFF59E0B);
      case ProjectStatus.underReview: return const Color(0xFFF59E0B);
      case ProjectStatus.approved: return const Color(0xFF22C55E);
      case ProjectStatus.rejected: return const Color(0xFFEF4444);
      case ProjectStatus.completed: return const Color(0xFF4ADE80);
    }
  }
}

enum ProjectLifecycleStatus {
  draft,
  active,
  paused,
  expired,
  archived,
}

extension ProjectLifecycleStatusX on ProjectLifecycleStatus {
  String get label {
    switch (this) {
      case ProjectLifecycleStatus.draft: return 'Draft';
      case ProjectLifecycleStatus.active: return 'Active';
      case ProjectLifecycleStatus.paused: return 'Paused';
      case ProjectLifecycleStatus.expired: return 'Expired';
      case ProjectLifecycleStatus.archived: return 'Archived';
    }
  }

  Color get color {
    switch (this) {
      case ProjectLifecycleStatus.draft: return const Color(0xFF94A3B8);
      case ProjectLifecycleStatus.active: return const Color(0xFF22C55E);
      case ProjectLifecycleStatus.paused: return const Color(0xFFF59E0B);
      case ProjectLifecycleStatus.expired: return const Color(0xFFEF4444);
      case ProjectLifecycleStatus.archived: return const Color(0xFF64748B);
    }
  }
}

class ProjectEligibility {
  final List<String> allowedCountries;
  final String minAppVersion;
  final bool newUsersOnly;
  final bool existingUsersOnly;
  final int maxAttemptsPerUser;
  final int dailyLimit;
  final int totalUserLimit;

  const ProjectEligibility({
    this.allowedCountries = const ['IN'],
    this.minAppVersion = '1.0.0',
    this.newUsersOnly = false,
    this.existingUsersOnly = false,
    this.maxAttemptsPerUser = 1,
    this.dailyLimit = 0,
    this.totalUserLimit = 0,
  });

  ProjectEligibility copyWith({
    List<String>? allowedCountries,
    String? minAppVersion,
    bool? newUsersOnly,
    bool? existingUsersOnly,
    int? maxAttemptsPerUser,
    int? dailyLimit,
    int? totalUserLimit,
  }) {
    return ProjectEligibility(
      allowedCountries: allowedCountries ?? this.allowedCountries,
      minAppVersion: minAppVersion ?? this.minAppVersion,
      newUsersOnly: newUsersOnly ?? this.newUsersOnly,
      existingUsersOnly: existingUsersOnly ?? this.existingUsersOnly,
      maxAttemptsPerUser: maxAttemptsPerUser ?? this.maxAttemptsPerUser,
      dailyLimit: dailyLimit ?? this.dailyLimit,
      totalUserLimit: totalUserLimit ?? this.totalUserLimit,
    );
  }

  Map<String, dynamic> toJson() => {
        'allowedCountries': allowedCountries,
        'minAppVersion': minAppVersion,
        'newUsersOnly': newUsersOnly,
        'existingUsersOnly': existingUsersOnly,
        'maxAttemptsPerUser': maxAttemptsPerUser,
        'dailyLimit': dailyLimit,
        'totalUserLimit': totalUserLimit,
      };

  factory ProjectEligibility.fromJson(Map<String, dynamic> json) =>
      ProjectEligibility(
        allowedCountries: (json['allowedCountries'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            ['IN'],
        minAppVersion: json['minAppVersion'] as String? ?? '1.0.0',
        newUsersOnly: json['newUsersOnly'] as bool? ?? false,
        existingUsersOnly: json['existingUsersOnly'] as bool? ?? false,
        maxAttemptsPerUser: json['maxAttemptsPerUser'] as int? ?? 1,
        dailyLimit: json['dailyLimit'] as int? ?? 0,
        totalUserLimit: json['totalUserLimit'] as int? ?? 0,
      );
}

class AffiliateProjectEntity {
  final String projectId;
  final String title;
  final String subtitle;
  final String description;
  final double rewardAmount;
  final String category;
  final ProjectType projectType;
  final String bannerImage;
  final String logoImage;
  final String affiliateTrackingLink;
  final String affiliateProvider;
  final List<String> instructions;
  final String termsAndConditions;
  final int completionTime;
  final ProjectDifficulty difficulty;
  final int maxParticipants;
  final int currentParticipants;
  final ProjectLifecycleStatus lifecycleStatus;
  final bool featured;
  final bool isNew;
  final DateTime createdDate;
  final DateTime expiryDate;
  final String createdBy;
  final DateTime updatedDate;
  final int clicks;
  final int completedCount;
  final double totalRewardsPaid;
  final bool allowRetry;
  final ProjectEligibility eligibility;
  final List<String> tags;

  const AffiliateProjectEntity({
    required this.projectId,
    required this.title,
    this.subtitle = '',
    required this.description,
    required this.rewardAmount,
    required this.category,
    this.projectType = ProjectType.affiliateOffer,
    this.bannerImage = '',
    this.logoImage = '',
    this.affiliateTrackingLink = '',
    this.affiliateProvider = '',
    this.instructions = const [],
    this.termsAndConditions = '',
    this.completionTime = 30,
    this.difficulty = ProjectDifficulty.easy,
    this.maxParticipants = 1000,
    this.currentParticipants = 0,
    this.lifecycleStatus = ProjectLifecycleStatus.draft,
    this.featured = false,
    this.isNew = true,
    required this.createdDate,
    required this.expiryDate,
    required this.createdBy,
    required this.updatedDate,
    this.clicks = 0,
    this.completedCount = 0,
    this.totalRewardsPaid = 0.0,
    this.allowRetry = false,
    this.eligibility = const ProjectEligibility(),
    this.tags = const [],
  });

  bool get isActive => lifecycleStatus == ProjectLifecycleStatus.active;
  bool get isExpired => lifecycleStatus == ProjectLifecycleStatus.expired;
  bool get isPaused => lifecycleStatus == ProjectLifecycleStatus.paused;
  bool get isDraft => lifecycleStatus == ProjectLifecycleStatus.draft;
  bool get isArchived => lifecycleStatus == ProjectLifecycleStatus.archived;
  bool get isFull => currentParticipants >= maxParticipants;
  bool get isEndingSoon => isActive && expiryDate.difference(DateTime.now()).inDays <= 3;
  String get rewardText => '\u20B9${rewardAmount.toStringAsFixed(0)}';
  String get typeLabel => projectType.label;

  bool get isTask => projectType != ProjectType.affiliateOffer;
  bool get isAffiliateOffer => projectType == ProjectType.affiliateOffer;

  bool get requiresAffiliateLink =>
      projectType == ProjectType.affiliateOffer ||
      projectType == ProjectType.installApp ||
      projectType == ProjectType.registration;

  bool get requiresFileUpload =>
      projectType == ProjectType.uploadScreenshot ||
      projectType == ProjectType.uploadPdf ||
      projectType == ProjectType.uploadImage;

  bool get requiresTextSubmission =>
      projectType == ProjectType.submitText ||
      projectType == ProjectType.customTask;

  String get difficultyLabel {
    switch (difficulty) {
      case ProjectDifficulty.easy: return 'Easy';
      case ProjectDifficulty.medium: return 'Medium';
      case ProjectDifficulty.hard: return 'Hard';
    }
  }

  Color get difficultyColor {
    switch (difficulty) {
      case ProjectDifficulty.easy: return const Color(0xFF22C55E);
      case ProjectDifficulty.medium: return const Color(0xFFF59E0B);
      case ProjectDifficulty.hard: return const Color(0xFFEF4444);
    }
  }

  String get completionTimeText {
    if (completionTime < 60) return '$completionTime min';
    final hours = completionTime ~/ 60;
    final mins = completionTime % 60;
    final buffer = StringBuffer('${hours}h');
    if (mins > 0) buffer.write(' ${mins}m');
    return buffer.toString();

  }

  double get conversionRate =>
      currentParticipants > 0 ? (completedCount / currentParticipants) : 0.0;

  AffiliateProjectEntity copyWith({
    String? projectId,
    String? title,
    String? subtitle,
    String? description,
    double? rewardAmount,
    String? category,
    ProjectType? projectType,
    String? bannerImage,
    String? logoImage,
    String? affiliateTrackingLink,
    String? affiliateProvider,
    List<String>? instructions,
    String? termsAndConditions,
    int? completionTime,
    ProjectDifficulty? difficulty,
    int? maxParticipants,
    int? currentParticipants,
    ProjectLifecycleStatus? lifecycleStatus,
    bool? featured,
    bool? isNew,
    DateTime? createdDate,
    DateTime? expiryDate,
    String? createdBy,
    DateTime? updatedDate,
    int? clicks,
    int? completedCount,
    double? totalRewardsPaid,
    bool? allowRetry,
    ProjectEligibility? eligibility,
    List<String>? tags,
  }) {
    return AffiliateProjectEntity(
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      description: description ?? this.description,
      rewardAmount: rewardAmount ?? this.rewardAmount,
      category: category ?? this.category,
      projectType: projectType ?? this.projectType,
      bannerImage: bannerImage ?? this.bannerImage,
      logoImage: logoImage ?? this.logoImage,
      affiliateTrackingLink: affiliateTrackingLink ?? this.affiliateTrackingLink,
      affiliateProvider: affiliateProvider ?? this.affiliateProvider,
      instructions: instructions ?? this.instructions,
      termsAndConditions: termsAndConditions ?? this.termsAndConditions,
      completionTime: completionTime ?? this.completionTime,
      difficulty: difficulty ?? this.difficulty,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      currentParticipants: currentParticipants ?? this.currentParticipants,
      lifecycleStatus: lifecycleStatus ?? this.lifecycleStatus,
      featured: featured ?? this.featured,
      isNew: isNew ?? this.isNew,
      createdDate: createdDate ?? this.createdDate,
      expiryDate: expiryDate ?? this.expiryDate,
      createdBy: createdBy ?? this.createdBy,
      updatedDate: updatedDate ?? this.updatedDate,
      clicks: clicks ?? this.clicks,
      completedCount: completedCount ?? this.completedCount,
      totalRewardsPaid: totalRewardsPaid ?? this.totalRewardsPaid,
      allowRetry: allowRetry ?? this.allowRetry,
      eligibility: eligibility ?? this.eligibility,
      tags: tags ?? this.tags,
    );
  }
}

class ProjectParticipationEntity {
  final String participationId;
  final String projectId;
  final String projectTitle;
  final String userId;
  final String userName;
  final double rewardAmount;
  final ProjectStatus status;
  final String? screenshotUrl;
  final String? note;
  final String? transactionId;
  final String? rejectionReason;
  final DateTime startedAt;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final bool rewardCredited;
  final int attemptNumber;

  const ProjectParticipationEntity({
    required this.participationId,
    required this.projectId,
    required this.projectTitle,
    required this.userId,
    required this.userName,
    required this.rewardAmount,
    this.status = ProjectStatus.notStarted,
    this.screenshotUrl,
    this.note,
    this.transactionId,
    this.rejectionReason,
    required this.startedAt,
    this.submittedAt,
    this.reviewedAt,
    this.reviewedBy,
    this.rewardCredited = false,
    this.attemptNumber = 1,
  });

  ProjectParticipationEntity copyWith({
    String? participationId,
    String? projectId,
    String? projectTitle,
    String? userId,
    String? userName,
    double? rewardAmount,
    ProjectStatus? status,
    String? screenshotUrl,
    String? note,
    String? transactionId,
    String? rejectionReason,
    DateTime? startedAt,
    DateTime? submittedAt,
    DateTime? reviewedAt,
    String? reviewedBy,
    bool? rewardCredited,
    int? attemptNumber,
  }) {
    return ProjectParticipationEntity(
      participationId: participationId ?? this.participationId,
      projectId: projectId ?? this.projectId,
      projectTitle: projectTitle ?? this.projectTitle,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      rewardAmount: rewardAmount ?? this.rewardAmount,
      status: status ?? this.status,
      screenshotUrl: screenshotUrl ?? this.screenshotUrl,
      note: note ?? this.note,
      transactionId: transactionId ?? this.transactionId,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      startedAt: startedAt ?? this.startedAt,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      rewardCredited: rewardCredited ?? this.rewardCredited,
      attemptNumber: attemptNumber ?? this.attemptNumber,
    );
  }
}

class ProjectAnalytics {
  final int totalProjects;
  final int activeProjects;
  final int totalClicks;
  final int totalParticipants;
  final int pendingReviews;
  final int approvedRewards;
  final int rejectedRewards;
  final double totalRewardsPaid;
  final double conversionRate;

  const ProjectAnalytics({
    this.totalProjects = 0,
    this.activeProjects = 0,
    this.totalClicks = 0,
    this.totalParticipants = 0,
    this.pendingReviews = 0,
    this.approvedRewards = 0,
    this.rejectedRewards = 0,
    this.totalRewardsPaid = 0.0,
    this.conversionRate = 0.0,
  });

  factory ProjectAnalytics.fromProjects(
      List<AffiliateProjectEntity> projects,
      List<ProjectParticipationEntity> participations) {
    final active = projects.where((p) => p.isActive).length;
    final clicks = projects.fold<int>(0, (sum, p) => sum + p.clicks);
    final totalParticipants = projects.fold<int>(0, (sum, p) => sum + p.currentParticipants);
    final totalRewards = projects.fold<double>(0, (sum, p) => sum + p.totalRewardsPaid);
    final pending = participations
        .where((p) => p.status == ProjectStatus.pendingReview || p.status == ProjectStatus.submitted)
        .length;
    final approved = participations.where((p) => p.status == ProjectStatus.approved).length;
    final rejected = participations.where((p) => p.status == ProjectStatus.rejected).length;
    final totalCompleted = projects.fold<int>(0, (sum, p) => sum + p.completedCount);
    final conversion = totalParticipants > 0 ? totalCompleted / totalParticipants : 0.0;

    return ProjectAnalytics(
      totalProjects: projects.length,
      activeProjects: active,
      totalClicks: clicks,
      totalParticipants: totalParticipants,
      pendingReviews: pending,
      approvedRewards: approved,
      rejectedRewards: rejected,
      totalRewardsPaid: totalRewards,
      conversionRate: conversion,
    );
  }
}
