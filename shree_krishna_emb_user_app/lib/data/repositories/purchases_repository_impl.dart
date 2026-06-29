import 'package:shree_krishna_core/shree_krishna_core.dart';
import 'package:shree_krishna_emb/data/datasources/firebase_purchases_datasource.dart';
import 'package:shree_krishna_emb/domain/repositories/purchases_repository.dart';

class PurchasesRepositoryImpl implements PurchasesRepository {
  final PurchasesDataSource _dataSource;

  PurchasesRepositoryImpl({required PurchasesDataSource dataSource})
    : _dataSource = dataSource;

  @override
  Future<Either<Failure, List<PurchaseModel>>> load() async {
    try {
      return Right(await _dataSource.getPurchases());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
