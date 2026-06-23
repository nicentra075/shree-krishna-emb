import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shree_krishna_emb_admin/core/errors/exceptions.dart';
import 'package:shree_krishna_emb_admin/core/utils/app_logger.dart';
import 'package:shree_krishna_emb_admin/data/models/user_list_item_model.dart';

abstract class UserListDataSource {
  Future<List<UserListItemModel>> getUsers({
    required int page,
    required int pageSize,
    String? searchQuery,
    String? roleFilter,
    bool forceRefresh,
  });

  Future<void> updateUser(UserListItemModel user);

  Future<void> toggleUserStatus(String userId, bool isActive);

  Future<void> deleteUser(String userId);

  Future<int> getUserCount({
    String? searchQuery,
    String? roleFilter,
    bool forceRefresh,
  });

  Future<void> createUser({
    required String name,
    required String email,
    required String password,
    required String phoneNumber,
    required String role,
    String? photoUrl,
    String? storeName,
    String? storeImageUrl,
    String? storeDescription,
    bool isAuthorisedSeller,
  });

  /// Send a password-reset email to [email] so the user can set a new password.
  Future<void> sendPasswordReset(String email);
}

class FirebaseUserListDataSource implements UserListDataSource {
  final FirebaseFirestore _firestore;

  FirebaseUserListDataSource({required FirebaseFirestore firestore})
      : _firestore = firestore;

  // ---- In-memory cache --------------------------------------------------
  // Search, role filtering and pagination are all done client-side over the
  // full users list, so we fetch the whole collection only ONCE and serve
  // every keystroke/filter/page from this cache. This avoids a full-collection
  // read on every interaction (big Firestore cost saving). The cache is
  // refreshed when it expires, when forceRefresh is requested (pull/refresh
  // button), or after any mutation invalidates it.
  List<UserListItemModel>? _cachedUsers;
  DateTime? _cachedAt;
  static const Duration _cacheTtl = Duration(minutes: 2);

  void _invalidateCache() {
    _cachedUsers = null;
    _cachedAt = null;
  }

  /// Returns all users, served from the in-memory cache when still fresh.
  Future<List<UserListItemModel>> _allUsers({bool forceRefresh = false}) async {
    final cache = _cachedUsers;
    final cachedAt = _cachedAt;
    final isFresh = cache != null &&
        cachedAt != null &&
        DateTime.now().difference(cachedAt) < _cacheTtl;
    if (!forceRefresh && isFresh) {
      return cache;
    }

    final snapshot = await _firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .get();

    final users = snapshot.docs
        .map((doc) => UserListItemModel.fromFirebaseJson({
              ...doc.data(),
              'id': doc.id,
            }))
        .toList();

    _cachedUsers = users;
    _cachedAt = DateTime.now();
    return users;
  }

  /// Apply role + search filters to a user list (client-side).
  List<UserListItemModel> _applyFilters(
    List<UserListItemModel> users, {
    String? searchQuery,
    String? roleFilter,
  }) {
    var result = users;
    if (roleFilter != null && roleFilter.isNotEmpty) {
      result = result.where((user) => user.role == roleFilter).toList();
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      result = result
          .where((user) =>
              user.name.toLowerCase().contains(q) ||
              user.email.toLowerCase().contains(q))
          .toList();
    }
    return result;
  }

  @override
  Future<List<UserListItemModel>> getUsers({
    required int page,
    required int pageSize,
    String? searchQuery,
    String? roleFilter,
    bool forceRefresh = false,
  }) async {
    try {
      final all = await _allUsers(forceRefresh: forceRefresh);
      final users = _applyFilters(
        all,
        searchQuery: searchQuery,
        roleFilter: roleFilter,
      );

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
      _invalidateCache();
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
      _invalidateCache();
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
      _invalidateCache();
    } on FirebaseException catch (e) {
      throw ServerException(
        message: e.message ?? 'Failed to delete user',
      );
    } catch (e) {
      throw ServerException(message: 'Unexpected error: $e');
    }
  }

  @override
  Future<int> getUserCount({
    String? searchQuery,
    String? roleFilter,
    bool forceRefresh = false,
  }) async {
    try {
      final all = await _allUsers(forceRefresh: forceRefresh);
      return _applyFilters(
        all,
        searchQuery: searchQuery,
        roleFilter: roleFilter,
      ).length;
    } on FirebaseException catch (e) {
      throw ServerException(
        message: e.message ?? 'Failed to get user count',
      );
    } catch (e) {
      throw ServerException(message: 'Unexpected error: $e');
    }
  }

