/// Abstract base class for all local (cached) data sources
///
/// This interface ensures all caching implementations have consistent
/// initialization and cleanup methods for cache management.
///
/// Usage:
/// ```dart
/// class HiveLocalUserDataSource extends LocalDataSourceBase {
///   @override
///   Future<void> init() async {
///     // Open Hive boxes, initialize SharedPreferences, etc.
///   }
///
///   @override
///   Future<void> clearAll() async {
///     // Clear all cached data
///   }
/// }
/// ```
abstract class LocalDataSourceBase {
  /// Initialize the local data source
  ///
  /// This is called once during app startup after service locator setup.
  /// Implementations should open database connections, load preferences, etc.
  Future<void> init();

  /// Clear all cached data
  ///
  /// This is called when user logs out or explicitly clears app cache.
  Future<void> clearAll();

  /// Clear only expired cache entries
  ///
  /// This is useful for periodic maintenance to free up storage space.
  /// Implementations should check TTL for each cached item and delete stale entries.
  Future<void> clearExpired();
}
