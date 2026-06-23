import 'package:shree_krishna_core/shree_krishna_core.dart';
import 'package:shree_krishna_emb/data/datasources/firebase_seller_datasource.dart';
import 'package:shree_krishna_emb/domain/entities/seller.dart';
import 'package:shree_krishna_emb/domain/repositories/seller_repository.dart';

class SellerRepositoryImpl implements SellerRepository {
  final SellerDataSource _dataSource;

  SellerRepositoryImpl({required SellerDataSource dataSource})
      : _dataSource = dataSource;

  @override
  Future<Either<Failure, List<SellerEntity>>> getAuthorisedSellers({
    int limit = 20,
  }) async {
    try {
      final sellers = await _dataSource.getAuthorisedSellers(limit: limit);
      return Right(sellers);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
