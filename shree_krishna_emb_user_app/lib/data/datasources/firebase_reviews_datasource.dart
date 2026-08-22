import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shree_krishna_core/shree_krishna_core.dart';

/// Reviews live at `designs/{designId}/reviews/{reviewerUid}` — one upsertable
/// review per user per design. Security rules gate create/update on the
/// reviewer owning `users/{uid}/purchases/{designId}`.
abstract class ReviewsDataSource {
  Future<List<ReviewModel>> getReviews(String designId, {int limit});

  Future<ReviewModel?> getMyReview(String designId);

  Future<void> upsertReview({
    required String designId,
    required int rating,
    required String comment,
  });

  Future<void> deleteReview(String designId);
}

class FirebaseReviewsDataSource implements ReviewsDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FirebaseReviewsDataSource({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  }) : _firestore = firestore,
       _auth = auth;

  CollectionReference<Map<String, dynamic>> _reviewsRef(String designId) =>
      _firestore
          .collection(FirestoreCollections.designs)
          .doc(designId)
          .collection(FirestoreCollections.reviews);

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) {
      throw ServerException(message: 'Not signed in');
    }
    return user.uid;
  }

  @override
  Future<List<ReviewModel>> getReviews(
    String designId, {
    int limit = 50,
  }) async {
    try {
      final snap = await _reviewsRef(designId).limit(limit).get();
      final reviews =
          snap.docs
              .map((d) => ReviewModel.fromFirebaseJson(d.data(), d.id))
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return reviews;
    } on FirebaseException catch (e) {
      throw ServerException(message: e.message ?? 'Failed to load reviews');
    } catch (e) {
      throw ServerException(message: 'Unexpected error: $e');
    }
  }

  @override
  Future<ReviewModel?> getMyReview(String designId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;
      final doc = await _reviewsRef(designId).doc(user.uid).get();
      if (!doc.exists || doc.data() == null) return null;
      return ReviewModel.fromFirebaseJson(doc.data()!, doc.id);
    } on FirebaseException catch (e) {
      throw ServerException(message: e.message ?? 'Failed to load review');
    } catch (e) {
      throw ServerException(message: 'Unexpected error: $e');
    }
  }

  @override
  Future<void> upsertReview({
    required String designId,
    required int rating,
    required String comment,
  }) async {
    try {
      final uid = _uid;

      // Reviewer display name from their user doc (falls back to auth).
      String userName = _auth.currentUser?.displayName ?? '';
      String? userPhotoUrl = _auth.currentUser?.photoURL;
      try {
        final userDoc = await _firestore
            .collection(FirestoreCollections.users)
            .doc(uid)
            .get();
        final name = userDoc.data()?['name']?.toString();
        if (name != null && name.trim().isNotEmpty) userName = name;
      } catch (_) {
        // Name lookup is cosmetic — the review still goes through.
      }

      // Order reference for the purchase being reviewed (best-effort).
      String orderId = '';
      try {
        final purchase = await _firestore
            .collection(FirestoreCollections.users)
            .doc(uid)
            .collection(FirestoreCollections.purchases)
            .doc(designId)
            .get();
        orderId = purchase.data()?['orderId']?.toString() ?? '';
      } catch (_) {}

      final existing = await _reviewsRef(designId).doc(uid).get();
      final now = DateTime.now();
      final review = ReviewModel(
        userId: uid,
        userName: userName,
        userPhotoUrl: userPhotoUrl,
        rating: rating,
        comment: comment,
        orderId: orderId,
        createdAt: existing.exists
            ? ReviewModel.fromFirebaseJson(existing.data()!, uid).createdAt
            : now,
        updatedAt: existing.exists ? now : null,
      );
      await _reviewsRef(designId).doc(uid).set(review.toFirebaseJson());
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw ServerException(
          message: 'Only buyers of this design can review it',
        );
      }
      throw ServerException(message: e.message ?? 'Failed to submit review');
    } catch (e) {
      throw ServerException(message: 'Unexpected error: $e');
    }
  }

  @override
  Future<void> deleteReview(String designId) async {
    try {
      await _reviewsRef(designId).doc(_uid).delete();
    } on FirebaseException catch (e) {
      throw ServerException(message: e.message ?? 'Failed to delete review');
    } catch (e) {
      throw ServerException(message: 'Unexpected error: $e');
    }
  }
}
