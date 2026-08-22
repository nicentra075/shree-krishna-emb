import 'package:equatable/equatable.dart';
import 'package:shree_krishna_core/models/user_model.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final UserModel user;

  const AuthAuthenticated({required this.user});

  @override
  List<Object?> get props => [user];
}

class AuthPhoneOtpSent extends AuthState {
  final String verificationId;
  final String phoneNumber;

  const AuthPhoneOtpSent({
    required this.verificationId,
    required this.phoneNumber,
  });

  @override
  List<Object?> get props => [verificationId, phoneNumber];
}

class AuthNewGoogleUser extends AuthState {
  final UserModel user;

  const AuthNewGoogleUser({required this.user});

  @override
  List<Object?> get props => [user];
}

class AuthNewPhoneUser extends AuthState {
  final UserModel user;
  final String phoneNumber;

  const AuthNewPhoneUser({required this.user, required this.phoneNumber});

  @override
  List<Object?> get props => [user, phoneNumber];
}

class AuthPasswordResetSent extends AuthState {
  const AuthPasswordResetSent();
}

class AuthError extends AuthState {
  final String message;

  const AuthError({required this.message});

  @override
  List<Object?> get props => [message];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// The account authenticated but has been suspended by an admin. The session
/// has already been torn down; the UI should route to login with a message.
class AuthSuspended extends AuthState {
  const AuthSuspended();
}
