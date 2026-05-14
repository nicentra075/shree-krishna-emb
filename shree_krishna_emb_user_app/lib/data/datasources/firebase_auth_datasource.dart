import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shree_krishna_core/models/user_model.dart';
import 'package:shree_krishna_core/errors/exceptions.dart';
import 'package:shree_krishna_emb/domain/repositories/auth_repository.dart';
import 'package:shree_krishna_emb/core/utils/app_logger.dart';
import 'dart:async';

abstract class FirebaseAuthDataSource {
  Future<UserModel> signUpWithEmail({
    required String name,
    required String email,
    required String phone,
    required String password,
  });

  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  });

  Future<AuthResult> signInWithGoogle();

  Future<String> sendPhoneOtp(String phoneNumber);

  Future<AuthResult> verifyPhoneOtp({
    required String verificationId,
    required String smsCode,
    String? phoneNumber,
  });

  Future<UserModel> completeGoogleProfile({
    required String uid,
    required String phoneNumber,
  });

  Future<UserModel> completePhoneProfile({
    required String uid,
    required String name,
    required String email,
  });

  Future<void> signOut(String userId);

  Future<UserModel?> getCurrentUser();

  Future<void> sendPasswordResetEmail(String email);
}

class FirebaseAuthDataSourceImpl implements FirebaseAuthDataSource {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  FirebaseAuthDataSourceImpl({
    required FirebaseAuth firebaseAuth,
    required FirebaseFirestore firestore,
    required GoogleSignIn googleSignIn,
  }) : _firebaseAuth = firebaseAuth,
       _firestore = firestore,
       _googleSignIn = googleSignIn;

