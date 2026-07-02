import 'package:flutter_test/flutter_test.dart';
import 'package:shree_krishna_core/shree_krishna_core.dart' hide Failure;
import 'package:shree_krishna_emb_admin/bloc/notifications/admin_notifications_cubit.dart';
import 'package:shree_krishna_emb_admin/core/errors/failures.dart';
import 'package:shree_krishna_emb_admin/domain/repositories/admin_notifications_repository.dart';

class _Repo implements AdminNotificationsRepository {
  final List<AppNotificationModel> Function(String adminUid)? itemsFor;

  _Repo({this.itemsFor});

  @override
  Stream<List<AppNotificationModel>> watch(String adminUid) => Stream.value(
        itemsFor?.call(adminUid) ??
            [
              AppNotificationModel(
                id: '1',
                type: AppNotificationType.purchase,
                title: 't',
                body: 'b',
                data: const {},
                read: false,
                createdAt: DateTime(2026),
              ),
            ],
      );

  @override
  Future<Either<Failure, void>> delete(String id) async => const Right(null);

  @override
  Future<Either<Failure, void>> markRead(String id, String adminUid) async =>
      const Right(null);
}

void main() {
  test('start streams admin feed', () async {
    final c = AdminNotificationsCubit(repository: _Repo());
    c.start('admin1');
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(c.state.items.length, 1);
    await c.close();
  });

  test('unreadCount counts items where read == false', () async {
    final c = AdminNotificationsCubit(
      repository: _Repo(
        itemsFor: (uid) => [
          AppNotificationModel(
            id: '1',
            type: AppNotificationType.purchase,
            title: 't1',
            body: 'b1',
            read: false,
            createdAt: DateTime(2026),
          ),
          AppNotificationModel(
            id: '2',
            type: AppNotificationType.purchase,
            title: 't2',
            body: 'b2',
            read: true,
            createdAt: DateTime(2026),
          ),
        ],
      ),
    );
    c.start('admin1');
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(c.state.unreadCount, 1);
    await c.close();
  });

  test('start is idempotent for the same adminUid (no duplicate subscriptions)', () async {
    var watchCalls = 0;
    final repo = _RepoCountingWatch(() => watchCalls++);
    final c = AdminNotificationsCubit(repository: repo);
    c.start('admin1');
    c.start('admin1');
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(watchCalls, 1);
    await c.close();
  });
}

class _RepoCountingWatch implements AdminNotificationsRepository {
  final void Function() onWatch;
  _RepoCountingWatch(this.onWatch);

  @override
  Stream<List<AppNotificationModel>> watch(String adminUid) {
    onWatch();
    return Stream.value(const []);
  }

  @override
  Future<Either<Failure, void>> delete(String id) async => const Right(null);

  @override
  Future<Either<Failure, void>> markRead(String id, String adminUid) async =>
      const Right(null);
}
