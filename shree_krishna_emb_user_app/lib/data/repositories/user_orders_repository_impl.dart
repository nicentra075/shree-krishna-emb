import 'package:shree_krishna_core/shree_krishna_core.dart';
import 'package:shree_krishna_emb/data/datasources/firebase_user_orders_datasource.dart';
import 'package:shree_krishna_emb/domain/repositories/user_orders_repository.dart';

class UserOrdersRepositoryImpl implements UserOrdersRepository {
  final UserOrdersDataSource _dataSource;

  UserOrdersRepositoryImpl({required UserOrdersDataSource dataSource})
    : _dataSource = dataSource;

  @override
  Future<Either<Failure, List<OrderModel>>> getMyOrders({
    int limit = 100,
  }) async {
    try {
      final orders = await _dataSource.getMyOrders(limit: limit);
      return Right(orders);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
