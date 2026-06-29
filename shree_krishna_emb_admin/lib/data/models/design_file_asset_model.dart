import 'package:shree_krishna_emb_admin/data/models/catalog_parse.dart';

/// A reusable design source file in the admin Design File Library
/// (`design_files/{id}` doc + a Storage object under `design_files/`). Tagged
/// with its [format] (DST | EMB | DHE | OTHER).
class DesignFileAssetModel {
  final String id;
  final String name;
  final String url;
  final String path; // Storage path, for delete
  final String format;
  final int sizeBytes;
  final DateTime createdAt;

  const DesignFileAssetModel({
    required this.id,
    required this.name,
    required this.url,
    required this.path,
    this.format = '',
    this.sizeBytes = 0,
    required this.createdAt,
  });

  factory DesignFileAssetModel.fromFirebaseJson(Map<String, dynamic> json) {
    return DesignFileAssetModel(
      id: toStringOrNull(json['id']) ?? '',
      name: toStringOrNull(json['name']) ?? 'file',
      url: toStringOrNull(json['url']) ?? '',
      path: toStringOrNull(json['path']) ?? '',
      format: (toStringOrNull(json['format']) ?? '').toUpperCase(),
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
    'format': format,
    'sizeBytes': sizeBytes,
    'createdAt': createdAt.toIso8601String(),
  };
}
