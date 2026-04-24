import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shree_krishna_core/shree_krishna_core.dart';

/// Abstract interface for local (cached) user data source
/// Mirrors the remote UserDataSource interface but returns cached data
abstract class LocalUserDataSource extends LocalDataSourceBase {
  /// Get cached user by ID, returns null if not found or expired
  Future<CachedData<UserModel>?> getCachedUser(String userId);

  /// Cache a user model
  Future<void> cacheUser(UserModel user);

  /// Get cached user list, returns null if not found or expired
  Future<CachedData<List<UserModel>>?> getCachedUserList(String cacheKey);

  /// Cache a list of users
  Future<void> cacheUserList(String cacheKey, List<UserModel> users);

  /// Remove a specific user from cache
  Future<void> invalidateUser(String userId);

  /// Remove a specific user list from cache
  Future<void> invalidateUserList(String cacheKey);

  /// Check if user has seen the walkthrough onboarding
  Future<bool> getWalkthroughSeen();

  /// Mark walkthrough as seen
  Future<void> setWalkthroughSeen(bool seen);

  /// Get saved theme mode preference (light/dark)
  Future<String?> getSavedThemeMode();

  /// Save theme mode preference
  Future<void> saveThemeMode(String mode);
}

/// Hive-based implementation of LocalUserDataSource
/// Uses Hive for structured data caching and SharedPreferences for simple flags
class HiveLocalUserDataSource implements LocalUserDataSource {
  final Box<String> _userBox;
  final Box<String> _userListBox;
  final SharedPreferences _prefs;

  HiveLocalUserDataSource({
    required Box<String> userBox,
    required Box<String> userListBox,
    required SharedPreferences prefs,
  })  : _userBox = userBox,
        _userListBox = userListBox,
        _prefs = prefs;

  @override
  Future<void> init() async {
    // Boxes are opened before construction in service locator
    // This is a no-op but required by LocalDataSourceBase interface
  }

  @override
  Future<void> clearAll() async {
    await _userBox.clear();
    await _userListBox.clear();
    await _prefs.clear();
  }

  @override
  Future<void> clearExpired() async {
    // Clear expired user entries
    final userKeys = _userBox.keys.toList();
    for (final key in userKeys) {
      final jsonString = _userBox.get(key);
      if (jsonString != null) {
        try {
          final json = jsonDecode(jsonString);
          final cached = CachedData.fromJson(
            json,
            (data) => UserModel.fromFirebaseJson(
              data,
              key,
            ),
          );
          if (cached.isExpired) {
            await _userBox.delete(key);
          }
        } catch (e) {
          // If parsing fails, delete the corrupted entry
          await _userBox.delete(key);
        }
      }
    }

    // Clear expired list entries
    final listKeys = _userListBox.keys.toList();
    for (final key in listKeys) {
      final jsonString = _userListBox.get(key);
      if (jsonString != null) {
        try {
          final json = jsonDecode(jsonString);
          final cachedAt = DateTime.parse(json['cachedAt']);
          final ttl = Duration(seconds: json['ttl']);
          if (DateTime.now().isAfter(cachedAt.add(ttl))) {
            await _userListBox.delete(key);
          }
        } catch (e) {
          await _userListBox.delete(key);
        }
      }
    }
  }

  @override
  Future<CachedData<UserModel>?> getCachedUser(String userId) async {
    try {
      final jsonString = _userBox.get('user_$userId');
      if (jsonString == null) return null;

      final json = jsonDecode(jsonString);
      final cached = CachedData.fromJson(
        json,
        (data) => UserModel.fromFirebaseJson(data, userId),
      );

      // Return null if expired (caller will fetch from remote)
      if (cached.isExpired) {
        return null;
      }

      return cached;
    } catch (e) {
      // On parsing error, remove corrupted entry
      await _userBox.delete('user_$userId');
      return null;
    }
  }

  @override
  Future<void> cacheUser(UserModel user) async {
    try {
      final cached = CachedData(
        data: user,
        cachedAt: DateTime.now(),
        ttl: CacheConfig.userTtl,
      );

      final json = cached.toJson((userData) => userData.toFirebaseJson());
      await _userBox.put('user_${user.id}', jsonEncode(json));
    } catch (e) {
      // Silently fail caching errors - don't crash the app
    }
  }

  @override
  Future<CachedData<List<UserModel>>?> getCachedUserList(
    String cacheKey,
  ) async {
    try {
      final jsonString = _userListBox.get(cacheKey);
      if (jsonString == null) return null;

      final json = jsonDecode(jsonString);
      final cachedAt = DateTime.parse(json['cachedAt']);
      final ttl = Duration(seconds: json['ttl']);

      // Check expiration
      if (DateTime.now().isAfter(cachedAt.add(ttl))) {
        return null;
      }

      final dataList = (json['data'] as List)
          .map((item) => UserModel.fromFirebaseJson(item, item['id']))
          .toList();

      return CachedData(
        data: dataList,
        cachedAt: cachedAt,
        ttl: ttl,
      );
    } catch (e) {
      // On parsing error, remove corrupted entry
      await _userListBox.delete(cacheKey);
      return null;
    }
  }

  @override
  Future<void> cacheUserList(
    String cacheKey,
    List<UserModel> users,
  ) async {
    try {
      final json = {
        'data': users.map((u) => u.toFirebaseJson()).toList(),
        'cachedAt': DateTime.now().toIso8601String(),
        'ttl': CacheConfig.userListTtl.inSeconds,
      };
      await _userListBox.put(cacheKey, jsonEncode(json));
    } catch (e) {
      // Silently fail caching errors
    }
  }

  @override
  Future<void> invalidateUser(String userId) async {
    try {
      await _userBox.delete('user_$userId');
    } catch (e) {
      // Silently fail invalidation errors
    }
  }

  @override
  Future<void> invalidateUserList(String cacheKey) async {
    try {
      await _userListBox.delete(cacheKey);
    } catch (e) {
      // Silently fail invalidation errors
    }
  }

  @override
  Future<bool> getWalkthroughSeen() async {
    return _prefs.getBool(CacheConfig.walkthroughSeenKey) ?? false;
  }

  @override
  Future<void> setWalkthroughSeen(bool seen) async {
    await _prefs.setBool(CacheConfig.walkthroughSeenKey, seen);
  }

  @override
  Future<String?> getSavedThemeMode() async {
    return _prefs.getString(CacheConfig.themeModeKey);
  }

  @override
  Future<void> saveThemeMode(String mode) async {
    await _prefs.setString(CacheConfig.themeModeKey, mode);
  }
}
