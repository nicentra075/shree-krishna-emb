import 'package:shree_krishna_core/errors/failures.dart';
import 'package:shree_krishna_core/models/user_model.dart';
import 'package:shree_krishna_core/utils/either.dart';

class AuthResult {
  final UserModel user;
  final bool isNewUser;
  final String? verificationId;

  AuthResult({
    required this.user,
    required this.isNewUser,
    this.verificationId,
  });
}

abstract class AuthRepository {
  Future<Either<Failure, UserModel>> signUpWithEmail({
    required String name,
    required String email,
    required String phone,
    required String password,
  });

  Future<Either<Failure, UserModel>> signInWithEmail({
    required String email,
    required String password,
  });

  Future<Either<Failure, AuthResult>> signInWithGoogle();

  Future<Either<Failure, AuthResult>> signInWithApple();

  Future<Either<Failure, String>> sendPhoneOtp(String phoneNumber);

  Future<Either<Failure, AuthResult>> verifyPhoneOtp({
    required String verificationId,
    required String smsCode,
    String? phoneNumber,
  });

  Future<Either<Failure, UserModel>> completeGoogleProfile({
    required String uid,
    required String phoneNumber,
  });

  Future<Either<Failure, UserModel>> completePhoneProfile({
    required String uid,
    required String name,
    required String email,
  });

  Future<Either<Failure, void>> signOut(String userId);

  Future<Either<Failure, UserModel?>> getCurrentUser();

  Future<Either<Failure, void>> sendPasswordResetEmail(String email);
}
