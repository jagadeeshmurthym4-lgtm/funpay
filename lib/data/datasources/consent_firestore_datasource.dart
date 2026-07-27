import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cashspark/core/constants/app_constants.dart';
import 'package:cashspark/data/models/consent_agreement_model.dart';
import 'package:flutter/foundation.dart' show debugPrint;

class ConsentFirestoreDataSource {
  final FirebaseFirestore _firestore;

  ConsentFirestoreDataSource({FirebaseFirestore? firestoreInstance})
      : _firestore = firestoreInstance ?? FirebaseFirestore.instance;

  Future<ConsentAgreementModel?> getConsentStatus(String uid) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.agreementsCollection)
          .doc(uid)
          .get();
      if (!doc.exists || doc.data() == null) return null;
      return ConsentAgreementModel.fromFirestore(doc.data()!);
    } catch (e) {
      debugPrint('Error getting consent status for $uid: $e');
      return null;
    }
  }

  Future<void> saveConsent(ConsentAgreementModel consent) async {
    await _firestore
        .collection(AppConstants.agreementsCollection)
        .doc(consent.uid)
        .set(consent.toFirestore());
  }

  Future<bool> hasAcceptedAgreements(String uid) async {
    final consent = await getConsentStatus(uid);
    return consent != null && consent.hasAcceptedAll;
  }
}
