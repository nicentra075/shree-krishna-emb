import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shree_krishna_emb/bloc/auth/auth_event.dart';
import 'package:shree_krishna_emb/bloc/auth/auth_state.dart';
import 'package:shree_krishna_emb/domain/usecases/auth_usecases.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SignUpUseCase signUpUseCase;
  final SignInUseCase signInUseCase;
  final SignInWithGoogleUseCase signInWithGoogleUseCase;
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
    on<SendPhoneOtpEvent>(_onSendPhoneOtp);
    on<VerifyPhoneOtpEvent>(_onVerifyPhoneOtp);
    on<CompleteGoogleProfileEvent>(_onCompleteGoogleProfile);
    on<CompletePhoneProfileEvent>(_onCompletePhoneProfile);
    on<SignOutEvent>(_onSignOut);
    on<SendPasswordResetEmailEvent>(_onSendPasswordResetEmail);
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await getCurrentUserUseCase();

    result.fold(
      (failure) => emit(const AuthUnauthenticated()),
      (user) {
        if (user != null) {
          emit(AuthAuthenticated(user: user));
        } else {
          emit(const AuthUnauthenticated());
        }
      },
    );
  }

  Future<void> _onSignUp(
    SignUpEvent event,
    Emitter<AuthState> emit,
  ) async {
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

  Future<void> _onSignIn(
    SignInEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await signInUseCase(
      email: event.email,
      password: event.password,
    );

    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (user) => emit(AuthAuthenticated(user: user)),
    );
  }

  Future<void> _onSignInWithGoogle(
    SignInWithGoogleEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await signInWithGoogleUseCase();

    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (authResult) {
        if (authResult.isNewUser) {
          emit(AuthNewGoogleUser(user: authResult.user));
        } else {
          emit(AuthAuthenticated(user: authResult.user));
        }
      },
    );
  }

  Future<void> _onSendPhoneOtp(
    SendPhoneOtpEvent event,
    Emitter<AuthState> emit,
  ) async {
    print('🔵 [AuthBloc] _onSendPhoneOtp event received - Phone: ${event.phoneNumber}');
    emit(const AuthLoading());
    print('🔵 [AuthBloc] Emitted AuthLoading state');
    final result = await sendPhoneOtpUseCase(event.phoneNumber);
    print('🔵 [AuthBloc] sendPhoneOtpUseCase result: ${result.toString()}');

    result.fold(
      (failure) {
        print('🔴 [AuthBloc] SendPhoneOtp failed - Error: ${failure.message}');
        emit(AuthError(message: failure.message));
      },
      (verificationId) {
        print('🟢 [AuthBloc] SendPhoneOtp succeeded - VerificationId: $verificationId');
        emit(AuthPhoneOtpSent(
          verificationId: verificationId,
          phoneNumber: event.phoneNumber,
        ));
        print('🟢 [AuthBloc] Emitted AuthPhoneOtpSent state');
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

    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (authResult) {
        if (authResult.isNewUser) {
          emit(AuthNewPhoneUser(
            user: authResult.user,
            phoneNumber: event.phoneNumber,
          ));
        } else {
          emit(AuthAuthenticated(user: authResult.user));
        }
      },
    );
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

  Future<void> _onSignOut(
    SignOutEvent event,
    Emitter<AuthState> emit,
  ) async {
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
