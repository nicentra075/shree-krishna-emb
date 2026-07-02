import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shree_krishna_core/enums/app_notification_type.dart';
import 'package:shree_krishna_core/errors/failures.dart';
import 'package:shree_krishna_core/models/app_notification_model.dart';
import 'package:shree_krishna_core/utils/either.dart';
import 'package:shree_krishna_emb/bloc/notifications/notification_cubit.dart';
import 'package:shree_krishna_emb/domain/repositories/notifications_repository.dart';
import 'package:shree_krishna_emb/screens/notifications/notifications_screen.dart';

/// Fake repository whose [watch] stream never emits, so the cubit stays in
/// its initial (empty-items) state and the screen renders the empty state.
class _EmptyRepo implements NotificationsRepository {
  @override
  Stream<List<AppNotificationModel>> watch(String uid) => const Stream.empty();

  @override
  Future<Either<Failure, void>> markAllRead(String uid) async =>
      const Right(null);

  @override
  Future<Either<Failure, void>> markRead(String uid, String id) async =>
      const Right(null);

  @override
  Future<Either<Failure, void>> delete(String uid, String id) async =>
      const Right(null);
}

/// Fake repository that emits a single unread notification so the loaded
/// (list) branch of the screen can be exercised.
class _WithItemsRepo implements NotificationsRepository {
  @override
  Stream<List<AppNotificationModel>> watch(String uid) =>
      Stream<List<AppNotificationModel>>.fromIterable([
        [
          AppNotificationModel(
            id: 'n1',
            type: AppNotificationType.broadcast,
            title: 'New design available',
            body: 'Check out our latest design.',
            read: false,
            createdAt: DateTime(2026, 1, 1),
          ),
        ],
      ]);

  @override
  Future<Either<Failure, void>> markAllRead(String uid) async =>
      const Right(null);

  @override
  Future<Either<Failure, void>> markRead(String uid, String id) async =>
      const Right(null);

  @override
  Future<Either<Failure, void>> delete(String uid, String id) async =>
      const Right(null);
}

void main() {
  testWidgets('renders empty state when there are no notifications',
      (tester) async {
    final cubit = NotificationCubit(repository: _EmptyRepo());
    cubit.start('u1');

    await tester.pumpWidget(MaterialApp(
      home: BlocProvider.value(value: cubit, child: const NotificationsScreen()),
    ));
    await tester.pump();

    expect(find.byType(NotificationsScreen), findsOneWidget);

    await cubit.close();
  });

  testWidgets('renders list when notifications are present', (tester) async {
    final cubit = NotificationCubit(repository: _WithItemsRepo());
    cubit.start('u1');

    await tester.pumpWidget(MaterialApp(
      home: BlocProvider.value(value: cubit, child: const NotificationsScreen()),
    ));
    await tester.pump();
    await tester.pump();

    expect(find.byType(NotificationsScreen), findsOneWidget);
    expect(find.text('New design available'), findsOneWidget);

    await cubit.close();
  });
}
