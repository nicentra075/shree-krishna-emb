import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shree_krishna_emb/data/services/checkout_service_factory.dart';
import 'package:shree_krishna_emb/domain/entities/order_draft.dart';
import 'package:shree_krishna_emb/domain/services/checkout_service.dart';

enum CheckoutStatus { idle, processing, success, cancelled, error }

class CheckoutState extends Equatable {
  final CheckoutStatus status;
  final String? orderId;
  final String? error;

  const CheckoutState({
    this.status = CheckoutStatus.idle,
    this.orderId,
    this.error,
  });

  bool get isProcessing => status == CheckoutStatus.processing;

  CheckoutState copyWith({
    CheckoutStatus? status,
    String? orderId,
    String? error,
  }) => CheckoutState(
    status: status ?? this.status,
    orderId: orderId,
    error: error,
  );

  @override
  List<Object?> get props => [status, orderId, error];
}

/// Drives a single checkout attempt. Created per checkout screen (factory),
/// builds the correct [CheckoutService] from the resolved payment mode + key.
class CheckoutCubit extends Cubit<CheckoutState> {
  final CheckoutServiceFactory factory;

  CheckoutService? _service;

  CheckoutCubit({required this.factory}) : super(const CheckoutState());

  Future<void> pay({
    required OrderDraft draft,
    required bool paymentTestMode,
    required String razorpayKeyId,
    required String businessName,
  }) async {
    if (state.isProcessing) return;
    emit(state.copyWith(status: CheckoutStatus.processing, error: null));

    _service?.dispose();
    final service = factory.create(
      paymentTestMode: paymentTestMode,
      razorpayKeyId: razorpayKeyId,
      businessName: businessName,
    );
    _service = service;

    final CheckoutResult result;
    try {
      result = await service.pay(draft);
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(status: CheckoutStatus.error, error: e.toString()));
      return;
    }

    if (isClosed) return;
    if (result.success) {
      emit(
        state.copyWith(status: CheckoutStatus.success, orderId: result.orderId),
      );
    } else if (result.cancelled) {
      emit(state.copyWith(status: CheckoutStatus.cancelled));
    } else {
      emit(state.copyWith(status: CheckoutStatus.error, error: result.error));
    }
  }

  /// Resets back to idle so the screen can re-enable the Pay button after a
  /// cancellation or error.
  void reset() {
    if (isClosed) return;
    emit(const CheckoutState());
  }

  @override
  Future<void> close() {
    _service?.dispose();
    return super.close();
  }
}
