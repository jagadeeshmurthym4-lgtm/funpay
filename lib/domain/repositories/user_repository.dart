import 'package:cashspark/domain/entities/user_entity.dart';

abstract class UserRepository {
  Future<UserEntity> getUser(String uid);
  Future<UserEntity> createUser(UserEntity user);
  Future<UserEntity> updateUser(UserEntity user);
  Future<void> deleteUser(String uid);
  Stream<UserEntity?> streamUser(String uid);
}
