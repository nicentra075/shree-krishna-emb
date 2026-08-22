import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shree_krishna_core/shree_krishna_core.dart' show OrderModel;
import 'package:shree_krishna_emb_admin/bloc/design_store/collections_cubit.dart'
    show CatalogStatus, kDefaultCatalogPageSize;
import 'package:shree_krishna_emb_admin/domain/repositories/orders_repository.dart';

class OrdersState extends Equatable {
  final CatalogStatus status;
  final List<OrderModel> orders;
  final int totalCount;
  final int page;
  final int pageSize;
  final String? statusFilter;
  final DateTime? start;
  final DateTime? end;
  final String? search;

  /// True while a refund callable is in flight (disables the refund button).
  final bool refunding;
  final String? error;

  const OrdersState({
    this.status = CatalogStatus.initial,
    this.orders = const [],
    this.totalCount = 0,
    this.page = 1,
    this.pageSize = kDefaultCatalogPageSize,
    this.statusFilter,
    this.start,
    this.end,
    this.search,
    this.refunding = false,
    this.error,
  });

  int get totalPages =>
      totalCount == 0 ? 1 : ((totalCount + pageSize - 1) ~/ pageSize);

  OrdersState copyWith({
    CatalogStatus? status,
    List<OrderModel>? orders,
    int? totalCount,
    int? page,
    int? pageSize,
    String? statusFilter,
    bool clearStatusFilter = false,
    DateTime? start,
    DateTime? end,
    bool clearDateRange = false,
    String? search,
    bool? refunding,
    String? error,
  }) {
    return OrdersState(
      status: status ?? this.status,
      orders: orders ?? this.orders,
      totalCount: totalCount ?? this.totalCount,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      statusFilter: clearStatusFilter
          ? null
          : (statusFilter ?? this.statusFilter),
      start: clearDateRange ? null : (start ?? this.start),
      end: clearDateRange ? null : (end ?? this.end),
      search: search ?? this.search,
      refunding: refunding ?? this.refunding,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
    status,
    orders,
    totalCount,
    page,
    pageSize,
    statusFilter,
    start,
    end,
    search,
    refunding,
    error,
  ];
}

/// Drives the admin Transactions list: status filter, date range, search,
/// pagination, and the refund action (calls `initiateRefund`).
class OrdersCubit extends Cubit<OrdersState> {
  final OrdersRepository repository;

  /// When set (designer sessions — D2), every load is restricted to orders
  /// containing this author's designs. Injected by the service locator.
  final String? scopedOwnerUid;

  OrdersCubit({required this.repository, this.scopedOwnerUid})
    : super(const OrdersState());

  Future<void> load({bool forceRefresh = false}) async {
    emit(state.copyWith(status: CatalogStatus.loading));
    final result = await repository.getOrders(
      page: state.page,
      pageSize: state.pageSize,
      statusFilter: state.statusFilter,
      start: state.start,
      end: state.end,
      search: state.search,
      forceRefresh: forceRefresh,
      ownerUid: scopedOwnerUid,
    );
    if (isClosed) return;
    result.fold(
      (failure) => emit(
        state.copyWith(status: CatalogStatus.error, error: failure.message),
      ),
      (pageData) => emit(
        state.copyWith(
          status: CatalogStatus.loaded,
          orders: pageData.orders,
          totalCount: pageData.totalCount,
        ),
      ),
    );
  }

  void setPage(int page) {
    emit(state.copyWith(page: page));
    load();
  }

  void setPageSize(int size) {
    emit(state.copyWith(pageSize: size, page: 1));
    load();
  }

  void setStatusFilter(String? statusValue) {
    if (statusValue == null) {
      emit(state.copyWith(clearStatusFilter: true, page: 1));
    } else {
      emit(state.copyWith(statusFilter: statusValue, page: 1));
    }
    load();
  }

  void setDateRange(DateTime? start, DateTime? end) {
    if (start == null && end == null) {
      emit(state.copyWith(clearDateRange: true, page: 1));
    } else {
      emit(state.copyWith(start: start, end: end, page: 1));
    }
    load();
  }

  void setSearch(String query) {
    emit(state.copyWith(search: query, page: 1));
    load();
  }

  /// Calls the refund callable. Returns true on success; the caller shows the
  /// snackbar (needs screen context) and the list is refreshed here.
  Future<bool> refundOrder({
    required String orderId,
    required String reason,
  }) async {
    emit(state.copyWith(refunding: true));
    final result = await repository.initiateRefund(
      orderId: orderId,
      reason: reason,
    );
    if (isClosed) return false;
    final success = result.fold(
      (failure) {
        emit(state.copyWith(refunding: false, error: failure.message));
        return false;
      },
      (ok) {
        emit(state.copyWith(refunding: false));
        return ok;
      },
    );
    if (success) {
      await load(forceRefresh: true);
    }
    return success;
  }
}
