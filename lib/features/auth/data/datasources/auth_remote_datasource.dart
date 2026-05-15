import 'dart:developer' as developer;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/auth_user_model.dart';

abstract class AuthRemoteDataSource {
  Future<AuthUserModel> signInWithEmail({
    required String email,
    required String password,
  });

  Future<AuthUserModel> signUpWithEmail({
    required String email,
    required String password,
  });

  Future<AuthUserModel> signInWithGoogle();

  Future<void> signOut();

  Future<void> deleteAccount();

  Future<AuthUserModel?> getCurrentUser();

  Stream<AuthUserModel?> get authStateChanges;
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth firebaseAuth;
  final GoogleSignIn googleSignIn;

  AuthRemoteDataSourceImpl({
    required this.firebaseAuth,
    required this.googleSignIn,
  });

  Future<void> _safeGoogleSignOut() async {
    try {
      await googleSignIn.signOut();
    } catch (e, stackTrace) {
      // Log Google sign-out failures (e.g., network issues or revoked
      // permissions) without blocking the caller's flow.
      developer.log(
        'Google sign-out failed.',
        error: e,
        stackTrace: stackTrace,
        name: 'AuthRemoteDataSource',
      );
    }
  }

  Future<void> _safeGoogleDisconnect() async {
    try {
      await googleSignIn.disconnect();
    } catch (e, stackTrace) {
      // Fallback to a simple sign-out if disconnect fails (for example,
      // due to network issues or revoked permissions). Errors are logged
      // but do not block account deletion.
      developer.log(
        'Google disconnect failed. Falling back to sign-out.',
        error: e,
        stackTrace: stackTrace,
        name: 'AuthRemoteDataSource',
      );
      await _safeGoogleSignOut();
    }
  }

  @override
  Future<AuthUserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user == null) {
        throw Exception(
          'An unexpected error occurred during login. Please try again.',
        );
      }
      return AuthUserModel.fromFirebaseUser(credential.user!);
    } on FirebaseAuthException catch (e) {
      throw Exception(_getReadableFirebaseAuthErrorMessage(e));
    } catch (e) {
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  @override
  Future<AuthUserModel> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user == null) {
        throw Exception(
          'An unexpected error occurred during sign up. Please try again.',
        );
      }
      return AuthUserModel.fromFirebaseUser(credential.user!);
    } on FirebaseAuthException catch (e) {
      throw Exception(_getReadableFirebaseAuthErrorMessage(e));
    } catch (e) {
      throw Exception('Sign up failed: ${e.toString()}');
    }
  }

  @override
  Future<AuthUserModel> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google sign-in was cancelled by the user.');
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      // Firebase accepts either token type when building credentials.
      if (googleAuth.idToken == null && googleAuth.accessToken == null) {
        throw Exception(
          'No authentication tokens received from Google. Please try again.',
        );
      }
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await firebaseAuth.signInWithCredential(
        credential,
      );
      if (userCredential.user == null) {
        throw Exception('An unexpected error occurred during Google sign-in.');
      }
      return AuthUserModel.fromFirebaseUser(userCredential.user!);
    } on FirebaseAuthException catch (e) {
      throw Exception(_getReadableFirebaseAuthErrorMessage(e));
    } catch (e) {
      throw Exception('Google sign-in failed: ${e.toString()}');
    }
  }

  String _getReadableFirebaseAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found for that email address.';
      case 'wrong-password':
        return 'Incorrect password provided for that user.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'email-already-in-use':
        return 'The account already exists for that email.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      case 'weak-password':
        return 'The password provided is too weak. Please use a stronger password.';
      case 'invalid-credential':
        return 'Invalid credentials provided. Please check your email and password.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with a different sign-in method.';
      case 'credential-already-in-use':
        return 'These credentials are already linked to another account.';
      case 'requires-recent-login':
        return 'Please sign in again to complete this sensitive action.';
      case 'network-request-failed':
        return 'Network error. Please check your connection and try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'user-mismatch':
        return 'The current user does not match the requested credentials.';
      default:
        return e.message ?? 'An unknown authentication error occurred.';
    }
  }

  @override
  Future<void> signOut() async {
    await _safeGoogleSignOut();
    // Firebase sign-out errors propagate to the caller.
    await firebaseAuth.signOut();
  }

  @override
  Future<void> deleteAccount() async {
    final user = firebaseAuth.currentUser;
    if (user == null) throw Exception('No user currently logged in.');

    try {
      if (user.providerData.any(
        (userInfo) => userInfo.providerId == 'google.com',
      )) {
        await _safeGoogleDisconnect();
      }
      await user.delete();
    } on FirebaseAuthException catch (e) {
      throw Exception(_getReadableFirebaseAuthErrorMessage(e));
    } catch (e) {
      throw Exception('Account deletion failed: ${e.toString()}');
    }
  }

  @override
  Future<AuthUserModel?> getCurrentUser() async {
    final user = firebaseAuth.currentUser;
    return user != null ? AuthUserModel.fromFirebaseUser(user) : null;
  }

  @override
  Stream<AuthUserModel?> get authStateChanges =>
      firebaseAuth.authStateChanges().map(
        (user) => user != null ? AuthUserModel.fromFirebaseUser(user) : null,
      );
}
