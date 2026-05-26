import 'package:shree_krishna_core/utils/either.dart';
import 'package:shree_krishna_emb_admin/core/errors/exceptions.dart';
import 'package:shree_krishna_emb_admin/core/errors/failures.dart';
import 'package:shree_krishna_emb_admin/data/datasources/firebase_user_list_datasource.dart';
import 'package:shree_krishna_emb_admin/data/models/user_list_item_model.dart';
import 'package:shree_krishna_emb_admin/domain/repositories/user_list_repository.dart';

class UserListRepositoryImpl implements UserListRepository {
  final UserListDataSource _dataSource;

  UserListRepositoryImpl({required UserListDataSource dataSource})
      : _dataSource = dataSource;

  @override
  Future<Either<Failure, List<UserListItemModel>>> getUsers({
    required int page,
    required int pageSize,
    String? searchQuery,
  }) async {
    try {
      final users = await _dataSource.getUsers(
        page: page,
        pageSize: pageSize,
        searchQuery: searchQuery,
      );
      return Right(users);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateUser(UserListItemModel user) async {
    try {
      await _dataSource.updateUser(user);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> toggleUserStatus(
    String userId,
    bool isActive,
  ) async {
    try {
      await _dataSource.toggleUserStatus(userId, isActive);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteUser(String userId) async {
    try {
      await _dataSource.deleteUser(userId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> getUserCount({String? searchQuery}) async {
    try {
      final count = await _dataSource.getUserCount(searchQuery: searchQuery);
      return Right(count);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
