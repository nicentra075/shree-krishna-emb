import 'package:flutter_test/flutter_test.dart';
import 'package:shree_krishna_core/errors/failures.dart';
import 'package:shree_krishna_core/models/app_notification_model.dart';
import 'package:shree_krishna_core/utils/either.dart';
import 'package:shree_krishna_emb/data/datasources/firebase_notifications_datasource.dart';
import 'package:shree_krishna_emb/data/repositories/notifications_repository_impl.dart';

class _FakeDs implements NotificationsDataSource {
  bool throwOnMutate = false;

  @override
  Future<void> delete(String uid, String id) async {
    if (throwOnMutate) throw Exception('x');
  }

  @override
  Future<void> markAllRead(String uid) async {
    if (throwOnMutate) throw Exception('x');
  }

  @override
  Future<void> markRead(String uid, String id) async {
    if (throwOnMutate) throw Exception('x');
  }

  @override
  Stream<List<AppNotificationModel>> watch(String uid) => const Stream.empty();
}

void main() {
  test('markRead ok -> Right', () async {
    final repo = NotificationsRepositoryImpl(dataSource: _FakeDs());
    final result = await repo.markRead('u', 'n');
    expect(result, isA<Right<Failure, void>>());
  });

  test('markRead failure -> Left', () async {
    final repo = NotificationsRepositoryImpl(
      dataSource: _FakeDs()..throwOnMutate = true,
    );
    final result = await repo.markRead('u', 'n');
    expect(result, isA<Left<Failure, void>>());
  });

  test('markAllRead ok -> Right', () async {
    final repo = NotificationsRepositoryImpl(dataSource: _FakeDs());
    final result = await repo.markAllRead('u');
    expect(result, isA<Right<Failure, void>>());
  });

  test('markAllRead failure -> Left', () async {
    final repo = NotificationsRepositoryImpl(
      dataSource: _FakeDs()..throwOnMutate = true,
    );
    final result = await repo.markAllRead('u');
    expect(result, isA<Left<Failure, void>>());
  });

  test('delete ok -> Right', () async {
    final repo = NotificationsRepositoryImpl(dataSource: _FakeDs());
    final result = await repo.delete('u', 'n');
    expect(result, isA<Right<Failure, void>>());
  });

  test('delete failure -> Left', () async {
    final repo = NotificationsRepositoryImpl(
      dataSource: _FakeDs()..throwOnMutate = true,
    );
    final result = await repo.delete('u', 'n');
    expect(result, isA<Left<Failure, void>>());
  });
}
