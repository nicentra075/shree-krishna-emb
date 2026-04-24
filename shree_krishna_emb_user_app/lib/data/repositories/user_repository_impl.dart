import 'package:shree_krishna_core/shree_krishna_core.dart';
import 'package:shree_krishna_emb/data/datasources/firebase_user_datasource.dart';
import 'package:shree_krishna_emb/data/datasources/local_user_datasource.dart';
import 'package:shree_krishna_emb/domain/repositories/user_repository.dart';

/// Implementation of UserRepository with cache-first strategy
/// 1. Check local cache first
/// 2. If cache is fresh, return cached data
/// 3. If stale/missing, fetch from remote
/// 4. Cache result on success (write-through)
/// 5. On network failure, return stale cache if available (graceful degradation)
class UserRepositoryImpl implements UserRepository {
  final UserDataSource _remoteDataSource;
  final LocalUserDataSource _localDataSource;

  UserRepositoryImpl({
    required UserDataSource remoteDataSource,
    required LocalUserDataSource localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  @override
  Future<Either<Failure, UserModel>> getUserById(String userId) async {
    try {
      // Step 1: Check local cache
      final cachedData = await _localDataSource.getCachedUser(userId);
      if (cachedData != null && !cachedData.isFresh) {
        return Right(cachedData.data);
      }

      // Step 2: Fetch from remote
      final user = await _remoteDataSource.getUserById(userId);

      // Step 3: Cache the result (write-through)
      await _localDataSource.cacheUser(user);

      return Right(user);
    } on ServerException catch (e) {
      // Try graceful degradation with stale cache
      final cachedData = await _localDataSource.getCachedUser(userId);
      if (cachedData != null) {
        return Right(cachedData.data);
      }
      return Left(ServerFailure(e.message, code: e.code));
    } on NetworkException catch (e) {
      // Try graceful degradation with stale cache
      final cachedData = await _localDataSource.getCachedUser(userId);
      if (cachedData != null) {
        return Right(cachedData.data);
      }
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<UserModel>>> getAllUsers({
    int? limit,
    String? lastDocumentId,
  }) async {
    try {
      final cacheKey = 'all_users_limit_${limit}_after_${lastDocumentId ?? 'start'}';

      // Step 1: Check local cache
      final cachedData = await _localDataSource.getCachedUserList(cacheKey);
      if (cachedData != null && !cachedData.isFresh) {
        return Right(cachedData.data);
      }

      // Step 2: Fetch from remote
      final users = await _remoteDataSource.getAllUsers(
        limit: limit,
        lastDocumentId: lastDocumentId,
      );

      // Step 3: Cache the result (write-through)
      await _localDataSource.cacheUserList(cacheKey, users);

      return Right(users);
    } on ServerException catch (e) {
      // Try graceful degradation with stale cache
      final cacheKey = 'all_users_limit_${limit}_after_${lastDocumentId ?? 'start'}';
      final cachedData = await _localDataSource.getCachedUserList(cacheKey);
      if (cachedData != null) {
        return Right(cachedData.data);
      }
      return Left(ServerFailure(e.message, code: e.code));
    } on NetworkException catch (e) {
      // Try graceful degradation with stale cache
      final cacheKey = 'all_users_limit_${limit}_after_${lastDocumentId ?? 'start'}';
      final cachedData = await _localDataSource.getCachedUserList(cacheKey);
      if (cachedData != null) {
        return Right(cachedData.data);
      }
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, UserModel>> createUser(UserModel user) async {
    try {
      final createdUser = await _remoteDataSource.createUser(user);

      // Write-through: cache the created user
      await _localDataSource.cacheUser(createdUser);

      return Right(createdUser);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message, fieldErrors: e.fieldErrors));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, UserModel>> updateUser(UserModel user) async {
    try {
      final updatedUser = await _remoteDataSource.updateUser(user);

      // Write-through: update the cache
      await _localDataSource.cacheUser(updatedUser);

      return Right(updatedUser);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message, fieldErrors: e.fieldErrors));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteUser(String userId) async {
    try {
      await _remoteDataSource.deleteUser(userId);

      // Invalidate cache
      await _localDataSource.invalidateUser(userId);

      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Stream<Either<Failure, UserModel>> watchUser(String userId) async* {
    try {
      await for (final user in _remoteDataSource.watchUser(userId)) {
        // Cache updates from stream
        await _localDataSource.cacheUser(user);
        yield Right(user);
      }
    } on ServerException catch (e) {
      yield Left(ServerFailure(e.message, code: e.code));
    } on NetworkException catch (e) {
      yield Left(NetworkFailure(e.message));
    } catch (e) {
      yield Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<UserModel>>> searchUsers(String query) async {
    try {
      if (query.isEmpty) {
        return const Left(ValidationFailure('Search query cannot be empty'));
      }

      final users = await _remoteDataSource.searchUsers(query);
      return Right(users);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }
}
