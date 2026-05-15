import 'package:shree_krishna_core/utils/either.dart';
import 'package:shree_krishna_emb_admin/core/errors/exceptions.dart';
import 'package:shree_krishna_emb_admin/core/errors/failures.dart';
import 'package:shree_krishna_emb_admin/data/datasources/firebase_admin_auth_datasource.dart';
import 'package:shree_krishna_emb_admin/domain/repositories/admin_auth_repository.dart';

/// Concrete implementation of AdminAuthRepository
/// Implements the repository interface and handles error conversion
class AdminAuthRepositoryImpl implements AdminAuthRepository {
  final AdminAuthDataSource _dataSource;

  AdminAuthRepositoryImpl({required AdminAuthDataSource dataSource})
      : _dataSource = dataSource;

  @override
  Future<Either<Failure, AdminAuthSuccess>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final result = await _dataSource.signIn(email: email, password: password);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await _dataSource.signOut();
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AdminAuthSuccess?>> checkAuthStatus() async {
    try {
      final result = await _dataSource.checkAuthStatus();
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
