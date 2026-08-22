import 'package:equatable/equatable.dart';
import 'package:shree_krishna_core/utils/either.dart';
import 'package:shree_krishna_emb_admin/core/errors/failures.dart';

/// Success model returned on successful authentication
class AdminAuthSuccess extends Equatable {
  final String adminId;
  final String email;
  final String name;
  final String role;

  const AdminAuthSuccess({
    required this.adminId,
    required this.email,
    this.name = '',
    this.role = '',
  });

  @override
  List<Object?> get props => [adminId, email, name, role];
}

/// Abstract repository interface for admin authentication
/// Backend-agnostic contract that can be implemented by Firebase or any future backend
abstract class AdminAuthRepository {
  /// Sign in admin with email and password
  /// Returns Either[Failure, AdminAuthSuccess] following clean architecture pattern
  Future<Either<Failure, AdminAuthSuccess>> signIn({
    required String email,
    required String password,
  });

  /// Sign out current admin
  Future<Either<Failure, void>> signOut();

  /// Check current authentication status
  /// Returns null if no user is authenticated
  Future<Either<Failure, AdminAuthSuccess?>> checkAuthStatus();

  /// Send a password reset email. Succeeds even for unknown emails so the
  /// UI can always show a generic "if this account exists" message.
  Future<Either<Failure, void>> sendPasswordResetEmail(String email);
}
