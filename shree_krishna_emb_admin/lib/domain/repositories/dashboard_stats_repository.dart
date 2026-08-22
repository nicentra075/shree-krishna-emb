import 'package:shree_krishna_core/utils/either.dart';
import 'package:shree_krishna_emb_admin/core/errors/failures.dart';
import 'package:shree_krishna_emb_admin/data/datasources/firebase_dashboard_stats_datasource.dart';

/// Backend-agnostic contract for the live admin dashboard counters + revenue.
abstract class DashboardStatsRepository {
  Future<Either<Failure, DashboardStats>> getStats({
    int chartDays,
    String? authorUid,
  });
}
