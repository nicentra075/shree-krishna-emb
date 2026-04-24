import 'package:equatable/equatable.dart';

/// Generic wrapper for cached data with TTL (Time To Live) support
///
/// Usage:
/// ```dart
/// final cached = CachedData(
///   data: user,
///   cachedAt: DateTime.now(),
///   ttl: Duration(hours: 1),
/// );
///
/// if (!cached.isExpired) {
///   // Data is still fresh
///   return cached.data;
/// }
/// ```
class CachedData<T> extends Equatable {
  final T data;
  final DateTime cachedAt;
  final Duration ttl;

  const CachedData({
    required this.data,
    required this.cachedAt,
    required this.ttl,
  });

  /// Check if this cached data has expired
  bool get isExpired {
    return DateTime.now().isAfter(cachedAt.add(ttl));
  }

  /// Check if this cached data is still fresh
  bool get isFresh => !isExpired;

  /// Get the time remaining before expiration, or null if already expired
  Duration? get timeRemaining {
    if (isExpired) return null;
    final expiresAt = cachedAt.add(ttl);
    return expiresAt.difference(DateTime.now());
  }

  /// Serialize the cached data to JSON
  /// Requires a serializer function to convert T to JSON
  Map<String, dynamic> toJson(Map<String, dynamic> Function(T) dataSerializer) {
    return {
      'data': dataSerializer(data),
      'cachedAt': cachedAt.toIso8601String(),
      'ttl': ttl.inSeconds,
    };
  }

  /// Deserialize cached data from JSON
  /// Requires a deserializer function to convert JSON to T
  factory CachedData.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) dataDeserializer,
  ) {
    return CachedData(
      data: dataDeserializer(json['data'] as Map<String, dynamic>),
      cachedAt: DateTime.parse(json['cachedAt'] as String),
      ttl: Duration(seconds: json['ttl'] as int),
    );
  }

  @override
  List<Object?> get props => [data, cachedAt, ttl];
}
