import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shree_krishna_core/constants/firestore_collections.dart';

/// Registers/removes the current device's FCM token under
/// `users/{uid}/fcm_tokens/{token}`.
abstract class FcmTokenDataSource {
  Future<void> registerToken(String uid, String token, String platform);
  Future<void> deleteToken(String uid, String token);
}

class FirebaseFcmTokenDataSource implements FcmTokenDataSource {
  final FirebaseFirestore _firestore;

  FirebaseFcmTokenDataSource({required FirebaseFirestore firestore})
    : _firestore = firestore;

  CollectionReference<Map<String, dynamic>> _tokens(String uid) => _firestore
      .collection(FirestoreCollections.users)
      .doc(uid)
      .collection(FirestoreCollections.fcmTokens);

  @override
  Future<void> registerToken(String uid, String token, String platform) async {
    await _tokens(uid).doc(token).set({
      'token': token,
      'platform': platform,
      'createdAt': FieldValue.serverTimestamp(),
      'lastSeenAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> deleteToken(String uid, String token) async {
    await _tokens(uid).doc(token).delete();
  }
}
