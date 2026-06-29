import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shree_krishna_core/shree_krishna_core.dart';

/// Reads the signed-in user's owned designs from `users/{uid}/purchases`.
/// Existence of a `users/{uid}/purchases/{designId}` doc == ownership.
/// Written only by Cloud Functions (live path) or the client order writer
/// (test/demo path).
abstract class PurchasesDataSource {
  Future<List<PurchaseModel>> getPurchases();
}

class FirebasePurchasesDataSource implements PurchasesDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FirebasePurchasesDataSource({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  }) : _firestore = firestore,
       _auth = auth;

  CollectionReference<Map<String, dynamic>> _collection() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw ServerException(message: 'Not signed in');
    }
    return _firestore
        .collection(FirestoreCollections.users)
        .doc(uid)
        .collection(FirestoreCollections.purchases);
  }

  @override
  Future<List<PurchaseModel>> getPurchases() async {
    try {
      final snap = await _collection().get();
      final list =
          snap.docs
              .map((d) => PurchaseModel.fromFirebaseJson(d.data(), d.id))
              .toList()
            // Newest first.
            ..sort((a, b) => b.purchasedAt.compareTo(a.purchasedAt));
      return list;
    } on FirebaseException catch (e) {
      throw ServerException(message: e.message ?? 'Failed to load purchases');
    }
  }
}
