import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shree_krishna_core/constants/firestore_collections.dart';

/// Registers/removes the current device's FCM token under the single
/// `users/{uid}/fcm_tokens/{_tokenDocId}` doc. Exactly one token doc per
/// user: overwritten on login/token-refresh, deleted on logout. The token
/// itself is stored as a field (not the doc id) so FCM's token rotation on
/// `deleteToken()` never orphans a doc.
abstract class FcmTokenDataSource {
  Future<void> registerToken(String uid, String token, String platform);
  Future<void> deleteToken(String uid);
}

class FirebaseFcmTokenDataSource implements FcmTokenDataSource {
  final FirebaseFirestore _firestore;

  FirebaseFcmTokenDataSource({required FirebaseFirestore firestore})
    : _firestore = firestore;

  /// Fixed doc id: one FCM token doc per user, never token-keyed.
  static const String _tokenDocId = 'primary';

  CollectionReference<Map<String, dynamic>> _tokens(String uid) => _firestore
      .collection(FirestoreCollections.users)
      .doc(uid)
      .collection(FirestoreCollections.fcmTokens);

  @override
  Future<void> registerToken(String uid, String token, String platform) async {
    await _tokens(uid).doc(_tokenDocId).set({
      'token': token,
      'platform': platform,
      'createdAt': FieldValue.serverTimestamp(),
      'lastSeenAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> deleteToken(String uid) async {
    await _tokens(uid).doc(_tokenDocId).delete();
  }
}
