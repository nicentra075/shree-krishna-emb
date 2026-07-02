import 'package:equatable/equatable.dart';
import 'package:shree_krishna_core/shree_krishna_core.dart';

enum NotifSettingsStatus { initial, loading, ready, saving, saved, error }

class NotificationSettingsState extends Equatable {
  final NotifSettingsStatus status;
  final NotificationSettingsModel settings;
  final String? error;

  const NotificationSettingsState({
    this.status = NotifSettingsStatus.initial,
    this.settings = const NotificationSettingsModel(),
    this.error,
  });

  NotificationSettingsState copyWith({
    NotifSettingsStatus? status,
    NotificationSettingsModel? settings,
    String? error,
  }) =>
      NotificationSettingsState(
        status: status ?? this.status,
        settings: settings ?? this.settings,
        error: error,
      );

  @override
  List<Object?> get props => [status, settings, error];
}
