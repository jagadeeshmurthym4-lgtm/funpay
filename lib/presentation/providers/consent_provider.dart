import 'package:cashspark/data/repositories/consent_repository_impl.dart';
import 'package:flutter/foundation.dart';

class ConsentProvider extends ChangeNotifier {
  final ConsentRepositoryImpl _consentRepository;

  bool _hasAccepted = false;
  bool _isLoading = false;
  bool _needsConsent = false;

  ConsentProvider({
    required ConsentRepositoryImpl consentRepository,
  }) : _consentRepository = consentRepository;

  bool get hasAccepted => _hasAccepted;
  bool get isLoading => _isLoading;
  bool get needsConsent => _needsConsent;

  Future<void> checkConsentStatus(String uid) async {
    _setLoading(true);
    try {
      _hasAccepted = await _consentRepository.hasAcceptedAgreements(uid);
      _needsConsent = !_hasAccepted;
    } catch (e) {
      debugPrint('Failed to check consent status: $e');
      _needsConsent = true;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> acceptAgreements({
    required String uid,
    required bool acceptedTerms,
    required bool acceptedPrivacy,
  }) async {
    try {
      await _consentRepository.acceptAgreements(
        uid: uid,
        acceptedTerms: acceptedTerms,
        acceptedPrivacy: acceptedPrivacy,
      );
      _hasAccepted = true;
      _needsConsent = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to save consent: $e');
      rethrow;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
