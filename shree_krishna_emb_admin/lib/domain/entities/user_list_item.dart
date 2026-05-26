import 'package:equatable/equatable.dart';

class UserListItem extends Equatable {
  final String id;
  final String name;
  final String email;
  final String role;
  final bool isActive;
  final DateTime createdAt;
  final String? userId;
  final String? phoneNumber;
  final String? loginMethod;
  final String? photoUrl;
  final DateTime? loginAt;
  final DateTime? logoutAt;

  const UserListItem({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.isActive,
    required this.createdAt,
    this.userId,
    this.phoneNumber,
    this.loginMethod,
    this.photoUrl,
    this.loginAt,
    this.logoutAt,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    email,
    role,
    isActive,
    createdAt,
    userId,
    phoneNumber,
    loginMethod,
    photoUrl,
    loginAt,
    logoutAt,
  ];
}
