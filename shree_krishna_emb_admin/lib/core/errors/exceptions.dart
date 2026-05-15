/// Server exceptions from Firebase or API calls
class ServerException implements Exception {
  final String message;

  ServerException({required this.message});

  @override
  String toString() => 'ServerException: $message';
}

/// Local exceptions from device storage (Hive, SharedPreferences)
class LocalException implements Exception {
  final String message;

  LocalException({required this.message});

  @override
  String toString() => 'LocalException: $message';
}

/// Invalid input/validation exceptions
class ValidationException implements Exception {
  final String message;

  ValidationException({required this.message});

  @override
  String toString() => 'ValidationException: $message';
}
