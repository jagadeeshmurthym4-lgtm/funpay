import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cashspark/domain/entities/affiliate_project_entity.dart';

class AffiliateProjectModel {
  final String projectId;
  final String title;
  final String subtitle;
  final String description;
  final double rewardAmount;
  final String category;
  final String projectType;
  final String bannerImage;
  final String logoImage;
  final String affiliateTrackingLink;
  final String affiliateProvider;
  final List<String> instructions;
  final String termsAndConditions;
  final int completionTime;
  final String difficulty;
  final int maxParticipants;
  final int currentParticipants;
  final String lifecycleStatus;
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
  final Map<String, dynamic> eligibility;
  final List<String> tags;

  const AffiliateProjectModel({
    required this.projectId,
    required this.title,
    this.subtitle = '',
    required this.description,
    required this.rewardAmount,
    required this.category,
    this.projectType = 'affiliateOffer',
    this.bannerImage = '',
    this.logoImage = '',
    this.affiliateTrackingLink = '',
    this.affiliateProvider = '',
    this.instructions = const [],
    this.termsAndConditions = '',
    this.completionTime = 30,
    this.difficulty = 'easy',
    this.maxParticipants = 1000,
    this.currentParticipants = 0,
    this.lifecycleStatus = 'draft',
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
    this.eligibility = const {},
    this.tags = const [],
  });

