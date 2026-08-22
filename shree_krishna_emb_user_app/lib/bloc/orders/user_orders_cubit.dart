import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shree_krishna_core/models/order_model.dart';
import 'package:shree_krishna_emb/domain/repositories/user_orders_repository.dart';

enum UserOrdersStatus { initial, loading, loaded, error }

class UserOrdersState extends Equatable {
  final UserOrdersStatus status;
  final List<OrderModel> orders;
  final String? error;

  const UserOrdersState({
    this.status = UserOrdersStatus.initial,
    this.orders = const [],
    this.error,
  });

  UserOrdersState copyWith({
    UserOrdersStatus? status,
    List<OrderModel>? orders,
    String? error,
  }) {
    return UserOrdersState(
      status: status ?? this.status,
      orders: orders ?? this.orders,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, orders, error];
}

/// The signed-in user's order history (WS-B3).
class UserOrdersCubit extends Cubit<UserOrdersState> {
  final UserOrdersRepository _repository;

  UserOrdersCubit({required UserOrdersRepository repository})
    : _repository = repository,
      super(const UserOrdersState());

  Future<void> load() async {
    emit(state.copyWith(status: UserOrdersStatus.loading));
    await _fetch();
  }

  /// Reload without the loading flash (pull-to-refresh / tab revisit).
  Future<void> refresh() => _fetch();

  Future<void> _fetch() async {
    final result = await _repository.getMyOrders();
    result.fold(
      (failure) => emit(
        state.copyWith(status: UserOrdersStatus.error, error: failure.message),
      ),
      (orders) =>
          emit(state.copyWith(status: UserOrdersStatus.loaded, orders: orders)),
    );
  }
}
