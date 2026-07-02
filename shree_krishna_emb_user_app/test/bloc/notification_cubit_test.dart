import 'package:flutter_test/flutter_test.dart';
import 'package:shree_krishna_core/enums/app_notification_type.dart';
import 'package:shree_krishna_core/errors/failures.dart';
import 'package:shree_krishna_core/models/app_notification_model.dart';
import 'package:shree_krishna_core/utils/either.dart';
import 'package:shree_krishna_emb/bloc/notifications/notification_cubit.dart';
import 'package:shree_krishna_emb/domain/repositories/notifications_repository.dart';

class _Repo implements NotificationsRepository {
  final _ctrl = Stream<List<AppNotificationModel>>.fromIterable([
    [
      AppNotificationModel(
        id: 'a',
        type: AppNotificationType.broadcast,
        title: 't',
        body: 'b',
        read: false,
        createdAt: DateTime(2026),
      ),
      AppNotificationModel(
        id: 'b',
        type: AppNotificationType.broadcast,
        title: 't',
        body: 'b',
        read: true,
        createdAt: DateTime(2026),
      ),
    ],
  ]);

  int markAllReadCalls = 0;
  int deleteCalls = 0;
  String? lastDeleteId;

  @override
  Future<Either<Failure, void>> delete(String uid, String id) async {
    deleteCalls++;
    lastDeleteId = id;
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> markAllRead(String uid) async {
    markAllReadCalls++;
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> markRead(String uid, String id) async =>
      const Right(null);

  @override
  Stream<List<AppNotificationModel>> watch(String uid) => _ctrl;
}

void main() {
  test('start streams items and computes unreadCount', () async {
    final cubit = NotificationCubit(repository: _Repo());
    cubit.start('u1');
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(cubit.state.items.length, 2);
    expect(cubit.state.unreadCount, 1);
    await cubit.close();
  });

  test('stop cancels subscription and resets state', () async {
    final cubit = NotificationCubit(repository: _Repo());
    cubit.start('u1');
    await Future<void>.delayed(const Duration(milliseconds: 50));
    cubit.stop();
    expect(cubit.state.items, isEmpty);
    expect(cubit.state.unreadCount, 0);
    await cubit.close();
  });

  test('markAllRead delegates to repository with active uid', () async {
    final repo = _Repo();
    final cubit = NotificationCubit(repository: repo);
    cubit.start('u1');
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await cubit.markAllRead();
    expect(repo.markAllReadCalls, 1);
    await cubit.close();
  });

  test('delete delegates to repository with active uid', () async {
    final repo = _Repo();
    final cubit = NotificationCubit(repository: repo);
    cubit.start('u1');
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await cubit.delete('a');
    expect(repo.deleteCalls, 1);
    expect(repo.lastDeleteId, 'a');
    await cubit.close();
  });
}
