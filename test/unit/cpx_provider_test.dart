// The Firestore collection/doc/snapshot types are sealed; mocktail still
// needs to implement them to stub the collection().doc().set() chain.
// ignore_for_file: subtype_of_sealed_class

import 'dart:convert';

import 'package:cashspark/core/constants/app_constants.dart';
import 'package:cashspark/presentation/providers/cpx_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFirestore extends Mock implements FirebaseFirestore {}

class _MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class _MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

class _MockDocumentSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

void main() {
  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue(SetOptions(merge: true));
  });

  group('CpxProvider.saveConfig', () {
    late _MockFirestore mockFirestore;
    late _MockCollectionReference mockCollection;
    late _MockDocumentReference mockDocRef;
    late _MockDocumentSnapshot mockDocSnapshot;

    setUp(() {
      mockFirestore = _MockFirestore();
      mockCollection = _MockCollectionReference();
      mockDocRef = _MockDocumentReference();
      mockDocSnapshot = _MockDocumentSnapshot();

      when(() => mockFirestore.collection(AppConstants.appSettingsCollection))
          .thenReturn(mockCollection);
      when(() => mockCollection.doc(AppConstants.cpxSettingsDocId))
          .thenReturn(mockDocRef);
      when(() => mockDocRef.get()).thenAnswer((_) async => mockDocSnapshot);
      when(() => mockDocSnapshot.exists).thenReturn(true);
      when(() => mockDocSnapshot.data()).thenReturn({
        'appId': '35037',
        'appSecureHash': '',
        'enabled': true,
      });
    });

    test('writes enabled/appSecureHash/appId with merge and updates state',
        () async {
      when(() => mockDocRef.set(any(), any())).thenAnswer((_) async {});

      final provider = CpxProvider(firestore: mockFirestore);
      // Let the fire-and-forget loadConfig() settle.
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      const newConfig = CpxConfig(
        appId: '35037',
        appSecureHash: 'abc123hash',
        enabled: false,
      );
      final ok = await provider.saveConfig(newConfig);

      expect(ok, true);
      verify(() => mockDocRef.set(
        any(that: predicate<Map<String, dynamic>>((m) =>
            m['enabled'] == false &&
            m['appSecureHash'] == 'abc123hash' &&
            m['appId'] == '35037' &&
            m.containsKey('updatedAt'))),
        any(),
      )).called(1);
      expect(provider.config?.enabled, false);
      expect(provider.config?.appSecureHash, 'abc123hash');
      expect(provider.isEnabled, false);
    });

    test('returns false and keeps previous config when the write fails',
        () async {
      when(() => mockDocRef.set(any(), any()))
          .thenThrow(Exception('permission denied'));

      final provider = CpxProvider(firestore: mockFirestore);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      const newConfig = CpxConfig(enabled: false, appSecureHash: 'x');
      final ok = await provider.saveConfig(newConfig);

      expect(ok, false);
      // Config stays as loaded (enabled: true from the stub doc).
      expect(provider.isEnabled, true);
      expect(provider.errorMessage, isNotNull);
    });
  });

  group('CpxProvider.buildOfferWallUrl', () {
    test('includes app_id and ext_user_id', () {
      final provider = CpxProvider();
      final url = provider.buildOfferWallUrl(userId: 'user-123');

      final uri = Uri.parse(url);
      expect(uri.host, 'offers.cpx-research.com');
      expect(uri.queryParameters['app_id'], AppConstants.cpxAppId);
      expect(uri.queryParameters['ext_user_id'], 'user-123');
    });

    test('omits secure_hash when no app secure hash is configured', () {
      final provider = CpxProvider();
      final url = provider.buildOfferWallUrl(userId: 'user-123');
      expect(Uri.parse(url).queryParameters.containsKey('secure_hash'), false);
    });

    test('adds secure_hash = md5("{userId}-{secret}") when configured', () {
      final provider = CpxProvider();
      const config = CpxConfig(appId: '35037', appSecureHash: 's3cret');
      final url = provider.buildOfferWallUrl(
        userId: 'user-123',
        config: config,
      );

      final expected =
          md5.convert(utf8.encode('user-123-s3cret')).toString();
      expect(Uri.parse(url).queryParameters['secure_hash'], expected);
    });

    test('adds email and username params', () {
      final provider = CpxProvider();
      final url = provider.buildOfferWallUrl(
        userId: 'user-123',
        email: 'a@b.co',
        username: 'Cool User',
      );

      final params = Uri.parse(url).queryParameters;
      expect(params['email'], 'a@b.co');
      expect(params['username'], 'Cool User');
    });

    test('isEnabled defaults to true when no config is loaded', () {
      final provider = CpxProvider();
      expect(provider.isEnabled, true);
    });
  });
}
