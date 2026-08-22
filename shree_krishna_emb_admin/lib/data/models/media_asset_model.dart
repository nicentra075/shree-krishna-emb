import 'package:shree_krishna_emb_admin/data/models/catalog_parse.dart';

/// A reusable image asset in the admin Media Library (`media/{id}` doc + a
/// Storage object under `media/`).
class MediaAssetModel {
  final String id;
  final String name;
  final String url;
  final String path; // Storage path, for delete
  final int sizeBytes;
  final DateTime createdAt;

  const MediaAssetModel({
    required this.id,
    required this.name,
    required this.url,
    required this.path,
    this.sizeBytes = 0,
    required this.createdAt,
  });

  factory MediaAssetModel.fromFirebaseJson(Map<String, dynamic> json) {
    return MediaAssetModel(
      id: toStringOrNull(json['id']) ?? '',
      name: toStringOrNull(json['name']) ?? 'image',
      url: toStringOrNull(json['url']) ?? '',
      path: toStringOrNull(json['path']) ?? '',
      sizeBytes: toInt(json['sizeBytes']),
      createdAt: json['createdAt'] != null
          ? parseTimestamp(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirebaseJson() => {
    'name': name,
    'url': url,
    'path': path,
    'sizeBytes': sizeBytes,
    'createdAt': createdAt.toIso8601String(),
  };
}
