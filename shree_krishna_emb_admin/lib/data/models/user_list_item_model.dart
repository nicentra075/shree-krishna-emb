import 'package:shree_krishna_emb_admin/domain/entities/user_list_item.dart';

class UserListItemModel extends UserListItem {
  const UserListItemModel({
    required super.id,
    required super.name,
    required super.email,
    required super.role,
    required super.isActive,
    required super.createdAt,
    super.userId,
    super.phoneNumber,
    super.loginMethod,
    super.photoUrl,
    super.loginAt,
    super.logoutAt,
  });

  // Firebase conversion
  factory UserListItemModel.fromFirebaseJson(Map<String, dynamic> json) {
    // Helper function to safely convert Firestore timestamps to DateTime
    DateTime? parseTimestamp(dynamic timestamp) {
      if (timestamp == null) return null;
      if (timestamp is DateTime) return timestamp;
      if (timestamp is String) return DateTime.tryParse(timestamp);
      // Handle Firestore Timestamp object
      try {
        if (timestamp.runtimeType.toString().contains('Timestamp')) {
          return (timestamp as dynamic).toDate() as DateTime;
        }
      } catch (_) {}
      return null;
    }

    // Helper function to safely convert to String
    String? toStringOrNull(dynamic value) {
      if (value == null) return null;
      return value.toString();
    }

    return UserListItemModel(
      id: toStringOrNull(json['id']) ?? toStringOrNull(json['uid']) ?? 'unknown',
      name: toStringOrNull(json['name']) ?? 'Unknown',
      email: toStringOrNull(json['email']) ?? 'unknown@example.com',
      role: toStringOrNull(json['role']) ?? 'user',
      isActive: json['isActive'] as bool? ?? true,
      createdAt: parseTimestamp(json['createdAt']) ?? DateTime.now(),
      userId: toStringOrNull(json['userId']),
      phoneNumber: toStringOrNull(json['phoneNumber']),
      loginMethod: toStringOrNull(json['loginMethod']),
      photoUrl: toStringOrNull(json['photoUrl']),
      loginAt: parseTimestamp(json['loginAt']),
      logoutAt: parseTimestamp(json['logoutAt']),
    );
  }

  Map<String, dynamic> toFirebaseJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'userId': userId,
      'phoneNumber': phoneNumber,
      'loginMethod': loginMethod,
      'photoUrl': photoUrl,
      'loginAt': loginAt?.toIso8601String(),
      'logoutAt': logoutAt?.toIso8601String(),
    };
  }

  // API conversion (for future backend migration)
  factory UserListItemModel.fromApiJson(Map<String, dynamic> json) {
    return UserListItemModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      isActive: json['isActive'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      userId: json['userId'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      loginMethod: json['loginMethod'] as String?,
      photoUrl: json['photoUrl'] as String?,
      loginAt: json['loginAt'] != null ? DateTime.parse(json['loginAt'] as String) : null,
      logoutAt: json['logoutAt'] != null ? DateTime.parse(json['logoutAt'] as String) : null,
    );
  }

  Map<String, dynamic> toApiJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'userId': userId,
      'phoneNumber': phoneNumber,
      'loginMethod': loginMethod,
      'photoUrl': photoUrl,
      'loginAt': loginAt?.toIso8601String(),
      'logoutAt': logoutAt?.toIso8601String(),
    };
  }
}
