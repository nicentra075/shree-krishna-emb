import 'package:shree_krishna_core/errors/failures.dart';
import 'package:shree_krishna_core/models/user_model.dart';
import 'package:shree_krishna_core/utils/either.dart';
import 'package:shree_krishna_emb/domain/repositories/auth_repository.dart';

// Sign up with email
class SignUpUseCase {
  final AuthRepository repository;

  SignUpUseCase(this.repository);

  Future<Either<Failure, UserModel>> call({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) {
    return repository.signUpWithEmail(
      name: name,
      email: email,
      phone: phone,
      password: password,
    );
  }
}

// Sign in with email
class SignInUseCase {
  final AuthRepository repository;

  SignInUseCase(this.repository);

  Future<Either<Failure, UserModel>> call({
    required String email,
    required String password,
  }) {
    return repository.signInWithEmail(
      email: email,
      password: password,
    );
  }
}

// Sign in with Google
class SignInWithGoogleUseCase {
  final AuthRepository repository;

  SignInWithGoogleUseCase(this.repository);

  Future<Either<Failure, AuthResult>> call() {
    return repository.signInWithGoogle();
  }
}

// Send phone OTP
class SendPhoneOtpUseCase {
  final AuthRepository repository;

  SendPhoneOtpUseCase(this.repository);

  Future<Either<Failure, String>> call(String phoneNumber) {
    print('🟣 [SendPhoneOtpUseCase] call() invoked with phoneNumber: $phoneNumber');
    final result = repository.sendPhoneOtp(phoneNumber);
    result.then((either) {
      either.fold(
        (failure) => print('🔴 [SendPhoneOtpUseCase] Repository returned failure: ${failure.message}'),
        (verificationId) => print('🟢 [SendPhoneOtpUseCase] Repository returned verificationId: $verificationId'),
      );
    });
    return result;
  }
}

// Verify phone OTP
class VerifyPhoneOtpUseCase {
  final AuthRepository repository;

  VerifyPhoneOtpUseCase(this.repository);

  Future<Either<Failure, AuthResult>> call({
    required String verificationId,
    required String smsCode,
    String? phoneNumber,
  }) {
    return repository.verifyPhoneOtp(
      verificationId: verificationId,
      smsCode: smsCode,
      phoneNumber: phoneNumber,
    );
  }
}

// Complete Google profile (add phone number)
class CompleteGoogleProfileUseCase {
  final AuthRepository repository;

  CompleteGoogleProfileUseCase(this.repository);

  Future<Either<Failure, UserModel>> call({
    required String uid,
    required String phoneNumber,
  }) {
    return repository.completeGoogleProfile(
      uid: uid,
      phoneNumber: phoneNumber,
    );
  }
}

// Complete phone profile (add name and email)
class CompletePhoneProfileUseCase {
  final AuthRepository repository;

  CompletePhoneProfileUseCase(this.repository);

  Future<Either<Failure, UserModel>> call({
    required String uid,
    required String name,
    required String email,
  }) {
    return repository.completePhoneProfile(
      uid: uid,
      name: name,
      email: email,
    );
  }
}

// Sign out
class SignOutUseCase {
  final AuthRepository repository;

  SignOutUseCase(this.repository);

  Future<Either<Failure, void>> call(String userId) {
    return repository.signOut(userId);
  }
}

// Get current user
class GetCurrentUserUseCase {
  final AuthRepository repository;

  GetCurrentUserUseCase(this.repository);

  Future<Either<Failure, UserModel?>> call() {
    return repository.getCurrentUser();
  }
}

// Send password reset email
class SendPasswordResetEmailUseCase {
  final AuthRepository repository;

  SendPasswordResetEmailUseCase(this.repository);

  Future<Either<Failure, void>> call(String email) {
    return repository.sendPasswordResetEmail(email);
  }
}
