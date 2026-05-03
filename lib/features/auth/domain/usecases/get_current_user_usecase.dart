import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

class GetCurrentUserUseCase
    implements UseCase<Either<Failure, AuthUser?>, NoParams> {
  final AuthRepository repository;

  GetCurrentUserUseCase(this.repository);

  @override
  Future<Either<Failure, AuthUser?>> call(NoParams params) {
    return repository.getCurrentUser();
  }
}
