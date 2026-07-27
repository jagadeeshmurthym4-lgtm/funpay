enum RiskLevel { low, medium, high }

enum FraudStatus { underReview, confirmed, dismissed }

class FraudReportEntity {
  final String reportId;
  final String userId;
  final String reason;
  final RiskLevel riskLevel;
  final double fraudScore;
  final FraudStatus status;
  final DateTime createdAt;
  final String? adminNotes;
  final String? detectedBy;

  const FraudReportEntity({
    required this.reportId,
    required this.userId,
    required this.reason,
    this.riskLevel = RiskLevel.low,
    this.fraudScore = 0.0,
    this.status = FraudStatus.underReview,
    required this.createdAt,
    this.adminNotes,
    this.detectedBy,
  });

  FraudReportEntity copyWith({
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
    return FraudReportEntity(
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
}
