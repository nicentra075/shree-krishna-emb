import 'package:shree_krishna_core/utils/either.dart';
import 'package:shree_krishna_emb_admin/core/errors/failures.dart';
import 'package:shree_krishna_emb_admin/data/datasources/firebase_payouts_datasource.dart';

/// Backend-agnostic contract for the interim read-only Payouts/earnings view.
abstract class PayoutsRepository {
  Future<Either<Failure, List<DesignerEarnings>>> getEarnings({
    bool forceRefresh,
    String? ownerUid,
  });
}
