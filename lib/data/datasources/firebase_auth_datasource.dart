import 'package:cashspark/core/errors/exceptions.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/services.dart' show PlatformException;
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseAuthDataSource {
  final auth.FirebaseAuth _auth;
  bool _googleSignInInitialized = false;

  /// Logs Firebase project info on initialization for debugging.
  FirebaseAuthDataSource({
    auth.FirebaseAuth? authInstance,
  })  : _auth = authInstance ?? auth.FirebaseAuth.instance {
    _logFirebaseProjectInfo();
  }

  /// Ensures GoogleSignIn is initialized before use (singleton, call once).
  /// Uses the Web client ID as serverClientId for Android to match the OAuth configuration.
  Future<void> _ensureGoogleSignInInitialized() async {
    if (!_googleSignInInitialized) {
      await GoogleSignIn.instance.initialize(
        serverClientId: '198439372867-5vfkneio32asqs6im247t0sle8dkcccs.apps.googleusercontent.com',
      );
      _googleSignInInitialized = true;
    }
  }

  Stream<auth.User?> get authStateChanges => _auth.authStateChanges();

  auth.User? get currentUser => _auth.currentUser;

  /// Logs the connected Firebase project info at runtime for debugging.
  void _logFirebaseProjectInfo() {
    try {
      final app = _auth.app;
      debugPrint('========== FIREBASE PROJECT INFO ==========');
      debugPrint('Firebase App Name: ${app.name}');
      debugPrint('Firebase Project ID: ${app.options.projectId}');
      debugPrint('Firebase App ID: ${app.options.appId}');
      final apiKey = app.options.apiKey;
      debugPrint('Firebase API Key: ${apiKey.length >= 8 ? apiKey.substring(0, 8) : apiKey}...');
      debugPrint('Firebase Storage Bucket: ${app.options.storageBucket}');
      debugPrint('Firebase Messaging Sender ID: ${app.options.messagingSenderId}');
      debugPrint('Auth instance: ${_auth.hashCode}');
      debugPrint('===========================================');
    } catch (e) {
      debugPrint('[FirebaseAuthDataSource] Error logging Firebase project info: $e');
    }
  }

  Future<auth.UserCredential> signInWithGoogle() async {
    if (kIsWeb) {
      final provider = auth.GoogleAuthProvider();
      final credential = await _auth.signInWithPopup(provider);
      return credential;
    }

    debugPrint('[FirebaseAuthDataSource] signInWithGoogle started');
    await _ensureGoogleSignInInitialized();
    final googleSignIn = GoogleSignIn.instance;

    // Try lightweight authentication first (no UI if previously signed in)
    GoogleSignInAccount? googleUser;
    bool cameFromSilentSignIn = false;
    try {
      final future = googleSignIn.attemptLightweightAuthentication();
      if (future != null) {
        googleUser = await future;
        cameFromSilentSignIn = googleUser != null;
      }
    } catch (e) {
      debugPrint('[FirebaseAuthDataSource] Lightweight auth attempt failed: $e');
    }

    if (googleUser == null) {
      debugPrint('[FirebaseAuthDataSource] No cached Google session — showing account picker');
      try {
        googleUser = await googleSignIn.authenticate();
      } on GoogleSignInException catch (e) {
        if (e.code == GoogleSignInExceptionCode.canceled) {
          debugPrint('[FirebaseAuthDataSource] Google sign-in was cancelled by user');
          throw AuthCancelledException();
        }
        debugPrint('[FirebaseAuthDataSource] GoogleSignInException: code=${e.code}');
        rethrow;
      } on PlatformException catch (e) {
        // PlatformException is thrown on Android when the OAuth client
        // configuration is incorrect (e.g. missing SHA fingerprint, mismatched
        // package name, or invalid client ID).
        debugPrint('[FirebaseAuthDataSource] PlatformException during Google sign-in:');
        debugPrint('  code: ${e.code}');
        debugPrint('  message: ${e.message}');
        debugPrint('  details: ${e.details}');

        // Common Android error codes:
        //   'sign_in_required' - user needs to pick an account (not a failure)
        //   'sign_in_failed' - actual auth failure
        //   'network_error' - network issue
        //   'internal_error' - often SHA mismatch or OAuth config problem
        if (e.code == 'sign_in_required') {
          debugPrint('[FirebaseAuthDataSource] sign_in_required indicates no accounts on device');
          throw AuthCancelledException();
        }
        rethrow;
      } catch (e) {
        debugPrint('[FirebaseAuthDataSource] Unexpected error during Google sign-in authenticate(): $e');
        if (e is Error) debugPrint('  stack: ${e.stackTrace}');
        rethrow;
      }
    }

    debugPrint('[FirebaseAuthDataSource] Google user selected: ${googleUser.email}');

    try {
      final googleAuth = googleUser.authentication;
      debugPrint('[FirebaseAuthDataSource] Google authentication tokens obtained: idToken=${googleAuth.idToken != null}');

      if (googleAuth.idToken == null) {
        // If lightweight auth returned a stale session with no idToken,
        // fall back to interactive sign-in to get fresh tokens.
        if (cameFromSilentSignIn) {
          debugPrint('[FirebaseAuthDataSource] Lightweight auth returned stale session — retrying with interactive sign-in');
          await googleSignIn.signOut();
          try {
            googleUser = await googleSignIn.authenticate();
          } on GoogleSignInException catch (e) {
            if (e.code == GoogleSignInExceptionCode.canceled) {
              debugPrint('[FirebaseAuthDataSource] Google sign-in was cancelled by user (retry)');
              throw AuthCancelledException();
            }
            debugPrint('[FirebaseAuthDataSource] GoogleSignInException (retry): code=${e.code}');
            rethrow;
          } on PlatformException catch (e) {
            debugPrint('[FirebaseAuthDataSource] PlatformException during retry: code=${e.code}, message=${e.message}, details=${e.details}');
            rethrow;
          }
          debugPrint('[FirebaseAuthDataSource] Interactive sign-in user selected: ${googleUser.email}');
          final freshAuth = googleUser.authentication;
          debugPrint('[FirebaseAuthDataSource] Fresh tokens: idToken=${freshAuth.idToken != null}');
          if (freshAuth.idToken == null) {
            debugPrint('[FirebaseAuthDataSource] CRITICAL: idToken still null after interactive sign-in!');
            debugPrint('[FirebaseAuthDataSource] This usually means the serverClientId does not match any Web OAuth client in Firebase Console.');
            debugPrint('[FirebaseAuthDataSource] Verify: serverClientId = 198439372867-5vfkneio32asqs6im247t0sle8dkcccs.apps.googleusercontent.com');
            throw const AuthConfigurationException(
              'Google sign-in configuration error: Unable to obtain authentication token. '
              'Please contact support with error code: TOKEN_NULL.',
            );
          }
          final credential = auth.GoogleAuthProvider.credential(
            idToken: freshAuth.idToken,
          );
          debugPrint('[FirebaseAuthDataSource] Firebase credential created from fresh tokens, signing in...');
          final result = await _auth.signInWithCredential(credential);
          debugPrint('[FirebaseAuthDataSource] Firebase signInWithCredential succeeded for: ${result.user?.email}');
          return result;
        }
        debugPrint('[FirebaseAuthDataSource] CRITICAL: idToken is null!');
        debugPrint('[FirebaseAuthDataSource] This usually means the serverClientId does not match any Web OAuth client in Firebase Console.');
        debugPrint('[FirebaseAuthDataSource] Verify: serverClientId = 198439372867-5vfkneio32asqs6im247t0sle8dkcccs.apps.googleusercontent.com');
        throw const AuthConfigurationException(
          'Google sign-in configuration error: Unable to obtain authentication token. '
          'Please contact support with error code: TOKEN_NULL.',
        );
      }

      // Only idToken is available in google_sign_in 7.x; accessToken was removed.
      // Firebase credential only requires idToken for Google sign-in.
      final credential = auth.GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      debugPrint('[FirebaseAuthDataSource] Firebase credential created, signing in...');
      final result = await _auth.signInWithCredential(credential);
      debugPrint('[FirebaseAuthDataSource] Firebase signInWithCredential succeeded for: ${result.user?.email}');
      return result;
    } on auth.FirebaseAuthException catch (e) {
      debugPrint('[FirebaseAuthDataSource] FirebaseAuthException during credential exchange:');
      debugPrint('  code: ${e.code}');
      debugPrint('  message: ${e.message}');
      debugPrint('  credential: ${e.credential}');
      rethrow;
    } catch (e) {
      debugPrint('[FirebaseAuthDataSource] Google sign-in error: $e');
      if (e is Error) {
        debugPrint('[FirebaseAuthDataSource] Error stack trace: ${e.stackTrace}');
      }
      rethrow;
    }
  }

  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  Future<void> signOut() async {
    await _ensureGoogleSignInInitialized();
    await GoogleSignIn.instance.signOut();
    await GoogleSignIn.instance.disconnect();
    await _auth.signOut();
  }

  Future<void> sendPasswordResetEmail(
    String email, {
    auth.ActionCodeSettings? actionCodeSettings,
  }) async {
    await _auth.sendPasswordResetEmail(
      email: email,
      actionCodeSettings: actionCodeSettings,
    );
  }

  /// Sends an email verification link to the currently signed-in user.
  Future<void> sendEmailVerification({
    auth.ActionCodeSettings? actionCodeSettings,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw auth.FirebaseAuthException(
        code: 'no-current-user',
        message: 'No user is currently signed in.',
      );
    }
    await user.sendEmailVerification(actionCodeSettings);
  }

  Future<auth.UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential;
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');
    if (user.email == null) throw Exception('No email on account');

    final credential = auth.EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }

  Future<auth.UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential;
  }

  Future<void> deleteUser() async {
    await _auth.currentUser?.delete();
  }
}
