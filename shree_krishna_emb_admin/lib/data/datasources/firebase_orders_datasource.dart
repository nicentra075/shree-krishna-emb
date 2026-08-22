import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shree_krishna_core/shree_krishna_core.dart'
    hide ServerException;
import 'package:shree_krishna_emb_admin/core/errors/exceptions.dart';
import 'package:shree_krishna_emb_admin/core/utils/app_logger.dart';

/// All orders fetched once into an in-memory cache (mirrors the user-list and
/// catalog datasources). Status filter, date range, search and pagination all
/// run client-side over the cache, so a keystroke/filter/page never triggers a
/// fresh Firestore read. The cache refreshes on TTL expiry or [forceRefresh].
///
/// Orders are written ONLY by Cloud Functions — this datasource is read-only
/// except [getCount] which is derived from the same cache.
abstract class OrdersDataSource {
  /// Returns the full, date-desc ordered order list (served from cache when
  /// fresh). Filtering/pagination is done by the repository/cubit.
  ///
  /// [ownerUid] (designer sessions — D2) restricts the read to orders whose
  /// `ownerIds` contains the uid; rules deny designers anything broader.
  Future<List<OrderModel>> getAllOrders({bool forceRefresh, String? ownerUid});

  /// Invalidate the cache so the next read hits Firestore (used after a refund).
  void invalidate();
}

class FirebaseOrdersDataSource implements OrdersDataSource {
  final FirebaseFirestore _firestore;

  FirebaseOrdersDataSource({required FirebaseFirestore firestore})
    : _firestore = firestore;

  static const Duration _ttl = Duration(minutes: 2);

  /// Safety cap so a huge orders collection can't blow up a client read.
  static const int _maxFetch = 2000;

  List<OrderModel>? _cache;
  DateTime? _cachedAt;

  bool get _fresh =>
      _cachedAt != null && DateTime.now().difference(_cachedAt!) < _ttl;

  @override
  void invalidate() {
    _cache = null;
    _cachedAt = null;
  }

  @override
  Future<List<OrderModel>> getAllOrders({
    bool forceRefresh = false,
    String? ownerUid,
  }) async {
    final cache = _cache;
    if (ownerUid == null && !forceRefresh && cache != null && _fresh) {
      return cache;
    }
    try {
      // Designer scope filters in the QUERY (rules require it) and skips
      // orderBy so no composite index is needed — sorted client-side.
      final snap = ownerUid == null
          ? await _firestore
                .collection(FirestoreCollections.orders)
                .orderBy('createdAt', descending: true)
                .limit(_maxFetch)
                .get()
          : await _firestore
                .collection(FirestoreCollections.orders)
                .where('ownerIds', arrayContains: ownerUid)
                .limit(_maxFetch)
                .get();

      final orders = snap.docs
          .map((d) => OrderModel.fromFirebaseJson(d.data(), d.id))
          .toList();
      if (ownerUid != null) {
        orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return orders; // designer reads are small — no shared cache
      }

      _cache = orders;
      _cachedAt = DateTime.now();
      return orders;
    } on FirebaseException catch (e, s) {
      AppLogger.logError('getAllOrders', error: e, stackTrace: s);
      throw ServerException(message: e.message ?? 'Failed to load orders');
    } catch (e, s) {
      AppLogger.logError('getAllOrders', error: e, stackTrace: s);
      throw ServerException(message: 'Unexpected error: $e');
    }
  }
}
