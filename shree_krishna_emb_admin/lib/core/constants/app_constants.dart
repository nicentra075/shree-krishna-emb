/// Centralized constants for the admin app.
/// All SharedPreferences/Hive storage keys must live here —
/// never hardcode storage keys in screens, services, or datasources.
class AppConstants {
  AppConstants._();

  // SharedPreferences keys — admin auth session
  static const String kIsAdminLoggedIn = 'is_admin_logged_in';
  static const String kAdminId = 'admin_id';
  static const String kAdminEmail = 'admin_email';
}
