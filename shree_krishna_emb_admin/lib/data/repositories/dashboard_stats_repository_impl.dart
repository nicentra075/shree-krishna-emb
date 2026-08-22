import 'package:shree_krishna_core/utils/either.dart';
import 'package:shree_krishna_emb_admin/core/errors/exceptions.dart';
import 'package:shree_krishna_emb_admin/core/errors/failures.dart';
import 'package:shree_krishna_emb_admin/data/datasources/firebase_dashboard_stats_datasource.dart';
import 'package:shree_krishna_emb_admin/domain/repositories/dashboard_stats_repository.dart';

class DashboardStatsRepositoryImpl implements DashboardStatsRepository {
  final DashboardStatsDataSource _dataSource;

  DashboardStatsRepositoryImpl({required DashboardStatsDataSource dataSource})
    : _dataSource = dataSource;

  @override
  Future<Either<Failure, DashboardStats>> getStats({
    int chartDays = 7,
    String? authorUid,
  }) async {
    try {
      return Right(
        await _dataSource.getStats(chartDays: chartDays, authorUid: authorUid),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
