import 'package:equatable/equatable.dart';
import '../enums/app_notification_type.dart';

class AppNotificationEntity extends Equatable {
  final String id;
  final AppNotificationType type;
  final String title;
  final String body;
  final String? imageUrl;
  final Map<String, dynamic> data;
  final bool read;
  final DateTime createdAt;

  const AppNotificationEntity({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.imageUrl,
    this.data = const {},
    this.read = false,
    required this.createdAt,
  });

  String? get designId => data['designId'] as String?;

  @override
  List<Object?> get props => [id, type, title, body, imageUrl, data, read, createdAt];
}

class AppNotificationModel extends AppNotificationEntity {
  const AppNotificationModel({
    required super.id,
    required super.type,
    required super.title,
    required super.body,
    super.imageUrl,
    super.data,
    super.read,
    required super.createdAt,
  });

  factory AppNotificationModel.fromFirebaseJson(Map<String, dynamic> json, String id) {
    return AppNotificationModel(
      id: id,
      type: AppNotificationType.fromString(json['type'] as String?),
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      data: (json['data'] as Map?)?.cast<String, dynamic>() ?? const {},
      read: json['read'] as bool? ?? false,
      createdAt: _parseTs(json['createdAt']),
    );
  }

  Map<String, dynamic> toFirebaseJson() => {
        'type': type.value,
        'title': title,
        'body': body,
        'imageUrl': imageUrl,
        'data': data,
        'read': read,
        'createdAt': createdAt.toIso8601String(),
      };

  factory AppNotificationModel.fromApiJson(Map<String, dynamic> json) =>
      AppNotificationModel.fromFirebaseJson(json, json['id'] as String? ?? '');

  Map<String, dynamic> toApiJson() => {'id': id, ...toFirebaseJson()};

  factory AppNotificationModel.fromEntity(AppNotificationEntity e) => AppNotificationModel(
        id: e.id, type: e.type, title: e.title, body: e.body,
        imageUrl: e.imageUrl, data: e.data, read: e.read, createdAt: e.createdAt,
      );

  static DateTime _parseTs(dynamic v) {
    if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
    // Firestore Timestamp has toDate(); avoid importing cloud_firestore in core.
    try { return (v as dynamic).toDate() as DateTime; } catch (_) { return DateTime.now(); }
  }
}
