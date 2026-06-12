/// Central configuration for all cache TTL (Time To Live) values
/// and cache-related constants
///
/// Usage:
/// ```dart
/// final userTtl = CacheConfig.userTtl; // Duration(hours: 1)
/// final seenKey = CacheConfig.walkthroughSeenKey; // 'walkthrough_seen'
/// ```
class CacheConfig {
  // Private constructor to prevent instantiation
  CacheConfig._();

  // ==== Cache TTL Values (Duration) ====

  /// TTL for individual user data fetches (1 hour)
  static const Duration userTtl = Duration(hours: 1);

  /// TTL for paginated user lists (15 minutes - lists change frequently)
  static const Duration userListTtl = Duration(minutes: 15);

  /// TTL for product data (2 hours)
  static const Duration productTtl = Duration(hours: 2);

  /// TTL for paginated product lists (30 minutes)
  static const Duration productListTtl = Duration(minutes: 30);

  /// TTL for order data (3 hours)
  static const Duration orderTtl = Duration(hours: 3);

  /// TTL for search results (10 minutes - volatile)
  static const Duration searchResultsTtl = Duration(minutes: 10);

  /// TTL for individual design docs (30 minutes)
  static const Duration designTtl = Duration(minutes: 30);

  /// TTL for paginated design lists (15 minutes)
  static const Duration designListTtl = Duration(minutes: 15);

  /// TTL for the category list (24 hours - rarely changes, ≤30 docs)
  static const Duration categoryTtl = Duration(hours: 24);

  /// TTL for the config/homeFeed banner doc (30 minutes)
  static const Duration homeFeedTtl = Duration(minutes: 30);

  /// TTL for the config/platform settings doc (6 hours)
  static const Duration configTtl = Duration(hours: 6);

  /// TTL for dashboard stats docs (5 minutes)
  static const Duration statsTtl = Duration(minutes: 5);

  // ==== Cache Key Constants (for SharedPreferences) ====

  /// Key for storing whether user has seen the walkthrough onboarding
  static const String walkthroughSeenKey = 'walkthrough_seen';

  /// Key for storing user's theme mode preference (light/dark)
  static const String themeModeKey = 'theme_mode';

  /// Key for storing the last sync timestamp
  static const String lastSyncKey = 'last_sync_time';

  /// Key for storing user authentication token (if needed)
  static const String authTokenKey = 'auth_token';

  // ==== Hive Box Names ====

  /// Hive box name for caching individual user models
  static const String userBoxName = 'user_cache';

  /// Hive box name for caching lists of users
  static const String userListBoxName = 'user_list_cache';

  /// Hive box name for caching products
  static const String productBoxName = 'product_cache';

  /// Hive box name for caching orders
  static const String orderBoxName = 'order_cache';

  /// Hive box name for the offline cart mirror (Firestore is authoritative)
  static const String cartBoxName = 'cart_cache';

  /// Hive box name for the wishlist mirror
  static const String wishlistBoxName = 'wishlist_cache';

  /// Hive box name for the local-only recently-viewed LRU (max 20 designs)
  static const String recentlyViewedBoxName = 'recently_viewed';

  /// Hive box name for the home feed (banners/categories/rails) cache
  static const String homeFeedBoxName = 'home_feed_cache';

  /// Hive box name for caching the My Orders list
  static const String orderListBoxName = 'order_list_cache';
}