  @override
  Future<void> createUser({
    required String name,
    required String email,
    required String password,
    required String phoneNumber,
    required String role,
    String? photoUrl,
    String? storeName,
    String? storeImageUrl,
    String? storeDescription,
    bool isAuthorisedSeller = false,
  }) async {
    // IMPORTANT: Creating a user with the PRIMARY FirebaseAuth instance signs
    // the admin OUT and signs the new user IN (client-SDK behaviour). To keep
    // the admin's session intact, we create the Auth user on a SECONDARY
    // Firebase app, then write the Firestore doc using the PRIMARY (admin)
    // session — which passes the rules' `isAdmin()` check for ANY role
    // (including 'admin') and has no fresh-session token race. Finally we tear
    // the secondary app down. The admin's primary session is never touched.
    FirebaseApp? secondaryApp;
    try {
      secondaryApp = await _secondaryApp();
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      final userCredential =
          await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = userCredential.user!.uid;

      // Sequential integer userId, matching the user-app signup flow. The user
      // app's UserModel parses `userId` as int?, so writing the uid String here
      // breaks login with a type-cast error. Use the shared counter instead.
      final userId = await _generateSequentialUserId();

      // Designer store fields only apply to the 'designer' role.
      final isDesigner = role == 'designer';

      // Write the Firestore doc using the primary admin session.
      await _firestore.collection('users').doc(uid).set({
        'id': uid,
        'userId': userId,
        'name': name,
        'email': email,
        'phoneNumber': phoneNumber,
        'role': role,
        'isActive': true,
        'createdAt': DateTime.now().toIso8601String(),
        'loginMethod': 'email',
        'photoUrl': (photoUrl != null && photoUrl.isNotEmpty) ? photoUrl : null,
        'loginAt': null,
        'logoutAt': null,
        'storeName': isDesigner ? storeName : null,
        'storeImageUrl': isDesigner ? storeImageUrl : null,
        'storeDescription': isDesigner ? storeDescription : null,
        'isAuthorisedSeller': isDesigner ? isAuthorisedSeller : false,
      });
      _invalidateCache();

      await secondaryAuth.signOut();
    } on FirebaseAuthException catch (e, s) {
      AppLogger.logError('createUser: FirebaseAuthException (${e.code})',
          error: e, stackTrace: s);
      String message = 'Failed to create user';
      if (e.code == 'weak-password') {
        message = 'Password is too weak';
      } else if (e.code == 'email-already-in-use') {
        message =
            'This email is already registered. Use a different email, '
            'or delete the existing account from Firebase Authentication first.';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email format';
      }
      throw ServerException(message: message);
    } on FirebaseException catch (e, s) {
      AppLogger.logError('createUser: FirebaseException (${e.code})',
          error: e, stackTrace: s);
      if (e.code == 'permission-denied') {
        // The signed-in account isn't recognised as admin by the rules — its
        // own users/{uid} doc must have role == 'admin' (or the latest rules
        // aren't deployed yet).
        throw ServerException(
          message: 'Permission denied. The signed-in account is not an admin, '
              'or the latest Firestore rules are not deployed.',
        );
      }
      throw ServerException(
        message: e.message ?? 'Failed to create user',
      );
    } catch (e, s) {
      AppLogger.logError('createUser: unexpected error', error: e, stackTrace: s);
      throw ServerException(message: 'Unexpected error: $e');
    } finally {
      // Always tear down the secondary app so a retry can recreate it.
      await secondaryApp?.delete();
    }
  }

  /// Returns the next sequential integer user id by reading the current maximum
  /// `userId` across the users collection (which an admin is allowed to read)
  /// and adding 1.
  ///
  /// We deliberately do NOT use the shared `counters/user_id_counter` document:
  /// Firestore rules lock the `counters` collection to Cloud Functions only
  /// (`allow read, write: if false`), so a client transaction there fails with
  /// permission-denied. Robust against docs storing userId as int/num/string.
  Future<int> _generateSequentialUserId() async {
    final snapshot = await _firestore.collection('users').get();

    var maxId = 0;
    for (final doc in snapshot.docs) {
      final raw = doc.data()['userId'];
      final id = raw is int
          ? raw
          : (raw is num ? raw.toInt() : int.tryParse('$raw') ?? 0);
      if (id > maxId) maxId = id;
    }
    return maxId + 1;
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    // Uses the primary FirebaseAuth instance. sendPasswordResetEmail does NOT
    // change auth state, so the admin's session is unaffected.
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      String message = 'Failed to send reset email';
      if (e.code == 'invalid-email') {
        message = 'Invalid email format';
      } else if (e.code == 'user-not-found') {
        message = 'No account found for this email';
      }
      throw ServerException(message: message);
    } on FirebaseException catch (e) {
      throw ServerException(message: e.message ?? 'Failed to send reset email');
    } catch (e) {
      throw ServerException(message: 'Unexpected error: $e');
    }
  }

  /// Returns a freshly-initialised secondary Firebase app dedicated to user
  /// creation, cloning the primary app's options. If a stale instance with the
  /// same name lingers (e.g. a prior crash), it is reused.
  Future<FirebaseApp> _secondaryApp() async {
    const name = 'adminUserCreation';
    try {
      return await Firebase.initializeApp(
        name: name,
        options: Firebase.app().options,
      );
    } on FirebaseException catch (_) {
      // Already initialised — reuse the existing instance.
      return Firebase.app(name);
    }
  }
}
