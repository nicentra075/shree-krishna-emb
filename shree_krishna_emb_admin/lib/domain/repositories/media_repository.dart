import 'dart:typed_data';

import 'package:shree_krishna_core/shree_krishna_core.dart';
import 'package:shree_krishna_emb_admin/data/models/media_asset_model.dart';

/// Contract for the admin Media Library.
abstract class MediaRepository {
  Future<Either<Failure, List<MediaAssetModel>>> list();
  Future<Either<Failure, MediaAssetModel>> uploadOne({
    required Uint8List bytes,
    required String filename,
    required int timestamp,
    int seed,
    void Function(double progress)? onProgress,
  });
  Future<Either<Failure, void>> delete(MediaAssetModel asset);
}
