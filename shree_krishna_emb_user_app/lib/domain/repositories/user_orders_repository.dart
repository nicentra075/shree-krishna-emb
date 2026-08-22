import 'package:shree_krishna_core/errors/failures.dart';
import 'package:shree_krishna_core/models/order_model.dart';
import 'package:shree_krishna_core/utils/either.dart';

/// Backend-agnostic contract for the user's own order history.
abstract class UserOrdersRepository {
  Future<Either<Failure, List<OrderModel>>> getMyOrders({int limit});
}
