import 'package:cashspark/data/datasources/admin_firestore_datasource.dart';
import 'package:cashspark/data/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  UserModel makeUser({
    required String uid,
    String email = '',
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      referralCode: 'REF',
      createdAt: createdAt ?? DateTime(2026, 1, 1),
      lastLoginAt: lastLoginAt,
    );
  }

  group('dedupeUsersByEmail', () {
    test('keeps only the most recently active doc per email', () {
      final users = [
        makeUser(
          uid: 'stale',
          email: 'same@test.com',
          createdAt: DateTime(2026, 7, 1),
          lastLoginAt: DateTime(2026, 7, 5),
        ),
        makeUser(
          uid: 'active',
          email: 'same@test.com',
          createdAt: DateTime(2026, 8, 1),
          lastLoginAt: DateTime(2026, 8, 4),
        ),
      ];
      final result = dedupeUsersByEmail(users);
      expect(result.length, 1);
      expect(result.first.uid, 'active');
    });

    test('prefers lastLoginAt over createdAt when picking the keeper', () {
      final users = [
        makeUser(
          uid: 'newer-created-older-login',
          email: 'a@b.com',
          createdAt: DateTime(2026, 8, 1),
          lastLoginAt: DateTime(2026, 6, 1),
        ),
        makeUser(
          uid: 'older-created-newer-login',
          email: 'A@B.com',
          createdAt: DateTime(2026, 5, 1),
          lastLoginAt: DateTime(2026, 8, 10),
        ),
      ];
      final result = dedupeUsersByEmail(users);
      expect(result.length, 1);
      expect(result.first.uid, 'older-created-newer-login');
    });

    test('keeps every doc without an email', () {
      final users = [
        makeUser(uid: 'no-email-1'),
        makeUser(uid: 'no-email-2'),
        makeUser(uid: 'with-email', email: 'x@y.com'),
      ];
      final result = dedupeUsersByEmail(users);
      expect(result.length, 3);
    });

    test('sorts results by most recent activity first', () {
      final users = [
        makeUser(uid: 'old', email: 'old@t.com', lastLoginAt: DateTime(2026, 1, 1)),
        makeUser(uid: 'new', email: 'new@t.com', lastLoginAt: DateTime(2026, 8, 1)),
      ];
      final result = dedupeUsersByEmail(users);
      expect(result.first.uid, 'new');
    });

    test('handles empty input', () {
      expect(dedupeUsersByEmail(const []), isEmpty);
    });
  });
}
