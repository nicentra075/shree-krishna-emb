import 'package:cloud_firestore/cloud_firestore.dart';
// Hide core's DesignModel — we use the admin model which exposes authorId
// mapping. ServerException is also hidden in favour of the admin's.
import 'package:shree_krishna_core/shree_krishna_core.dart'
    hide ServerException, DesignModel;
import 'package:shree_krishna_emb_admin/core/errors/exceptions.dart';
import 'package:shree_krishna_emb_admin/core/utils/app_logger.dart';
import 'package:shree_krishna_emb_admin/data/datasources/firebase_orders_datasource.dart';
import 'package:shree_krishna_emb_admin/data/models/design_model.dart';

/// Interim, READ-ONLY earnings owed per designer.
///
/// NOTE: This is a stop-gap until the proper wallet/payout Cloud Functions
/// land (the `/wallet-payout-skill` work). It client-aggregates earnings by
/// joining paid-order line items → `designs.authorId` → sum of the seller's
/// net (item price minus the order's platform-fee share). No money moves here;
/// every row's status is simply "Owed".
class DesignerEarnings {
  final String designerId;
  final String designerName;

  /// Integer rupees the designer is owed (net of platform fee share).
  final int amountOwed;

  /// Gross integer rupees of their items sold.
  final int grossSales;
  final int unitsSold;

  const DesignerEarnings({
    required this.designerId,
    required this.designerName,
    required this.amountOwed,
    required this.grossSales,
    required this.unitsSold,
  });
}

abstract class PayoutsDataSource {
  /// [ownerUid] (designer sessions — D2) computes ONLY that designer's row,
  /// from queries the rules allow a designer to run.
  Future<List<DesignerEarnings>> getEarnings({
    bool forceRefresh,
    String? ownerUid,
  });
}

class FirebasePayoutsDataSource implements PayoutsDataSource {
  final FirebaseFirestore _firestore;
  final OrdersDataSource _ordersDataSource;

  FirebasePayoutsDataSource({
    required FirebaseFirestore firestore,
    required OrdersDataSource ordersDataSource,
  }) : _firestore = firestore,
       _ordersDataSource = ordersDataSource;

  static const int _maxDesignFetch = 5000;

  @override
  Future<List<DesignerEarnings>> getEarnings({
    bool forceRefresh = false,
    String? ownerUid,
  }) async {
    try {
      final orders = await _ordersDataSource.getAllOrders(
        forceRefresh: forceRefresh,
        ownerUid: ownerUid,
      );

      // designId -> authorId (skip platform-owned designs). Designer scope
      // queries only their own designs (rules deny anything broader).
      var designsQ = _firestore
          .collection(FirestoreCollections.designs)
          .limit(_maxDesignFetch);
      if (ownerUid != null) {
        designsQ = _firestore
            .collection(FirestoreCollections.designs)
            .where('authorId', isEqualTo: ownerUid)
            .limit(_maxDesignFetch);
      }
      final designSnap = await designsQ.get();

      final authorByDesign = <String, String>{};
      for (final doc in designSnap.docs) {
        final design = DesignModel.fromFirebaseJson({
          ...doc.data(),
          'id': doc.id,
        });
        authorByDesign[doc.id] = design.authorId;
        authorByDesign[design.id] = design.authorId;
      }

      // designer authorId -> name (best-effort from users).
      final nameByDesigner = <String, String>{};

      final agg = <String, _EarnAgg>{};
      for (final order in orders) {
        if (order.status != OrderStatus.paid) continue;
        // The platform-fee share for this order, prorated per line by price.
        final gross = order.itemsSubtotal == 0 ? 1 : order.itemsSubtotal;
        for (final item in order.items) {
          final author = authorByDesign[item.designId];
          // Only designer-owned designs are payable; 'platform' is the house.
          if (author == null || author.isEmpty || author == 'platform') {
            continue;
          }
          final feeShare = (order.platformFee * item.price / gross).round();
          final net = (item.price - feeShare).clamp(0, item.price);
          final e = agg.putIfAbsent(author, () => _EarnAgg());
          e.amount += net;
          e.gross += item.price;
          e.units += 1;
        }
      }

      // Resolve designer names for the authors we actually owe.
      for (final designerId in agg.keys) {
        try {
          final userDoc = await _firestore
              .collection(FirestoreCollections.users)
              .doc(designerId)
              .get();
          final name = userDoc.data()?['name'] as String?;
          nameByDesigner[designerId] = (name != null && name.isNotEmpty)
              ? name
              : designerId;
        } catch (_) {
          nameByDesigner[designerId] = designerId;
        }
      }

      final rows =
          agg.entries
              .map(
                (e) => DesignerEarnings(
                  designerId: e.key,
                  designerName: nameByDesigner[e.key] ?? e.key,
                  amountOwed: e.value.amount,
                  grossSales: e.value.gross,
                  unitsSold: e.value.units,
                ),
              )
              .toList()
            ..sort((a, b) => b.amountOwed.compareTo(a.amountOwed));

      if (ownerUid != null) {
        return rows.where((r) => r.designerId == ownerUid).toList();
      }
      return rows;
    } on FirebaseException catch (e, s) {
      AppLogger.logError('getEarnings', error: e, stackTrace: s);
      throw ServerException(message: e.message ?? 'Failed to compute earnings');
    } catch (e, s) {
      AppLogger.logError('getEarnings', error: e, stackTrace: s);
      throw ServerException(message: 'Unexpected error: $e');
    }
  }
}

class _EarnAgg {
  int amount = 0;
  int gross = 0;
  int units = 0;
}
