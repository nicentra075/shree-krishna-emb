import 'package:shree_krishna_core/shree_krishna_core.dart' show OrderModel;
import 'package:shree_krishna_core/utils/either.dart';
import 'package:shree_krishna_emb_admin/core/errors/failures.dart';

/// A page of orders plus the total count of orders matching the active filters
/// (used to compute the number of pages).
class OrdersPage {
  final List<OrderModel> orders;
  final int totalCount;

  const OrdersPage({required this.orders, required this.totalCount});
}

/// Backend-agnostic contract for reading orders and initiating refunds.
abstract class OrdersRepository {
  /// Returns a filtered, paginated page of orders. [statusFilter] is the
  /// `OrderStatus.value` string (null = all). [start]/[end] bound `createdAt`.
  /// [search] matches buyer name/email or order id (case-insensitive).
  Future<Either<Failure, OrdersPage>> getOrders({
    required int page,
    required int pageSize,
    String? statusFilter,
    DateTime? start,
    DateTime? end,
    String? search,
    bool forceRefresh,
  });

  /// The full filtered (unpaginated) set — used for exports/aggregation.
  Future<Either<Failure, List<OrderModel>>> getAllOrders({bool forceRefresh});

  /// Calls the `initiateRefund` Cloud Function for a paid order.
  /// Returns true when `{success: true}` comes back.
  Future<Either<Failure, bool>> initiateRefund({
    required String orderId,
    required String reason,
  });
}
