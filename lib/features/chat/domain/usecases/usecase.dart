import '../../../../core/errors/failures.dart';
import '../../../../core/types/either.dart';

/// Base Use Case Class
/// All use cases should extend this class
abstract class UseCase<T, Params> {
  Future<Either<Failure, T>> call(Params params);
}

/// No parameters class for use cases that don't require parameters
class NoParams {
  const NoParams();
}
