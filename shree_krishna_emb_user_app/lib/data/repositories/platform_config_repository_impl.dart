import 'package:shree_krishna_core/shree_krishna_core.dart';
import 'package:shree_krishna_emb/data/datasources/firebase_platform_config_datasource.dart';
import 'package:shree_krishna_emb/domain/repositories/platform_config_repository.dart';

class PlatformConfigRepositoryImpl implements PlatformConfigRepository {
  final PlatformConfigDataSource _dataSource;

  PlatformConfigRepositoryImpl({required PlatformConfigDataSource dataSource})
    : _dataSource = dataSource;

  @override
  Future<Either<Failure, PlatformConfig>> load() async {
    try {
      return Right(await _dataSource.getPlatformConfig());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
