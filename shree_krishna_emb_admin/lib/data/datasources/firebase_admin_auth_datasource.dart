import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shree_krishna_emb_admin/core/constants/app_constants.dart';
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
  final SharedPreferences _prefs;

  FirebaseAdminAuthDataSource({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    required SharedPreferences prefs,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _prefs = prefs;

  Future<void> _saveSession({
    required String adminId,
    required String email,
  }) async {
    await _prefs.setBool(AppConstants.kIsAdminLoggedIn, true);
    await _prefs.setString(AppConstants.kAdminId, adminId);
    await _prefs.setString(AppConstants.kAdminEmail, email);
  }

  Future<void> _clearSession() async {
    await _prefs.remove(AppConstants.kIsAdminLoggedIn);
    await _prefs.remove(AppConstants.kAdminId);
    await _prefs.remove(AppConstants.kAdminEmail);
  }

  /// On web, Firebase Auth restores the cached session asynchronously after
  /// page load — [FirebaseAuth.currentUser] is null until the first
  /// [FirebaseAuth.authStateChanges] event fires, so wait for it.
  Future<User?> _getRestoredUser() async {
    final current = _firebaseAuth.currentUser;
    if (current != null) return current;

    try {
      return await _firebaseAuth.authStateChanges().first.timeout(
        const Duration(seconds: 5),
      );
    } on TimeoutException {
      return _firebaseAuth.currentUser;
    }
  }

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

      // Cache the session so the app can restore it on reload/restart
      await _saveSession(adminId: user.uid, email: user.email ?? '');

      return AdminAuthSuccess(
        adminId: user.uid,
        email: user.email ?? '',
        name: userData?['name'] as String? ?? '',
        role: userRole ?? '',
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
      await _clearSession();
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
      final currentUser = await _getRestoredUser();
      if (currentUser == null) {
        await _clearSession();
        return null;
      }

      // Verify user still has admin role
      final userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();
      if (!userDoc.exists) {
        await _firebaseAuth.signOut();
        await _clearSession();
        return null;
      }

      final userData = userDoc.data();
      final userRole = userData?['role'] as String?;
      if (userRole != 'admin') {
        await _firebaseAuth.signOut();
        await _clearSession();
        return null;
      }

      // Keep the cached session in sync with the restored Firebase session
      await _saveSession(
        adminId: currentUser.uid,
        email: currentUser.email ?? '',
      );

      return AdminAuthSuccess(
        adminId: currentUser.uid,
        email: currentUser.email ?? '',
        name: userData?['name'] as String? ?? '',
        role: userRole ?? '',
      );
    } catch (e) {
      throw ServerException(
        message: 'Unexpected error checking auth status: $e',
      );
    }
  }
}
