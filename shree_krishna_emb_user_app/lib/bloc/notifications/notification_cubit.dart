import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/notifications_repository.dart';
import 'notification_state.dart';

/// Owns the in-app notification feed for the currently signed-in user.
/// [start]/[stop] are driven by the app-wide auth listener (see main.dart).
class NotificationCubit extends Cubit<NotificationState> {
  final NotificationsRepository repository;
  StreamSubscription? _sub;
  String? _uid;

  NotificationCubit({required this.repository}) : super(const NotificationState());

  void start(String uid) {
    _uid = uid;
    _sub?.cancel();
    emit(state.copyWith(status: NotificationStatus.loading));
    _sub = repository.watch(uid).listen(
      (items) => emit(state.copyWith(status: NotificationStatus.loaded, items: items)),
      onError: (Object e) =>
          emit(state.copyWith(status: NotificationStatus.error, error: e.toString())),
    );
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
    _uid = null;
    emit(const NotificationState());
  }

  Future<void> markAllRead() async {
    final uid = _uid;
    if (uid == null) return;
    await repository.markAllRead(uid);
  }

  Future<void> delete(String id) async {
    final uid = _uid;
    if (uid == null) return;
    await repository.delete(uid, id);
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
