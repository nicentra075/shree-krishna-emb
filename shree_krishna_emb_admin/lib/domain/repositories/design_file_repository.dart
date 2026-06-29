import 'dart:typed_data';

import 'package:shree_krishna_core/shree_krishna_core.dart';
import 'package:shree_krishna_emb_admin/data/models/design_file_asset_model.dart';

/// Contract for the admin Design File Library (downloadable source files).
abstract class DesignFileRepository {
  Future<Either<Failure, List<DesignFileAssetModel>>> list();
  Future<Either<Failure, DesignFileAssetModel>> uploadOne({
    required Uint8List bytes,
    required String filename,
    required int timestamp,
    String? format,
    int seed,
    void Function(double progress)? onProgress,
  });
  Future<Either<Failure, void>> delete(DesignFileAssetModel asset);
}
