import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shree_krishna_core/shree_krishna_core.dart'
    show AppNotificationModel;

import '../../domain/repositories/admin_notifications_repository.dart';

class AdminNotificationsState extends Equatable {
  final List<AppNotificationModel> items;

  const AdminNotificationsState({this.items = const []});

  /// Unread = admin uid NOT in the doc's `readBy` array — the datasource
  /// already folds that into each model's `read` flag per current admin.
  int get unreadCount => items.where((n) => !n.read).length;

  AdminNotificationsState copyWith({List<AppNotificationModel>? items}) =>
      AdminNotificationsState(items: items ?? this.items);

  @override
  List<Object?> get props => [items];
}

/// Streams the shared `admin_notifications` inbox for the signed-in admin
/// and exposes mark-read / mark-all-read / delete actions. Registered as a
/// singleton so the dashboard bell badge and the inbox screen share one
/// live subscription.
class AdminNotificationsCubit extends Cubit<AdminNotificationsState> {
  final AdminNotificationsRepository repository;

  StreamSubscription<List<AppNotificationModel>>? _sub;
  String? _adminUid;

  AdminNotificationsCubit({required this.repository})
    : super(const AdminNotificationsState());

  /// Starts (or restarts, e.g. on re-login as a different admin) the feed
  /// subscription for [adminUid].
  void start(String adminUid) {
    if (_adminUid == adminUid && _sub != null) return;
    _adminUid = adminUid;
    _sub?.cancel();
    _sub = repository.watch(adminUid).listen((items) {
      emit(state.copyWith(items: items));
    });
  }

  Future<void> markRead(String id) async {
    final adminUid = _adminUid;
    if (adminUid == null) return;
    await repository.markRead(id, adminUid);
  }

  Future<void> markAllRead() async {
    final adminUid = _adminUid;
    if (adminUid == null) return;
    for (final n in state.items.where((n) => !n.read)) {
      await repository.markRead(n.id, adminUid);
    }
  }

  Future<void> delete(String id) => repository.delete(id);

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
