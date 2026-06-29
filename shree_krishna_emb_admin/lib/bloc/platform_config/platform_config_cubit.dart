import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shree_krishna_core/shree_krishna_core.dart'
    show PlatformSettingsModel;
import 'package:shree_krishna_emb_admin/data/datasources/firebase_platform_config_datasource.dart';
import 'package:shree_krishna_emb_admin/domain/repositories/platform_config_repository.dart';

enum PlatformConfigStatus { initial, loading, loaded, saving, error }

class PlatformConfigState extends Equatable {
  final PlatformConfigStatus status;
  final PlatformConfig? config;
  final String? error;

  const PlatformConfigState({
    this.status = PlatformConfigStatus.initial,
    this.config,
    this.error,
  });

  PlatformConfigState copyWith({
    PlatformConfigStatus? status,
    PlatformConfig? config,
    String? error,
  }) {
    return PlatformConfigState(
      status: status ?? this.status,
      config: config ?? this.config,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, config, error];
}

/// Loads + saves the `config/platform` document (fee/gst, payment mode,
/// Razorpay publishable keys, seller info).
class PlatformConfigCubit extends Cubit<PlatformConfigState> {
  final PlatformConfigRepository repository;

  PlatformConfigCubit({required this.repository})
    : super(const PlatformConfigState());

  Future<void> load() async {
    emit(state.copyWith(status: PlatformConfigStatus.loading));
    final result = await repository.getConfig();
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

  /// Saves the editable config. Returns true on success so the caller can show
  /// a snackbar with the screen's context.
  Future<bool> save({
    required double platformFeePercent,
    required double gstPercent,
    required bool paymentTestMode,
    required bool platformFeeEnabled,
    required bool gstEnabled,
    required String razorpayKeyIdTest,
    required String razorpayKeyIdLive,
    String? supportEmail,
    String? invoicePrefix,
    String? sellerName,
    String? sellerAddress,
    String? sellerGstin,
    required String updatedBy,
  }) async {
    emit(state.copyWith(status: PlatformConfigStatus.saving));
    final result = await repository.saveConfig(
      platformFeePercent: platformFeePercent,
      gstPercent: gstPercent,
      paymentTestMode: paymentTestMode,
      platformFeeEnabled: platformFeeEnabled,
      gstEnabled: gstEnabled,
      razorpayKeyIdTest: razorpayKeyIdTest,
      razorpayKeyIdLive: razorpayKeyIdLive,
      supportEmail: supportEmail,
      invoicePrefix: invoicePrefix,
      sellerName: sellerName,
      sellerAddress: sellerAddress,
      sellerGstin: sellerGstin,
      updatedBy: updatedBy,
    );
    if (isClosed) return false;
    return result.fold(
      (failure) {
        emit(
          state.copyWith(
            status: PlatformConfigStatus.error,
            error: failure.message,
          ),
        );
        return false;
      },
      (_) {
        // Optimistically reflect the saved values locally.
        final current = state.config;
        if (current != null) {
          final updatedSettings = PlatformSettingsModel.fromEntity(
            current.settings.copyWith(
              platformFeePercent: platformFeePercent,
              gstPercent: gstPercent,
              platformFeeEnabled: platformFeeEnabled,
              gstEnabled: gstEnabled,
            ),
          );
          emit(
            state.copyWith(
              status: PlatformConfigStatus.loaded,
              config: current.copyWith(
                settings: updatedSettings,
                paymentTestMode: paymentTestMode,
                razorpayKeyIdTest: razorpayKeyIdTest,
                razorpayKeyIdLive: razorpayKeyIdLive,
              ),
            ),
          );
        } else {
          emit(state.copyWith(status: PlatformConfigStatus.loaded));
        }
        return true;
      },
    );
  }

  /// Stores a Razorpay key secret for [mode] ('test' | 'live') securely. The
  /// plaintext is sent to the `setRazorpaySecret` Cloud Function, encrypted
  /// server-side, and never persisted anywhere the client can read. Returns
  /// true on success; the matching "secret set" flag is then flipped locally
  /// so the UI shows a saved state.
  Future<bool> setRazorpaySecret({
    required String mode,
    required String secret,
  }) async {
    final result = await repository.setRazorpaySecret(
      mode: mode,
      secret: secret,
    );
    if (isClosed) return false;
    return result.fold(
      (failure) {
        emit(
          state.copyWith(
            status: PlatformConfigStatus.error,
            error: failure.message,
          ),
        );
        return false;
      },
      (_) {
        final current = state.config;
        if (current != null) {
          emit(
            state.copyWith(
              status: PlatformConfigStatus.loaded,
              config: current.copyWith(
                razorpayKeySecretTestSet: mode == 'test'
                    ? true
                    : current.razorpayKeySecretTestSet,
                razorpayKeySecretLiveSet: mode == 'live'
                    ? true
                    : current.razorpayKeySecretLiveSet,
              ),
            ),
          );
        }
        return true;
      },
    );
  }
}
