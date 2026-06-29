import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shree_krishna_core/shree_krishna_core.dart';

/// Reads/writes the signed-in user's `carts/{uid}` document. The whole cart is
/// a single doc (items array), mirroring the wishlist pattern.
abstract class CartDataSource {
  Future<CartModel> getCart();
  Future<void> saveCart(CartModel cart);
}

class FirebaseCartDataSource implements CartDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FirebaseCartDataSource({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  }) : _firestore = firestore,
       _auth = auth;

  DocumentReference<Map<String, dynamic>> _doc() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw ServerException(message: 'Not signed in');
    }
    return _firestore.collection(FirestoreCollections.carts).doc(uid);
  }

  @override
  Future<CartModel> getCart() async {
    try {
      final snap = await _doc().get();
      if (!snap.exists || snap.data() == null) return const CartModel();
      return CartModel.fromFirebaseJson(snap.data()!);
    } on FirebaseException catch (e) {
      throw ServerException(message: e.message ?? 'Failed to load cart');
    }
  }

  @override
  Future<void> saveCart(CartModel cart) async {
    try {
      await _doc().set(cart.toFirebaseJson());
    } on FirebaseException catch (e) {
      throw ServerException(message: e.message ?? 'Failed to save cart');
    }
  }
}
