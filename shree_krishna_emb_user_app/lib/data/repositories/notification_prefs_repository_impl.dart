import 'package:shree_krishna_core/shree_krishna_core.dart';
import 'package:shree_krishna_emb/data/datasources/firebase_notification_prefs_datasource.dart';
import 'package:shree_krishna_emb/domain/entities/user_notification_prefs.dart';
import 'package:shree_krishna_emb/domain/repositories/notification_prefs_repository.dart';

class NotificationPrefsRepositoryImpl implements NotificationPrefsRepository {
  final NotificationPrefsDataSource _dataSource;

  NotificationPrefsRepositoryImpl({
    required NotificationPrefsDataSource dataSource,
  }) : _dataSource = dataSource;

  @override
  Future<Either<Failure, UserNotificationPrefs>> getPrefs() async {
    try {
      final prefs = await _dataSource.getPrefs();
      return Right(prefs);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> savePrefs(UserNotificationPrefs prefs) async {
    try {
      await _dataSource.savePrefs(prefs);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
