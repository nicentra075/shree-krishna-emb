/// Centralized constants for the entire app
/// All hardcoded strings, API endpoints, and storage keys should be defined here
abstract class AppConstants {
  // ========== SharedPreferences Keys ==========
  /// User authentication and session storage keys
  static const String prefKeyRememberMe = 'remember_me';
  static const String prefKeySavedEmail = 'saved_email';
  static const String prefKeySavedPassword = 'saved_password';

  /// Date (yyyy-MM-dd) of the last account-status (suspension) check, used to
  /// throttle the home-screen re-validation to once per day.
  static const String prefKeyLastStatusCheckDate = 'last_status_check_date';

  // Add more SharedPreferences keys here as needed
  // static const String prefKeyUserToken = 'user_token';
  // static const String prefKeyUserId = 'user_id';
  // static const String prefKeyLastLoginTime = 'last_login_time';

  // ========== Hive Box Names ==========
  /// Hive database box names for local storage
  // static const String hiveBoxUsers = 'users';
  // static const String hiveBoxProducts = 'products';
  // static const String hiveBoxOrders = 'orders';
  // static const String hiveBoxCache = 'cache';

  // ========== API Endpoints ==========
  // static const String apiBaseUrl = 'https://api.example.com';
  // static const String apiLoginEndpoint = '/auth/login';
  // static const String apiSignupEndpoint = '/auth/signup';

  // ========== Validation Rules ==========
  // static const int minPasswordLength = 8;
  // static const int maxNameLength = 50;
  // static const int maxPhoneLength = 20;

  // ========== Timeout Durations ==========
  // static const Duration apiTimeout = Duration(seconds: 30);
  // static const Duration sessionTimeout = Duration(hours: 24);
}
