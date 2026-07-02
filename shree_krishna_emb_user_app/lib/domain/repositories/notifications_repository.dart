import 'package:shree_krishna_core/errors/failures.dart';
import 'package:shree_krishna_core/models/app_notification_model.dart';
import 'package:shree_krishna_core/utils/either.dart';

/// Contract for the in-app notification feed. Backend-agnostic; implemented
/// by [NotificationsRepositoryImpl] against Firebase today.
abstract class NotificationsRepository {
  Stream<List<AppNotificationModel>> watch(String uid);
  Future<Either<Failure, void>> markRead(String uid, String id);
  Future<Either<Failure, void>> markAllRead(String uid);
  Future<Either<Failure, void>> delete(String uid, String id);
}
