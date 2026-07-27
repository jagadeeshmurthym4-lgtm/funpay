import 'package:cashspark/data/datasources/consent_firestore_datasource.dart';
import 'package:cashspark/data/models/consent_agreement_model.dart';
import 'package:cashspark/domain/repositories/consent_repository.dart';

class ConsentRepositoryImpl implements ConsentRepository {
  final ConsentFirestoreDataSource _dataSource;

  ConsentRepositoryImpl({
    required ConsentFirestoreDataSource dataSource,
  }) : _dataSource = dataSource;

  @override
  Future<ConsentAgreementModel?> getConsentStatus(String uid) async {
    return _dataSource.getConsentStatus(uid);
  }

  @override
  Future<void> acceptAgreements({
    required String uid,
    required bool acceptedTerms,
    required bool acceptedPrivacy,
  }) async {
    final consent = ConsentAgreementModel(
      uid: uid,
      acceptedTerms: acceptedTerms,
      acceptedPrivacy: acceptedPrivacy,
      acceptedAt: DateTime.now(),
      acceptedVersion: '1.0',
    );
    await _dataSource.saveConsent(consent);
  }

  @override
  Future<bool> hasAcceptedAgreements(String uid) async {
    return _dataSource.hasAcceptedAgreements(uid);
  }
}
