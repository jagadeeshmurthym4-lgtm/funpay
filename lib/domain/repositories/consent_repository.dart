import 'package:cashspark/data/models/consent_agreement_model.dart';

abstract class ConsentRepository {
  Future<ConsentAgreementModel?> getConsentStatus(String uid);
  Future<void> acceptAgreements({
    required String uid,
    required bool acceptedTerms,
    required bool acceptedPrivacy,
  });
  Future<bool> hasAcceptedAgreements(String uid);
}
