import 'package:cashspark/core/utils/helpers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Helpers.formatCurrency', () {
    test('formats positive amounts correctly', () {
      expect(Helpers.formatCurrency(0), '0.00 pts');
      expect(Helpers.formatCurrency(10.5), '10.50 pts');
      expect(Helpers.formatCurrency(1000), '1000.00 pts');
      expect(Helpers.formatCurrency(99.99), '99.99 pts');
      expect(Helpers.formatCurrency(1234.567), '1234.57 pts');
    });

    test('formats zero correctly', () {
      expect(Helpers.formatCurrency(0.0), '0.00 pts');
    });

    test('formats negative amounts correctly', () {
      expect(Helpers.formatCurrency(-10), '-10.00 pts');
      expect(Helpers.formatCurrency(-0.5), '-0.50 pts');
    });
  });

  group('Helpers.formatNumber', () {
    test('formats numbers less than 1000', () {
      expect(Helpers.formatNumber(0), '0');
      expect(Helpers.formatNumber(999), '999');
      expect(Helpers.formatNumber(100), '100');
    });

    test('formats thousands with K suffix', () {
      expect(Helpers.formatNumber(1000), '1.0K');
      expect(Helpers.formatNumber(1500), '1.5K');
      expect(Helpers.formatNumber(10000), '10.0K');
      expect(Helpers.formatNumber(999999), '1000.0K');
    });

    test('formats millions with M suffix', () {
      expect(Helpers.formatNumber(1000000), '1.0M');
      expect(Helpers.formatNumber(2500000), '2.5M');
    });

    test('handles string numbers', () {
      expect(Helpers.formatNumber('1000'), '0');
      expect(Helpers.formatNumber('500'), '0');
    });
  });

  group('Helpers.formatDateTime', () {
    test('returns "Just now" for recent times', () {
      final now = DateTime.now();
      final justNow = now.subtract(const Duration(seconds: 30));
      expect(Helpers.formatDateTime(justNow), 'Just now');
    });

    test('returns minutes ago format', () {
      final now = DateTime.now();
      final minutesAgo = now.subtract(const Duration(minutes: 5));
      expect(Helpers.formatDateTime(minutesAgo), '5m ago');
    });

    test('returns hours ago format', () {
      final now = DateTime.now();
      final hoursAgo = now.subtract(const Duration(hours: 3));
      expect(Helpers.formatDateTime(hoursAgo), '3h ago');
    });

    test('returns days ago format', () {
      final now = DateTime.now();
      final daysAgo = now.subtract(const Duration(days: 4));
      expect(Helpers.formatDateTime(daysAgo), '4d ago');
    });

    test('returns date format for older dates', () {
      final date = DateTime(2024, 1, 15);
      expect(Helpers.formatDateTime(date), '15/1/2024');
    });
  });

  group('Helpers.maskEmail', () {
    test('masks middle of email name', () {
      expect(Helpers.maskEmail('john.doe@example.com'), 'jo***@example.com');
    });

    test('masks short email names', () {
      // 2-char names get masked from the first char
      expect(Helpers.maskEmail('ab@test.com'), 'a***@test.com');
      expect(Helpers.maskEmail('a@test.com'), 'a***@test.com');
    });

    test('returns original string if no @ symbol', () {
      expect(Helpers.maskEmail('notanemail'), 'notanemail');
    });
  });

  group('Helpers.generateReferralCode', () {
    test('generates code of correct length', () {
      final code = Helpers.generateReferralCode();
      expect(code.length, 8);
    });

    test('generates code with custom length', () {
      final code = Helpers.generateReferralCode(length: 12);
      expect(code.length, 12);
    });

    test('generates alphanumeric codes', () {
      for (var i = 0; i < 10; i++) {
        final code = Helpers.generateReferralCode();
        expect(code, matches(RegExp(r'^[A-Z0-9]+$')));
      }
    });

    test('generates unique codes', () {
      final codes = <String>{};
      for (var i = 0; i < 100; i++) {
        codes.add(Helpers.generateReferralCode());
      }
      expect(codes.length, 100);
    });
  });

  group('Helpers.safeCast', () {
    test('returns value when type matches', () {
      expect(Helpers.safeCast<String>('hello'), 'hello');
      expect(Helpers.safeCast<int>(42), 42);
    });

    test('returns null when type does not match', () {
      expect(Helpers.safeCast<int>('hello'), isNull);
      expect(Helpers.safeCast<String>(42), isNull);
    });

    test('returns null for null input', () {
      expect(Helpers.safeCast<String>(null), isNull);
    });
  });
}
