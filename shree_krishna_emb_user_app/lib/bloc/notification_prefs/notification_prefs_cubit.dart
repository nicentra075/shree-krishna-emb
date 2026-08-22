import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shree_krishna_emb/domain/entities/user_notification_prefs.dart';
import 'package:shree_krishna_emb/domain/repositories/notification_prefs_repository.dart';

enum NotificationPrefsStatus { initial, loading, loaded, error }

/// One-shot save outcomes surfaced as toasts (D6).
enum PrefsSaveResult { none, saved, failed }

class NotificationPrefsState extends Equatable {
  final NotificationPrefsStatus status;
  final UserNotificationPrefs prefs;
  final PrefsSaveResult saveResult;
  final String? error;

  const NotificationPrefsState({
    this.status = NotificationPrefsStatus.initial,
    this.prefs = const UserNotificationPrefs(),
    this.saveResult = PrefsSaveResult.none,
    this.error,
  });

  NotificationPrefsState copyWith({
    NotificationPrefsStatus? status,
    UserNotificationPrefs? prefs,
    PrefsSaveResult? saveResult,
    String? error,
  }) {
    return NotificationPrefsState(
      status: status ?? this.status,
      prefs: prefs ?? this.prefs,
      saveResult: saveResult ?? PrefsSaveResult.none,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, prefs, saveResult, error];
}

/// Loads and saves the user's notification preferences (WS-B4). Toggles apply
/// optimistically and roll back with an error toast when the save fails.
class NotificationPrefsCubit extends Cubit<NotificationPrefsState> {
  final NotificationPrefsRepository _repository;

  NotificationPrefsCubit({required NotificationPrefsRepository repository})
    : _repository = repository,
      super(const NotificationPrefsState());

  Future<void> load() async {
    emit(state.copyWith(status: NotificationPrefsStatus.loading));
    final result = await _repository.getPrefs();
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: NotificationPrefsStatus.error,
          error: failure.message,
        ),
      ),
      (prefs) => emit(
        state.copyWith(status: NotificationPrefsStatus.loaded, prefs: prefs),
      ),
    );
  }

  Future<void> update(UserNotificationPrefs next) async {
    final previous = state.prefs;
    emit(state.copyWith(prefs: next)); // optimistic

    final result = await _repository.savePrefs(next);
    result.fold(
      (failure) => emit(
        state.copyWith(
          prefs: previous,
          saveResult: PrefsSaveResult.failed,
          error: failure.message,
        ),
      ),
      (_) => emit(state.copyWith(saveResult: PrefsSaveResult.saved)),
    );
  }
}
