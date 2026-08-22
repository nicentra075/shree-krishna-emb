import 'package:shree_krishna_core/utils/either.dart';
import 'package:shree_krishna_emb_admin/core/errors/failures.dart';
import 'package:shree_krishna_emb_admin/data/datasources/firebase_reports_datasource.dart';

/// Backend-agnostic contract for the admin Reports module.
abstract class ReportsRepository {
  Future<Either<Failure, ReportSummary>> getReport({
    required DateTime start,
    required DateTime end,
    bool forceRefresh,
    String? ownerUid,
  });
}
