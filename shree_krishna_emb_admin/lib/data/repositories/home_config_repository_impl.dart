import 'package:shree_krishna_core/utils/either.dart';
import 'package:shree_krishna_emb_admin/core/errors/exceptions.dart';
import 'package:shree_krishna_emb_admin/core/errors/failures.dart';
import 'package:shree_krishna_emb_admin/data/datasources/firebase_home_config_datasource.dart';
import 'package:shree_krishna_emb_admin/data/models/home_feed_config_model.dart';
import 'package:shree_krishna_emb_admin/domain/repositories/home_config_repository.dart';

class HomeConfigRepositoryImpl implements HomeConfigRepository {
  final HomeConfigDataSource _dataSource;

  HomeConfigRepositoryImpl({required HomeConfigDataSource dataSource})
    : _dataSource = dataSource;

  @override
  Future<Either<Failure, HomeFeedConfig>> read() async {
    try {
      return Right(await _dataSource.read());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> save(HomeFeedConfig config) async {
    try {
      await _dataSource.save(config);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
