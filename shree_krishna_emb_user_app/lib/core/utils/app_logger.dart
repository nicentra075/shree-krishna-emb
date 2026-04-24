import 'package:flutter/foundation.dart';
import 'package:shree_krishna_emb/core/utils/curl_generator.dart';

/// Common debug logging utility for the app
///
/// All logging methods automatically respect debug mode.
/// In release mode, NO logging will occur regardless of method called.
///
/// Usage:
/// ```dart
/// AppLogger.log('User navigated to login screen');
/// AppLogger.logNavigation('/login');
/// AppLogger.logError('Error occurred', error);
/// AppLogger.logFirebaseOperation('Read', collection: 'users', document: 'user123');
/// AppLogger.logApi('GET', 'https://api.example.com/users', headers: {...});
/// ```
class AppLogger {
  AppLogger._();

  /// Log a general message
  ///
  /// Only logs in debug mode
  static void log(String message) {
    if (!kDebugMode) return;
    debugPrint('🔵 [AppLog] $message');
  }

  /// Log navigation events with full details
  ///
  /// Only logs in debug mode
  static void logNavigation(String routeName, {Object? arguments}) {
    if (!kDebugMode) return;
    final time = DateTime.now().toString().split('.')[0];
    final args = arguments != null ? ' | Args: $arguments' : '';
    debugPrint('════════════════════════════════════════════════════');
    debugPrint('🧭 [NAVIGATION] $time');
    debugPrint('Route: $routeName$args');
    debugPrint('════════════════════════════════════════════════════');
  }

  /// Log error messages with optional stack trace
  ///
  /// Only logs in debug mode
  static void logError(String message, {dynamic error, StackTrace? stackTrace}) {
    if (!kDebugMode) return;
    debugPrint('════════════════════════════════════════════════════');
    debugPrint('❌ [ERROR] $message');
    if (error != null) {
      debugPrint('Exception: $error');
    }
    if (stackTrace != null) {
      debugPrint('StackTrace:\n$stackTrace');
    }
    debugPrint('════════════════════════════════════════════════════');
  }

  /// Log API/async operation events
  ///
  /// Only logs in debug mode
  static void logOperation(String operation, {String? status, dynamic data}) {
    if (!kDebugMode) return;
    final statusText = status != null ? ' | Status: $status' : '';
    final dataText = data != null ? ' | Data: $data' : '';
    debugPrint('⚙️ [OPERATION] $operation$statusText$dataText');
  }

  /// Log user actions and interactions
  ///
  /// Only logs in debug mode
  static void logUserAction(String action, {String? details}) {
    if (!kDebugMode) return;
    final detailsText = details != null ? ' - $details' : '';
    debugPrint('👤 [USER ACTION] $action$detailsText');
  }

  /// Log data and state changes
  ///
  /// Only logs in debug mode
  static void logStateChange(String stateName, {String? details, dynamic newValue}) {
    if (!kDebugMode) return;
    final detailsText = details != null ? ' | Details: $details' : '';
    final valueText = newValue != null ? ' | Value: $newValue' : '';
    debugPrint('📊 [STATE CHANGE] $stateName$detailsText$valueText');
  }

  /// Log API calls with full request and response details
  ///
  /// Generates curl command for easy testing and debugging
  /// Only logs in debug mode
  static void logApi(
    String method,
    String endpoint, {
    Map<String, String>? headers,
    dynamic requestBody,
    int? statusCode,
    dynamic responseBody,
    String? errorMessage,
  }) {
    if (!kDebugMode) return;

    debugPrint('════════════════════════════════════════════════════');
    debugPrint('🌐 [API REQUEST] $method $endpoint');
    debugPrint('════════════════════════════════════════════════════');

    // Log headers
    if (headers != null && headers.isNotEmpty) {
      debugPrint('📋 Headers:');
      headers.forEach((key, value) {
        debugPrint('  $key: $value');
      });
    }

    // Log request body
    if (requestBody != null) {
      debugPrint('📤 Request Body:');
      debugPrint('  $requestBody');
    }

    // Log response status
    if (statusCode != null) {
      final statusEmoji = statusCode >= 200 && statusCode < 300 ? '✅' : '❌';
      debugPrint('$statusEmoji Response Status: $statusCode');
    }

    // Log response body
    if (responseBody != null) {
      debugPrint('📥 Response Body:');
      debugPrint('  $responseBody');
    }

    // Log error if present
    if (errorMessage != null) {
      debugPrint('⚠️ Error: $errorMessage');
    }

    // Generate and log curl command
    final curlCommand = CurlGenerator.generate(
      method: method,
      url: endpoint,
      headers: headers,
      body: requestBody,
    );
    debugPrint('');
    debugPrint('🔧 Curl Command (for testing):');
    debugPrint(curlCommand);
    debugPrint('════════════════════════════════════════════════════');
  }

