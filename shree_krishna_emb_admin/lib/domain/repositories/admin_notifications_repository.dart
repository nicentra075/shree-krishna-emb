import 'package:shree_krishna_core/shree_krishna_core.dart'
    show AppNotificationModel, Either;

import '../../core/errors/failures.dart';

/// Contract for the shared admin notification inbox (`admin_notifications`).
/// [watch] streams the feed for a given admin uid so read state (`readBy`
/// array membership) is computed per-caller.
abstract class AdminNotificationsRepository {
  Stream<List<AppNotificationModel>> watch(String adminUid);
  Future<Either<Failure, void>> markRead(String id, String adminUid);
  Future<Either<Failure, void>> delete(String id);
}
