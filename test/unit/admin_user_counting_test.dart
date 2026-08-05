import 'package:cashspark/data/datasources/admin_firestore_datasource.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('countUniqueUsersByEmail', () {
    Map<String, dynamic> userDoc({required String uid, String? email}) => {
          'uid': uid,
          'fullName': 'User $uid',
          if (email != null) 'email': email,
        };

    test('counts the same email (new UID after re-signup) only once', () {
      final docs = [
        userDoc(uid: 'uid-a', email: 'same@test.com'),
        userDoc(uid: 'uid-b', email: 'same@test.com'),
        userDoc(uid: 'uid-c', email: 'other@test.com'),
      ];
      expect(countUniqueUsersByEmail(docs), 2);
    });

    test('matches emails case-insensitively and trims whitespace', () {
      final docs = [
        userDoc(uid: 'uid-a', email: '  User@TEST.com  '),
        userDoc(uid: 'uid-b', email: 'user@test.com'),
      ];
      expect(countUniqueUsersByEmail(docs), 1);
    });

    test('counts docs without a usable email individually', () {
      final docs = [
        userDoc(uid: 'uid-a'),
        userDoc(uid: 'uid-b', email: ''),
        userDoc(uid: 'uid-c', email: 'a@b.com'),
      ];
      expect(countUniqueUsersByEmail(docs), 3);
    });

    test('handles empty input', () {
      expect(countUniqueUsersByEmail(const []), 0);
    });
  });
}
