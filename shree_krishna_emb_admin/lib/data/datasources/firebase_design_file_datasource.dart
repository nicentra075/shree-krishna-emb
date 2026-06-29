import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shree_krishna_core/shree_krishna_core.dart';
import 'package:shree_krishna_emb_admin/data/datasources/firebase_image_storage_datasource.dart';
import 'package:shree_krishna_emb_admin/data/models/design_file_asset_model.dart';

/// Reads/writes the Design File Library: Storage objects under `design_files/`
/// indexed by `design_files/{id}` Firestore docs. Distinct from the image
/// Media Library (`media/`) — these are downloadable embroidery source files.
class FirebaseDesignFileDataSource {
  final FirebaseFirestore _firestore;
  final ImageStorageDataSource _storage;

  FirebaseDesignFileDataSource({
    required FirebaseFirestore firestore,
    required ImageStorageDataSource storage,
  }) : _firestore = firestore,
       _storage = storage;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('design_files');

  /// Infers the format tag from the file extension (DST/EMB/DHE), else 'OTHER'.
  static String formatFromName(String name) {
    final i = name.lastIndexOf('.');
    if (i < 0 || i == name.length - 1) return 'OTHER';
    final ext = name.substring(i + 1).toUpperCase();
    return const ['DST', 'EMB', 'DHE'].contains(ext) ? ext : 'OTHER';
  }

  Future<List<DesignFileAssetModel>> list() async {
    try {
      final snap = await _col
          .orderBy('createdAt', descending: true)
          .limit(300)
          .get();
      return snap.docs
          .map(
            (d) => DesignFileAssetModel.fromFirebaseJson({
              ...d.data(),
              'id': d.id,
            }),
          )
          .toList();
    } on FirebaseException catch (e) {
      throw ServerException(
        message: e.message ?? 'Failed to load design files',
      );
    }
  }

  /// Uploads one design file and indexes it. [seed] varies the filename so a
  /// batch uploaded in the same millisecond doesn't collide. [format] overrides
  /// the extension-inferred tag (e.g. the slot the admin is filling).
  Future<DesignFileAssetModel> uploadOne({
    required Uint8List bytes,
    required String filename,
    required int timestamp,
    String? format,
    int seed = 0,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final uploaded = await _storage.upload(
        bytes: bytes,
        folder: 'design_files',
        filename: '${timestamp}_${seed}_$filename',
        contentType: 'application/octet-stream',
        onProgress: onProgress,
      );
      final doc = _col.doc();
      final asset = DesignFileAssetModel(
        id: doc.id,
        name: filename,
        url: uploaded.url,
        path: uploaded.path,
        format: (format ?? formatFromName(filename)).toUpperCase(),
        sizeBytes: bytes.length,
        createdAt: DateTime.fromMillisecondsSinceEpoch(timestamp),
      );
      await doc.set(asset.toFirebaseJson());
      return asset;
    } on FirebaseException catch (e) {
      throw ServerException(message: e.message ?? 'Design file upload failed');
    }
  }

  Future<void> delete(DesignFileAssetModel asset) async {
    try {
      await _storage.forceDeleteByUrl(asset.url);
      await _col.doc(asset.id).delete();
    } on FirebaseException catch (e) {
      throw ServerException(message: e.message ?? 'Design file delete failed');
    }
  }
}
