import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shree_krishna_core/shree_krishna_core.dart';

// Abstract interface for user data source
abstract class UserDataSource {
  Future<UserModel> getUserById(String userId);
  Future<List<UserModel>> getAllUsers({int? limit, String? lastDocumentId});
  Future<UserModel> createUser(UserModel user);
  Future<UserModel> updateUser(UserModel user);
  Future<void> deleteUser(String userId);
  Stream<UserModel> watchUser(String userId);
  Future<List<UserModel>> searchUsers(String query);
}

// Firebase implementation
class FirebaseUserDataSource implements UserDataSource {
  final FirebaseFirestore _firestore;
  static const String _collectionName = 'users';

  FirebaseUserDataSource({required FirebaseFirestore firestore})
    : _firestore = firestore;

  @override
  Future<UserModel> getUserById(String userId) async {
    try {
      final doc = await _firestore
          .collection(_collectionName)
          .doc(userId)
          .get();

      if (!doc.exists) {
        throw ServerException(
          message: 'User not found',
          code: 'USER_NOT_FOUND',
        );
      }

      return UserModel.fromFirebaseJson(doc.data()!, doc.id);
    } on FirebaseException catch (e) {
      throw ServerException(
        message: e.message ?? 'Firebase error',
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      throw ServerException(message: 'Failed to fetch user', originalError: e);
    }
  }

  @override
  Future<List<UserModel>> getAllUsers({
    int? limit,
    String? lastDocumentId,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection(_collectionName)
          .orderBy('createdAt', descending: true);

      if (limit != null) {
        query = query.limit(limit + 1);
      }

      if (lastDocumentId != null) {
        final lastDoc = await _firestore
            .collection(_collectionName)
            .doc(lastDocumentId)
            .get();
        query = query.startAfterDocument(lastDoc);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => UserModel.fromFirebaseJson(doc.data(), doc.id))
          .toList();
    } on FirebaseException catch (e) {
      throw ServerException(
        message: e.message ?? 'Firebase error',
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      throw ServerException(message: 'Failed to fetch users', originalError: e);
    }
  }

  @override
  Future<UserModel> createUser(UserModel user) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(user.id)
          .set(user.toFirebaseJson());

      return user;
    } on FirebaseException catch (e) {
      throw ServerException(
        message: e.message ?? 'Firebase error',
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      throw ServerException(message: 'Failed to create user', originalError: e);
    }
  }

  @override
  Future<UserModel> updateUser(UserModel user) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(user.id)
          .update(user.toFirebaseJson());

      return user;
    } on FirebaseException catch (e) {
      throw ServerException(
        message: e.message ?? 'Firebase error',
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      throw ServerException(message: 'Failed to update user', originalError: e);
    }
  }

  @override
  Future<void> deleteUser(String userId) async {
    try {
      await _firestore.collection(_collectionName).doc(userId).delete();
    } on FirebaseException catch (e) {
      throw ServerException(
        message: e.message ?? 'Firebase error',
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      throw ServerException(message: 'Failed to delete user', originalError: e);
    }
  }

  @override
  Stream<UserModel> watchUser(String userId) {
    return _firestore
        .collection(_collectionName)
        .doc(userId)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) {
            throw ServerException(
              message: 'User not found',
              code: 'USER_NOT_FOUND',
            );
          }
          return UserModel.fromFirebaseJson(snapshot.data()!, snapshot.id);
        })
        .handleError((e) {
          throw ServerException(
            message: 'Failed to watch user',
            originalError: e,
          );
        });
  }

  @override
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThan: '${query}z')
          .limit(20)
          .get();

      return snapshot.docs
          .map((doc) => UserModel.fromFirebaseJson(doc.data(), doc.id))
          .toList();
    } on FirebaseException catch (e) {
      throw ServerException(
        message: e.message ?? 'Firebase error',
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      throw ServerException(
        message: 'Failed to search users',
        originalError: e,
      );
    }
  }
}
