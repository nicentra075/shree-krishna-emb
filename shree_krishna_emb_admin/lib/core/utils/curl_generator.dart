/// Utility to generate curl commands from API request details
///
/// Useful for debugging, testing, and API documentation
///
/// Usage:
/// ```dart
/// final curl = CurlGenerator.generate(
///   method: 'POST',
///   url: 'https://api.example.com/users',
///   headers: {'Authorization': 'Bearer token', 'Content-Type': 'application/json'},
///   body: {'name': 'John', 'email': 'john@example.com'},
/// );
/// print(curl); // Prints full curl command
/// ```
class CurlGenerator {
  CurlGenerator._();

  /// Generate a curl command from API request details
  static String generate({
    required String method,
    required String url,
    Map<String, String>? headers,
    dynamic body,
    Map<String, String>? queryParams,
  }) {
    final buffer = StringBuffer();

    // Base curl command
    buffer.write('curl -X $method');

    // URL with query parameters
    String finalUrl = url;
    if (queryParams != null && queryParams.isNotEmpty) {
      final queryString = queryParams.entries
          .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');
      finalUrl = '$url?$queryString';
    }
    buffer.write(' "$finalUrl"');

    // Headers
    if (headers != null && headers.isNotEmpty) {
      for (final entry in headers.entries) {
        buffer.write(' \\');
        buffer.write('\n');
        buffer.write('  -H "${entry.key}: ${entry.value}"');
      }
    }

    // Body
    if (body != null) {
      buffer.write(' \\');
      buffer.write('\n');

      String bodyString;
      if (body is String) {
        bodyString = body;
      } else if (body is Map) {
        // Convert map to JSON-like string
        bodyString = _mapToJsonString(body);
      } else {
        bodyString = body.toString();
      }

      // Escape quotes in body
      bodyString = bodyString.replaceAll('"', '\\"');
      buffer.write('  -d "$bodyString"');
    }

    return buffer.toString();
  }

  /// Convert a map to JSON-like string representation
  static String _mapToJsonString(Map<dynamic, dynamic> map) {
    final entries = <String>[];

    for (final entry in map.entries) {
      final key = entry.key;
      final value = entry.value;

      String valueStr;
      if (value is String) {
        valueStr = '"$value"';
      } else if (value is bool) {
        valueStr = value ? 'true' : 'false';
      } else if (value is num) {
        valueStr = value.toString();
      } else if (value is Map) {
        valueStr = _mapToJsonString(value);
      } else if (value is List) {
        valueStr = _listToJsonString(value);
      } else {
        valueStr = '"$value"';
      }

      entries.add('"$key": $valueStr');
    }

    return '{${entries.join(', ')}}';
  }

  /// Convert a list to JSON-like string representation
  static String _listToJsonString(List<dynamic> list) {
    final items = <String>[];

    for (final item in list) {
      String itemStr;
      if (item is String) {
        itemStr = '"$item"';
      } else if (item is bool) {
        itemStr = item ? 'true' : 'false';
      } else if (item is num) {
        itemStr = item.toString();
      } else if (item is Map) {
        itemStr = _mapToJsonString(item);
      } else if (item is List) {
        itemStr = _listToJsonString(item);
      } else {
        itemStr = '"$item"';
      }

      items.add(itemStr);
    }

    return '[${items.join(', ')}]';
  }
}
