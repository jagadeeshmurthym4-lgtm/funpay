import 'package:cashspark/domain/entities/user_entity.dart';

abstract class AuthRepository {
  Stream<UserEntity?> get authStateChanges;
  UserEntity? get currentUser;

  /// Signs in with Google. Returns [UserEntity] and a flag indicating
  /// whether this is a new user (profile needs to be completed).
  Future<({UserEntity user, bool isNewUser})> signInWithGoogle();

  Future<void> reloadUser();
  Future<void> signOut();
  Future<UserEntity?> getCurrentUser();

  /// Completes the profile for a new user, saves all fields to Firestore,
  /// optionally processes referral code bonuses, and marks profile as completed.
  Future<UserEntity> completeProfile({
    required String firstName,
    required String lastName,
    required String phone,
    required String dateOfBirth,
    String? referralCode,
  });

  Future<UserEntity> updateProfile({
    String? fullName,
    String? phone,
    String? dateOfBirth,
    String? gender,
    String? address,
    String? city,
    String? state,
    String? country,
    String? username,
    String? aboutMe,
    String? education,
    String? experience,
    List<String>? portfolioLinks,
    String? profilePicture,
    String? coverImage,
  });

  Future<void> sendPasswordResetEmail(String email, {Map<String, dynamic>? actionCodeSettings});

  /// Sends an email verification link to the currently signed-in user.
  ///
  /// Returns `true` if the email was sent successfully, `false` if
  /// the user's email is already verified.
  Future<bool> sendEmailVerification();

  /// Signs in an existing user with email and password.
  Future<UserEntity> signInWithEmail({
    required String email,
    required String password,
  });

  /// Creates a user with email & password, saves profile to Firestore,
  /// optionally processes referral code, and returns the created user.
  ///
  /// [firstName], [lastName], and [dateOfBirth] are used when the registration
  /// form collects these fields separately. When omitted, [fullName] is split
  /// to derive first/last name.
  Future<UserEntity> signUpWithEmail({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    String? firstName,
    String? lastName,
    String? dateOfBirth,
    String? referralCode,
  });

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<void> deleteAccount();
}
