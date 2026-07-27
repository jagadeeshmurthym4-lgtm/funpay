import 'package:cashspark/domain/entities/user_entity.dart';
import 'package:cashspark/domain/repositories/auth_repository.dart';

class SignInWithGoogle {
  final AuthRepository repository;
  SignInWithGoogle(this.repository);

  Future<({UserEntity user, bool isNewUser})> call() {
    return repository.signInWithGoogle();
  }
}

class SignOut {
  final AuthRepository repository;
  SignOut(this.repository);

  Future<void> call() {
    return repository.signOut();
  }
}

class GetCurrentUser {
  final AuthRepository repository;
  GetCurrentUser(this.repository);

  Future<UserEntity?> call() {
    return repository.getCurrentUser();
  }
}

class AuthStateChanges {
  final AuthRepository repository;
  AuthStateChanges(this.repository);

  Stream<UserEntity?> call() {
    return repository.authStateChanges;
  }
}
