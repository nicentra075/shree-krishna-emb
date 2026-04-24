import 'package:shared_preferences/shared_preferences.dart';
import 'locales/locale_base.dart';
import 'locales/en_us.dart';
import 'locales/hi_in.dart';

class AppLocalization {
  static late SharedPreferences _prefs;
  static LocaleStrings _currentStrings = EnUSStrings();
  static const String _localeKey = 'app_locale';

  static LocaleStrings get strings => _currentStrings;

  static Future<void> initialize(SharedPreferences prefs) async {
    _prefs = prefs;
    final savedLocale = _prefs.getString(_localeKey) ?? 'en_US';
    await setLocale(savedLocale);
  }

  static Future<void> setLocale(String locale) async {
    _currentStrings = _getStringsForLocale(locale);
    await _prefs.setString(_localeKey, locale);
  }

  static LocaleStrings _getStringsForLocale(String locale) {
    switch (locale) {
      case 'hi_IN':
      case 'hi':
        return HiINStrings();
      case 'en_US':
      case 'en':
      default:
        return EnUSStrings();
    }
  }

  static String getCurrentLocale() {
    return _prefs.getString(_localeKey) ?? 'en_US';
  }

  static List<String> getSupportedLocales() => ['en_US', 'hi_IN'];
}
