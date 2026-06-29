import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shree_krishna_core/shree_krishna_core.dart';
import 'package:shree_krishna_emb/domain/entities/order_draft.dart';

/// Client-side order writer for the TEST/DEMO checkout paths only.
///
/// Writes a paid `orders/demo_<millis>` doc, one `users/{uid}/purchases/{id}`
/// per item, and clears the user's cart. In the LIVE path the
/// `verifyRazorpayPayment` Cloud Function does all of this server-side and the
/// client must NOT call this (Firestore rules permit these writes only in test
/// mode). Amounts are integer rupees.
class FirebaseOrderWriter {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FirebaseOrderWriter({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  }) : _firestore = firestore,
       _auth = auth;

  /// Persists the order + purchases + clears the cart. Returns the order doc id.
  Future<String> writePaidOrder(
    OrderDraft draft, {
    String? razorpayPaymentId,
  }) async {
    final user = _auth.currentUser;
    final uid = user?.uid;
    if (uid == null) {
      throw ServerException(message: 'Not signed in');
    }

    // Fall back to the signed-in user's profile so every order (incl. free
    // claims that don't go through checkout) records who purchased it.
    final buyerName = draft.buyerName.isNotEmpty
        ? draft.buyerName
        : (user?.displayName ?? '');
    final buyerEmail = draft.buyerEmail.isNotEmpty
        ? draft.buyerEmail
        : (user?.email ?? '');

    final now = DateTime.now();
    final orderId = 'demo_${now.millisecondsSinceEpoch}';

    final orderItems = draft.items
        .map(
          (i) => OrderItemModel(
            designId: i.designId,
            title: i.title,
            thumbUrl: i.thumbUrl,
            price: i.price,
            categoryName: i.categoryName,
          ),
        )
        .toList();

    final order = OrderModel(
      id: orderId,
      userId: uid,
      buyerName: buyerName,
      buyerEmail: buyerEmail,
      items: orderItems,
      itemsSubtotal: draft.subtotal,
      platformFee: draft.platformFee,
      gstAmount: draft.gst,
      totalAmount: draft.total,
      platformFeePercent: draft.platformFeePercent,
      gstPercent: draft.gstPercent,
      status: OrderStatus.paid,
      razorpayPaymentId: razorpayPaymentId,
      createdAt: now,
      paidAt: now,
    );

    try {
      final batch = _firestore.batch();

      batch.set(
        _firestore.collection(FirestoreCollections.orders).doc(orderId),
        order.toFirebaseJson(),
      );

      final purchasesCol = _firestore
          .collection(FirestoreCollections.users)
          .doc(uid)
          .collection(FirestoreCollections.purchases);

      for (final item in draft.items) {
        final purchase = PurchaseModel(
          designId: item.designId,
          orderId: orderId,
          title: item.title,
          thumbUrl: item.thumbUrl,
          pricePaid: item.price,
          purchasedAt: now,
        );
        batch.set(purchasesCol.doc(item.designId), purchase.toFirebaseJson());
      }

      // Clear the cart in the same batch.
      batch.set(
        _firestore.collection(FirestoreCollections.carts).doc(uid),
        const CartModel().toFirebaseJson(),
      );

      await batch.commit();
      return orderId;
    } on FirebaseException catch (e) {
      throw ServerException(message: e.message ?? 'Failed to record order');
    }
  }
}
