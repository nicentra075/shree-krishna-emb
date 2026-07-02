import 'package:shree_krishna_core/errors/failures.dart';
import 'package:shree_krishna_core/models/app_notification_model.dart';
import 'package:shree_krishna_core/utils/either.dart';

import '../../domain/repositories/notifications_repository.dart';
import '../datasources/firebase_notifications_datasource.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  final NotificationsDataSource dataSource;

  NotificationsRepositoryImpl({required this.dataSource});

  @override
  Stream<List<AppNotificationModel>> watch(String uid) => dataSource.watch(uid);

  @override
  Future<Either<Failure, void>> markRead(String uid, String id) =>
      _guard(() => dataSource.markRead(uid, id));

  @override
  Future<Either<Failure, void>> markAllRead(String uid) =>
      _guard(() => dataSource.markAllRead(uid));

  @override
  Future<Either<Failure, void>> delete(String uid, String id) =>
      _guard(() => dataSource.delete(uid, id));

  Future<Either<Failure, void>> _guard(Future<void> Function() op) async {
    try {
      await op();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