  factory AffiliateProjectModel.fromFirestore(Map<String, dynamic> data) {
    return AffiliateProjectModel(
      projectId: data['projectId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      subtitle: data['subtitle'] as String? ?? '',
      description: data['description'] as String? ?? '',
      rewardAmount: (data['rewardAmount'] as num?)?.toDouble() ?? 0.0,
      category: data['category'] as String? ?? 'General',
      projectType: data['projectType'] as String? ?? 'affiliateOffer',
      bannerImage: data['bannerImage'] as String? ?? '',
      logoImage: data['logoImage'] as String? ?? '',
      affiliateTrackingLink: data['affiliateTrackingLink'] as String? ?? '',
      affiliateProvider: data['affiliateProvider'] as String? ?? '',
      instructions: (data['instructions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      termsAndConditions: data['termsAndConditions'] as String? ?? '',
      completionTime: data['completionTime'] as int? ?? 30,
      difficulty: data['difficulty'] as String? ?? 'easy',
      maxParticipants: data['maxParticipants'] as int? ?? 1000,
      currentParticipants: data['currentParticipants'] as int? ?? 0,
      lifecycleStatus: data['lifecycleStatus'] as String? ?? 'draft',
      featured: data['featured'] as bool? ?? false,
      isNew: data['isNew'] as bool? ?? true,
      createdDate:
          (data['createdDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiryDate: (data['expiryDate'] as Timestamp?)?.toDate() ??
          DateTime.now().add(const Duration(days: 30)),
      createdBy: data['createdBy'] as String? ?? '',
      updatedDate:
          (data['updatedDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      clicks: data['clicks'] as int? ?? 0,
      completedCount: data['completedCount'] as int? ?? 0,
      totalRewardsPaid:
          (data['totalRewardsPaid'] as num?)?.toDouble() ?? 0.0,
      allowRetry: data['allowRetry'] as bool? ?? false,
      eligibility: (data['eligibility'] as Map<String, dynamic>?) ?? {},
      tags: (data['tags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'projectId': projectId,
      'title': title,
      'subtitle': subtitle,
      'description': description,
      'rewardAmount': rewardAmount,
      'category': category,
      'projectType': projectType,
      'bannerImage': bannerImage,
      'logoImage': logoImage,
      'affiliateTrackingLink': affiliateTrackingLink,
      'affiliateProvider': affiliateProvider,
      'instructions': instructions,
      'termsAndConditions': termsAndConditions,
      'completionTime': completionTime,
      'difficulty': difficulty,
      'maxParticipants': maxParticipants,
      'currentParticipants': currentParticipants,
      'lifecycleStatus': lifecycleStatus,
      'featured': featured,
      'isNew': isNew,
      'createdDate': Timestamp.fromDate(createdDate),
      'expiryDate': Timestamp.fromDate(expiryDate),
      'createdBy': createdBy,
      'updatedDate': Timestamp.fromDate(updatedDate),
      'clicks': clicks,
      'completedCount': completedCount,
      'totalRewardsPaid': totalRewardsPaid,
      'allowRetry': allowRetry,
      'eligibility': eligibility,
      'tags': tags,
    };
  }

  AffiliateProjectEntity toEntity() {
    return AffiliateProjectEntity(
      projectId: projectId,
      title: title,
      subtitle: subtitle,
      description: description,
      rewardAmount: rewardAmount,
      category: category,
      projectType: _parseProjectType(projectType),
      bannerImage: bannerImage,
      logoImage: logoImage,
      affiliateTrackingLink: affiliateTrackingLink,
      affiliateProvider: affiliateProvider,
      instructions: instructions,
      termsAndConditions: termsAndConditions,
      completionTime: completionTime,
      difficulty: _parseDifficulty(difficulty),
      maxParticipants: maxParticipants,
      currentParticipants: currentParticipants,
      lifecycleStatus: _parseLifecycleStatus(lifecycleStatus),
      featured: featured,
      isNew: isNew,
      createdDate: createdDate,
      expiryDate: expiryDate,
      createdBy: createdBy,
      updatedDate: updatedDate,
      clicks: clicks,
      completedCount: completedCount,
      totalRewardsPaid: totalRewardsPaid,
      allowRetry: allowRetry,
      eligibility: ProjectEligibility.fromJson(eligibility),
      tags: tags,
    );
  }

  factory AffiliateProjectModel.fromEntity(AffiliateProjectEntity entity) {
    return AffiliateProjectModel(
      projectId: entity.projectId,
      title: entity.title,
      subtitle: entity.subtitle,
      description: entity.description,
      rewardAmount: entity.rewardAmount,
      category: entity.category,
      projectType: entity.projectType.name,
      bannerImage: entity.bannerImage,
      logoImage: entity.logoImage,
      affiliateTrackingLink: entity.affiliateTrackingLink,
      affiliateProvider: entity.affiliateProvider,
      instructions: entity.instructions,
      termsAndConditions: entity.termsAndConditions,
      completionTime: entity.completionTime,
      difficulty: entity.difficulty.name,
      maxParticipants: entity.maxParticipants,
      currentParticipants: entity.currentParticipants,
      lifecycleStatus: entity.lifecycleStatus.name,
      featured: entity.featured,
      isNew: entity.isNew,
      createdDate: entity.createdDate,
      expiryDate: entity.expiryDate,
      createdBy: entity.createdBy,
      updatedDate: entity.updatedDate,
      clicks: entity.clicks,
      completedCount: entity.completedCount,
      totalRewardsPaid: entity.totalRewardsPaid,
      allowRetry: entity.allowRetry,
      eligibility: entity.eligibility.toJson(),
      tags: entity.tags,
    );
  }

  static ProjectDifficulty _parseDifficulty(String value) =>
      ProjectDifficulty.values.firstWhere(
        (e) => e.name == value,
        orElse: () => ProjectDifficulty.easy,
      );

  static ProjectType _parseProjectType(String value) =>
      ProjectType.values.firstWhere(
        (e) => e.name == value,
        orElse: () => ProjectType.affiliateOffer,
      );

  static ProjectLifecycleStatus _parseLifecycleStatus(String value) =>
      ProjectLifecycleStatus.values.firstWhere(
        (e) => e.name == value,
        orElse: () => ProjectLifecycleStatus.draft,
      );
}

class ProjectParticipationModel {
  final String participationId;
  final String projectId;
  final String projectTitle;
  final String userId;
  final String userName;
  final double rewardAmount;
  final String status;
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

  const ProjectParticipationModel({
    required this.participationId,
    required this.projectId,
    required this.projectTitle,
    required this.userId,
    required this.userName,
    required this.rewardAmount,
    this.status = 'notStarted',
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

  factory ProjectParticipationModel.fromFirestore(Map<String, dynamic> data) {
    return ProjectParticipationModel(
      participationId: data['participationId'] as String? ?? '',
      projectId: data['projectId'] as String? ?? '',
      projectTitle: data['projectTitle'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String? ?? '',
      rewardAmount: (data['rewardAmount'] as num?)?.toDouble() ?? 0.0,
      status: data['status'] as String? ?? 'notStarted',
      screenshotUrl: data['screenshotUrl'] as String?,
      note: data['note'] as String?,
      transactionId: data['transactionId'] as String?,
      rejectionReason: data['rejectionReason'] as String?,
      startedAt:
          (data['startedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      submittedAt: (data['submittedAt'] as Timestamp?)?.toDate(),
      reviewedAt: (data['reviewedAt'] as Timestamp?)?.toDate(),
      reviewedBy: data['reviewedBy'] as String?,
      rewardCredited: data['rewardCredited'] as bool? ?? false,
      attemptNumber: data['attemptNumber'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'participationId': participationId,
      'projectId': projectId,
      'projectTitle': projectTitle,
      'userId': userId,
      'userName': userName,
      'rewardAmount': rewardAmount,
      'status': status,
      'screenshotUrl': screenshotUrl,
      'note': note,
      'transactionId': transactionId,
      'rejectionReason': rejectionReason,
      'startedAt': Timestamp.fromDate(startedAt),
      'submittedAt':
          submittedAt != null ? Timestamp.fromDate(submittedAt!) : null,
      'reviewedAt':
          reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'reviewedBy': reviewedBy,
      'rewardCredited': rewardCredited,
      'attemptNumber': attemptNumber,
    };
  }

  ProjectParticipationEntity toEntity() {
    return ProjectParticipationEntity(
      participationId: participationId,
      projectId: projectId,
      projectTitle: projectTitle,
      userId: userId,
      userName: userName,
      rewardAmount: rewardAmount,
      status: _parseStatus(status),
      screenshotUrl: screenshotUrl,
      note: note,
      transactionId: transactionId,
      rejectionReason: rejectionReason,
      startedAt: startedAt,
      submittedAt: submittedAt,
      reviewedAt: reviewedAt,
      reviewedBy: reviewedBy,
      rewardCredited: rewardCredited,
      attemptNumber: attemptNumber,
    );
  }

  factory ProjectParticipationModel.fromEntity(
      ProjectParticipationEntity entity) {
    return ProjectParticipationModel(
      participationId: entity.participationId,
      projectId: entity.projectId,
      projectTitle: entity.projectTitle,
      userId: entity.userId,
      userName: entity.userName,
      rewardAmount: entity.rewardAmount,
      status: entity.status.name,
      screenshotUrl: entity.screenshotUrl,
      note: entity.note,
      transactionId: entity.transactionId,
      rejectionReason: entity.rejectionReason,
      startedAt: entity.startedAt,
      submittedAt: entity.submittedAt,
      reviewedAt: entity.reviewedAt,
      reviewedBy: entity.reviewedBy,
      rewardCredited: entity.rewardCredited,
      attemptNumber: entity.attemptNumber,
    );
  }

  static ProjectStatus _parseStatus(String value) =>
      ProjectStatus.values.firstWhere(
        (e) => e.name == value,
        orElse: () => ProjectStatus.notStarted,
      );
}
