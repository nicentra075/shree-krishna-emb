import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../cache/cache_config.dart';

/// App-wide theme mode state with SharedPreferences persistence.
/// Shared by the Admin and User apps; provided once in main.dart:
///
/// ```dart
/// BlocProvider.value(value: getIt<ThemeCubit>(), child: ...)
/// // MaterialApp(themeMode: context.watch<ThemeCubit>().state, ...)
/// ```
class ThemeCubit extends Cubit<ThemeMode> {
  final SharedPreferences _prefs;

  ThemeCubit(this._prefs) : super(_load(_prefs));

  static ThemeMode _load(SharedPreferences prefs) {
    final stored = prefs.getString(CacheConfig.themeModeKey);
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == stored,
      orElse: () => ThemeMode.system,
    );
  }

  void setMode(ThemeMode mode) {
    emit(mode);
    _prefs.setString(CacheConfig.themeModeKey, mode.name);
  }

  /// Light ↔ dark convenience toggle (system resolves to the opposite of
  /// the current platform brightness on first toggle).
  void toggle() {
    setMode(state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }
}