  /// Log database operations
  ///
  /// Only logs in debug mode
  static void logDatabase(String operation, {String? collection, dynamic data}) {
    if (!kDebugMode) return;
    final coll = collection != null ? ' | Collection: $collection' : '';
    final dt = data != null ? ' | Data: $data' : '';
    debugPrint('💾 [DATABASE] $operation$coll$dt');
  }

  /// Log Firebase/Firestore operations with complete details
  ///
  /// Shows:
  /// - Operation type (Read, Write, Delete, Update, Query, Watch)
  /// - Collection and document path
  /// - Query parameters if applicable
  /// - Data being written
  /// - Results/errors
  /// Only logs in debug mode
  static void logFirebaseOperation(
    String operationType, {
    required String collection,
    String? document,
    Map<String, dynamic>? queryParams,
    dynamic data,
    dynamic result,
    String? errorMessage,
    int? durationMs,
  }) {
    if (!kDebugMode) return;

    debugPrint('════════════════════════════════════════════════════');
    debugPrint('🔥 [FIREBASE] $operationType | $collection');
    debugPrint('════════════════════════════════════════════════════');

    // Log document path
    if (document != null) {
      debugPrint('📄 Document: $document');
      debugPrint('   Full Path: $collection/$document');
    }

    // Log query parameters
    if (queryParams != null && queryParams.isNotEmpty) {
      debugPrint('🔍 Query Parameters:');
      queryParams.forEach((key, value) {
        debugPrint('  $key: $value');
      });
    }

    // Log data being written/updated
    if (data != null) {
      debugPrint('📝 Data:');
      debugPrint('  $data');
    }

    // Log result
    if (result != null) {
      debugPrint('✅ Result:');
      debugPrint('  $result');
    }

    // Log error if present
    if (errorMessage != null) {
      debugPrint('❌ Error: $errorMessage');
    }

    // Log duration if available
    if (durationMs != null) {
      debugPrint('⏱️ Duration: ${durationMs}ms');
    }

    debugPrint('════════════════════════════════════════════════════');
  }

  /// Log Firestore query watch events
  ///
  /// Useful for debugging real-time listeners
  static void logFirebaseWatch(
    String collection, {
    String? query,
    int? docCount,
    String? errorMessage,
  }) {
    if (!kDebugMode) return;

    debugPrint('────────────────────────────────────────────────────');
    debugPrint('👁️ [FIREBASE WATCH] $collection');
    if (query != null) {
      debugPrint('   Query: $query');
    }
    if (docCount != null) {
      debugPrint('   Documents received: $docCount');
    }
    if (errorMessage != null) {
      debugPrint('   ⚠️ Error: $errorMessage');
    }
    debugPrint('────────────────────────────────────────────────────');
  }

  /// Log Firestore batch write operations
  ///
  /// Useful for debugging complex write operations
  static void logFirebaseBatch({
    required int operationCount,
    List<String>? operations,
    bool? isCommitted,
    String? errorMessage,
  }) {
    if (!kDebugMode) return;

    debugPrint('════════════════════════════════════════════════════');
    debugPrint('📦 [FIREBASE BATCH] Total Operations: $operationCount');
    debugPrint('════════════════════════════════════════════════════');

    if (operations != null && operations.isNotEmpty) {
      debugPrint('Operations:');
      for (int i = 0; i < operations.length; i++) {
        debugPrint('  ${i + 1}. ${operations[i]}');
      }
    }

    if (isCommitted != null) {
      final status = isCommitted ? '✅ Committed' : '⏳ Pending';
      debugPrint(status);
    }

    if (errorMessage != null) {
      debugPrint('❌ Error: $errorMessage');
    }

    debugPrint('════════════════════════════════════════════════════');
  }
}
