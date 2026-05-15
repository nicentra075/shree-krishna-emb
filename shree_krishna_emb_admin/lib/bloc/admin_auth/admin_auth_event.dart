part of 'admin_auth_bloc.dart';

abstract class AdminAuthEvent extends Equatable {
  const AdminAuthEvent();

  @override
  List<Object?> get props => [];
}

class AdminSignInEvent extends AdminAuthEvent {
  final String email;
  final String password;

  const AdminSignInEvent({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class AdminSignOutEvent extends AdminAuthEvent {
  const AdminSignOutEvent();
}

class AdminCheckAuthStatusEvent extends AdminAuthEvent {
  const AdminCheckAuthStatusEvent();
}
