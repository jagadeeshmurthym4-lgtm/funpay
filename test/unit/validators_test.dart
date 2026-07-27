import 'package:cashspark/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators.validateEmail', () {
    test('returns null for valid email', () {
      expect(Validators.validateEmail('test@example.com'), isNull);
      expect(Validators.validateEmail('user.name+tag@domain.co'), isNull);
      expect(Validators.validateEmail('a@b.cd'), isNull);
    });

    test('returns error for empty email', () {
      expect(Validators.validateEmail(''), isNotNull);
      expect(Validators.validateEmail(null), isNotNull);
      expect(Validators.validateEmail('   '), isNotNull);
    });

    test('returns error for invalid email format', () {
      expect(Validators.validateEmail('notanemail'), isNotNull);
      expect(Validators.validateEmail('@domain.com'), isNotNull);
      expect(Validators.validateEmail('user@'), isNotNull);
      expect(Validators.validateEmail('user@.com'), isNotNull);
    });
  });

  group('Validators.validatePassword', () {
    test('returns null for valid password', () {
      expect(Validators.validatePassword('Abcd123!'), isNull);
      expect(Validators.validatePassword('Strong@Pass1'), isNull);
      expect(Validators.validatePassword('A1@${'x' * 100}'), isNull);
    });

    test('returns error for empty password', () {
      expect(Validators.validatePassword(''), isNotNull);
      expect(Validators.validatePassword(null), isNotNull);
    });

    test('returns error for password too short', () {
      expect(Validators.validatePassword('Ab1@'), isNotNull);
      expect(Validators.validatePassword('Ab12@'), isNotNull);
      expect(Validators.validatePassword('Abc1@'), isNotNull);
    });

    test('returns error for password without uppercase', () {
      expect(Validators.validatePassword('abcd123!'), isNotNull);
    });

    test('returns error for password without lowercase', () {
      expect(Validators.validatePassword('ABCD123!'), isNotNull);
    });

    test('returns error for password without number', () {
      expect(Validators.validatePassword('Abcdefg!'), isNotNull);
    });

    test('returns error for password without special character', () {
      expect(Validators.validatePassword('Abcdefg1'), isNotNull);
    });
  });

  group('Validators.validateFullName', () {
    test('returns null for valid name', () {
      expect(Validators.validateFullName('John Doe'), isNull);
      expect(Validators.validateFullName('Alice'), isNull);
      expect(Validators.validateFullName('Ab'), isNull);
    });

    test('returns error for empty name', () {
      expect(Validators.validateFullName(''), isNotNull);
      expect(Validators.validateFullName(null), isNotNull);
      expect(Validators.validateFullName('   '), isNotNull);
    });

    test('returns error for name with special characters', () {
      expect(Validators.validateFullName('John123'), isNotNull);
      expect(Validators.validateFullName('User!Name'), isNotNull);
    });
  });

  group('Validators.validatePhone', () {
    test('returns null for empty phone (optional field)', () {
      expect(Validators.validatePhone(''), isNull);
      expect(Validators.validatePhone(null), isNull);
    });

    test('returns null for valid phone', () {
      expect(Validators.validatePhone('9876543210'), isNull);
      expect(Validators.validatePhone('+919876543210'), isNull);
    });

    test('returns error for too short phone', () {
      expect(Validators.validatePhone('12345'), isNotNull);
    });

    test('returns error for invalid characters in phone', () {
      expect(Validators.validatePhone('abc123'), isNotNull);
    });
  });

  group('Validators.validateReferralCode', () {
    test('returns null for empty code (optional field)', () {
      expect(Validators.validateReferralCode(''), isNull);
      expect(Validators.validateReferralCode(null), isNull);
    });

    test('returns null for valid referral code', () {
      expect(Validators.validateReferralCode('ABC12345'), isNull);
    });

    test('returns error for wrong length', () {
      expect(Validators.validateReferralCode('ABC'), isNotNull);
      expect(Validators.validateReferralCode('ABCDEFGHI'), isNotNull);
    });

    test('returns error for special characters', () {
      expect(Validators.validateReferralCode('ABC 1234'), isNotNull);
    });
  });

  group('Validators.validateConfirmPassword', () {
    test('returns null when passwords match', () {
      expect(Validators.validateConfirmPassword('Password1', 'Password1'), isNull);
    });

    test('returns error when confirm is empty', () {
      expect(Validators.validateConfirmPassword('Password1', ''), isNotNull);
      expect(Validators.validateConfirmPassword('Password1', null), isNotNull);
    });

    test('returns error when passwords do not match', () {
      expect(Validators.validateConfirmPassword('Password1', 'Different1'), isNotNull);
    });
  });
}
