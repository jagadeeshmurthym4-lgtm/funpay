import 'package:cashspark/core/errors/exceptions.dart';
import 'package:cashspark/data/datasources/firebase_firestore_datasource.dart';
import 'package:cashspark/data/models/user_model.dart';
import 'package:cashspark/domain/entities/user_entity.dart';
import 'package:cashspark/domain/repositories/user_repository.dart';

class UserRepositoryImpl implements UserRepository {
  final FirebaseFirestoreDataSource _firestoreDataSource;

  UserRepositoryImpl({
    required FirebaseFirestoreDataSource firestoreDataSource,
  }) : _firestoreDataSource = firestoreDataSource;

  @override
  Future<UserEntity> getUser(String uid) async {
    try {
      final user = await _firestoreDataSource.getUser(uid);
      if (user == null) throw FirestoreException('User not found');
      return user;
    } catch (e) {
      if (e is FirestoreException) rethrow;
      throw FirestoreException('Failed to get user: $e');
    }
  }

  @override
  Future<UserEntity> createUser(UserEntity user) async {
    try {
      final userModel = UserModel.fromEntity(user);
      await _firestoreDataSource.createUser(userModel);
      return userModel;
    } catch (e) {
      throw FirestoreException('Failed to create user: $e');
    }
  }

  @override
  Future<UserEntity> updateUser(UserEntity user) async {
    try {
      final userModel = UserModel.fromEntity(user);
      await _firestoreDataSource.updateUser(userModel);
      return userModel;
    } catch (e) {
      throw FirestoreException('Failed to update user: $e');
    }
  }

  @override
  Future<void> deleteUser(String uid) async {
    try {
      await _firestoreDataSource.deleteUser(uid);
    } catch (e) {
      throw FirestoreException('Failed to delete user: $e');
    }
  }

  @override
  Stream<UserEntity?> streamUser(String uid) {
    return _firestoreDataSource.streamUser(uid).map((userModel) => userModel);
  }
}
