import 'dart:typed_data';

import 'package:shree_krishna_core/shree_krishna_core.dart';
import 'package:shree_krishna_emb_admin/data/datasources/firebase_design_file_datasource.dart';
import 'package:shree_krishna_emb_admin/data/models/design_file_asset_model.dart';
import 'package:shree_krishna_emb_admin/domain/repositories/design_file_repository.dart';

class DesignFileRepositoryImpl implements DesignFileRepository {
  final FirebaseDesignFileDataSource _dataSource;

  DesignFileRepositoryImpl({required FirebaseDesignFileDataSource dataSource})
    : _dataSource = dataSource;

  @override
  Future<Either<Failure, List<DesignFileAssetModel>>> list() async {
    try {
      return Right(await _dataSource.list());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, DesignFileAssetModel>> uploadOne({
    required Uint8List bytes,
    required String filename,
    required int timestamp,
    String? format,
    int seed = 0,
    void Function(double progress)? onProgress,
  }) async {
    try {
      return Right(
        await _dataSource.uploadOne(
          bytes: bytes,
          filename: filename,
          timestamp: timestamp,
          format: format,
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
  Future<Either<Failure, void>> delete(DesignFileAssetModel asset) async {
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
