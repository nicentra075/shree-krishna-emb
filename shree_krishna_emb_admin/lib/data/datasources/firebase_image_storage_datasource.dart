import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:shree_krishna_core/shree_krishna_core.dart';
import 'package:shree_krishna_emb_admin/core/utils/app_logger.dart';

/// Uploaded image: the public download URL + its Storage path (used for delete).
class UploadedImage {
  final String url;
  final String path;
  const UploadedImage({required this.url, required this.path});
}

/// Uploads/deletes catalog images in Firebase Storage. Works on the free Spark
/// plan (Storage is free-tier). Cross-platform: uploads raw bytes.
class ImageStorageDataSource {
  final FirebaseStorage _storage;

  ImageStorageDataSource({required FirebaseStorage storage})
      : _storage = storage;

  /// Uploads [bytes] under [folder] (e.g. 'collections', 'designs', 'media').
  /// Returns the download URL + storage path.
  Future<UploadedImage> upload({
    required Uint8List bytes,
    required String folder,
    required String filename,
    String contentType = 'image/jpeg',
  }) async {
    try {
      final safeName = filename.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
      final path = '$folder/$safeName';
      final ref = _storage.ref(path);
      final task = await ref.putData(
        bytes,
        SettableMetadata(contentType: contentType),
      );
      final url = await task.ref.getDownloadURL();
      return UploadedImage(url: url, path: path);
    } on FirebaseException catch (e) {
      throw ServerException(message: e.message ?? 'Image upload failed');
    } catch (e) {
      throw ServerException(message: 'Image upload failed: $e');
    }
  }

  /// True when [url] points at a shared Media Library asset (under `media/`),
  /// which must NOT be deleted when an item that merely references it is deleted.
  bool isMediaLibraryUrl(String url) {
    try {
      return _storage.refFromURL(url).fullPath.startsWith('media/');
    } catch (_) {
      return false;
    }
  }

  /// Best-effort delete of a Storage object by its download URL. Skips non-
  /// Storage URLs (e.g. manually-pasted external URLs) and shared media assets.
  /// Never throws — a failure here must not block the Firestore delete.
  Future<void> deleteByUrl(String url) async {
    if (url.isEmpty) return;
    try {
      final ref = _storage.refFromURL(url);
      if (ref.fullPath.startsWith('media/')) return; // shared asset — keep
      await ref.delete();
    } catch (e, s) {
      AppLogger.logError('deleteByUrl', error: e, stackTrace: s);
    }
  }

  /// Best-effort delete of many image URLs.
  Future<void> deleteUrls(Iterable<String> urls) async {
    for (final u in urls) {
      await deleteByUrl(u);
    }
  }

  /// Deletes a Storage object by URL even if it lives under `media/`. Used by
  /// the Media Library itself when the admin explicitly deletes an asset.
  Future<void> forceDeleteByUrl(String url) async {
    if (url.isEmpty) return;
    try {
      await _storage.refFromURL(url).delete();
    } catch (e, s) {
      AppLogger.logError('forceDeleteByUrl', error: e, stackTrace: s);
    }
  }
}
