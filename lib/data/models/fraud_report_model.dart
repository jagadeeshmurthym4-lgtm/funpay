import 'package:cashspark/domain/entities/fraud_report_entity.dart';

class FraudReportModel extends FraudReportEntity {
  const FraudReportModel({
    required super.reportId,
    required super.userId,
    required super.reason,
    super.riskLevel = RiskLevel.low,
    super.fraudScore = 0.0,
    super.status = FraudStatus.underReview,
    required super.createdAt,
    super.adminNotes,
    super.detectedBy,
  });

  factory FraudReportModel.fromEntity(FraudReportEntity entity) {
    return FraudReportModel(
      reportId: entity.reportId,
      userId: entity.userId,
      reason: entity.reason,
      riskLevel: entity.riskLevel,
      fraudScore: entity.fraudScore,
      status: entity.status,
      createdAt: entity.createdAt,
      adminNotes: entity.adminNotes,
      detectedBy: entity.detectedBy,
    );
  }

  factory FraudReportModel.fromFirestore(Map<String, dynamic> map) {
    return FraudReportModel(
      reportId: map['reportId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      reason: map['reason'] as String? ?? '',
      riskLevel: _parseRiskLevel(map['riskLevel'] as String? ?? 'low'),
      fraudScore: (map['fraudScore'] as num?)?.toDouble() ?? 0.0,
      status: _parseFraudStatus(map['status'] as String? ?? 'underReview'),
      createdAt: (map['createdAt'] as dynamic) != null
          ? (map['createdAt'] as dynamic).toDate() as DateTime
          : DateTime.now(),
      adminNotes: map['adminNotes'] as String?,
      detectedBy: map['detectedBy'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'reportId': reportId,
      'userId': userId,
      'reason': reason,
      'riskLevel': riskLevel.name,
      'fraudScore': fraudScore,
      'status': status.name,
      'createdAt': createdAt,
      if (adminNotes != null) 'adminNotes': adminNotes,
      if (detectedBy != null) 'detectedBy': detectedBy,
    };
  }

  FraudReportModel copyWithModel({
    String? reportId,
    String? userId,
    String? reason,
    RiskLevel? riskLevel,
    double? fraudScore,
    FraudStatus? status,
    DateTime? createdAt,
    String? adminNotes,
    String? detectedBy,
  }) {
    return FraudReportModel(
      reportId: reportId ?? this.reportId,
      userId: userId ?? this.userId,
      reason: reason ?? this.reason,
      riskLevel: riskLevel ?? this.riskLevel,
      fraudScore: fraudScore ?? this.fraudScore,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      adminNotes: adminNotes ?? this.adminNotes,
      detectedBy: detectedBy ?? this.detectedBy,
    );
  }

  static RiskLevel _parseRiskLevel(String value) {
    switch (value) {
      case 'medium':
        return RiskLevel.medium;
      case 'high':
        return RiskLevel.high;
      default:
        return RiskLevel.low;
    }
  }

  static FraudStatus _parseFraudStatus(String value) {
    switch (value) {
      case 'confirmed':
        return FraudStatus.confirmed;
      case 'dismissed':
        return FraudStatus.dismissed;
      default:
        return FraudStatus.underReview;
    }
  }
}
