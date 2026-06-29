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
  Future<DashboardStats> getStats({int chartDays});
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

  @override
  Future<DashboardStats> getStats({int chartDays = 7}) async {
    try {
      final usersRef = _firestore.collection(FirestoreCollections.users);
      final designsRef = _firestore.collection(FirestoreCollections.designs);
      final ordersRef = _firestore.collection(FirestoreCollections.orders);

      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final windowStart = todayStart.subtract(Duration(days: chartDays - 1));

      // Counts via aggregate queries (cheap; one read unit each).
      final results = await Future.wait<int>([
        _count(usersRef),
        _count(usersRef.where('role', isEqualTo: UserRole.designer.value)),
        _count(designsRef),
        _count(designsRef.where('status', isEqualTo: 'active')),
        _count(designsRef.where('status', isEqualTo: 'pending')),
        _count(ordersRef),
      ]);

      // Paid orders for revenue. Bounded + ordered by createdAt so we sum the
      // most recent paid orders. We filter status client-side to avoid needing
      // a composite index (status + createdAt).
      final paidSnap = await ordersRef
          .orderBy('createdAt', descending: true)
          .limit(_maxOrderFetch)
          .get();

      final paidOrders = paidSnap.docs
          .map((d) => OrderModel.fromFirebaseJson(d.data(), d.id))
          .where((o) => o.status == OrderStatus.paid)
          .toList();

      var revenueToday = 0;
      var revenue7d = 0;
      var revenueTotal = 0;
      var ordersToday = 0;
      final perDay = <DateTime, _DayAgg>{};

      final sevenDayStart = todayStart.subtract(const Duration(days: 6));

      for (final o in paidOrders) {
        final amount = o.totalAmount; // integer rupees
        revenueTotal += amount;
        final created = o.createdAt;
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
        totalOrders: results[5],
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
