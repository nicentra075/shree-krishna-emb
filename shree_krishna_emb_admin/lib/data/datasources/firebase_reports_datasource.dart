import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shree_krishna_core/shree_krishna_core.dart'
    hide ServerException;
import 'package:shree_krishna_emb_admin/core/errors/exceptions.dart';
import 'package:shree_krishna_emb_admin/core/utils/app_logger.dart';
import 'package:shree_krishna_emb_admin/data/datasources/firebase_orders_datasource.dart';

/// A ranked row in the top-designs / top-categories tables.
class RankedRow {
  final String id;
  final String label;
  final int unitsSold;

  /// Integer rupees attributed to this design/category.
  final int revenue;

  const RankedRow({
    required this.id,
    required this.label,
    required this.unitsSold,
    required this.revenue,
  });
}

/// A single CSV line item (one order line).
class ReportLineItem {
  final String orderId;
  final DateTime date;
  final String buyerName;
  final String buyerEmail;
  final String status;
  final String designId;
  final String designTitle;
  final String categoryName;
  final int price;
  final String invoiceNumber;

  const ReportLineItem({
    required this.orderId,
    required this.date,
    required this.buyerName,
    required this.buyerEmail,
    required this.status,
    required this.designId,
    required this.designTitle,
    required this.categoryName,
    required this.price,
    required this.invoiceNumber,
  });
}

/// The computed report for a date range.
class ReportSummary {
  /// Integer rupees of paid revenue in range.
  final int totalSales;
  final int paidOrders;

  /// Average order value (integer rupees), 0 when no orders.
  final int averageOrderValue;
  final int newUsers;
  final int totalPlatformFees;
  final int totalGst;
  final List<RankedRow> topDesigns;
  final List<RankedRow> topCategories;
  final List<ReportLineItem> lineItems;

  const ReportSummary({
    this.totalSales = 0,
    this.paidOrders = 0,
    this.averageOrderValue = 0,
    this.newUsers = 0,
    this.totalPlatformFees = 0,
    this.totalGst = 0,
    this.topDesigns = const [],
    this.topCategories = const [],
    this.lineItems = const [],
  });
}

abstract class ReportsDataSource {
  /// [ownerUid] (designer sessions - D2) scopes the report to that designer's
  /// items only (their line items, no platform-wide user counts).
  Future<ReportSummary> getReport({
    required DateTime start,
    required DateTime end,
    bool forceRefresh,
    String? ownerUid,
  });
}

class FirebaseReportsDataSource implements ReportsDataSource {
  final FirebaseFirestore _firestore;
  final OrdersDataSource _ordersDataSource;

  FirebaseReportsDataSource({
    required FirebaseFirestore firestore,
    required OrdersDataSource ordersDataSource,
  }) : _firestore = firestore,
       _ordersDataSource = ordersDataSource;

  @override
  Future<ReportSummary> getReport({
    required DateTime start,
    required DateTime end,
    bool forceRefresh = false,
    String? ownerUid,
  }) async {
    try {
      final allOrders = await _ordersDataSource.getAllOrders(
        forceRefresh: forceRefresh,
        ownerUid: ownerUid,
      );

      // Paid orders within [start, end].
      final paid = allOrders.where((o) {
        if (o.status != OrderStatus.paid) return false;
        final d = o.createdAt;
        return !d.isBefore(start) && !d.isAfter(end);
      }).toList();

      var totalSales = 0;
      var totalFees = 0;
      var totalGst = 0;
      final designAgg = <String, _RankAgg>{};
      final categoryAgg = <String, _RankAgg>{};
      final lineItems = <ReportLineItem>[];

      for (final o in paid) {
        totalSales += o.totalAmount;
        totalFees += o.platformFee;
        totalGst += o.gstAmount;
        for (final item in o.items) {
          final d = designAgg.putIfAbsent(
            item.designId,
            () => _RankAgg(item.title),
          );
          d.units += 1;
          d.revenue += item.price;

          final catKey = item.categoryId.isNotEmpty
              ? item.categoryId
              : (item.categoryName.isNotEmpty
                    ? item.categoryName
                    : 'uncategorised');
          final c = categoryAgg.putIfAbsent(
            catKey,
            () => _RankAgg(
              item.categoryName.isNotEmpty
                  ? item.categoryName
                  : 'Uncategorised',
            ),
          );
          c.units += 1;
          c.revenue += item.price;

          lineItems.add(
            ReportLineItem(
              orderId: o.id,
              date: o.createdAt,
              buyerName: o.buyerName,
              buyerEmail: o.buyerEmail,
              status: o.status.value,
              designId: item.designId,
              designTitle: item.title,
              categoryName: item.categoryName,
              price: item.price,
              invoiceNumber: o.invoiceNumber ?? '',
            ),
          );
        }
      }

      final topDesigns = _rank(designAgg);
      final topCategories = _rank(categoryAgg);

      final aov = paid.isEmpty ? 0 : (totalSales / paid.length).round();
      // Platform-wide signup counts are admin-only (rules + relevance).
      final newUsers = ownerUid == null ? await _countNewUsers(start, end) : 0;

      return ReportSummary(
        totalSales: totalSales,
        paidOrders: paid.length,
        averageOrderValue: aov,
        newUsers: newUsers,
        totalPlatformFees: totalFees,
        totalGst: totalGst,
        topDesigns: topDesigns,
        topCategories: topCategories,
        lineItems: lineItems,
      );
    } on FirebaseException catch (e, s) {
      AppLogger.logError('getReport', error: e, stackTrace: s);
      throw ServerException(message: e.message ?? 'Failed to build report');
    } catch (e, s) {
      AppLogger.logError('getReport', error: e, stackTrace: s);
      throw ServerException(message: 'Unexpected error: $e');
    }
  }

  List<RankedRow> _rank(Map<String, _RankAgg> agg) {
    final rows =
        agg.entries
            .map(
              (e) => RankedRow(
                id: e.key,
                label: e.value.label,
                unitsSold: e.value.units,
                revenue: e.value.revenue,
              ),
            )
            .toList()
          ..sort((a, b) => b.revenue.compareTo(a.revenue));
    return rows.take(10).toList();
  }

  /// New users created within the range. `createdAt` is stored as an ISO
  /// string in this app, so an inequality range query works on the field.
  Future<int> _countNewUsers(DateTime start, DateTime end) async {
    try {
      final snap = await _firestore
          .collection(FirestoreCollections.users)
          .where('createdAt', isGreaterThanOrEqualTo: start.toIso8601String())
          .where('createdAt', isLessThanOrEqualTo: end.toIso8601String())
          .count()
          .get();
      return snap.count ?? 0;
    } catch (e, s) {
      // Some user docs may store createdAt as Timestamp; degrade gracefully.
      AppLogger.logError('countNewUsers', error: e, stackTrace: s);
      return 0;
    }
  }
}

class _RankAgg {
  final String label;
  int units = 0;
  int revenue = 0;
  _RankAgg(this.label);
}
