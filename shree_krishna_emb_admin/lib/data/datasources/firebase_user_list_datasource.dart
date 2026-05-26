import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shree_krishna_emb_admin/core/errors/exceptions.dart';
import 'package:shree_krishna_emb_admin/data/models/user_list_item_model.dart';

abstract class UserListDataSource {
  Future<List<UserListItemModel>> getUsers({
    required int page,
    required int pageSize,
    String? searchQuery,
  });

  Future<void> updateUser(UserListItemModel user);

  Future<void> toggleUserStatus(String userId, bool isActive);

  Future<void> deleteUser(String userId);

  Future<int> getUserCount({String? searchQuery});
}

class FirebaseUserListDataSource implements UserListDataSource {
  final FirebaseFirestore _firestore;

  FirebaseUserListDataSource({required FirebaseFirestore firestore})
      : _firestore = firestore;

  @override
  Future<List<UserListItemModel>> getUsers({
    required int page,
    required int pageSize,
    String? searchQuery,
  }) async {
    try {
      // Get all users first (for search), then paginate
      Query query = _firestore.collection('users');

      // Order by creation date descending
      query = query.orderBy('createdAt', descending: true);

      // Execute query
      final snapshot = await query.get();

      // Convert to models
      var users = snapshot.docs
          .map((doc) => UserListItemModel.fromFirebaseJson({
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
              }))
          .toList();

      // Apply search filter if provided
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        users = users
            .where((user) =>
                user.name.toLowerCase().contains(query) ||
                user.email.toLowerCase().contains(query))
            .toList();
      }

      // Apply pagination
      final startIndex = (page - 1) * pageSize;
      final endIndex = startIndex + pageSize;

      if (startIndex >= users.length) {
        return [];
      }

      return users.sublist(
        startIndex,
        endIndex > users.length ? users.length : endIndex,
      );
    } on FirebaseException catch (e) {
      throw ServerException(
        message: e.message ?? 'Failed to fetch users',
      );
    } catch (e) {
      throw ServerException(message: 'Unexpected error: $e');
    }
  }

  @override
  Future<void> updateUser(UserListItemModel user) async {
    try {
      await _firestore
          .collection('users')
          .doc(user.id)
          .update(user.toFirebaseJson());
    } on FirebaseException catch (e) {
      throw ServerException(
        message: e.message ?? 'Failed to update user',
      );
    } catch (e) {
      throw ServerException(message: 'Unexpected error: $e');
    }
  }

  @override
  Future<void> toggleUserStatus(String userId, bool isActive) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .update({'isActive': isActive});
    } on FirebaseException catch (e) {
      throw ServerException(
        message: e.message ?? 'Failed to update user status',
      );
    } catch (e) {
      throw ServerException(message: 'Unexpected error: $e');
    }
  }

  @override
  Future<void> deleteUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).delete();
    } on FirebaseException catch (e) {
      throw ServerException(
        message: e.message ?? 'Failed to delete user',
      );
    } catch (e) {
      throw ServerException(message: 'Unexpected error: $e');
    }
  }

  @override
  Future<int> getUserCount({String? searchQuery}) async {
    try {
      final snapshot = await _firestore.collection('users').get();

      var users = snapshot.docs
          .map((doc) => UserListItemModel.fromFirebaseJson({
                ...doc.data(),
                'id': doc.id,
              }))
          .toList();

      if (searchQuery != null && searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        users = users
            .where((user) =>
                user.name.toLowerCase().contains(query) ||
                user.email.toLowerCase().contains(query))
            .toList();
      }

      return users.length;
    } on FirebaseException catch (e) {
      throw ServerException(
        message: e.message ?? 'Failed to get user count',
      );
    } catch (e) {
      throw ServerException(message: 'Unexpected error: $e');
    }
  }
}
