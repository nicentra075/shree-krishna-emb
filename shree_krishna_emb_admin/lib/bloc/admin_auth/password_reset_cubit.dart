import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shree_krishna_emb_admin/domain/repositories/admin_auth_repository.dart';

/// States for the forgot-password flow. Kept OUT of [AdminAuthBloc] on purpose
/// — that singleton drives session gating (splash/dashboard), and a reset
/// request must never be mistaken for a sign-in/out transition.
abstract class PasswordResetState extends Equatable {
  const PasswordResetState();

  @override
  List<Object?> get props => [];
}

class PasswordResetInitial extends PasswordResetState {
  const PasswordResetInitial();
}

class PasswordResetSending extends PasswordResetState {
  const PasswordResetSending();
}

class PasswordResetSent extends PasswordResetState {
  const PasswordResetSent();
}

class PasswordResetError extends PasswordResetState {
  final String message;

  const PasswordResetError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Sends password reset emails for admin/designer panel accounts.
class PasswordResetCubit extends Cubit<PasswordResetState> {
  final AdminAuthRepository _repository;

  PasswordResetCubit({required AdminAuthRepository repository})
    : _repository = repository,
      super(const PasswordResetInitial());

  Future<void> sendResetEmail(String email) async {
    emit(const PasswordResetSending());

    final result = await _repository.sendPasswordResetEmail(email);

    result.fold(
      (failure) => emit(PasswordResetError(failure.message)),
      (_) => emit(const PasswordResetSent()),
    );
  }
}
