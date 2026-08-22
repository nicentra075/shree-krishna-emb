import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shree_krishna_core/shree_krishna_core.dart';
import 'package:shree_krishna_emb/domain/entities/user_notification_prefs.dart';

/// Per-user notification preferences, stored as a `notificationPrefs` map on
/// `users/{uid}` (owner-writable per existing rules — no rules change needed).
///
/// The master switch also drives the `all_users` FCM topic subscription so
/// broadcasts/digests stop immediately; category flags are persisted for the
/// send-side Cloud Functions to respect.
abstract class NotificationPrefsDataSource {
  Future<UserNotificationPrefs> getPrefs();

  Future<void> savePrefs(UserNotificationPrefs prefs);
}

class FirebaseNotificationPrefsDataSource
    implements NotificationPrefsDataSource {
  static const String _topicAllUsers = 'all_users';

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirebaseMessaging _messaging;

  FirebaseNotificationPrefsDataSource({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
    FirebaseMessaging? messaging,
  }) : _firestore = firestore,
       _auth = auth,
       _messaging = messaging ?? FirebaseMessaging.instance;

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) {
      throw ServerException(message: 'Not signed in');
    }
    return user.uid;
  }

  @override
  Future<UserNotificationPrefs> getPrefs() async {
    try {
      final doc = await _firestore
          .collection(FirestoreCollections.users)
          .doc(_uid)
          .get();
      final raw = doc.data()?['notificationPrefs'];
      return UserNotificationPrefs.fromJson(
        raw is Map<String, dynamic> ? raw : null,
      );
    } on FirebaseException catch (e) {
      throw ServerException(message: e.message ?? 'Failed to load preferences');
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Unexpected error: $e');
    }
  }

  @override
  Future<void> savePrefs(UserNotificationPrefs prefs) async {
    try {
      await _firestore.collection(FirestoreCollections.users).doc(_uid).set({
        'notificationPrefs': prefs.toJson(),
      }, SetOptions(merge: true));

      // Master switch takes effect immediately for topic sends (broadcasts,
      // new-design digests). Best-effort — the saved prefs are the truth.
      try {
        if (prefs.pushEnabled) {
          await _messaging.subscribeToTopic(_topicAllUsers);
        } else {
          await _messaging.unsubscribeFromTopic(_topicAllUsers);
        }
      } catch (_) {}
    } on FirebaseException catch (e) {
      throw ServerException(message: e.message ?? 'Failed to save preferences');
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Unexpected error: $e');
    }
  }
}
