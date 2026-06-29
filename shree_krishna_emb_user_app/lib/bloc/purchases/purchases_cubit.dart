import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shree_krishna_core/shree_krishna_core.dart';
import 'package:shree_krishna_emb/domain/repositories/purchases_repository.dart';

enum PurchasesStatus { initial, loading, loaded, error }

class PurchasesState extends Equatable {
  final PurchasesStatus status;
  final List<PurchaseModel> purchases;
  final String? error;

  const PurchasesState({
    this.status = PurchasesStatus.initial,
    this.purchases = const [],
    this.error,
  });

  bool isOwned(String designId) => purchases.any((p) => p.designId == designId);

  PurchasesState copyWith({
    PurchasesStatus? status,
    List<PurchaseModel>? purchases,
    String? error,
  }) => PurchasesState(
    status: status ?? this.status,
    purchases: purchases ?? this.purchases,
    error: error,
  );

  @override
  List<Object?> get props => [status, purchases, error];
}

/// App-wide ownership state. Singleton so the design detail screen and the My
/// Purchases screen agree on what the user owns from one read.
class PurchasesCubit extends Cubit<PurchasesState> {
  final PurchasesRepository repository;

  PurchasesCubit({required this.repository}) : super(const PurchasesState());

  Future<void> load() async {
    emit(state.copyWith(status: PurchasesStatus.loading));
    final result = await repository.load();
    if (isClosed) return;
    result.fold(
      (failure) => emit(
        state.copyWith(status: PurchasesStatus.error, error: failure.message),
      ),
      (purchases) => emit(
        state.copyWith(status: PurchasesStatus.loaded, purchases: purchases),
      ),
    );
  }

  /// Reloads ownership without flashing the loading state (e.g. after a
  /// successful checkout).
  Future<void> refresh() async {
    final result = await repository.load();
    if (isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(error: failure.message)),
      (purchases) => emit(
        state.copyWith(status: PurchasesStatus.loaded, purchases: purchases),
      ),
    );
  }

  bool isOwned(String designId) => state.isOwned(designId);
}
