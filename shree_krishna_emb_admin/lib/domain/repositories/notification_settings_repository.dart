import 'package:shree_krishna_core/shree_krishna_core.dart';

/// Contract for reading/writing the admin's notification settings
/// (`config/notifications`). Backend-agnostic: the data layer decides how
/// this is implemented (Firebase today).
abstract class NotificationSettingsRepository {
  Future<Either<Failure, NotificationSettingsModel>> load();

  Future<Either<Failure, void>> save(
    NotificationSettingsModel settings,
    String adminUid,
  );
}
