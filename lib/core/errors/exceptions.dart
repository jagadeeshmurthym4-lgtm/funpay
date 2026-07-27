class AuthException implements Exception {
  final String message;
  final String? code;
  AuthException(this.message, {this.code});

  @override
  String toString() => 'AuthException: $message (code: $code)';
}

class FirestoreException implements Exception {
  final String message;
  final String? code;
  FirestoreException(this.message, {this.code});

  @override
  String toString() => 'FirestoreException: $message (code: $code)';
}

class CacheException implements Exception {
  final String message;
  CacheException(this.message);

  @override
  String toString() => 'CacheException: $message';
}

class WalletException implements Exception {
  final String message;
  final String? code;
  WalletException(this.message, {this.code});

  @override
  String toString() => 'WalletException: $message (code: $code)';
}

class InsufficientBalanceException implements Exception {
  final String message;
  InsufficientBalanceException([this.message = 'Insufficient balance']);

  @override
  String toString() => 'InsufficientBalanceException: $message';
}

class ReferralException implements Exception {
  final String message;
  final String? code;
  ReferralException(this.message, {this.code});

  @override
  String toString() => 'ReferralException: $message (code: $code)';
}

class RewardsException implements Exception {
  final String message;
  RewardsException(this.message);

  @override
  String toString() => 'RewardsException: $message';
}

class WithdrawalException implements Exception {
  final String message;
  WithdrawalException(this.message);

  @override
  String toString() => 'WithdrawalException: $message';
}

class AdminException implements Exception {
  final String message;
  AdminException(this.message);

  @override
  String toString() => 'AdminException: $message';
}

class FraudException implements Exception {
  final String message;
  FraudException(this.message);

  @override
  String toString() => 'FraudException: $message';
}
