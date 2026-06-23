import 'package:equatable/equatable.dart';

// Entity - Domain layer (pure Dart, no Firebase/API dependencies)
class UserEntity extends Equatable {
  final String id;
  final String email;
  final String? name;
  final String? phoneNumber;
  final String? photoUrl;
  final int? userId;
  final String loginMethod;
  final DateTime createdAt;
  final DateTime? loginAt;
  final DateTime? logoutAt;
  final bool isActive;

  const UserEntity({
    required this.id,
    required this.email,
    this.name,
    this.phoneNumber,
    this.photoUrl,
    this.userId,
    this.loginMethod = 'email',
    required this.createdAt,
    this.loginAt,
    this.logoutAt,
    required this.isActive,
  });

  @override
  List<Object?> get props => [
    id,
    email,
    name,
    phoneNumber,
    photoUrl,
    userId,
    loginMethod,
    createdAt,
    loginAt,
    logoutAt,
    isActive,
  ];

  // Create copy with modified fields
  UserEntity copyWith({
    String? id,
    String? email,
    String? name,
    String? phoneNumber,
    String? photoUrl,
    int? userId,
    String? loginMethod,
    DateTime? createdAt,
    DateTime? loginAt,
    DateTime? logoutAt,
    bool? isActive,
  }) {
    return UserEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      userId: userId ?? this.userId,
      loginMethod: loginMethod ?? this.loginMethod,
      createdAt: createdAt ?? this.createdAt,
      loginAt: loginAt ?? this.loginAt,
      logoutAt: logoutAt ?? this.logoutAt,
      isActive: isActive ?? this.isActive,
    );
  }
}

// Model - Data layer (can be converted from Firebase/API)
class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    super.name,
    super.phoneNumber,
    super.photoUrl,
    super.userId,
    super.loginMethod,
    required super.createdAt,
    super.loginAt,
    super.logoutAt,
    required super.isActive,
  });

  // Convert from Firebase Firestore JSON
  factory UserModel.fromFirebaseJson(Map<String, dynamic> json, String id) {
    return UserModel(
      id: id,
      email: json['email'] as String? ?? '',
      name: json['name'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      photoUrl: json['photoUrl'] as String?,
      userId: _parseUserId(json['userId']),
      loginMethod: json['loginMethod'] as String? ?? 'email',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      loginAt: json['loginAt'] != null
          ? DateTime.parse(json['loginAt'] as String)
          : null,
      logoutAt: json['logoutAt'] != null
          ? DateTime.parse(json['logoutAt'] as String)
          : null,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  // Safely parse `userId`, which may be stored as an int (user-app signup) or
  // a String (admin-panel edits). Tolerating both prevents type-cast crashes
  // on login when the same document is written by different clients.
  static int? _parseUserId(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  // Convert to Firebase Firestore JSON
  Map<String, dynamic> toFirebaseJson() {
    return {
      'email': email,
      'name': name,
      'phoneNumber': phoneNumber,
      'photoUrl': photoUrl,
      'userId': userId,
      'loginMethod': loginMethod,
      'createdAt': createdAt.toIso8601String(),
      'loginAt': loginAt?.toIso8601String(),
      'logoutAt': logoutAt?.toIso8601String(),
      'isActive': isActive,
    };
  }

  // Convert from REST API JSON (future migration)
  factory UserModel.fromApiJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      name: json['name'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      photoUrl: json['photoUrl'] as String?,
      userId: json['userId'] as int?,
      loginMethod: json['loginMethod'] as String? ?? 'email',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      loginAt: json['loginAt'] != null
          ? DateTime.parse(json['loginAt'] as String)
          : null,
      logoutAt: json['logoutAt'] != null
          ? DateTime.parse(json['logoutAt'] as String)
          : null,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  // Convert to REST API JSON
  Map<String, dynamic> toApiJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phoneNumber': phoneNumber,
      'photoUrl': photoUrl,
      'userId': userId,
      'loginMethod': loginMethod,
      'createdAt': createdAt.toIso8601String(),
      'loginAt': loginAt?.toIso8601String(),
      'logoutAt': logoutAt?.toIso8601String(),
      'isActive': isActive,
    };
  }

  // Convert entity to model
  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      email: entity.email,
      name: entity.name,
      phoneNumber: entity.phoneNumber,
      photoUrl: entity.photoUrl,
      userId: entity.userId,
      loginMethod: entity.loginMethod,
      createdAt: entity.createdAt,
      loginAt: entity.loginAt,
      logoutAt: entity.logoutAt,
      isActive: entity.isActive,
    );
  }
}
