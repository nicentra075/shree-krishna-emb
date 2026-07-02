import 'package:shree_krishna_core/shree_krishna_core.dart' hide ServerException;
import 'package:shree_krishna_emb_admin/core/errors/exceptions.dart';
import 'package:shree_krishna_emb_admin/data/datasources/firebase_notification_settings_datasource.dart';
import 'package:shree_krishna_emb_admin/domain/repositories/notification_settings_repository.dart';

class NotificationSettingsRepositoryImpl
    implements NotificationSettingsRepository {
  final NotificationSettingsDataSource dataSource;

  NotificationSettingsRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, NotificationSettingsModel>> load() async {
    try {
      return Right(await dataSource.get());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> save(
    NotificationSettingsModel settings,
    String adminUid,
  ) async {
    try {
      await dataSource.save(settings, adminUid);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