  @override
  Future<UserModel> signUpWithEmail({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw ServerException(message: 'Failed to create user account');
      }

      final uid = userCredential.user!.uid;
      final userId = await _generateSequentialUserId();

      final user = UserModel(
        id: uid,
        email: email,
        name: name,
        phoneNumber: phone,
        userId: userId,
        loginMethod: 'email',
        createdAt: DateTime.now(),
        loginAt: DateTime.now(),
        logoutAt: null,
        isActive: true,
      );

      await _firestore.collection('users').doc(uid).set(user.toFirebaseJson());

      return user;
    } on FirebaseAuthException catch (e) {
      throw ServerException(message: _handleAuthException(e));
    } catch (e) {
      throw ServerException(message: 'Failed to sign up: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw ServerException(message: 'Failed to sign in');
      }

      final uid = userCredential.user!.uid;
      final userDoc = await _firestore.collection('users').doc(uid).get();

      if (!userDoc.exists) {
        throw ServerException(message: 'User profile not found');
      }

      final user = UserModel.fromFirebaseJson(userDoc.data()!, uid);

      await _firestore.collection('users').doc(uid).update({
        'loginAt': DateTime.now().toIso8601String(),
      });

      return user;
    } on FirebaseAuthException catch (e) {
      throw ServerException(message: _handleAuthException(e));
    } catch (e) {
      throw ServerException(message: 'Failed to sign in: ${e.toString()}');
    }
  }

  @override
  Future<AuthResult> signInWithGoogle() async {
    try {
      AppLogger.logOperation('signInWithGoogle', status: 'starting authentication');

      // v7.x API: authenticate() returns GoogleSignInAuthentication directly
      final googleAuth = await _googleSignIn.authenticate();

      if (googleAuth == null) {
        throw ServerException(message: 'Google sign in cancelled');
      }

      // In v7.x, the authentication object has accessToken and idToken directly
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );

      if (userCredential.user == null) {
        throw ServerException(message: 'Failed to sign in with Google');
      }

      final uid = userCredential.user!.uid;
      final userDoc = await _firestore.collection('users').doc(uid).get();

      final isNewUser = !userDoc.exists;

      if (isNewUser) {
        final user = UserModel(
          id: uid,
          email: userCredential.user!.email ?? '',
          name: userCredential.user!.displayName,
          phoneNumber: null,
          userId: await _generateSequentialUserId(),
          loginMethod: 'google',
          createdAt: DateTime.now(),
          loginAt: DateTime.now(),
          logoutAt: null,
          isActive: true,
        );

        await _firestore
            .collection('users')
            .doc(uid)
            .set(user.toFirebaseJson());

        return AuthResult(user: user, isNewUser: true);
      } else {
        final user = UserModel.fromFirebaseJson(userDoc.data()!, uid);

        await _firestore.collection('users').doc(uid).update({
          'loginAt': DateTime.now().toIso8601String(),
        });

        return AuthResult(user: user, isNewUser: false);
      }
    } catch (e) {
      throw ServerException(message: 'Google sign in failed: ${e.toString()}');
    }
  }

  @override
  Future<String> sendPhoneOtp(String phoneNumber) async {
    try {
      AppLogger.logOperation('sendPhoneOtp', data: phoneNumber);

      final completer = Completer<String>();
      bool isCompleted = false;

      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          AppLogger.logOperation('verificationCompleted', status: 'Auto-signing in with credential');
          if (!isCompleted) {
            isCompleted = true;
            await _firebaseAuth.signInWithCredential(credential);
            if (!completer.isCompleted) {
              completer.completeError(
                ServerException(
                  message:
                      'Auto verification completed, but OTP flow was not initiated',
                ),
              );
            }
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          AppLogger.logError('verificationFailed', error: '${e.code} - ${e.message}');
          if (!isCompleted) {
            isCompleted = true;
            if (!completer.isCompleted) {
              completer.completeError(
                ServerException(message: _handleAuthException(e)),
              );
            }
          }
        },
        codeSent: (String vId, int? resendToken) {
          AppLogger.logOperation('codeSent', data: 'VerificationID: $vId, ResendToken: $resendToken');
          if (!isCompleted) {
            isCompleted = true;
            if (!completer.isCompleted) {
              completer.complete(vId);
            }
          }
        },
        codeAutoRetrievalTimeout: (String vId) {
          AppLogger.logOperation('codeAutoRetrievalTimeout', data: 'VerificationID: $vId');
          if (!isCompleted) {
            isCompleted = true;
            if (!completer.isCompleted) {
              completer.complete(vId);
            }
          }
        },
        timeout: const Duration(seconds: 60),
      );

      final verificationId = await completer.future;
      AppLogger.logOperation('sendPhoneOtp', status: 'completed', data: 'VerificationID: $verificationId');
      return verificationId;
    } catch (e) {
      AppLogger.logError('sendPhoneOtp Exception', error: e.toString());
      throw ServerException(
        message: 'Failed to send phone OTP: ${e.toString()}',
      );
    }
  }

  @override
  Future<AuthResult> verifyPhoneOtp({
    required String verificationId,
    required String smsCode,
    String? phoneNumber,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );

      if (userCredential.user == null) {
        throw ServerException(message: 'Failed to verify OTP');
      }

      final uid = userCredential.user!.uid;
      final userDoc = await _firestore.collection('users').doc(uid).get();

      final isNewUser = !userDoc.exists;

      if (isNewUser) {
        final user = UserModel(
          id: uid,
          email: '',
          name: null,
          phoneNumber: phoneNumber,
          userId: await _generateSequentialUserId(),
          loginMethod: 'phone',
          createdAt: DateTime.now(),
          loginAt: DateTime.now(),
          logoutAt: null,
          isActive: true,
        );

        await _firestore
            .collection('users')
            .doc(uid)
            .set(user.toFirebaseJson());

        return AuthResult(user: user, isNewUser: true);
      } else {
        final user = UserModel.fromFirebaseJson(userDoc.data()!, uid);

        await _firestore.collection('users').doc(uid).update({
          'loginAt': DateTime.now().toIso8601String(),
        });

        return AuthResult(user: user, isNewUser: false);
      }
    } on FirebaseAuthException catch (e) {
      throw ServerException(message: _handleAuthException(e));
    } catch (e) {
      throw ServerException(message: 'Failed to verify OTP: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> completeGoogleProfile({
    required String uid,
    required String phoneNumber,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'phoneNumber': phoneNumber,
      });

      final userDoc = await _firestore.collection('users').doc(uid).get();
      final user = UserModel.fromFirebaseJson(userDoc.data()!, uid);

      return user;
    } catch (e) {
      throw ServerException(
        message: 'Failed to complete profile: ${e.toString()}',
      );
    }
  }

  @override
  Future<UserModel> completePhoneProfile({
    required String uid,
    required String name,
    required String email,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'name': name,
        'email': email,
      });

      final userDoc = await _firestore.collection('users').doc(uid).get();
      final user = UserModel.fromFirebaseJson(userDoc.data()!, uid);

      return user;
    } catch (e) {
      throw ServerException(
        message: 'Failed to complete profile: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> signOut(String userId) async {
    try {
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser != null) {
        await _firestore.collection('users').doc(currentUser.uid).update({
          'logoutAt': DateTime.now().toIso8601String(),
        });
      }

      await _firebaseAuth.signOut();
      await _googleSignIn.signOut();
    } catch (e) {
      throw ServerException(message: 'Failed to sign out: ${e.toString()}');
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final firebaseUser = _firebaseAuth.currentUser;

      if (firebaseUser == null) {
        return null;
      }

      final userDoc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (!userDoc.exists) {
        return null;
      }

      return UserModel.fromFirebaseJson(userDoc.data()!, firebaseUser.uid);
    } catch (e) {
      throw ServerException(
        message: 'Failed to get current user: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw ServerException(message: _handleAuthException(e));
    } catch (e) {
      throw ServerException(
        message: 'Failed to send reset email: ${e.toString()}',
      );
    }
  }

  Future<int> _generateSequentialUserId() async {
    final counterDoc = _firestore.collection('counters').doc('user_id_counter');

    final result = await _firestore.runTransaction<int>((transaction) async {
      final doc = await transaction.get(counterDoc);

      if (!doc.exists) {
        transaction.set(counterDoc, {'count': 1});
        return 1;
      }

      final currentCount = (doc.data()?['count'] as int?) ?? 0;
      final newCount = currentCount + 1;

      transaction.update(counterDoc, {'count': newCount});

      return newCount;
    });

    return result;
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak';
      case 'email-already-in-use':
        return 'An account already exists for this email';
      case 'invalid-email':
        return 'The email address is invalid';
      case 'user-disabled':
        return 'This user account has been disabled';
      case 'user-not-found':
        return 'No user found for this email';
      case 'wrong-password':
        return 'Wrong password provided';
      case 'invalid-verification-code':
        return 'Invalid OTP code';
      case 'session-expired':
        return 'OTP has expired. Please request a new one';
      default:
        return e.message ?? 'Authentication failed';
    }
  }
}
