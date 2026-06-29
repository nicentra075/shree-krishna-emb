import 'package:cloud_functions/cloud_functions.dart';
import 'package:shree_krishna_core/shree_krishna_core.dart'
    show OrderModel, CloudFunctionNames;
import 'package:shree_krishna_core/utils/either.dart';
import 'package:shree_krishna_emb_admin/core/errors/exceptions.dart';
import 'package:shree_krishna_emb_admin/core/errors/failures.dart';
import 'package:shree_krishna_emb_admin/core/utils/app_logger.dart';
import 'package:shree_krishna_emb_admin/data/datasources/firebase_orders_datasource.dart';
import 'package:shree_krishna_emb_admin/domain/repositories/orders_repository.dart';

class OrdersRepositoryImpl implements OrdersRepository {
  final OrdersDataSource _dataSource;
  final FirebaseFunctions _functions;

  OrdersRepositoryImpl({
    required OrdersDataSource dataSource,
    required FirebaseFunctions functions,
  }) : _dataSource = dataSource,
       _functions = functions;

  /// Apply status + date-range + search filters client-side.
  List<OrderModel> _applyFilters(
    List<OrderModel> orders, {
    String? statusFilter,
    DateTime? start,
    DateTime? end,
    String? search,
  }) {
    var result = orders;
    if (statusFilter != null && statusFilter.isNotEmpty) {
      result = result.where((o) => o.status.value == statusFilter).toList();
    }
    if (start != null) {
      result = result.where((o) => !o.createdAt.isBefore(start)).toList();
    }
    if (end != null) {
      // [end] is inclusive of the whole day — caller passes the day's end.
      result = result.where((o) => !o.createdAt.isAfter(end)).toList();
    }
    if (search != null && search.trim().isNotEmpty) {
      final q = search.trim().toLowerCase();
      result = result.where((o) {
        return o.id.toLowerCase().contains(q) ||
            o.buyerName.toLowerCase().contains(q) ||
            o.buyerEmail.toLowerCase().contains(q) ||
            (o.invoiceNumber?.toLowerCase().contains(q) ?? false);
      }).toList();
    }
    return result;
  }

  @override
  Future<Either<Failure, OrdersPage>> getOrders({
    required int page,
    required int pageSize,
    String? statusFilter,
    DateTime? start,
    DateTime? end,
    String? search,
    bool forceRefresh = false,
  }) async {
    try {
      final all = await _dataSource.getAllOrders(forceRefresh: forceRefresh);
      final filtered = _applyFilters(
        all,
        statusFilter: statusFilter,
        start: start,
        end: end,
        search: search,
      );
      final startIndex = (page - 1) * pageSize;
      if (startIndex >= filtered.length) {
        return Right(OrdersPage(orders: const [], totalCount: filtered.length));
      }
      final endIndex = (startIndex + pageSize).clamp(0, filtered.length);
      return Right(
        OrdersPage(
          orders: filtered.sublist(startIndex, endIndex),
          totalCount: filtered.length,
        ),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<OrderModel>>> getAllOrders({
    bool forceRefresh = false,
  }) async {
    try {
      return Right(await _dataSource.getAllOrders(forceRefresh: forceRefresh));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> initiateRefund({
    required String orderId,
    required String reason,
  }) async {
    try {
      final callable = _functions.httpsCallable(
        CloudFunctionNames.initiateRefund,
      );
      final response = await callable.call<Map<String, dynamic>>({
        'orderId': orderId,
        'reason': reason,
      });
      final success = response.data['success'] == true;
      if (success) {
        // Force a refresh on the next list read so the refunded status shows.
        _dataSource.invalidate();
      }
      return Right(success);
    } on FirebaseFunctionsException catch (e, s) {
      AppLogger.logError('initiateRefund (${e.code})', error: e, stackTrace: s);
      return Left(ServerFailure(e.message ?? 'Refund failed'));
    } catch (e, s) {
      AppLogger.logError('initiateRefund', error: e, stackTrace: s);
      return Left(UnknownFailure(e.toString()));
    }
  }
}
