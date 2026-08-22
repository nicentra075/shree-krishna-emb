import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shree_krishna_core/shree_krishna_core.dart'
    show CloudFunctionNames;
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

  Future<void> sendPasswordResetEmail(String email);
}

/// Firebase implementation of AdminAuthDataSource
/// Handles all Firebase authentication logic with role-based access control
class FirebaseAdminAuthDataSource implements AdminAuthDataSource {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final FirebaseFunctions? _functions;
  final SharedPreferences _prefs;

  FirebaseAdminAuthDataSource({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
    required SharedPreferences prefs,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _functions = functions,
       _prefs = prefs;

  /// Syncs the `role` custom claim with users/{uid}.role and force-refreshes
  /// the ID token so Storage rules (which can only see claims, not Firestore)
  /// accept this session's uploads immediately.
  ///
  /// Best-effort by design: if the callable isn't deployed yet or the network
  /// hiccups, sign-in must still succeed — uploads would then rely on a
  /// previously synced claim (or fail with permission-denied until retry).
  Future<void> _refreshRoleClaim(User user) async {
    final functions = _functions;
    if (functions == null) return;
    try {
      await functions
          .httpsCallable(CloudFunctionNames.refreshRoleClaim)
          .call<Map<String, dynamic>>();
      await user.getIdToken(true);
    } catch (_) {
      // Non-fatal: claim sync is retried on next sign-in/session restore.
    }
  }

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
      // D2: both platform admins and designers use this panel; everyone else
      // is rejected. The UI scopes what each role can see (AccessPolicy).
      if (userRole != 'admin' && userRole != 'designer') {
        await _firebaseAuth.signOut();
        throw ServerException(message: 'Access denied: Staff role required');
      }

      // Cache the session so the app can restore it on reload/restart
      await _saveSession(adminId: user.uid, email: user.email ?? '');

      // Storage rules gate uploads on the `role` custom claim — sync it now.
      await _refreshRoleClaim(user);

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
      if (userRole != 'admin' && userRole != 'designer') {
        await _firebaseAuth.signOut();
        await _clearSession();
        return null;
      }

      // Keep the cached session in sync with the restored Firebase session
      await _saveSession(
        adminId: currentUser.uid,
        email: currentUser.email ?? '',
      );

      // Storage rules gate uploads on the `role` custom claim — sync it now.
      await _refreshRoleClaim(currentUser);

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

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      // Don't leak which emails exist — treat user-not-found as success so the
      // screen can always show the generic "if this account exists" message.
      if (e.code == 'user-not-found') return;
      throw ServerException(
        message: e.message ?? 'Failed to send password reset email',
      );
    } catch (e) {
      throw ServerException(
        message: 'Unexpected error sending password reset email: $e',
      );
    }
  }
}
