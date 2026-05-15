part of 'admin_auth_bloc.dart';

abstract class AdminAuthState extends Equatable {
  const AdminAuthState();

  @override
  List<Object?> get props => [];
}

class AdminAuthInitial extends AdminAuthState {
  const AdminAuthInitial();
}

class AdminAuthLoading extends AdminAuthState {
  const AdminAuthLoading();
}

class AdminAuthAuthenticated extends AdminAuthState {
  final String adminId;
  final String email;

  const AdminAuthAuthenticated({required this.adminId, required this.email});

  @override
  List<Object?> get props => [adminId, email];
}

class AdminAuthUnauthenticated extends AdminAuthState {
  const AdminAuthUnauthenticated();
}

class AdminAuthError extends AdminAuthState {
  final String message;

  const AdminAuthError(this.message);

  @override
  List<Object?> get props => [message];
}
