import 'package:shree_krishna_core/utils/either.dart';
import 'package:shree_krishna_emb_admin/core/errors/exceptions.dart';
import 'package:shree_krishna_emb_admin/core/errors/failures.dart';
import 'package:shree_krishna_emb_admin/data/datasources/firebase_reports_datasource.dart';
import 'package:shree_krishna_emb_admin/domain/repositories/reports_repository.dart';

class ReportsRepositoryImpl implements ReportsRepository {
  final ReportsDataSource _dataSource;

  ReportsRepositoryImpl({required ReportsDataSource dataSource})
    : _dataSource = dataSource;

  @override
  Future<Either<Failure, ReportSummary>> getReport({
    required DateTime start,
    required DateTime end,
    bool forceRefresh = false,
  }) async {
    try {
      return Right(
        await _dataSource.getReport(
          start: start,
          end: end,
          forceRefresh: forceRefresh,
        ),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
