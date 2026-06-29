import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shree_krishna_emb_admin/data/datasources/firebase_payouts_datasource.dart';
import 'package:shree_krishna_emb_admin/domain/repositories/payouts_repository.dart';

enum PayoutsStatus { initial, loading, loaded, error }

class PayoutsState extends Equatable {
  final PayoutsStatus status;
  final List<DesignerEarnings> earnings;
  final String? error;

  const PayoutsState({
    this.status = PayoutsStatus.initial,
    this.earnings = const [],
    this.error,
  });

  /// Total integer rupees owed across all designers.
  int get totalOwed => earnings.fold(0, (sum, e) => sum + e.amountOwed);

  PayoutsState copyWith({
    PayoutsStatus? status,
    List<DesignerEarnings>? earnings,
    String? error,
  }) {
    return PayoutsState(
      status: status ?? this.status,
      earnings: earnings ?? this.earnings,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, earnings, error];
}

/// Loads the interim read-only designer earnings list.
class PayoutsCubit extends Cubit<PayoutsState> {
  final PayoutsRepository repository;

  PayoutsCubit({required this.repository}) : super(const PayoutsState());

  Future<void> load({bool forceRefresh = false}) async {
    emit(state.copyWith(status: PayoutsStatus.loading));
    final result = await repository.getEarnings(forceRefresh: forceRefresh);
    if (isClosed) return;
    result.fold(
      (failure) => emit(
        state.copyWith(status: PayoutsStatus.error, error: failure.message),
      ),
      (earnings) => emit(
        state.copyWith(status: PayoutsStatus.loaded, earnings: earnings),
      ),
    );
  }
}
