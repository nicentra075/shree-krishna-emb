import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shree_krishna_core/shree_krishna_core.dart';

/// Reads/writes the signed-in user's `wishlists/{uid}` document. One read powers
/// both the Favorites screen and the heart state across the app.
abstract class WishlistDataSource {
  Future<WishlistModel> getWishlist();
  Future<void> saveWishlist(WishlistModel wishlist);
}

class FirebaseWishlistDataSource implements WishlistDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FirebaseWishlistDataSource({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  })  : _firestore = firestore,
        _auth = auth;

  DocumentReference<Map<String, dynamic>> _doc() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw ServerException(message: 'Not signed in');
    }
    return _firestore.collection(FirestoreCollections.wishlists).doc(uid);
  }

  @override
  Future<WishlistModel> getWishlist() async {
    try {
      final snap = await _doc().get();
      if (!snap.exists || snap.data() == null) return const WishlistModel();
      return WishlistModel.fromFirebaseJson(snap.data()!);
    } on FirebaseException catch (e) {
      throw ServerException(message: e.message ?? 'Failed to load favorites');
    }
  }

  @override
  Future<void> saveWishlist(WishlistModel wishlist) async {
    try {
      await _doc().set(wishlist.toFirebaseJson());
    } on FirebaseException catch (e) {
      throw ServerException(message: e.message ?? 'Failed to save favorites');
    }
  }
}
