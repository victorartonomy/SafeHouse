import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/auth_user.dart';

abstract class AuthRepository {
  Future<Either<Failure, AuthUser>> signInWithEmail({
    required String email,
    required String password,
  });

  Future<Either<Failure, AuthUser>> signUpWithEmail({
    required String email,
    required String password,
  });

  Future<Either<Failure, AuthUser>> signInWithGoogle();

  Future<Either<Failure, void>> signOut();

  Future<Either<Failure, void>> deleteAccount();

  Future<Either<Failure, AuthUser?>> getCurrentUser();

  Stream<AuthUser?> get authStateChanges;
}
