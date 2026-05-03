import 'package:equatable/equatable.dart';

/// Base contract for all use cases in the domain layer.
/// [Output] is the return type; [Params] carries the input arguments.
abstract class UseCase<Output, Params> {
  Future<Output> call(Params params);
}

/// Sentinel used when a use case requires no parameters.
class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object> get props => [];
}
