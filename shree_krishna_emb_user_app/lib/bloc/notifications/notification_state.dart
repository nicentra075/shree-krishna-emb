import 'package:equatable/equatable.dart';
import 'package:shree_krishna_core/models/app_notification_model.dart';

enum NotificationStatus { initial, loading, loaded, error }

class NotificationState extends Equatable {
  final NotificationStatus status;
  final List<AppNotificationModel> items;
  final String? error;

  const NotificationState({
    this.status = NotificationStatus.initial,
    this.items = const [],
    this.error,
  });

  int get unreadCount => items.where((n) => !n.read).length;

  NotificationState copyWith({
    NotificationStatus? status,
    List<AppNotificationModel>? items,
    String? error,
  }) => NotificationState(
    status: status ?? this.status,
    items: items ?? this.items,
    error: error,
  );

  @override
  List<Object?> get props => [status, items, error];
}
