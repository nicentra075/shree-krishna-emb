import 'package:shree_krishna_core/errors/failures.dart';
import 'package:shree_krishna_core/utils/either.dart';
import 'package:shree_krishna_emb/domain/entities/user_notification_prefs.dart';

/// Backend-agnostic contract for per-user notification preferences.
abstract class NotificationPrefsRepository {
  Future<Either<Failure, UserNotificationPrefs>> getPrefs();

  Future<Either<Failure, void>> savePrefs(UserNotificationPrefs prefs);
}
