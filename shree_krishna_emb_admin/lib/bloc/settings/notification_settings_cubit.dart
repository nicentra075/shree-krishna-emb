import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shree_krishna_core/shree_krishna_core.dart';
import 'package:shree_krishna_emb_admin/domain/repositories/notification_settings_repository.dart';
import 'notification_settings_state.dart';

/// Drives the admin's Notification Settings form: loads/saves
/// `config/notifications` and manages the up-to-4 daily send-time slots.
class NotificationSettingsCubit extends Cubit<NotificationSettingsState> {
  final NotificationSettingsRepository repository;

  NotificationSettingsCubit({required this.repository})
    : super(const NotificationSettingsState());

  static const int maxSlots = 4;

  Future<void> load() async {
    emit(state.copyWith(status: NotifSettingsStatus.loading));
    final result = await repository.load();
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: NotifSettingsStatus.error,
          error: failure.message,
        ),
      ),
      (settings) => emit(
        state.copyWith(
          status: NotifSettingsStatus.ready,
          settings: settings,
          lastSaved: settings,
        ),
      ),
    );
  }

  void _update(NotificationSettingsEntity entity) => emit(
    state.copyWith(
      status: NotifSettingsStatus.ready,
      settings: NotificationSettingsModel.fromEntity(entity),
    ),
  );

  void toggleMaster(bool value) =>
      _update(state.settings.copyWith(masterEnabled: value));

  void togglePurchase(bool value) =>
      _update(state.settings.copyWith(purchaseAlertsEnabled: value));

  void toggleNewDesign(bool value) =>
      _update(state.settings.copyWith(newDesignAlertsEnabled: value));

  void setTimezone(String timezone) =>
      _update(state.settings.copyWith(timezone: timezone));

  /// Adds an "HH:mm" slot. Rejects when already at [maxSlots] or the slot is
  /// a duplicate. Keeps the resulting list sorted.
  void addSlot(String hhmm) {
    final slots = [...state.settings.dailySlots];
    if (slots.length >= maxSlots || slots.contains(hhmm)) return;
    slots
      ..add(hhmm)
      ..sort();
    _update(state.settings.copyWith(dailySlots: slots));
  }

  void removeSlot(String hhmm) {
    final slots = [...state.settings.dailySlots]..remove(hhmm);
    _update(state.settings.copyWith(dailySlots: slots));
  }

  Future<void> save(String adminUid) async {
    emit(state.copyWith(status: NotifSettingsStatus.saving));
    final result = await repository.save(state.settings, adminUid);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: NotifSettingsStatus.error,
          error: failure.message,
        ),
      ),
      (_) => emit(
        state.copyWith(
          status: NotifSettingsStatus.saved,
          lastSaved: state.settings,
        ),
      ),
    );
  }

  /// Reverts any in-progress edits back to the last successfully
  /// loaded/saved config. No-op if nothing has been loaded yet.
  void discardChanges() {
    final saved = state.lastSaved;
    if (saved == null) return;
    emit(
      state.copyWith(
        status: NotifSettingsStatus.ready,
        settings: saved,
        error: null,
      ),
    );
  }
}
