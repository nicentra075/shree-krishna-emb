import 'package:equatable/equatable.dart';

import '../enums/activity_type.dart';

// Entity - Domain layer.
// An `activity/{autoId}` document (admin recent-activity feed).
// NOTE: the Firestore doc also carries an `expireAt` Timestamp (30-day TTL)
// written by Cloud Functions — intentionally absent from the Dart model.
class ActivityEntity extends Equatable {
  final String id;
  final ActivityType type;

  /// Pre-rendered English message.
  final String message;
  final String? refId;
  final String? actorId;
  final String? actorName;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  const ActivityEntity({
    required this.id,
    required this.type,
    required this.message,
    this.refId,
    this.actorId,
    this.actorName,
    this.metadata = const {},
    required this.createdAt,
  });

  @override
  List<Object?> get props =>
      [id, type, message, refId, actorId, actorName, metadata, createdAt];
}

// Model - Data layer
class ActivityModel extends ActivityEntity {
  const ActivityModel({
    required super.id,
    required super.type,
    required super.message,
    super.refId,
    super.actorId,
    super.actorName,
    super.metadata,
    required super.createdAt,
  });

  factory ActivityModel.fromFirebaseJson(Map<String, dynamic> json, String id) {
    return ActivityModel(
      id: id,
      type: ActivityType.fromString(json['type'] as String?),
      message: json['message'] as String? ?? '',
      refId: json['refId'] as String?,
      actorId: json['actorId'] as String?,
      actorName: json['actorName'] as String?,
      metadata:
          (json['metadata'] as Map<String, dynamic>?) ?? const {},
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  // Used by the admin client when batching activity entries with
  // design/category CRUD ops (expireAt is appended by the datasource).
  Map<String, dynamic> toFirebaseJson() {
    return {
      'type': type.value,
      'message': message,
      'refId': refId,
      'actorId': actorId,
      'actorName': actorName,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ActivityModel.fromApiJson(Map<String, dynamic> json) =>
      ActivityModel.fromFirebaseJson(json, json['id'] as String? ?? '');

  Map<String, dynamic> toApiJson() => {'id': id, ...toFirebaseJson()};
}
