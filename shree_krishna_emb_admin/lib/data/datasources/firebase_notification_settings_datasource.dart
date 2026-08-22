import 'package:cloud_firestore/cloud_firestore.dart';
// Core exports its own ServerException which clashes with the admin app's;
// hide it so the admin's local version is used (mirrors
// firebase_platform_config_datasource.dart).
import 'package:shree_krishna_core/shree_krishna_core.dart'
    hide ServerException;
import 'package:shree_krishna_emb_admin/core/errors/exceptions.dart';
import 'package:shree_krishna_emb_admin/core/utils/app_logger.dart';

/// Reads/writes the single `config/notifications` document that stores the
/// admin's push-notification settings (master toggle, purchase/new-design
/// alert toggles, daily send-time slots, timezone).
abstract class NotificationSettingsDataSource {
  Future<NotificationSettingsModel> get();

  /// Persists [settings]. [adminUid] is stamped as `updatedBy` for audit.
  Future<void> save(NotificationSettingsModel settings, String adminUid);
}

class FirebaseNotificationSettingsDataSource
    implements NotificationSettingsDataSource {
  final FirebaseFirestore _firestore;

  FirebaseNotificationSettingsDataSource({required FirebaseFirestore firestore})
    : _firestore = firestore;

  DocumentReference<Map<String, dynamic>> get _doc => _firestore
      .collection(FirestoreCollections.config)
      .doc(FirestoreCollections.configNotificationsDoc);

  @override
  Future<NotificationSettingsModel> get() async {
    try {
      final snap = await _doc.get();
      if (!snap.exists || snap.data() == null) {
        return NotificationSettingsModel.defaults();
      }
      return NotificationSettingsModel.fromFirebaseJson(snap.data()!);
    } on FirebaseException catch (e, s) {
      AppLogger.logError('notificationSettings.get', error: e, stackTrace: s);
      throw ServerException(
        message: e.message ?? 'Failed to load notification settings',
      );
    } catch (e, s) {
      AppLogger.logError('notificationSettings.get', error: e, stackTrace: s);
      throw ServerException(message: 'Unexpected error: $e');
    }
  }

  @override
  Future<void> save(NotificationSettingsModel settings, String adminUid) async {
    try {
      final payload = settings.toFirebaseJson()
        ..['updatedAt'] = DateTime.now().toIso8601String()
        ..['updatedBy'] = adminUid;
      await _doc.set(payload, SetOptions(merge: true));
    } on FirebaseException catch (e, s) {
      AppLogger.logError('notificationSettings.save', error: e, stackTrace: s);
      throw ServerException(
        message: e.message ?? 'Failed to save notification settings',
      );
    } catch (e, s) {
      AppLogger.logError('notificationSettings.save', error: e, stackTrace: s);
      throw ServerException(message: 'Unexpected error: $e');
    }
  }
}
