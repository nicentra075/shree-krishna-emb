import 'package:shree_krishna_core/shree_krishna_core.dart';
import 'package:shree_krishna_emb/domain/repositories/user_repository.dart';

// Use case for getting a user by ID
class GetUserUseCase {
  final UserRepository repository;

  GetUserUseCase(this.repository);

  Future<Either<Failure, UserModel>> call(String userId) async {
    return await repository.getUserById(userId);
  }
}

// Use case for fetching all users (pagination)
class GetAllUsersUseCase {
  final UserRepository repository;

  GetAllUsersUseCase(this.repository);

  Future<Either<Failure, List<UserModel>>> call({
    int limit = 20,
    String? lastDocumentId,
  }) async {
    return await repository.getAllUsers(
      limit: limit,
      lastDocumentId: lastDocumentId,
    );
  }
}

// Use case for creating a user
class CreateUserUseCase {
  final UserRepository repository;

  CreateUserUseCase(this.repository);

  Future<Either<Failure, UserModel>> call(UserModel user) async {
    return await repository.createUser(user);
  }
}

// Use case for updating a user
class UpdateUserUseCase {
  final UserRepository repository;

  UpdateUserUseCase(this.repository);

  Future<Either<Failure, UserModel>> call(UserModel user) async {
    return await repository.updateUser(user);
  }
}

// Use case for watching user changes in real-time
class WatchUserUseCase {
  final UserRepository repository;

  WatchUserUseCase(this.repository);

  Stream<Either<Failure, UserModel>> call(String userId) {
    return repository.watchUser(userId);
  }
}

// Use case for searching users
class SearchUsersUseCase {
  final UserRepository repository;

  SearchUsersUseCase(this.repository);

  Future<Either<Failure, List<UserModel>>> call(String query) async {
    return await repository.searchUsers(query);
  }
}
