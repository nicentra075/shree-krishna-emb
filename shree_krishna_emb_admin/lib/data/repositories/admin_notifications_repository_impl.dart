import 'package:shree_krishna_core/shree_krishna_core.dart'
    show AppNotificationModel, Either, Right, Left;

import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/repositories/admin_notifications_repository.dart';
import '../datasources/firebase_admin_notifications_datasource.dart';

class AdminNotificationsRepositoryImpl implements AdminNotificationsRepository {
  final AdminNotificationsDataSource _dataSource;

  AdminNotificationsRepositoryImpl({
    required AdminNotificationsDataSource dataSource,
  }) : _dataSource = dataSource;

  @override
  Stream<List<AppNotificationModel>> watch(String adminUid) =>
      _dataSource.watch(adminUid);

  @override
  Future<Either<Failure, void>> markRead(String id, String adminUid) async {
    try {
      await _dataSource.markRead(id, adminUid);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> delete(String id) async {
    try {
      await _dataSource.delete(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
