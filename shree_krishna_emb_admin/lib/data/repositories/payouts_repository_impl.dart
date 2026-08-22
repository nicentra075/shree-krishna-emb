import 'package:shree_krishna_core/utils/either.dart';
import 'package:shree_krishna_emb_admin/core/errors/exceptions.dart';
import 'package:shree_krishna_emb_admin/core/errors/failures.dart';
import 'package:shree_krishna_emb_admin/data/datasources/firebase_payouts_datasource.dart';
import 'package:shree_krishna_emb_admin/domain/repositories/payouts_repository.dart';

class PayoutsRepositoryImpl implements PayoutsRepository {
  final PayoutsDataSource _dataSource;

  PayoutsRepositoryImpl({required PayoutsDataSource dataSource})
    : _dataSource = dataSource;

  @override
  Future<Either<Failure, List<DesignerEarnings>>> getEarnings({
    bool forceRefresh = false,
    String? ownerUid,
  }) async {
    try {
      return Right(
        await _dataSource.getEarnings(
          forceRefresh: forceRefresh,
          ownerUid: ownerUid,
        ),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
