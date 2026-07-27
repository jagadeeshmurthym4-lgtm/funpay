

class ConsentAgreementModel {
  final String uid;
  final bool acceptedTerms;
  final bool acceptedPrivacy;
  final DateTime acceptedAt;
  final String acceptedVersion;

  const ConsentAgreementModel({
    required this.uid,
    required this.acceptedTerms,
    required this.acceptedPrivacy,
    required this.acceptedAt,
    this.acceptedVersion = '1.0',
  });

  factory ConsentAgreementModel.fromFirestore(Map<String, dynamic> map) {
    return ConsentAgreementModel(
      uid: map['uid'] as String? ?? '',
      acceptedTerms: map['acceptedTerms'] as bool? ?? false,
      acceptedPrivacy: map['acceptedPrivacy'] as bool? ?? false,
      acceptedAt: (map['acceptedAt'] as dynamic)?.toDate() as DateTime? ?? DateTime.now(),
      acceptedVersion: map['acceptedVersion'] as String? ?? '1.0',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'acceptedTerms': acceptedTerms,
      'acceptedPrivacy': acceptedPrivacy,
      'acceptedAt': acceptedAt,
      'acceptedVersion': acceptedVersion,
    };
  }

  bool get hasAcceptedAll => acceptedTerms && acceptedPrivacy;
}
