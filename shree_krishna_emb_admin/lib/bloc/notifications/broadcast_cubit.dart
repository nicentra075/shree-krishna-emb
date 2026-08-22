import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/services/broadcast_service.dart';

enum BroadcastStatus { initial, sending, sent, error }

class BroadcastState extends Equatable {
  final BroadcastStatus status;
  final int recipientCount;
  final String? error;

  const BroadcastState({
    this.status = BroadcastStatus.initial,
    this.recipientCount = 0,
    this.error,
  });

  BroadcastState copyWith({
    BroadcastStatus? status,
    int? recipientCount,
    String? error,
  }) {
    return BroadcastState(
      status: status ?? this.status,
      recipientCount: recipientCount ?? this.recipientCount,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, recipientCount, error];
}

/// Drives the admin "send broadcast" flow: validates the title/body, calls
/// the [BroadcastService], and exposes the recipient count / error to the UI.
class BroadcastCubit extends Cubit<BroadcastState> {
  static const int titleMaxLength = 120;

  final BroadcastService service;

  BroadcastCubit({required this.service}) : super(const BroadcastState());

  Future<void> send(String title, String body) async {
    final trimmedTitle = title.trim();
    final trimmedBody = body.trim();

    if (trimmedTitle.isEmpty || trimmedTitle.length > titleMaxLength) {
      emit(
        state.copyWith(status: BroadcastStatus.error, error: 'invalid_title'),
      );
      return;
    }
    if (trimmedBody.isEmpty) {
      emit(
        state.copyWith(status: BroadcastStatus.error, error: 'invalid_body'),
      );
      return;
    }

    emit(state.copyWith(status: BroadcastStatus.sending));
    try {
      final count = await service.send(trimmedTitle, trimmedBody);
      emit(state.copyWith(status: BroadcastStatus.sent, recipientCount: count));
    } catch (e) {
      emit(state.copyWith(status: BroadcastStatus.error, error: e.toString()));
    }
  }

  /// Resets to [BroadcastStatus.initial] so the dialog can be reused.
  void reset() => emit(const BroadcastState());
}
