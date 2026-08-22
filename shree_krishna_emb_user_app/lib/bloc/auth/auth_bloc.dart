import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shree_krishna_core/errors/failures.dart';
import 'package:shree_krishna_emb/bloc/auth/auth_event.dart';
import 'package:shree_krishna_emb/bloc/auth/auth_state.dart';
import 'package:shree_krishna_emb/domain/usecases/auth_usecases.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SignUpUseCase signUpUseCase;
  final SignInUseCase signInUseCase;
  final SignInWithGoogleUseCase signInWithGoogleUseCase;
  final SignInWithAppleUseCase signInWithAppleUseCase;
  final SendPhoneOtpUseCase sendPhoneOtpUseCase;
  final VerifyPhoneOtpUseCase verifyPhoneOtpUseCase;
  final CompleteGoogleProfileUseCase completeGoogleProfileUseCase;
  final CompletePhoneProfileUseCase completePhoneProfileUseCase;
  final SignOutUseCase signOutUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;
  final SendPasswordResetEmailUseCase sendPasswordResetEmailUseCase;

  AuthBloc({
    required this.signUpUseCase,
    required this.signInUseCase,
    required this.signInWithGoogleUseCase,
    required this.signInWithAppleUseCase,
    required this.sendPhoneOtpUseCase,
    required this.verifyPhoneOtpUseCase,
    required this.completeGoogleProfileUseCase,
    required this.completePhoneProfileUseCase,
    required this.signOutUseCase,
    required this.getCurrentUserUseCase,
    required this.sendPasswordResetEmailUseCase,
  }) : super(const AuthInitial()) {
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<SignUpEvent>(_onSignUp);
    on<SignInEvent>(_onSignIn);
    on<SignInWithGoogleEvent>(_onSignInWithGoogle);
    on<SignInWithAppleEvent>(_onSignInWithApple);
    on<SendPhoneOtpEvent>(_onSendPhoneOtp);
    on<VerifyPhoneOtpEvent>(_onVerifyPhoneOtp);
    on<CompleteGoogleProfileEvent>(_onCompleteGoogleProfile);
    on<CompletePhoneProfileEvent>(_onCompletePhoneProfile);
    on<SignOutEvent>(_onSignOut);
    on<VerifyAccountStatusEvent>(_onVerifyAccountStatus);
    on<SendPasswordResetEmailEvent>(_onSendPasswordResetEmail);
  }

  /// Emits [AuthSuspended] for a suspended account, otherwise a generic
  /// [AuthError]. Keeps the suspended case distinct so the UI can show a
  /// dedicated message and route to login.
  void _emitAuthFailure(Failure failure, Emitter<AuthState> emit) {
    if (failure is SuspendedFailure) {
      emit(const AuthSuspended());
    } else {
      emit(AuthError(message: failure.message));
    }
  }

  /// Re-validates the current user's status against the backend. If the account
  /// is suspended (or otherwise no longer valid) the datasource has already
  /// signed out, so we emit [AuthSuspended] to route the user to login. A
  /// transient failure (e.g. network) is ignored so we never log users out by
  /// mistake.
  Future<void> _onVerifyAccountStatus(
    VerifyAccountStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    final result = await getCurrentUserUseCase();

    result.fold((failure) {}, (user) {
      if (user == null) {
        emit(const AuthSuspended());
      }
    });
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await getCurrentUserUseCase();

    result.fold((failure) => emit(const AuthUnauthenticated()), (user) {
      if (user != null) {
        emit(AuthAuthenticated(user: user));
      } else {
        emit(const AuthUnauthenticated());
      }
    });
  }

  Future<void> _onSignUp(SignUpEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    final result = await signUpUseCase(
      name: event.name,
      email: event.email,
      phone: event.phone,
      password: event.password,
    );

    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (user) => emit(AuthAuthenticated(user: user)),
    );
  }

  Future<void> _onSignIn(SignInEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    final result = await signInUseCase(
      email: event.email,
      password: event.password,
    );

    result.fold(
      (failure) => _emitAuthFailure(failure, emit),
      (user) => emit(AuthAuthenticated(user: user)),
    );
  }

  Future<void> _onSignInWithGoogle(
    SignInWithGoogleEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await signInWithGoogleUseCase();

    result.fold((failure) => _emitAuthFailure(failure, emit), (authResult) {
      if (authResult.isNewUser) {
        emit(AuthNewGoogleUser(user: authResult.user));
      } else {
        emit(AuthAuthenticated(user: authResult.user));
      }
    });
  }

  Future<void> _onSignInWithApple(
    SignInWithAppleEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await signInWithAppleUseCase();

    // New Apple users take the same complete-profile route as Google users —
    // both are social sign-ins that still need a phone number.
    result.fold((failure) => _emitAuthFailure(failure, emit), (authResult) {
      if (authResult.isNewUser) {
        emit(AuthNewGoogleUser(user: authResult.user));
      } else {
        emit(AuthAuthenticated(user: authResult.user));
      }
    });
  }

  Future<void> _onSendPhoneOtp(
    SendPhoneOtpEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await sendPhoneOtpUseCase(event.phoneNumber);

    result.fold(
      (failure) {
        emit(AuthError(message: failure.message));
      },
      (verificationId) {
        emit(
          AuthPhoneOtpSent(
            verificationId: verificationId,
            phoneNumber: event.phoneNumber,
          ),
        );
      },
    );
  }

  Future<void> _onVerifyPhoneOtp(
    VerifyPhoneOtpEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await verifyPhoneOtpUseCase(
      verificationId: event.verificationId,
      smsCode: event.smsCode,
      phoneNumber: event.phoneNumber,
    );

    result.fold((failure) => _emitAuthFailure(failure, emit), (authResult) {
      if (authResult.isNewUser) {
        emit(
          AuthNewPhoneUser(
            user: authResult.user,
            phoneNumber: event.phoneNumber,
          ),
        );
      } else {
        emit(AuthAuthenticated(user: authResult.user));
      }
    });
  }

  Future<void> _onCompleteGoogleProfile(
    CompleteGoogleProfileEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await completeGoogleProfileUseCase(
      uid: event.uid,
      phoneNumber: event.phoneNumber,
    );

    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (user) => emit(AuthAuthenticated(user: user)),
    );
  }

  Future<void> _onCompletePhoneProfile(
    CompletePhoneProfileEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await completePhoneProfileUseCase(
      uid: event.uid,
      name: event.name,
      email: event.email,
    );

    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (user) => emit(AuthAuthenticated(user: user)),
    );
  }

  Future<void> _onSignOut(SignOutEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    final result = await signOutUseCase('');

    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (_) => emit(const AuthUnauthenticated()),
    );
  }

  Future<void> _onSendPasswordResetEmail(
    SendPasswordResetEmailEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await sendPasswordResetEmailUseCase(event.email);

    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (_) => emit(const AuthPasswordResetSent()),
    );
  }
}
