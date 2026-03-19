import 'package:shared_preferences/shared_preferences.dart';

class PreferenceKeys {
  static const String userId = 'userId';
  static const String userName = 'userName';
  static const String userEmail = 'userEmail';
  static const String userAvatarUrl = 'userAvatarUrl';
  static const String deviceId = 'deviceId';
  static const String fcmToken = 'fcmToken';
  static const String dbEncryptionKey = 'dbEncryptionKey';
  static const String lastSyncTimestamp = 'lastSyncTimestamp';
  static const String isFirstLaunch = 'isFirstLaunch';
  static const String notificationsEnabled = 'notificationsEnabled';
  static const String selectedFolderId = 'selectedFolderId';
  static const String themeMode = 'themeMode'; // 'light', 'dark', 'system'
}

class SharedPreferenceHelper {
  static late SharedPreferences _prefs;

  static Future<SharedPreferences> init() async {
    _prefs = await SharedPreferences.getInstance();
    return _prefs;
  }

  // Sets
  static Future<bool> setBool(String key, bool value) async =>
      await _prefs.setBool(key, value);

  static Future<bool> setDouble(String key, double value) async =>
      await _prefs.setDouble(key, value);

  static Future<bool> setInt(String key, int value) async =>
      await _prefs.setInt(key, value);

  static Future<bool> setString(String key, String value) async =>
      await _prefs.setString(key, value);

  static Future<bool> setStringList(String key, List<String> value) async =>
      await _prefs.setStringList(key, value);

  // Gets
  static bool? getBool(String key) => _prefs.getBool(key);

  static double? getDouble(String key) => _prefs.getDouble(key);

  static int? getInt(String key) => _prefs.getInt(key);

  static String? getString(String key) => _prefs.getString(key);

  static List<String>? getStringList(String key) => _prefs.getStringList(key);

  // Deletes
  static Future<bool> remove(String key) async => await _prefs.remove(key);

  static Future<bool> clear() async => await _prefs.clear();
}
