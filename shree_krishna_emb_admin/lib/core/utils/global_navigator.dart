import 'package:flutter/material.dart';

/// Global Navigator Key for the Admin App
///
/// This key provides access to the navigator state from anywhere in the app
/// without needing to pass context through the widget tree.
///
/// Usage:
/// ```dart
/// // Push a named route
/// GlobalNavigator.navigatorKey.currentState?.pushNamed('/login');
///
/// // Pop the current route
/// GlobalNavigator.navigatorKey.currentState?.pop();
///
/// // Get current context
/// BuildContext? context = GlobalNavigator.navigatorKey.currentContext;
///
/// // Check if navigator is available
/// if (GlobalNavigator.isNavigatorReady) {
///   GlobalNavigator.navigatorKey.currentState?.pushNamed('/home');
/// }
/// ```
class GlobalNavigator {
  GlobalNavigator._();

  /// The global navigator key for the app
  /// Must be assigned to MaterialApp's navigatorKey property
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Get the current navigator state
  static NavigatorState? get state => navigatorKey.currentState;

  /// Get the current build context
  static BuildContext? get context => navigatorKey.currentContext;

  /// Check if navigator is ready to use
  static bool get isNavigatorReady =>
      navigatorKey.currentState != null && navigatorKey.currentContext != null;

  /// Push a named route
  static Future? pushNamed(String routeName, {Object? arguments}) {
    return state?.pushNamed(routeName, arguments: arguments);
  }

  /// Push a replacement route
  static Future? pushReplacementNamed(String routeName,
      {Object? arguments, Object? result}) {
    return state?.pushReplacementNamed(routeName,
        arguments: arguments, result: result);
  }

  /// Push and remove all previous routes
  static Future? pushNamedAndRemoveUntil(
    String routeName, {
    Object? arguments,
  }) {
    return state?.pushNamedAndRemoveUntil(
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }

  /// Pop the current route
  static void pop<T>([T? result]) {
    state?.pop<T>(result);
  }

  /// Pop until a route
  static void popUntil(bool Function(Route<dynamic>) predicate) {
    state?.popUntil(predicate);
  }

  /// Check if can pop
  static bool canPop() {
    return state?.canPop() ?? false;
  }
}
