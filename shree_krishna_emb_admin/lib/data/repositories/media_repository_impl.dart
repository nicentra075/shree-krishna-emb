import 'dart:typed_data';

import 'package:shree_krishna_core/shree_krishna_core.dart';
import 'package:shree_krishna_emb_admin/data/datasources/firebase_media_datasource.dart';
import 'package:shree_krishna_emb_admin/data/models/media_asset_model.dart';
import 'package:shree_krishna_emb_admin/domain/repositories/media_repository.dart';

class MediaRepositoryImpl implements MediaRepository {
  final FirebaseMediaDataSource _dataSource;

  MediaRepositoryImpl({required FirebaseMediaDataSource dataSource})
    : _dataSource = dataSource;

  @override
  Future<Either<Failure, List<MediaAssetModel>>> list() async {
    try {
      return Right(await _dataSource.list());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, MediaAssetModel>> uploadOne({
    required Uint8List bytes,
    required String filename,
    required int timestamp,
    int seed = 0,
    void Function(double progress)? onProgress,
  }) async {
    try {
      return Right(
        await _dataSource.uploadOne(
          bytes: bytes,
          filename: filename,
          timestamp: timestamp,
          seed: seed,
          onProgress: onProgress,
        ),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> delete(MediaAssetModel asset) async {
    try {
      await _dataSource.delete(asset);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
