import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

part 'admin_auth_event.dart';
part 'admin_auth_state.dart';

class AdminAuthBloc extends Bloc<AdminAuthEvent, AdminAuthState> {
  final FirebaseAuth _firebaseAuth;

  AdminAuthBloc({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
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
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );

      final user = userCredential.user;
      if (user != null) {
        emit(AdminAuthAuthenticated(
          adminId: user.uid,
          email: user.email ?? '',
        ));
      } else {
        emit(const AdminAuthError('Sign in failed'));
      }
    } on FirebaseAuthException catch (e) {
      emit(AdminAuthError(e.message ?? 'Authentication error'));
    } catch (e) {
      emit(AdminAuthError(e.toString()));
    }
  }

  Future<void> _onSignOut(
    AdminSignOutEvent event,
    Emitter<AdminAuthState> emit,
  ) async {
    try {
      await _firebaseAuth.signOut();
      emit(const AdminAuthUnauthenticated());
    } catch (e) {
      emit(AdminAuthError(e.toString()));
    }
  }

  Future<void> _onCheckAuthStatus(
    AdminCheckAuthStatusEvent event,
    Emitter<AdminAuthState> emit,
  ) async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser != null) {
      emit(AdminAuthAuthenticated(
        adminId: currentUser.uid,
        email: currentUser.email ?? '',
      ));
    } else {
      emit(const AdminAuthUnauthenticated());
    }
  }
}
