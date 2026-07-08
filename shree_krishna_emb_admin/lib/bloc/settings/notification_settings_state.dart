import 'package:equatable/equatable.dart';
import 'package:shree_krishna_core/shree_krishna_core.dart';

enum NotifSettingsStatus { initial, loading, ready, saving, saved, error }

class NotificationSettingsState extends Equatable {
  final NotifSettingsStatus status;
  final NotificationSettingsModel settings;

  /// Snapshot of [settings] as of the last successful `load()`/`save()`.
  /// Null until the first successful load. Used to detect unsaved edits.
  final NotificationSettingsModel? lastSaved;
  final String? error;

  const NotificationSettingsState({
    this.status = NotifSettingsStatus.initial,
    this.settings = const NotificationSettingsModel(),
    this.lastSaved,
    this.error,
  });

  /// True once a config has been loaded/saved and the in-progress edits
  /// diverge from that last-saved snapshot.
  bool get hasUnsavedChanges => lastSaved != null && settings != lastSaved;

  NotificationSettingsState copyWith({
    NotifSettingsStatus? status,
    NotificationSettingsModel? settings,
    NotificationSettingsModel? lastSaved,
    String? error,
  }) => NotificationSettingsState(
    status: status ?? this.status,
    settings: settings ?? this.settings,
    lastSaved: lastSaved ?? this.lastSaved,
    error: error,
  );

  @override
  List<Object?> get props => [status, settings, lastSaved, error];
}
