import 'package:equatable/equatable.dart';

abstract class Either<L, R> extends Equatable {
  const Either();

  B fold<B>(B Function(L l) ifLeft, B Function(R r) ifRight);

  R getOrElse(R Function(L l) ifLeft);

  Either<L, B> map<B>(B Function(R r) f);

  Either<L, R> orElse(Either<L, R> Function(L l) ifLeft);
}

class Left<L, R> extends Either<L, R> {
  final L value;

  const Left(this.value);

  @override
  B fold<B>(B Function(L l) ifLeft, B Function(R r) ifRight) {
    return ifLeft(value);
  }

  @override
  R getOrElse(R Function(L l) ifLeft) {
    return ifLeft(value);
  }

  @override
  Either<L, B> map<B>(B Function(R r) f) {
    return Left(value);
  }

  @override
  Either<L, R> orElse(Either<L, R> Function(L l) ifLeft) {
    return ifLeft(value);
  }

  @override
  List<Object?> get props => [value];
}

class Right<L, R> extends Either<L, R> {
  final R value;

  const Right(this.value);

  @override
  B fold<B>(B Function(L l) ifLeft, B Function(R r) ifRight) {
    return ifRight(value);
  }

  @override
  R getOrElse(R Function(L l) ifLeft) {
    return value;
  }

  @override
  Either<L, B> map<B>(B Function(R r) f) {
    return Right(f(value));
  }

  @override
  Either<L, R> orElse(Either<L, R> Function(L l) ifLeft) {
    return Right(value);
  }

  @override
  List<Object?> get props => [value];
}
