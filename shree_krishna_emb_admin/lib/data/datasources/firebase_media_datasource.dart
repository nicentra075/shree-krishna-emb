import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shree_krishna_core/shree_krishna_core.dart';
import 'package:shree_krishna_emb_admin/data/datasources/firebase_image_storage_datasource.dart';
import 'package:shree_krishna_emb_admin/data/models/media_asset_model.dart';

/// Reads/writes the Media Library: Storage objects under `media/` indexed by
/// `media/{id}` Firestore docs.
class FirebaseMediaDataSource {
  final FirebaseFirestore _firestore;
  final ImageStorageDataSource _imageStorage;

  FirebaseMediaDataSource({
    required FirebaseFirestore firestore,
    required ImageStorageDataSource imageStorage,
  })  : _firestore = firestore,
        _imageStorage = imageStorage;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('media');

  Future<List<MediaAssetModel>> list() async {
    try {
      final snap = await _col.orderBy('createdAt', descending: true).limit(300).get();
      return snap.docs
          .map((d) => MediaAssetModel.fromFirebaseJson({...d.data(), 'id': d.id}))
          .toList();
    } on FirebaseException catch (e) {
      throw ServerException(message: e.message ?? 'Failed to load media');
    }
  }

  /// Uploads one image and indexes it. [seed] varies the filename so a batch
  /// uploaded in the same millisecond doesn't collide.
  Future<MediaAssetModel> uploadOne({
    required Uint8List bytes,
    required String filename,
    required int timestamp,
    int seed = 0,
  }) async {
    try {
      final uploaded = await _imageStorage.upload(
        bytes: bytes,
        folder: 'media',
        filename: '${timestamp}_${seed}_$filename',
      );
      final doc = _col.doc();
      final asset = MediaAssetModel(
        id: doc.id,
        name: filename,
        url: uploaded.url,
        path: uploaded.path,
        sizeBytes: bytes.length,
        createdAt: DateTime.fromMillisecondsSinceEpoch(timestamp),
      );
      await doc.set(asset.toFirebaseJson());
      return asset;
    } on FirebaseException catch (e) {
      throw ServerException(message: e.message ?? 'Media upload failed');
    }
  }

  Future<void> delete(MediaAssetModel asset) async {
    try {
      // Force-delete the Storage object (it lives under `media/`, which the
      // best-effort deleteByUrl deliberately skips).
      await _imageStorage.forceDeleteByUrl(asset.url);
      await _col.doc(asset.id).delete();
    } on FirebaseException catch (e) {
      throw ServerException(message: e.message ?? 'Media delete failed');
    }
  }
}
