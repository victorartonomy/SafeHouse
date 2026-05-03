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
      default:
        return e.message ?? 'An unknown authentication error occurred.';
    }
  }

  @override
  Future<void> signOut() async {
    await googleSignIn.signOut();
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
        await googleSignIn.disconnect();
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
