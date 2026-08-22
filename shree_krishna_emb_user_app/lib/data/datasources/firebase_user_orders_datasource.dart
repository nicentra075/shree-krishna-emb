import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shree_krishna_core/shree_krishna_core.dart';

/// Read-only view of the signed-in user's orders (`orders` where
/// userId == uid). Order docs are written by the payment Cloud Functions
/// (or the test-mode demo writer); the app never mutates them.
abstract class UserOrdersDataSource {
  Future<List<OrderModel>> getMyOrders({int limit});
}

class FirebaseUserOrdersDataSource implements UserOrdersDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FirebaseUserOrdersDataSource({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  }) : _firestore = firestore,
       _auth = auth;

  @override
  Future<List<OrderModel>> getMyOrders({int limit = 100}) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        throw ServerException(message: 'Not signed in');
      }
      // Equality-only where + client-side sort keeps this index-free (a
      // where+orderBy combo would need a composite index deploy).
      final snap = await _firestore
          .collection(FirestoreCollections.orders)
          .where('userId', isEqualTo: uid)
          .limit(limit)
          .get();
      final orders =
          snap.docs
              .map((d) => OrderModel.fromFirebaseJson(d.data(), d.id))
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return orders;
    } on FirebaseException catch (e) {
      throw ServerException(message: e.message ?? 'Failed to load orders');
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Unexpected error: $e');
    }
  }
}
