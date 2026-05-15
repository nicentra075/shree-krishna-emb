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
      AppLogger.logOperation('signInWithGoogle', status: 'initiating');

      // v7.2.0: Stream-based authentication pattern from official demo
      final userCompleter = Completer<GoogleSignInAccount?>();

      late StreamSubscription<GoogleSignInAuthenticationEvent> subscription;
      subscription = _googleSignIn.authenticationEvents.listen(
        (GoogleSignInAuthenticationEvent event) {
          AppLogger.logOperation(
            'signInWithGoogle',
            status: 'authentication event received',
          );

          // v7.2.0 pattern match: switch on event type
          final GoogleSignInAccount? user = switch (event) {
            GoogleSignInAuthenticationEventSignIn() => event.user,
            GoogleSignInAuthenticationEventSignOut() => null,
          };

          if (!userCompleter.isCompleted) {
            userCompleter.complete(user);
          }
          subscription.cancel();
        },
        onError: (Object error) {
          AppLogger.logError(
            'signInWithGoogle',
            error: 'Authentication event stream error: $error',
          );
          if (!userCompleter.isCompleted) {
            userCompleter.completeError(error);
          }
          subscription.cancel();
        },
      );

      // v7.2.0: Use authenticate() if supported (recommended path)
      AppLogger.logOperation(
        'signInWithGoogle',
        status: 'calling authenticate()',
      );
      if (_googleSignIn.supportsAuthenticate()) {
        await _googleSignIn.authenticate();
      } else {
        // Platform doesn't support authenticate() - shouldn't happen on modern platforms
        throw ServerException(
          message: 'Platform does not support Google authentication',
        );
      }

      // Wait for authentication event (with timeout safety)
      final googleUser = await userCompleter.future.timeout(
        const Duration(seconds: 30),
      );

      if (googleUser == null) {
        AppLogger.logOperation(
          'signInWithGoogle',
          status: 'user cancelled sign in',
        );
        throw ServerException(message: 'Google sign in cancelled');
      }

      AppLogger.logOperation(
        'signInWithGoogle',
        status: 'user account obtained',
      );

      // v7.2.0: Get authentication object
      // In v7.2.0, try to get idToken from authentication
      final googleAuth = googleUser.authentication;

      AppLogger.logOperation(
        'signInWithGoogle',
        status: 'authentication object retrieved',
      );

      // Try to extract ID token (this may work even if accessToken doesn't)
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        AppLogger.logError(
          'signInWithGoogle',
          error: 'Failed to retrieve ID token from authentication',
        );
        throw ServerException(
          message: 'Failed to retrieve authentication token',
        );
      }

      AppLogger.logOperation('signInWithGoogle', status: 'ID token obtained');

      // Create Firebase credential with ID token
      // For v7.2.0, we use only idToken (accessToken is optional)
      final credential = GoogleAuthProvider.credential(idToken: idToken);

      AppLogger.logOperation(
        'signInWithGoogle',
        status: 'Firebase credential created',
      );

      // Sign in with Firebase
      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );

      if (userCredential.user == null) {
        AppLogger.logError(
          'signInWithGoogle',
          error: 'Firebase authentication failed',
        );
        throw ServerException(message: 'Failed to sign in with Google');
      }

      AppLogger.logOperation(
        'signInWithGoogle',
        status: 'Firebase authentication successful',
      );

      final uid = userCredential.user!.uid;
      final userDoc = await _firestore.collection('users').doc(uid).get();
      final isNewUser = !userDoc.exists;

      if (isNewUser) {
        AppLogger.logOperation('signInWithGoogle', status: 'creating new user');

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

        AppLogger.logOperation(
          'signInWithGoogle',
          status: 'new user created in Firestore',
        );

        return AuthResult(user: user, isNewUser: true);
      } else {
        AppLogger.logOperation(
          'signInWithGoogle',
          status: 'existing user login',
        );

        final user = UserModel.fromFirebaseJson(userDoc.data()!, uid);

        await _firestore.collection('users').doc(uid).update({
          'loginAt': DateTime.now().toIso8601String(),
        });

        AppLogger.logOperation(
          'signInWithGoogle',
          status: 'user login timestamp updated',
        );

        return AuthResult(user: user, isNewUser: false);
      }
    } on TimeoutException {
      AppLogger.logError('signInWithGoogle', error: 'Authentication timed out');
      throw ServerException(message: 'Google sign in timed out');
    } on FirebaseAuthException catch (e) {
      AppLogger.logError(
        'signInWithGoogle',
        error: 'Firebase error: ${e.code} - ${e.message}',
      );
      throw ServerException(message: _handleAuthException(e));
    } catch (e) {
      AppLogger.logError(
        'signInWithGoogle',
        error: 'Unexpected error: ${e.toString()}',
      );
      throw ServerException(message: 'Google sign in failed: ${e.toString()}');
    }
  }

  @override
  Future<String> sendPhoneOtp(String phoneNumber) async {
    try {
      print(
        '🟡 [FirebaseAuthDataSource] sendPhoneOtp called with: $phoneNumber',
      );

      final completer = Completer<String>();
      bool isCompleted = false;

      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          print(
            '🟢 [FirebaseAuthDataSource] verificationCompleted - Auto-signing in with credential',
          );
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
          print(
            '🔴 [FirebaseAuthDataSource] verificationFailed - Error: ${e.code} - ${e.message}',
          );
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
          print(
            '🟢 [FirebaseAuthDataSource] codeSent - Verification ID: $vId, ResendToken: $resendToken',
          );
          if (!isCompleted) {
            isCompleted = true;
            if (!completer.isCompleted) {
              completer.complete(vId);
            }
          }
        },
        codeAutoRetrievalTimeout: (String vId) {
          print(
            '🟠 [FirebaseAuthDataSource] codeAutoRetrievalTimeout - Verification ID: $vId',
          );
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
      print(
        '🟢 [FirebaseAuthDataSource] sendPhoneOtp completed successfully with ID: $verificationId',
      );
      return verificationId;
    } catch (e) {
      print(
        '🔴 [FirebaseAuthDataSource] sendPhoneOtp Exception: ${e.toString()}',
      );
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
