import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shree_krishna_emb_admin/data/datasources/firebase_dashboard_stats_datasource.dart';
import 'package:shree_krishna_emb_admin/domain/repositories/dashboard_stats_repository.dart';

enum DashboardStatsStatus { initial, loading, loaded, error }

class DashboardStatsState extends Equatable {
  final DashboardStatsStatus status;
  final DashboardStats? stats;
  final String? error;

  const DashboardStatsState({
    this.status = DashboardStatsStatus.initial,
    this.stats,
    this.error,
  });

  DashboardStatsState copyWith({
    DashboardStatsStatus? status,
    DashboardStats? stats,
    String? error,
  }) {
    return DashboardStatsState(
      status: status ?? this.status,
      stats: stats ?? this.stats,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, stats, error];
}

/// Loads live dashboard KPIs + the revenue chart series.
class DashboardStatsCubit extends Cubit<DashboardStatsState> {
  final DashboardStatsRepository repository;
  final int chartDays;

  DashboardStatsCubit({required this.repository, this.chartDays = 7})
    : super(const DashboardStatsState());

  /// [authorUid] scopes the stats to one designer's data (D2).
  Future<void> load({String? authorUid}) async {
    emit(state.copyWith(status: DashboardStatsStatus.loading));
    final result = await repository.getStats(
      chartDays: chartDays,
      authorUid: authorUid,
    );
    if (isClosed) return;
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: DashboardStatsStatus.error,
          error: failure.message,
        ),
      ),
      (stats) => emit(
        state.copyWith(status: DashboardStatsStatus.loaded, stats: stats),
      ),
    );
  }
}
