import 'package:shree_krishna_core/utils/either.dart';
import 'package:shree_krishna_emb_admin/core/errors/failures.dart';
import 'package:shree_krishna_emb_admin/data/models/user_list_item_model.dart';

/// Abstract repository interface for user list management
/// Backend-agnostic contract that can be implemented by Firebase or any future backend
abstract class UserListRepository {
  /// Get paginated list of users with optional search
  /// Returns [Either<Failure, List<UserListItemModel>>] following clean architecture pattern
  Future<Either<Failure, List<UserListItemModel>>> getUsers({
    required int page,
    required int pageSize,
    String? searchQuery,
  });

  /// Update user details
  Future<Either<Failure, void>> updateUser(UserListItemModel user);

  /// Toggle user active/inactive status
  Future<Either<Failure, void>> toggleUserStatus(String userId, bool isActive);

  /// Delete user permanently
  Future<Either<Failure, void>> deleteUser(String userId);

  /// Get total count of users with optional search filter
  Future<Either<Failure, int>> getUserCount({String? searchQuery});
}
