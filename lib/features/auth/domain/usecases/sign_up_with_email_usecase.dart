import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

class SignUpWithEmailUseCase
    implements UseCase<Either<Failure, AuthUser>, SignUpWithEmailParams> {
  final AuthRepository repository;

  SignUpWithEmailUseCase(this.repository);

  @override
  Future<Either<Failure, AuthUser>> call(SignUpWithEmailParams params) {
    return repository.signUpWithEmail(
      email: params.email,
      password: params.password,
    );
  }
}

class SignUpWithEmailParams extends Equatable {
  final String email;
  final String password;

  const SignUpWithEmailParams({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}
