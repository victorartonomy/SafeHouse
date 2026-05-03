import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/auth_user.dart';

class AuthUserModel extends AuthUser {
  const AuthUserModel({
    required super.id,
    super.email,
    super.displayName,
    super.photoUrl,
  });

  factory AuthUserModel.fromFirebaseUser(User user) {
    return AuthUserModel(
      id: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoURL,
    );
  }

  AuthUser toEntity() {
    return AuthUser(
      id: id,
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
    );
  }
}
