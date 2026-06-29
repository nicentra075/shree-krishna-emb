import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shree_krishna_emb_admin/data/datasources/firebase_reports_datasource.dart';
import 'package:shree_krishna_emb_admin/domain/repositories/reports_repository.dart';

enum ReportsStatus { initial, loading, loaded, error }

class ReportsState extends Equatable {
  final ReportsStatus status;
  final ReportSummary? report;
  final DateTime start;
  final DateTime end;
  final String? error;

  const ReportsState({
    this.status = ReportsStatus.initial,
    this.report,
    required this.start,
    required this.end,
    this.error,
  });

  ReportsState copyWith({
    ReportsStatus? status,
    ReportSummary? report,
    DateTime? start,
    DateTime? end,
    String? error,
  }) {
    return ReportsState(
      status: status ?? this.status,
      report: report ?? this.report,
      start: start ?? this.start,
      end: end ?? this.end,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, report, start, end, error];
}

/// Drives the Reports module: a date range + computed summary.
class ReportsCubit extends Cubit<ReportsState> {
  final ReportsRepository repository;

  ReportsCubit({required this.repository})
    : super(ReportsState(start: _defaultStart(), end: _defaultEnd()));

  static DateTime _defaultStart() {
    final now = DateTime.now();
    // Last 30 days by default.
    final start = now.subtract(const Duration(days: 29));
    return DateTime(start.year, start.month, start.day);
  }

  static DateTime _defaultEnd() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, 23, 59, 59);
  }

  Future<void> load({bool forceRefresh = false}) async {
    emit(state.copyWith(status: ReportsStatus.loading));
    final result = await repository.getReport(
      start: state.start,
      end: state.end,
      forceRefresh: forceRefresh,
    );
    if (isClosed) return;
    result.fold(
      (failure) => emit(
        state.copyWith(status: ReportsStatus.error, error: failure.message),
      ),
      (report) =>
          emit(state.copyWith(status: ReportsStatus.loaded, report: report)),
    );
  }

  void setDateRange(DateTime start, DateTime end) {
    // Normalise: start at midnight, end at end-of-day so the range is inclusive.
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day, 23, 59, 59);
    emit(state.copyWith(start: s, end: e));
    load();
  }
}
