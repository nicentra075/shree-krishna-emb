import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shree_krishna_core/shree_krishna_core.dart'
    hide ServerException;
import 'package:shree_krishna_emb_admin/core/errors/exceptions.dart';
import 'package:shree_krishna_emb_admin/core/utils/app_logger.dart';

/// A single point on the revenue-per-day chart.
class DailyRevenuePoint {
  /// Local day (midnight).
  final DateTime day;

  /// Integer rupees of paid-order revenue on [day].
  final int revenue;

  /// Number of paid orders on [day].
  final int orders;

  const DailyRevenuePoint({
    required this.day,
    required this.revenue,
    required this.orders,
  });
}

/// Live dashboard counters + a revenue summary, computed resiliently:
/// counts use Firestore aggregate `count()`; revenue is summed from a bounded
/// `orders` query. Missing fields/docs degrade to 0 rather than throwing.
class DashboardStats {
  final int totalUsers;
  final int totalDesigners;
  final int totalDesigns;
  final int activeDesigns;
  final int pendingDesigns;
  final int totalOrders;
  final int ordersToday;

  /// Integer rupees.
  final int revenueToday;
  final int revenue7d;
  final int revenueTotal;

  /// Last [chartDays] days of revenue, oldest-first (for the chart).
  final List<DailyRevenuePoint> dailyRevenue;

  const DashboardStats({
    this.totalUsers = 0,
    this.totalDesigners = 0,
    this.totalDesigns = 0,
    this.activeDesigns = 0,
    this.pendingDesigns = 0,
    this.totalOrders = 0,
    this.ordersToday = 0,
    this.revenueToday = 0,
    this.revenue7d = 0,
    this.revenueTotal = 0,
    this.dailyRevenue = const [],
  });
}

abstract class DashboardStatsDataSource {
  /// [authorUid] scopes everything to one designer's data (D2): design counts
  /// by `authorId`, orders/revenue via the `ownerIds`/`ownerTotals` fields
  /// stamped by finalizeOrder. Null = platform-wide (admin).
  Future<DashboardStats> getStats({int chartDays, String? authorUid});
}

class FirebaseDashboardStatsDataSource implements DashboardStatsDataSource {
  final FirebaseFirestore _firestore;

  FirebaseDashboardStatsDataSource({required FirebaseFirestore firestore})
    : _firestore = firestore;

  /// Bounded read for revenue aggregation — orders within this window.
  static const int _maxOrderFetch = 2000;

  Future<int> _count(Query<Map<String, dynamic>> query) async {
    try {
      final snap = await query.count().get();
      return snap.count ?? 0;
    } catch (e, s) {
      // Aggregate count can fail on emulators/old SDKs — degrade to 0.
      AppLogger.logError('dashboard count()', error: e, stackTrace: s);
      return 0;
    }
  }

  /// Demo/test orders (`demo_*` ids) store integer rupees; live server orders
  /// store paise. Normalizes to integer rupees for display.
  static int _toRupees(String orderId, num value) =>
      orderId.startsWith('demo_') ? value.toInt() : (value / 100).round();

  @override
  Future<DashboardStats> getStats({
    int chartDays = 7,
    String? authorUid,
  }) async {
    try {
      final usersRef = _firestore.collection(FirestoreCollections.users);
      final designsBase = _firestore.collection(FirestoreCollections.designs);
      final ordersRef = _firestore.collection(FirestoreCollections.orders);

      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final windowStart = todayStart.subtract(Duration(days: chartDays - 1));

      Query<Map<String, dynamic>> designsQ = designsBase;
      if (authorUid != null) {
        designsQ = designsQ.where('authorId', isEqualTo: authorUid);
      }

      // Counts via aggregate queries (cheap; one read unit each). User counts
      // are platform-wide — skipped for designer-scoped dashboards.
      final results = await Future.wait<int>([
        authorUid == null ? _count(usersRef) : Future.value(0),
        authorUid == null
            ? _count(usersRef.where('role', isEqualTo: UserRole.designer.value))
            : Future.value(0),
        _count(designsQ),
        _count(designsQ.where('status', isEqualTo: 'active')),
        _count(designsQ.where('status', isEqualTo: 'pending')),
      ]);

      // Paid orders for revenue, bounded. Admin reads the most recent orders;
      // a designer can ONLY query orders containing their designs (rules), so
      // the query filters on ownerIds and sorts client-side (index-free).
      final paidSnap = authorUid == null
          ? await ordersRef
                .orderBy('createdAt', descending: true)
                .limit(_maxOrderFetch)
                .get()
          : await ordersRef
                .where('ownerIds', arrayContains: authorUid)
                .limit(_maxOrderFetch)
                .get();

      var revenueToday = 0;
      var revenue7d = 0;
      var revenueTotal = 0;
      var ordersToday = 0;
      var totalOrders = 0;
      final perDay = <DateTime, _DayAgg>{};

      final sevenDayStart = todayStart.subtract(const Duration(days: 6));

      for (final doc in paidSnap.docs) {
        final data = doc.data();
        if (data['status'] != 'paid') continue;

        // Designer sees only their own share of each order (ownerTotals is
        // stamped server-side by finalizeOrder, always in paise).
        final int amount;
        if (authorUid == null) {
          amount = _toRupees(doc.id, (data['totalAmount'] as num?) ?? 0);
        } else {
          final totals = data['ownerTotals'];
          final share = totals is Map ? totals[authorUid] : null;
          if (share is! num) continue;
          amount = (share / 100).round();
        }

        totalOrders += 1;
        revenueTotal += amount;
        final created =
            DateTime.tryParse(data['createdAt']?.toString() ?? '') ?? now;
        final day = DateTime(created.year, created.month, created.day);
        if (!day.isBefore(todayStart)) {
          revenueToday += amount;
          ordersToday += 1;
        }
        if (!day.isBefore(sevenDayStart)) {
          revenue7d += amount;
        }
        if (!day.isBefore(windowStart)) {
          final agg = perDay.putIfAbsent(day, () => _DayAgg());
          agg.revenue += amount;
          agg.orders += 1;
        }
      }

      // Platform-wide order count comes from a cheap aggregate; the scoped
      // count is what the bounded fetch found.
      if (authorUid == null) {
        totalOrders = await _count(ordersRef);
      }

      // Build a continuous series for the chart (fill gaps with zero).
      final daily = <DailyRevenuePoint>[];
      for (var i = 0; i < chartDays; i++) {
        final day = windowStart.add(Duration(days: i));
        final agg = perDay[day];
        daily.add(
          DailyRevenuePoint(
            day: day,
            revenue: agg?.revenue ?? 0,
            orders: agg?.orders ?? 0,
          ),
        );
      }

      return DashboardStats(
        totalUsers: results[0],
        totalDesigners: results[1],
        totalDesigns: results[2],
        activeDesigns: results[3],
        pendingDesigns: results[4],
        totalOrders: totalOrders,
        ordersToday: ordersToday,
        revenueToday: revenueToday,
        revenue7d: revenue7d,
        revenueTotal: revenueTotal,
        dailyRevenue: daily,
      );
    } on FirebaseException catch (e, s) {
      AppLogger.logError('getStats', error: e, stackTrace: s);
      throw ServerException(message: e.message ?? 'Failed to load stats');
    } catch (e, s) {
      AppLogger.logError('getStats', error: e, stackTrace: s);
      throw ServerException(message: 'Unexpected error: $e');
    }
  }
}

class _DayAgg {
  int revenue = 0;
  int orders = 0;
}
