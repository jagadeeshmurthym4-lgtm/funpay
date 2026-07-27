sealed class Failure {
  final String message;
  const Failure(this.message);
}

final class AuthFailure extends Failure {
  final String? code;
  const AuthFailure(super.message, {this.code});
}

final class FirestoreFailure extends Failure {
  final String? code;
  const FirestoreFailure(super.message, {this.code});
}

final class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

final class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

final class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}
