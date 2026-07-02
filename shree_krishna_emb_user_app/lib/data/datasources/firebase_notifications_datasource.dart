import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shree_krishna_core/constants/firestore_collections.dart';
import 'package:shree_krishna_core/models/app_notification_model.dart';

/// Reads/mutates the current user's in-app notification feed at
/// `users/{uid}/notifications/{id}`.
abstract class NotificationsDataSource {
  Stream<List<AppNotificationModel>> watch(String uid);
  Future<void> markRead(String uid, String id);
  Future<void> markAllRead(String uid);
  Future<void> delete(String uid, String id);
}

class FirebaseNotificationsDataSource implements NotificationsDataSource {
  final FirebaseFirestore _firestore;

  FirebaseNotificationsDataSource({required FirebaseFirestore firestore})
    : _firestore = firestore;

  CollectionReference<Map<String, dynamic>> _col(String uid) => _firestore
      .collection(FirestoreCollections.users)
      .doc(uid)
      .collection(FirestoreCollections.userNotifications);

  @override
  Stream<List<AppNotificationModel>> watch(String uid) => _col(uid)
      .orderBy('createdAt', descending: true)
      .limit(100)
      .snapshots()
      .map(
        (snap) => snap.docs
            .map((d) => AppNotificationModel.fromFirebaseJson(d.data(), d.id))
            .toList(),
      );

  @override
  Future<void> markRead(String uid, String id) =>
      _col(uid).doc(id).update({'read': true});

  @override
  Future<void> markAllRead(String uid) async {
    final unread = await _col(uid).where('read', isEqualTo: false).get();
    final batch = _firestore.batch();
    for (final d in unread.docs) {
      batch.update(d.reference, {'read': true});
    }
    await batch.commit();
  }

  @override
  Future<void> delete(String uid, String id) => _col(uid).doc(id).delete();
}
