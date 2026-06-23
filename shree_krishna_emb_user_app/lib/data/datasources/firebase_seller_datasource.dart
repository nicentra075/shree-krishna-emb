import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shree_krishna_core/shree_krishna_core.dart';
import 'package:shree_krishna_emb/data/models/seller_model.dart';

abstract class SellerDataSource {
  /// Authorised designer sellers (role == 'designer' && isAuthorisedSeller).
  Future<List<SellerModel>> getAuthorisedSellers({int limit});
}

class FirebaseSellerDataSource implements SellerDataSource {
  final FirebaseFirestore _firestore;

  FirebaseSellerDataSource({required FirebaseFirestore firestore})
      : _firestore = firestore;

  @override
  Future<List<SellerModel>> getAuthorisedSellers({int limit = 20}) async {
    try {
      // Two equality filters — no composite index required. The Firestore rule
      // permits reading designer docs where isAuthorisedSeller == true, which
      // this query is constrained to, so every returned doc is authorised.
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'designer')
          .where('isAuthorisedSeller', isEqualTo: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => SellerModel.fromFirebaseJson(doc.data(), doc.id))
          .toList();
    } on FirebaseException catch (e) {
      throw ServerException(message: e.message ?? 'Failed to load sellers');
    } catch (e) {
      throw ServerException(message: 'Unexpected error: $e');
    }
  }
}
