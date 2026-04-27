import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class CheckAuthStatusEvent extends AuthEvent {
  const CheckAuthStatusEvent();
}

class SignUpEvent extends AuthEvent {
  final String name;
  final String email;
  final String phone;
  final String password;

  const SignUpEvent({
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
  });

  @override
  List<Object?> get props => [name, email, phone, password];
}

class SignInEvent extends AuthEvent {
  final String email;
  final String password;

  const SignInEvent({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

class SignInWithGoogleEvent extends AuthEvent {
  const SignInWithGoogleEvent();
}

class SendPhoneOtpEvent extends AuthEvent {
  final String phoneNumber;

  const SendPhoneOtpEvent({required this.phoneNumber});

  @override
  List<Object?> get props => [phoneNumber];
}

class VerifyPhoneOtpEvent extends AuthEvent {
  final String verificationId;
  final String smsCode;
  final String phoneNumber;

  const VerifyPhoneOtpEvent({
    required this.verificationId,
    required this.smsCode,
    required this.phoneNumber,
  });

  @override
  List<Object?> get props => [verificationId, smsCode, phoneNumber];
}

class CompleteGoogleProfileEvent extends AuthEvent {
  final String uid;
  final String phoneNumber;

  const CompleteGoogleProfileEvent({
    required this.uid,
    required this.phoneNumber,
  });

  @override
  List<Object?> get props => [uid, phoneNumber];
}

class CompletePhoneProfileEvent extends AuthEvent {
  final String uid;
  final String name;
  final String email;

  const CompletePhoneProfileEvent({
    required this.uid,
    required this.name,
    required this.email,
  });

  @override
  List<Object?> get props => [uid, name, email];
}

class SignOutEvent extends AuthEvent {
  const SignOutEvent();
}

class SendPasswordResetEmailEvent extends AuthEvent {
  final String email;

  const SendPasswordResetEmailEvent({required this.email});

  @override
  List<Object?> get props => [email];
}
