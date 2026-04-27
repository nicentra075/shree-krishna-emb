import 'package:shree_krishna_core/errors/exceptions.dart';
import 'package:shree_krishna_core/errors/failures.dart';
import 'package:shree_krishna_core/models/user_model.dart';
import 'package:shree_krishna_core/utils/either.dart';
import 'package:shree_krishna_emb/data/datasources/firebase_auth_datasource.dart';
import 'package:shree_krishna_emb/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuthDataSource _dataSource;

  AuthRepositoryImpl({required FirebaseAuthDataSource dataSource})
      : _dataSource = dataSource;

  @override
  Future<Either<Failure, UserModel>> signUpWithEmail({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final user = await _dataSource.signUpWithEmail(
        name: name,
        email: email,
        phone: phone,
        password: password,
      );
      return Right(user);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserModel>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _dataSource.signInWithEmail(
        email: email,
        password: password,
      );
      return Right(user);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AuthResult>> signInWithGoogle() async {
    try {
      final result = await _dataSource.signInWithGoogle();
      return Right(AuthResult(
        user: result.user,
        isNewUser: result.isNewUser,
        verificationId: result.verificationId,
      ));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> sendPhoneOtp(String phoneNumber) async {
    try {
      final verificationId = await _dataSource.sendPhoneOtp(phoneNumber);
      return Right(verificationId);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AuthResult>> verifyPhoneOtp({
    required String verificationId,
    required String smsCode,
    String? phoneNumber,
  }) async {
    try {
      final result = await _dataSource.verifyPhoneOtp(
        verificationId: verificationId,
        smsCode: smsCode,
        phoneNumber: phoneNumber,
      );
      return Right(AuthResult(
        user: result.user,
        isNewUser: result.isNewUser,
        verificationId: result.verificationId,
      ));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserModel>> completeGoogleProfile({
    required String uid,
    required String phoneNumber,
  }) async {
    try {
      final user = await _dataSource.completeGoogleProfile(
        uid: uid,
        phoneNumber: phoneNumber,
      );
      return Right(user);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserModel>> completePhoneProfile({
    required String uid,
    required String name,
    required String email,
  }) async {
    try {
      final user = await _dataSource.completePhoneProfile(
        uid: uid,
        name: name,
        email: email,
      );
      return Right(user);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> signOut(String userId) async {
    try {
      await _dataSource.signOut(userId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserModel?>> getCurrentUser() async {
    try {
      final user = await _dataSource.getCurrentUser();
      return Right(user);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> sendPasswordResetEmail(String email) async {
    try {
      await _dataSource.sendPasswordResetEmail(email);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
