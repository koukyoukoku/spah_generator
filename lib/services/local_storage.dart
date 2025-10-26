import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static const String _lastSyncKey = 'last_sync_time';
  static const String _isSyncedKey = 'is_synced';

  static Future<void> saveLastSyncTime(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncKey, time.toIso8601String());
  }

  static Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timeString = prefs.getString(_lastSyncKey);
    if (timeString != null) {
      return DateTime.parse(timeString);
    }
    return null;
  }

  static Future<void> setSyncStatus(bool isSynced) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isSyncedKey, isSynced);
  }

  static Future<bool> getSyncStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isSyncedKey) ?? false;
  }
}