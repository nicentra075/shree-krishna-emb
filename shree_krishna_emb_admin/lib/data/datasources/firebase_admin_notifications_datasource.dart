import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shree_krishna_core/shree_krishna_core.dart';

/// Reads/writes the shared `admin_notifications` feed (top-level collection,
/// one doc per event e.g. a new paid order). Unread state is NOT a `read`
/// bool on the doc — it is derived per-admin from the `readBy` array, so
/// [watch] takes the current admin's uid and maps each doc into an
/// [AppNotificationModel] with `read = readBy.contains(adminUid)`.
abstract class AdminNotificationsDataSource {
  Stream<List<AppNotificationModel>> watch(String adminUid);
  Future<void> markRead(String id, String adminUid);
  Future<void> delete(String id);
}

class FirebaseAdminNotificationsDataSource
    implements AdminNotificationsDataSource {
  final FirebaseFirestore _firestore;

  FirebaseAdminNotificationsDataSource({required FirebaseFirestore firestore})
      : _firestore = firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(FirestoreCollections.adminNotifications);

  @override
  Stream<List<AppNotificationModel>> watch(String adminUid) => _col
      .orderBy('createdAt', descending: true)
      .limit(100)
      .snapshots()
      .map(
        (snap) => snap.docs.map((d) {
          final data = d.data();
          final readBy = (data['readBy'] as List?)?.cast<String>() ?? const [];
          return AppNotificationModel.fromFirebaseJson(
            {...data, 'read': readBy.contains(adminUid)},
            d.id,
          );
        }).toList(),
      );

  @override
  Future<void> markRead(String id, String adminUid) => _col.doc(id).update({
        'readBy': FieldValue.arrayUnion([adminUid]),
      });

  @override
  Future<void> delete(String id) => _col.doc(id).delete();
}
