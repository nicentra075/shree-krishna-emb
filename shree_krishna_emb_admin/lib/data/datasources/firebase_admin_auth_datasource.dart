import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
/// Handles all Firebase authentication logic with role-based access control
class FirebaseAdminAuthDataSource implements AdminAuthDataSource {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  FirebaseAdminAuthDataSource({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

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

      // Check if user has admin role in Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        await _firebaseAuth.signOut();
        throw ServerException(message: 'User profile not found');
      }

      final userData = userDoc.data();
      final userRole = userData?['role'] as String?;
      if (userRole != 'admin') {
        await _firebaseAuth.signOut();
        throw ServerException(message: 'Access denied: Admin role required');
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

      // Verify user still has admin role
      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      if (!userDoc.exists) {
        await _firebaseAuth.signOut();
        return null;
      }

      final userData = userDoc.data();
      final userRole = userData?['role'] as String?;
      if (userRole != 'admin') {
        await _firebaseAuth.signOut();
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
