import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shree_krishna_emb_admin/domain/repositories/admin_auth_repository.dart';

part 'admin_auth_event.dart';
part 'admin_auth_state.dart';

/// AdminAuthBloc handles all admin authentication events
/// Depends on AdminAuthRepository (injected, no Firebase imports)
/// Follows clean architecture: repository is a contract, not implementation
class AdminAuthBloc extends Bloc<AdminAuthEvent, AdminAuthState> {
  final AdminAuthRepository _repository;

  AdminAuthBloc({required AdminAuthRepository repository})
      : _repository = repository,
        super(const AdminAuthInitial()) {
    on<AdminSignInEvent>(_onSignIn);
    on<AdminSignOutEvent>(_onSignOut);
    on<AdminCheckAuthStatusEvent>(_onCheckAuthStatus);
  }

  Future<void> _onSignIn(
    AdminSignInEvent event,
    Emitter<AdminAuthState> emit,
  ) async {
    emit(const AdminAuthLoading());

    final result = await _repository.signIn(
      email: event.email,
      password: event.password,
    );

    result.fold(
      (failure) => emit(AdminAuthError(failure.message)),
      (success) => emit(AdminAuthAuthenticated(
        adminId: success.adminId,
        email: success.email,
        name: success.name,
        role: success.role,
      )),
    );
  }

  Future<void> _onSignOut(
    AdminSignOutEvent event,
    Emitter<AdminAuthState> emit,
  ) async {
    final result = await _repository.signOut();

    result.fold(
      (failure) => emit(AdminAuthError(failure.message)),
      (_) => emit(const AdminAuthUnauthenticated()),
    );
  }

  Future<void> _onCheckAuthStatus(
    AdminCheckAuthStatusEvent event,
    Emitter<AdminAuthState> emit,
  ) async {
    final result = await _repository.checkAuthStatus();

    result.fold(
      (failure) => emit(AdminAuthError(failure.message)),
      (success) {
        if (success != null) {
          emit(AdminAuthAuthenticated(
            adminId: success.adminId,
            email: success.email,
            name: success.name,
            role: success.role,
          ));
        } else {
          emit(const AdminAuthUnauthenticated());
        }
      },
    );
  }
}
