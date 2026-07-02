
import 'package:shree_krishna_core/errors/failures.dart';
import 'package:shree_krishna_core/models/user_model.dart';
import 'package:shree_krishna_core/utils/either.dart';

abstract class UserRepository {
  /// Fetch user by ID
  Future<Either<Failure, UserModel>> getUserById(String userId);

  /// Fetch all users (admin only)
  Future<Either<Failure, List<UserModel>>> getAllUsers({
    int? limit,
    String? lastDocumentId,
  });

  /// Create new user
  Future<Either<Failure, UserModel>> createUser(UserModel user);

  /// Update user
  Future<Either<Failure, UserModel>> updateUser(UserModel user);

  /// Delete user
  Future<Either<Failure, void>> deleteUser(String userId);

  /// Watch user changes in real-time
  Stream<Either<Failure, UserModel>> watchUser(String userId);

  /// Search users
  Future<Either<Failure, List<UserModel>>> searchUsers(String query);
  
}
