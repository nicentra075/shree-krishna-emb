// Custom exceptions for better error handling

class ServerException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  ServerException({
    required this.message,
    this.code,
    this.originalError,
  });

  @override
  String toString() => 'ServerException: $message${code != null ? ' (Code: $code)' : ''}';
}

class CacheException implements Exception {
  final String message;

  CacheException(this.message);

  @override
  String toString() => 'CacheException: $message';
}

class NetworkException implements Exception {
  final String message;

  NetworkException(this.message);

  @override
  String toString() => 'NetworkException: $message';
}

class AuthenticationException implements Exception {
  final String message;

  AuthenticationException(this.message);

  @override
  String toString() => 'AuthenticationException: $message';
}

class ValidationException implements Exception {
  final String message;
  final Map<String, String>? fieldErrors;

  ValidationException({required this.message, this.fieldErrors});

  @override
  String toString() => 'ValidationException: $message';
}
