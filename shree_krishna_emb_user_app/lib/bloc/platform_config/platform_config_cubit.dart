import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shree_krishna_emb/data/datasources/firebase_platform_config_datasource.dart';
import 'package:shree_krishna_emb/domain/repositories/platform_config_repository.dart';

enum PlatformConfigStatus { initial, loading, loaded, error }

class PlatformConfigState extends Equatable {
  final PlatformConfigStatus status;
  final PlatformConfig? config;
  final String? error;

  const PlatformConfigState({
    this.status = PlatformConfigStatus.initial,
    this.config,
    this.error,
  });

  /// True when the platform fee should be charged + shown: the admin has it
  /// enabled AND the percent is greater than 0. A 0% or disabled fee is omitted
  /// from totals and hidden in the UI.
  bool get platformFeeActive =>
      (config?.settings.platformFeeEnabled ?? false) &&
      (config?.platformFeePercent ?? 0) > 0;

  /// True when GST should be charged + shown (enabled AND percent > 0).
  bool get gstActive =>
      (config?.settings.gstEnabled ?? false) && (config?.gstPercent ?? 0) > 0;

  /// Effective fee percent used in totals — the admin-configured value when
  /// active, otherwise 0. No phantom default; whatever the admin sets is honored.
  double get feePercent => platformFeeActive ? config!.platformFeePercent : 0;

  /// Effective GST percent used in totals — configured value when active, else 0.
  double get gstPercent => gstActive ? config!.gstPercent : 0;

  /// True when the demo/test checkout path should be used. Defaults to true
  /// until config has loaded.
  bool get paymentTestMode => config?.paymentTestMode ?? true;

  String get razorpayKeyId => config?.activeRazorpayKeyId ?? '';

  String get buyerSupportEmail => config?.settings.supportEmail ?? '';

  PlatformConfigState copyWith({
    PlatformConfigStatus? status,
    PlatformConfig? config,
    String? error,
  }) => PlatformConfigState(
    status: status ?? this.status,
    config: config ?? this.config,
    error: error,
  );

  @override
  List<Object?> get props => [status, config, error];
}

/// App-wide platform settings (fee%, gst%, payment mode, razorpay key).
/// Loaded once after login; held as a singleton so checkout can read it.
class PlatformConfigCubit extends Cubit<PlatformConfigState> {
  final PlatformConfigRepository repository;

  PlatformConfigCubit({required this.repository})
    : super(const PlatformConfigState());

  Future<void> load() async {
    emit(state.copyWith(status: PlatformConfigStatus.loading));
    final result = await repository.load();
    if (isClosed) return;
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: PlatformConfigStatus.error,
          error: failure.message,
        ),
      ),
      (config) => emit(
        state.copyWith(status: PlatformConfigStatus.loaded, config: config),
      ),
    );
  }
}
