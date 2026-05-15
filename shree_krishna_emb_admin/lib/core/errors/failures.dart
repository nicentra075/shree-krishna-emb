import 'package:equatable/equatable.dart';

/// Base failure class for Either[Failure, Data] pattern
abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

/// Server failures from Firebase or API calls
class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

/// Local storage failures from Hive or SharedPreferences
class LocalFailure extends Failure {
  const LocalFailure(super.message);
}

/// Validation failures from input validation
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// Network connectivity failures
class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

/// Unknown/unexpected failures
class UnknownFailure extends Failure {
  const UnknownFailure(super.message);
}
