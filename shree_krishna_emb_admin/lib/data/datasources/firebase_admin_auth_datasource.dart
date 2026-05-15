import 'package:firebase_auth/firebase_auth.dart';
import 'package:shree_krishna_emb_admin/core/errors/exceptions.dart';
import 'package:shree_krishna_emb_admin/domain/repositories/admin_auth_repository.dart';

/// Abstract datasource interface for admin authentication
/// Defines the contract that all auth datasources must implement
abstract class AdminAuthDataSource {
  Future<AdminAuthSuccess> signIn({
    required String email,
    required String password,
  });

  Future<void> signOut();

  Future<AdminAuthSuccess?> checkAuthStatus();
}

/// Firebase implementation of AdminAuthDataSource
/// Handles all Firebase authentication logic
class FirebaseAdminAuthDataSource implements AdminAuthDataSource {
  final FirebaseAuth _firebaseAuth;

  FirebaseAdminAuthDataSource({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  @override
  Future<AdminAuthSuccess> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        throw ServerException(message: 'Sign in failed: User is null');
      }

      return AdminAuthSuccess(
        adminId: user.uid,
        email: user.email ?? '',
      );
    } on FirebaseAuthException catch (e) {
      throw ServerException(
        message: e.message ?? 'Firebase authentication error',
      );
    } catch (e) {
      throw ServerException(message: 'Unexpected error during sign in: $e');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } on FirebaseException catch (e) {
      throw ServerException(
        message: e.message ?? 'Firebase error during sign out',
      );
    } catch (e) {
      throw ServerException(message: 'Unexpected error during sign out: $e');
    }
  }

  @override
  Future<AdminAuthSuccess?> checkAuthStatus() async {
    try {
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser == null) {
        return null;
      }

      return AdminAuthSuccess(
        adminId: currentUser.uid,
        email: currentUser.email ?? '',
      );
    } catch (e) {
      throw ServerException(
        message: 'Unexpected error checking auth status: $e',
      );
    }
  }
}
