import 'dart:async';
import 'package:cashspark/core/errors/exceptions.dart';
import 'package:cashspark/domain/entities/user_entity.dart';
import 'package:cashspark/domain/repositories/auth_repository.dart';
import 'package:cashspark/services/firestore_cache_busting_service.dart';
import 'package:flutter/foundation.dart';

enum AuthStatus { uninitialized, authenticated, unauthenticated, loading }

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;
  StreamSubscription? _authSubscription;

  AuthStatus _status = AuthStatus.uninitialized;
  UserEntity? _user;
  String? _errorMessage;
  String? _successMessage;
  bool _isLoading = false;
  bool _isNewUser = false;

  /// Prevents notifyListeners() after dispose, which would crash with
  /// "InheritedProvider setState() after dispose" FlutterError.
  bool _disposed = false;

  AuthProvider({
    required AuthRepository authRepository,
  }) : _authRepository = authRepository {
    _init();
  }

  AuthStatus get status => _status;
  UserEntity? get user => _user;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isNewUser => _isNewUser;
  bool get needsProfileCompletion => _isNewUser || (_user != null && !_user!.profileCompleted);

  void _init() async {
    if (_disposed) return;
    _status = AuthStatus.loading;
    _safeNotifyListeners();

    final existingUser = _authRepository.currentUser;
    if (existingUser != null) {
      try {
        _user = await _authRepository.getCurrentUser();
        _status = AuthStatus.authenticated;
        _isNewUser = _user != null && !_user!.profileCompleted;
        _safeNotifyListeners();
      } catch (_) {
        if (_disposed) return;
        _user = existingUser;
        _status = AuthStatus.authenticated;
        _isNewUser = existingUser.profileCompleted == false;
        _safeNotifyListeners();
      }
    }

    if (_disposed) return;
    _authSubscription = _authRepository.authStateChanges.listen(
      (userEntity) {
        if (_disposed) return;
        if (_status == AuthStatus.authenticated && userEntity != null) {
          return;
        }
        if (userEntity != null) {
          _status = AuthStatus.authenticated;
        } else if (_status != AuthStatus.authenticated) {
          _user = null;
          _status = AuthStatus.unauthenticated;
        }
        _safeNotifyListeners();
      },
      onError: (error) {
        if (_disposed) return;
        if (_status != AuthStatus.authenticated) {
          _errorMessage = error.toString();
          _status = AuthStatus.unauthenticated;
          _safeNotifyListeners();
        }
      },
    );
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      _user = await _authRepository.signInWithEmail(
        email: email,
        password: password,
      );
      _status = AuthStatus.authenticated;
      _isNewUser = false;

      // Bust Firestore cache so the freshly logged-in user sees the
      // absolute latest data from the server on every device.
      unawaited(_bustCacheAfterLogin());
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _status = AuthStatus.unauthenticated;
    } catch (e) {
      debugPrint('AuthProvider.signInWithEmail error: $e${(e is Error) ? '\\n${e.stackTrace}' : ''}');
      _errorMessage = 'Sign-in failed. Please try again.';
      _status = AuthStatus.unauthenticated;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signInWithGoogle() async {
    _setLoading(true);
    _clearError();
    try {
      final result = await _authRepository.signInWithGoogle();
      _user = result.user;
      _isNewUser = result.isNewUser;
      _status = AuthStatus.authenticated;

      // Bust Firestore cache after Google sign-in.
      unawaited(_bustCacheAfterLogin());
    } on AuthCancelledException {
      // User cancelled the Google account picker — silently ignore.
      // Don't set any error message, don't change status.
      _status = AuthStatus.unauthenticated;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      debugPrint('[AuthProvider] signInWithGoogle AuthException: ${e.message} (code: ${e.code})');
      _status = AuthStatus.unauthenticated;
    } catch (e) {
      debugPrint('[AuthProvider] signInWithGoogle error: $e${(e is Error) ? '\\n${e.stackTrace}' : ''}');
      _errorMessage = 'Google sign-in failed. Please try again or use email sign-in.';
      _status = AuthStatus.unauthenticated;
    } finally {
      _setLoading(false);
    }
  }

  /// Combined flow: signs in with Google then immediately completes the profile.
  /// Used by the new user registration screen to avoid an intermediate
  /// "incomplete profile" state that could trigger a redirect.
  ///
  /// [gmailAddress] is the email the user entered on the registration form.
  /// It is validated against the Google account email after sign-in.
  Future<void> signUpWithGoogleAndCompleteProfile({
    required String firstName,
    required String lastName,
    required String phone,
    required String dateOfBirth,
    required String gmailAddress,
    String? referralCode,
  }) async {
    _isLoading = true;
    _clearError();
    notifyListeners();
    try {
      // Step 1: Sign in with Google
      final result = await _authRepository.signInWithGoogle();
      _user = result.user;
      _isNewUser = result.isNewUser;
      _status = AuthStatus.authenticated;

      // Validate that the Google account email matches the entered Gmail
      final googleEmail = _user!.email.trim().toLowerCase();
      final enteredEmail = gmailAddress.trim().toLowerCase();
      if (googleEmail != enteredEmail) {
        // Sign out to undo the Google sign-in
        await _authRepository.signOut();
        _user = null;
        _isNewUser = false;
        _status = AuthStatus.unauthenticated;
        throw AuthException(
          'The Gmail address you entered ($enteredEmail) does not match '
          'the Google account you signed in with ($googleEmail). '
          'Please use the same Google account as the Gmail address you entered.',
        );
      }

      // Bust Firestore cache after Google sign-in for new user.
      unawaited(_bustCacheAfterLogin());

      // Step 2: Complete the profile with registration form data
      _user = await _authRepository.completeProfile(
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        dateOfBirth: dateOfBirth,
        referralCode: referralCode,
      );
      _isNewUser = false;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _status = AuthStatus.unauthenticated;
      rethrow;
    } on ReferralException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      debugPrint('AuthProvider.signUpWithGoogleAndCompleteProfile error: $e${(e is Error) ? '\\n${e.stackTrace}' : ''}');
      _errorMessage = _friendlyErrorMessage(e);
      _status = AuthStatus.unauthenticated;
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  Future<void> completeProfile({
    required String firstName,
    required String lastName,
    required String phone,
    required String dateOfBirth,
    String? referralCode,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      _user = await _authRepository.completeProfile(
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        dateOfBirth: dateOfBirth,
        referralCode: referralCode,
      );
      _isNewUser = false;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      rethrow;
    } on ReferralException catch (e) {
      _errorMessage = e.message;
      rethrow;
    } catch (e) {
      _errorMessage = 'Failed to complete profile: ${e.toString()}';
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    _clearError();
    try {
      await _authRepository.signOut();
      _user = null;
      _isNewUser = false;
      _status = AuthStatus.unauthenticated;
    } catch (e) {
      _errorMessage = 'Failed to sign out';
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    _setLoading(true);
    _clearError();
    try {
      // Configure ActionCodeSettings so the password reset link can
      // open the app directly on mobile or handle it in-app on web.
      final actionCodeSettings = <String, dynamic>{
        'url': 'https://cashspark-c15bd.firebaseapp.com',
        'handleCodeInApp': true,
        'iOSBundleId': 'com.spydev.funpay',
        'androidPackageName': 'com.spydev.funpay',
        'androidInstallApp': true,
      };

      await _authRepository.sendPasswordResetEmail(
        email,
        actionCodeSettings: actionCodeSettings,
      );
      _setLoading(false);
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = 'Failed to send reset email. Please try again.';
      _setLoading(false);
      return false;
    }
  }

  Future<void> signUpWithEmail({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    String? firstName,
    String? lastName,
    String? dateOfBirth,
    String? referralCode,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      _user = await _authRepository.signUpWithEmail(
        fullName: fullName,
        email: email,
        phone: phone,
        password: password,
        firstName: firstName,
        lastName: lastName,
        dateOfBirth: dateOfBirth,
        referralCode: referralCode,
      );
      _status = AuthStatus.authenticated;
      _isNewUser = false;

      // Send email verification after successful sign-up
      unawaited(_sendVerificationAfterSignUp());

      // Bust Firestore cache after sign-up too.
      unawaited(_bustCacheAfterLogin());
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _status = AuthStatus.unauthenticated;
    } on ReferralException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      debugPrint('AuthProvider.signUpWithEmail error: $e${(e is Error) ? '\\n${e.stackTrace}' : ''}');
      _errorMessage = 'Sign-up failed. Please try again.';
      _status = AuthStatus.unauthenticated;
    } finally {
      _setLoading(false);
    }
  }

  /// Sends an email verification link to the current user.
  ///
  /// Returns `true` if sent successfully, `false` if already verified.
  Future<bool> sendEmailVerification() async {
    try {
      final sent = await _authRepository.sendEmailVerification();
      if (sent) {
        _successMessage = 'Verification email sent! Please check your inbox.';
        _safeNotifyListeners();
      } else {
        _successMessage = 'Your email is already verified.';
        _safeNotifyListeners();
      }
      return sent;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _safeNotifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to send verification email. Please try again.';
      _safeNotifyListeners();
      return false;
    }
  }

  /// Called after sign-up to send verification (best-effort).
  Future<void> _sendVerificationAfterSignUp() async {
    try {
      final sent = await _authRepository.sendEmailVerification();
      if (sent) {
        _successMessage = 'Account created! Please check your email to verify your account.';
        _safeNotifyListeners();
      }
    } catch (e) {
      debugPrint('[AuthProvider] _sendVerificationAfterSignUp error: $e');
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      await _authRepository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
    } on AuthException catch (e) {
      _errorMessage = e.message;
      rethrow;
    } catch (e) {
      debugPrint('AuthProvider.changePassword error: $e${(e is Error) ? '\\n${e.stackTrace}' : ''}');
      _errorMessage = 'Failed to change password. Please check your current password.';
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshUser() async {
    if (_disposed) return;
    try {
      _user = await _authRepository.getCurrentUser();
      if (_user != null) {
        _isNewUser = !_user!.profileCompleted;
      }
      _safeNotifyListeners();
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> updateProfile({
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
    String? upiQrCodeUrl,
    DateTime? qrCodeUploadedAt,
    DateTime? qrCodeUpdatedAt,
    String? qrCodeUploadedBy,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      _user = await _authRepository.updateProfile(
        fullName: fullName,
        phone: phone,
        dateOfBirth: dateOfBirth,
        gender: gender,
        address: address,
        city: city,
        state: state,
        country: country,
        username: username,
        aboutMe: aboutMe,
        education: education,
        experience: experience,
        portfolioLinks: portfolioLinks,
        profilePicture: profilePicture,
        coverImage: coverImage,
        upiQrCodeUrl: upiQrCodeUrl,
        qrCodeUploadedAt: qrCodeUploadedAt,
        qrCodeUpdatedAt: qrCodeUpdatedAt,
        qrCodeUploadedBy: qrCodeUploadedBy,
      );
    } on AuthException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Failed to update profile';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteAccount() async {
    _setLoading(true);
    _clearError();
    try {
      await _authRepository.deleteAccount();
      _user = null;
      _isNewUser = false;
      _status = AuthStatus.unauthenticated;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      rethrow;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred';
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  void clearError() {
    _clearError();
  }

  void _setLoading(bool value) {
    if (_disposed) return;
    _isLoading = value;
    _safeNotifyListeners();
  }

  void _clearError() {
    if (_disposed) return;
    _errorMessage = null;
    _successMessage = null;
    _safeNotifyListeners();
  }

  /// Force-refreshes all Firestore collections after login so the user
  /// sees the latest data from the server on every device.
  Future<void> _bustCacheAfterLogin() async {
    try {
      final uid = _user?.uid;
      if (uid != null) {
        final service = FirestoreCacheBustingService();
        await service.cacheCurrentUserUid(uid);
        await service.refreshOnLogin();
      }
    } catch (e) {
      debugPrint('[AuthProvider] _bustCacheAfterLogin error: $e');
      // Non-critical — stream subscriptions will eventually pick up server data.
    }
  }

  /// Maps common backend/network errors to user-friendly messages.
  /// Never shows raw error codes like "permission-denied" to the user.
  String _friendlyErrorMessage(Object error) {
    final msg = error.toString().toLowerCase();

    if (msg.contains('permission-denied') || msg.contains('permission_denied')) {
      return 'Unable to save your account data. Please try again or contact support.';
    }
    if (msg.contains('network-request-failed') || msg.contains('network_error')) {
      return 'Network error. Please check your internet connection and try again.';
    }
    if (msg.contains('too-many-requests')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    if (msg.contains('unavailable') || msg.contains('deadline-exceeded')) {
      return 'Service is temporarily unavailable. Please try again shortly.';
    }

    return 'Sign-up failed. Please try again.';
  }

  void _safeNotifyListeners() {
    if (_disposed) return;
    try {
      notifyListeners();
    } catch (_) {}
  }

  @override
  void dispose() {
    _disposed = true;
    _authSubscription?.cancel();
    super.dispose();
  }
}
