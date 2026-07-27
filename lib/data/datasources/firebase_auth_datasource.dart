import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
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
          throw Exception('Google sign-in was cancelled');
        }
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
              throw Exception('Google sign-in was cancelled');
            }
            rethrow;
          }
          debugPrint('[FirebaseAuthDataSource] Interactive sign-in user selected: ${googleUser.email}');
          final freshAuth = googleUser.authentication;
          debugPrint('[FirebaseAuthDataSource] Fresh tokens: idToken=${freshAuth.idToken != null}');
          if (freshAuth.idToken == null) {
            debugPrint('[FirebaseAuthDataSource] CRITICAL: idToken still null after interactive sign-in! serverClientId may be incorrect.');
            throw Exception('Google sign-in failed: ID token is null after retry. Verify the OAuth client configuration in Firebase Console.');
          }
          // Use the fresh tokens — only idToken is available in google_sign_in 7.x
          final credential = auth.GoogleAuthProvider.credential(
            idToken: freshAuth.idToken,
          );
          debugPrint('[FirebaseAuthDataSource] Firebase credential created from fresh tokens, signing in...');
          final result = await _auth.signInWithCredential(credential);
          debugPrint('[FirebaseAuthDataSource] Firebase signInWithCredential succeeded for: ${result.user?.email}');
          return result;
        }
        debugPrint('[FirebaseAuthDataSource] CRITICAL: idToken is null! serverClientId may be incorrect.');
        throw Exception('Google sign-in failed: ID token is null. Verify the OAuth client configuration in Firebase Console.');
      }

      // Only idToken is available in google_sign_in 7.x; accessToken was removed.
      // Firebase credential only requires idToken for Google sign-in.
      final credential = auth.GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // If user is already signed in (session restored), reuse the existing session
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        debugPrint('[FirebaseAuthDataSource] User already signed in (${currentUser.uid}) — reusing session');
        // The credential is valid and the user is already logged in.
        // No need to sign in again. Return the current user credential.
        // We still sign in with credential to ensure we have the latest tokens.
        final result = await _auth.signInWithCredential(credential);
        return result;
      }

      debugPrint('[FirebaseAuthDataSource] Firebase credential created, signing in...');
      final result = await _auth.signInWithCredential(credential);
      debugPrint('[FirebaseAuthDataSource] Firebase signInWithCredential succeeded for: ${result.user?.email}');
      return result;
    } catch (e) {
      debugPrint('[FirebaseAuthDataSource] Google sign-in error: $e');
      if (e is auth.FirebaseAuthException) {
        debugPrint('[FirebaseAuthDataSource] FirebaseAuthException code: ${e.code}');
        debugPrint('[FirebaseAuthDataSource] FirebaseAuthException message: ${e.message}');
      } else if (e is Error) {
        debugPrint('[FirebaseAuthDataSource] Error stack trace: ${e.stackTrace}');
      }
      rethrow;
    }
  }

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
  ///
  /// Requires the user to be signed in. Passing [actionCodeSettings] allows
  /// the link to open the app directly on mobile.
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

    // Re-authenticate
    final credential = auth.EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);

    // Update password
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

